import '../../models/patient_record_brd.dart';

/// Encapsulates all search/filter criteria for SQL-based clinical query
class SqlSearchCriteria {
  // Free-text search (LIKE across multiple fields)
  final String? searchQuery;

  // Date range filter (operations.created_at BETWEEN)
  final DateTime? dateFrom;
  final DateTime? dateTo;

  // POD filter (complications.pod_day range)
  final int? podDayMin;
  final int? podDayMax;
  final bool? podFilterActive;

  // Complications only
  final bool? complicationsOnly;

  // Advanced filters
  final String? procedure;           // Single-select: = ?
  final List<String>? procedures;    // Multi-select: IN (?, ?, ...)
  final String? gender;              // Single-select: = ?
  final double? ageMin;              // Number: >= ?
  final double? ageMax;              // Number: <= ?
  final String? complicationGrade;   // Single-select: = ?
  final List<String>? complicationGrades; // Multi-select: IN (?, ?, ...)
  final bool? garmentRequired;       // Boolean: = 1 or = 0
  final double? bmiMin;              // Number: >= ?
  final double? bmiMax;              // Number: <= ?
  final String? medicalHistoryQuery; // Text: LIKE ?
  final double? fatVolumeMin;        // Number: >= ?
  final double? fatVolumeMax;        // Number: <= ?

  final String? patientNameQuery;
  final String? operativeProcedureQuery;
  final String? procedureTechniqueQuery;

  const SqlSearchCriteria({
    this.searchQuery,
    this.dateFrom,
    this.dateTo,
    this.podDayMin,
    this.podDayMax,
    this.podFilterActive,
    this.complicationsOnly,
    this.procedure,
    this.procedures,
    this.gender,
    this.ageMin,
    this.ageMax,
    this.complicationGrade,
    this.complicationGrades,
    this.garmentRequired,
    this.bmiMin,
    this.bmiMax,
    this.medicalHistoryQuery,
    this.fatVolumeMin,
    this.fatVolumeMax,
    this.patientNameQuery,
    this.operativeProcedureQuery,
    this.procedureTechniqueQuery,
  });

  bool get hasAnyFilter =>
      searchQuery != null && searchQuery!.trim().isNotEmpty ||
      dateFrom != null ||
      dateTo != null ||
      podFilterActive == true ||
      complicationsOnly == true ||
      procedure != null ||
      (procedures != null && procedures!.isNotEmpty) ||
      gender != null ||
      ageMin != null ||
      ageMax != null ||
      complicationGrade != null ||
      (complicationGrades != null && complicationGrades!.isNotEmpty) ||
      garmentRequired != null ||
      bmiMin != null ||
      bmiMax != null ||
      (medicalHistoryQuery != null && medicalHistoryQuery!.trim().isNotEmpty) ||
      fatVolumeMin != null ||
      fatVolumeMax != null ||
      (patientNameQuery != null && patientNameQuery!.trim().isNotEmpty) ||
      (operativeProcedureQuery != null && operativeProcedureQuery!.trim().isNotEmpty) ||
      (procedureTechniqueQuery != null && procedureTechniqueQuery!.trim().isNotEmpty);
}

/// Result from SQL query builder containing the WHERE clause and parameters
class SqlQueryParts {
  final String whereClause;
  final List<dynamic> whereArgs;
  final List<String> requiredJoins;

  const SqlQueryParts({
    required this.whereClause,
    required this.whereArgs,
    required this.requiredJoins,
  });
}

/// High-Performance SQL Query Builder for Clinical Research
///
/// Builds dynamic SQL WHERE clauses based on field types:
/// - Text fields:       LIKE '%query%'
/// - Numeric fields:    BETWEEN ? AND ? / >= ? / <= ?
/// - Date fields:       BETWEEN ? AND ?
/// - Boolean fields:    = 1 or = 0
/// - Single-choice:     = ?
/// - Multi-choice:      IN (?, ?, ...)
class SqlCaseQueryBuilder {
  /// Table aliases used in queries
  static const String _tOp = 'o';
  static const String _tPat = 'p';
  static const String _tPre = 'pre';
  static const String _tIntra = 'intra';
  static const String _tPost = 'post';
  // Note: complications and labs are queried via EXISTS subqueries,
  // so they don't need table aliases in the main FROM clause.

  /// Base FROM clause with all JOINs
  static String get baseFromClause => '''
    ${OperationTable.tableName} $_tOp
    JOIN ${PatientTable.tableName} $_tPat ON $_tOp.${OperationTable.columnPatientId} = $_tPat.${PatientTable.columnPatientId}
    LEFT JOIN ${PreOpTable.tableName} $_tPre ON $_tOp.${OperationTable.columnOperationId} = $_tPre.${PreOpTable.columnOperationId}
    LEFT JOIN ${IntraOpTable.tableName} $_tIntra ON $_tOp.${OperationTable.columnOperationId} = $_tIntra.${IntraOpTable.columnOperationId}
    LEFT JOIN ${PostOpTable.tableName} $_tPost ON $_tOp.${OperationTable.columnOperationId} = $_tPost.${PostOpTable.columnOperationId}
  ''';

  /// Build WHERE clause and args from SqlSearchCriteria
  static SqlQueryParts buildSearchQuery(SqlSearchCriteria criteria) {
    final List<String> conditions = [];
    final List<dynamic> args = [];
    final Set<String> requiredJoins = {};

    // =============================================
    // 1. DATE RANGE (BETWEEN ? AND ?)
    // =============================================
    if (criteria.dateFrom != null) {
      conditions.add('$_tOp.${OperationTable.columnCreatedAt} >= ?');
      args.add(criteria.dateFrom!.toIso8601String());
    }
    if (criteria.dateTo != null) {
      conditions.add('$_tOp.${OperationTable.columnCreatedAt} <= ?');
      args.add(criteria.dateTo!.toIso8601String());
    }

    // =============================================
    // 2. SINGLE-CHOICE: Procedure (= ?)
    // =============================================
    if (criteria.procedure != null && criteria.procedure!.isNotEmpty) {
      conditions.add('$_tOp.${OperationTable.columnOperationType} = ?');
      args.add(criteria.procedure!);
    }

    // =============================================
    // 3. MULTI-CHOICE: Procedures (IN (?, ?, ...))
    // =============================================
    if (criteria.procedures != null && criteria.procedures!.isNotEmpty) {
      final placeholders = criteria.procedures!.map((_) => '?').join(', ');
      conditions.add('$_tOp.${OperationTable.columnOperationType} IN ($placeholders)');
      args.addAll(criteria.procedures!);
    }

    // =============================================
    // 4. SINGLE-CHOICE: Gender (= ?)
    //    Demographics is JSON, so use json_extract
    // =============================================
    if (criteria.gender != null && criteria.gender!.isNotEmpty) {
      conditions.add("json_extract($_tPat.${PatientTable.columnDemographics}, '\$.gender') = ?");
      args.add(criteria.gender!);
    }

    // =============================================
    // 5. NUMERIC RANGE: Age (BETWEEN / >= / <=)
    //    Age is computed from DOB in JSON demographics
    //    We use a calculated expression for age
    // =============================================
    if (criteria.ageMin != null || criteria.ageMax != null) {
      // Age calculation from date_of_birth in JSON demographics
      // SQLite: (julianday('now') - julianday(dob)) / 365.25
      const ageExpr = """
        CAST((julianday('now') - julianday(
          json_extract($_tPat.${PatientTable.columnDemographics}, '\$.date_of_birth')
        )) / 365.25 AS INTEGER)
      """;

      if (criteria.ageMin != null && criteria.ageMax != null) {
        conditions.add('($ageExpr) BETWEEN ? AND ?');
        args.add(criteria.ageMin!.toInt());
        args.add(criteria.ageMax!.toInt());
      } else if (criteria.ageMin != null) {
        conditions.add('($ageExpr) >= ?');
        args.add(criteria.ageMin!.toInt());
      } else {
        conditions.add('($ageExpr) <= ?');
        args.add(criteria.ageMax!.toInt());
      }
    }

    // =============================================
    // 6. BOOLEAN: Garment Required (= 1 or = 0)
    // =============================================
    if (criteria.garmentRequired != null) {
      conditions.add('$_tIntra.${IntraOpTable.columnIsGarmentRequired} = ?');
      args.add(criteria.garmentRequired! ? 1 : 0);
    }

    // =============================================
    // 7. NUMERIC RANGE: BMI (BETWEEN / >= / <=)
    //    BMI = weight_kg / (height_m * height_m)
    // =============================================
    if (criteria.bmiMin != null || criteria.bmiMax != null) {
      const bmiExpr = '($_tPre.${PreOpTable.columnWeightKg} / ($_tPre.${PreOpTable.columnHeightM} * $_tPre.${PreOpTable.columnHeightM}))';

      // Ensure weight and height are valid
      conditions.add('$_tPre.${PreOpTable.columnWeightKg} > 0');
      conditions.add('$_tPre.${PreOpTable.columnHeightM} > 0');

      if (criteria.bmiMin != null && criteria.bmiMax != null) {
        conditions.add('($bmiExpr) BETWEEN ? AND ?');
        args.add(criteria.bmiMin!);
        args.add(criteria.bmiMax!);
      } else if (criteria.bmiMin != null) {
        conditions.add('($bmiExpr) >= ?');
        args.add(criteria.bmiMin!);
      } else {
        conditions.add('($bmiExpr) <= ?');
        args.add(criteria.bmiMax!);
      }
    }

    // =============================================
    // 8. NUMERIC RANGE: Fat Volume (BETWEEN / >= / <=)
    // =============================================
    if (criteria.fatVolumeMin != null || criteria.fatVolumeMax != null) {
      if (criteria.fatVolumeMin != null && criteria.fatVolumeMax != null) {
        conditions.add('$_tIntra.${IntraOpTable.columnAmountOfFatLiters} BETWEEN ? AND ?');
        args.add(criteria.fatVolumeMin!);
        args.add(criteria.fatVolumeMax!);
      } else if (criteria.fatVolumeMin != null) {
        conditions.add('$_tIntra.${IntraOpTable.columnAmountOfFatLiters} >= ?');
        args.add(criteria.fatVolumeMin!);
      } else {
        conditions.add('$_tIntra.${IntraOpTable.columnAmountOfFatLiters} <= ?');
        args.add(criteria.fatVolumeMax!);
      }
    }

    // =============================================
    // 9. TEXT: Medical History LIKE
    // =============================================
    if (criteria.medicalHistoryQuery != null && criteria.medicalHistoryQuery!.trim().isNotEmpty) {
      final likeVal = '%${criteria.medicalHistoryQuery!.trim()}%';
      conditions.add('''(
        $_tPre.${PreOpTable.columnPastMedicalHistory} LIKE ?
        OR $_tOp.${OperationTable.columnDiagnosisDetails} LIKE ?
        OR $_tPre.${PreOpTable.columnCaseDescription} LIKE ?
      )''');
      args.addAll([likeVal, likeVal, likeVal]);
    }

    // =============================================
    // 10. COMPLICATIONS ONLY (Boolean-like existence check)
    // =============================================
    if (criteria.complicationsOnly == true) {
      requiredJoins.add('complications');
      conditions.add('''EXISTS (
        SELECT 1 FROM ${ComplicationTable.tableName} _c
        WHERE _c.${ComplicationTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
      )''');
    }

    // =============================================
    // 11. SINGLE-CHOICE: Complication Grade (= ?)
    // =============================================
    if (criteria.complicationGrade != null && criteria.complicationGrade!.isNotEmpty) {
      requiredJoins.add('complications');
      conditions.add('''EXISTS (
        SELECT 1 FROM ${ComplicationTable.tableName} _c
        WHERE _c.${ComplicationTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
          AND (_c.${ComplicationTable.columnGrade} LIKE ? OR _c.${ComplicationTable.columnDescription} LIKE ?)
      )''');
      final likeGrade = '%${criteria.complicationGrade!}%';
      args.addAll([likeGrade, likeGrade]);
    }

    // =============================================
    // 12. MULTI-CHOICE: Complication Grades (IN)
    // =============================================
    if (criteria.complicationGrades != null && criteria.complicationGrades!.isNotEmpty) {
      requiredJoins.add('complications');
      final placeholders = criteria.complicationGrades!.map((_) => '?').join(', ');
      conditions.add('''EXISTS (
        SELECT 1 FROM ${ComplicationTable.tableName} _c
        WHERE _c.${ComplicationTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
          AND _c.${ComplicationTable.columnGrade} IN ($placeholders)
      )''');
      args.addAll(criteria.complicationGrades!);
    }

    // =============================================
    // 13. POD DAY RANGE (BETWEEN / >= / <=)
    // =============================================
    if (criteria.podFilterActive == true && (criteria.podDayMin != null || criteria.podDayMax != null)) {
      requiredJoins.add('complications');
      if (criteria.podDayMin != null && criteria.podDayMax != null) {
        conditions.add('''EXISTS (
          SELECT 1 FROM ${ComplicationTable.tableName} _c
          WHERE _c.${ComplicationTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
            AND _c.${ComplicationTable.columnPodDay} BETWEEN ? AND ?
        )''');
        args.addAll([criteria.podDayMin!, criteria.podDayMax!]);
      } else if (criteria.podDayMin != null) {
        conditions.add('''EXISTS (
          SELECT 1 FROM ${ComplicationTable.tableName} _c
          WHERE _c.${ComplicationTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
            AND _c.${ComplicationTable.columnPodDay} >= ?
        )''');
        args.add(criteria.podDayMin!);
      } else {
        conditions.add('''EXISTS (
          SELECT 1 FROM ${ComplicationTable.tableName} _c
          WHERE _c.${ComplicationTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
            AND _c.${ComplicationTable.columnPodDay} <= ?
        )''');
        args.add(criteria.podDayMax!);
      }
    }

    // =============================================
    // 14. FREE-TEXT SEARCH (LIKE across many fields)
    // =============================================
    if (criteria.searchQuery != null && criteria.searchQuery!.trim().isNotEmpty) {
      final likeVal = '%${criteria.searchQuery!.trim()}%';
      conditions.add('''(
        $_tPat.${PatientTable.columnMedicalRecordNumber} LIKE ?
        OR json_extract($_tPat.${PatientTable.columnDemographics}, '\$.name') LIKE ?
        OR $_tOp.${OperationTable.columnOperationType} LIKE ?
        OR $_tOp.${OperationTable.columnDiagnosisDetails} LIKE ?
        OR $_tOp.${OperationTable.columnHospital} LIKE ?
        OR $_tPre.${PreOpTable.columnCaseDescription} LIKE ?
        OR $_tPre.${PreOpTable.columnPastMedicalHistory} LIKE ?
        OR $_tPre.${PreOpTable.columnOccupation} LIKE ?
        OR $_tIntra.${IntraOpTable.columnOperativeNotes} LIKE ?
        OR $_tPost.${PostOpTable.columnPostOpDescription} LIKE ?
        OR EXISTS (
          SELECT 1 FROM ${ComplicationTable.tableName} _c
          WHERE _c.${ComplicationTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
            AND (_c.${ComplicationTable.columnGrade} LIKE ? OR _c.${ComplicationTable.columnTreatment} LIKE ?)
        )
        OR EXISTS (
          SELECT 1 FROM ${BloodLabTable.tableName} _l
          WHERE _l.${BloodLabTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
            AND (_l.${BloodLabTable.columnTestName} LIKE ? OR _l.${BloodLabTable.columnResultValue} LIKE ?)
        )
      )''');
      args.addAll([
        likeVal, likeVal, likeVal, likeVal, likeVal,
        likeVal, likeVal, likeVal,
        likeVal, likeVal,
        likeVal, likeVal,
        likeVal, likeVal,
      ]);
    }

    // =============================================
    // 15. SPECIFIC TEXT: Patient Name / MRN LIKE
    // =============================================
    if (criteria.patientNameQuery != null && criteria.patientNameQuery!.trim().isNotEmpty) {
      final likeVal = '%${criteria.patientNameQuery!.trim()}%';
      conditions.add('''(
        $_tPat.${PatientTable.columnMedicalRecordNumber} LIKE ?
        OR json_extract($_tPat.${PatientTable.columnDemographics}, '\$.name') LIKE ?
      )''');
      args.addAll([likeVal, likeVal]);
    }

    // =============================================
    // 16. SPECIFIC TEXT: Operative Procedure LIKE
    // =============================================
    if (criteria.operativeProcedureQuery != null && criteria.operativeProcedureQuery!.trim().isNotEmpty) {
      final likeVal = '%${criteria.operativeProcedureQuery!.trim()}%';
      conditions.add('''(
        $_tOp.${OperationTable.columnOperationType} LIKE ?
        OR $_tOp.${OperationTable.columnDiagnosisDetails} LIKE ?
      )''');
      args.addAll([likeVal, likeVal]);
    }

    // =============================================
    // 17. SPECIFIC TEXT: Procedure Technique LIKE
    // =============================================
    if (criteria.procedureTechniqueQuery != null && criteria.procedureTechniqueQuery!.trim().isNotEmpty) {
      final likeVal = '%${criteria.procedureTechniqueQuery!.trim()}%';
      conditions.add('''(
        $_tIntra.${IntraOpTable.columnOperativeNotes} LIKE ?
      )''');
      args.addAll([likeVal]);
    }

    final whereClause = conditions.isEmpty ? '1=1' : conditions.join(' AND ');

    return SqlQueryParts(
      whereClause: whereClause,
      whereArgs: args,
      requiredJoins: requiredJoins.toList(),
    );
  }

  // =============================================
  // ANALYTICS AGGREGATE QUERIES
  // =============================================

  /// Build KPI Summary Query (COUNT, AVG, rates)
  /// Returns single row: total_cases, cases_with_complications, mean_age, garment_cases
  static String buildKpiQuery(SqlQueryParts queryParts) {
    return '''
      SELECT
        COUNT(DISTINCT $_tOp.${OperationTable.columnOperationId}) AS total_cases,
        COUNT(DISTINCT CASE
          WHEN EXISTS (
            SELECT 1 FROM ${ComplicationTable.tableName} _c
            WHERE _c.${ComplicationTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
          ) THEN $_tOp.${OperationTable.columnOperationId}
        END) AS cases_with_complications,
        AVG(
          COALESCE(
            CAST((julianday('now') - julianday(
              COALESCE(
                json_extract($_tPat.${PatientTable.columnDemographics}, '\$.date_of_birth'),
                json_extract($_tPat.${PatientTable.columnDemographics}, '\$.dob'),
                json_extract($_tPat.${PatientTable.columnDemographics}, '\$.birth_date')
              )
            )) / 365.25 AS REAL),
            CAST(json_extract($_tPat.${PatientTable.columnDemographics}, '\$.age') AS REAL)
          )
        ) AS mean_age,
        COUNT(DISTINCT CASE
          WHEN $_tIntra.${IntraOpTable.columnIsGarmentRequired} = 1
          THEN $_tOp.${OperationTable.columnOperationId}
        END) AS garment_cases
      FROM $baseFromClause
      WHERE ${queryParts.whereClause}
    ''';
  }

  /// Build Procedures Distribution Query (GROUP BY operation_type)
  static String buildProceduresDistributionQuery(SqlQueryParts queryParts) {
    return '''
      SELECT
        $_tOp.${OperationTable.columnOperationType} AS procedure_name,
        COUNT(*) AS case_count
      FROM $baseFromClause
      WHERE ${queryParts.whereClause}
      GROUP BY $_tOp.${OperationTable.columnOperationType}
      ORDER BY case_count DESC
    ''';
  }

  /// Build Complications Grade Distribution Query (GROUP BY grade)
  static String buildComplicationsDistributionQuery(SqlQueryParts queryParts) {
    return '''
      SELECT
        _c.${ComplicationTable.columnGrade} AS grade,
        COUNT(*) AS count
      FROM ${ComplicationTable.tableName} _c
      JOIN ${OperationTable.tableName} $_tOp ON _c.${ComplicationTable.columnOperationId} = $_tOp.${OperationTable.columnOperationId}
      JOIN ${PatientTable.tableName} $_tPat ON $_tOp.${OperationTable.columnPatientId} = $_tPat.${PatientTable.columnPatientId}
      LEFT JOIN ${PreOpTable.tableName} $_tPre ON $_tOp.${OperationTable.columnOperationId} = $_tPre.${PreOpTable.columnOperationId}
      LEFT JOIN ${IntraOpTable.tableName} $_tIntra ON $_tOp.${OperationTable.columnOperationId} = $_tIntra.${IntraOpTable.columnOperationId}
      LEFT JOIN ${PostOpTable.tableName} $_tPost ON $_tOp.${OperationTable.columnOperationId} = $_tPost.${PostOpTable.columnOperationId}
      WHERE ${queryParts.whereClause}
      GROUP BY _c.${ComplicationTable.columnGrade}
      ORDER BY count DESC
    ''';
  }

  /// Build query to fetch matching operation IDs for case assembly
  static String buildOperationIdsQuery(SqlQueryParts queryParts) {
    return '''
      SELECT DISTINCT $_tOp.${OperationTable.columnOperationId}
      FROM $baseFromClause
      WHERE ${queryParts.whereClause}
      ORDER BY $_tOp.${OperationTable.columnCreatedAt} DESC
    ''';
  }
}

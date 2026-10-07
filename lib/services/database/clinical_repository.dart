import 'package:sqflite/sqflite.dart';
import '../../models/patient_record_brd.dart';
import '../../services/search_engine/sql_query_builder.dart';
import '../../services/search_engine/research_search_engine.dart';
import 'app_database.dart';
import 'connection/database_connection.dart';
import 'repositories/abstract_repository.dart';
import 'repositories/blood_lab_repository.dart';
import 'repositories/complication_repository.dart';
import 'repositories/intra_op_repository.dart';
import 'repositories/operation_repository.dart';
import 'repositories/patient_repository.dart';
import 'repositories/post_op_repository.dart';
import 'repositories/pre_op_repository.dart';
import 'repositories/procedure_catalog_repository.dart';
import 'repositories/complication_catalog_repository.dart';
import 'repositories/survey_repository.dart';
import 'repositories/template_repository.dart';
import 'repositories/garment_catalog_repository.dart';
import 'mock_data_service.dart';

/// Clinical Coordinator & Aggregated Repository Facade
class ClinicalRepository {
  final DatabaseConnection _connection = DatabaseConnection();

  // Individual Table Repositories
  final PatientRepository patientRepo = PatientRepository();
  final OperationRepository operationRepo = OperationRepository();
  final ProcedureCatalogRepository procedureCatalogRepo =
      ProcedureCatalogRepository();
  final ComplicationCatalogRepository complicationCatalogRepo =
      ComplicationCatalogRepository();
  final PreOpRepository preOpRepo = PreOpRepository();
  final IntraOpRepository intraOpRepo = IntraOpRepository();
  final PostOpRepository postOpRepo = PostOpRepository();
  final ComplicationRepository complicationRepo = ComplicationRepository();
  final BloodLabRepository bloodLabRepo = BloodLabRepository();
  final SurveyRepository surveyRepo = SurveyRepository();
  final ResearchTemplateRepository templateRepo = ResearchTemplateRepository();
  final ResearchAbstractRepository abstractRepo = ResearchAbstractRepository();
  final GarmentCatalogRepository garmentCatalogRepo =
      GarmentCatalogRepository();
  final MockDataService mockDataService = MockDataService();

  Future<Database> get _db => _connection.database;

  // ==========================================
  // 1. PATIENTS CRUD
  // ==========================================
  Future<List<PatientModel>> getAllPatients() =>
      patientRepo.getAll(orderBy: '${PatientTable.columnCreatedAt} DESC');

  Future<void> insertPatient(PatientModel patient) =>
      patientRepo.insert(patient);

  Future<void> updatePatient(PatientModel patient) =>
      patientRepo.update(patient);

  Future<void> deletePatient(String patientId) =>
      patientRepo.delete(patientId);

  // ==========================================
  // 2. OPERATIONS CRUD & PROCEDURE CATALOG
  // ==========================================
  Future<List<OperationModel>> getAllOperations() =>
      operationRepo.getAll(orderBy: '${OperationTable.columnCreatedAt} DESC');

  Future<void> insertOperation(OperationModel operation) async {
    await operationRepo.insert(operation);
    // Automatically ensure the procedure is available in master catalog for future patients
    try {
      await procedureCatalogRepo.getOrCreateProcedure(
        operation.operationType,
        description: operation.diagnosisDetails,
      );
    } catch (_) {}
  }

  Future<void> updateOperation(OperationModel operation) =>
      operationRepo.update(operation);

  Future<void> deleteOperation(String operationId) =>
      operationRepo.delete(operationId);

  // Master Procedure Catalog Methods
  Future<List<ProcedureCatalogModel>> getProcedureCatalog() =>
      procedureCatalogRepo.getAllProcedures();

  Future<ProcedureCatalogModel> addProcedureToCatalog(
    String name, {
    String description = '',
    String pastMedicalHistory = '',
    String occupation = '',
  }) =>
      procedureCatalogRepo.getOrCreateProcedure(
        name,
        description: description,
        pastMedicalHistory: pastMedicalHistory,
        occupation: occupation,
      );

  Future<void> deleteProcedureFromCatalog(String id) =>
      procedureCatalogRepo.delete(id);

  // ==========================================
  // 3. PRE-OP ASSESSMENTS CRUD
  // ==========================================
  Future<List<PreOpModel>> getAllPreOps() => preOpRepo.getAll();

  Future<void> insertPreOp(PreOpModel preOp) => preOpRepo.insert(preOp);

  Future<void> deletePreOp(String preOpId) => preOpRepo.delete(preOpId);

  // ==========================================
  // 4. INTRA-OP DETAILS CRUD
  // ==========================================
  Future<List<IntraOpModel>> getAllIntraOps() => intraOpRepo.getAll();

  Future<void> insertIntraOp(IntraOpModel intraOp) async {
    await intraOpRepo.insert(intraOp);
    if (intraOp.isGarmentRequired) {
      try {
        if (intraOp.garmentBrandModel.trim().isNotEmpty) {
          await garmentCatalogRepo.saveBrand(intraOp.garmentBrandModel.trim());
        }
        if (intraOp.garmentType.trim().isNotEmpty) {
          await garmentCatalogRepo.saveType(intraOp.garmentType.trim());
        }
      } catch (_) {}
    }
  }

  Future<List<String>> getGarmentBrandSuggestions() =>
      garmentCatalogRepo.getBrandSuggestions();

  Future<List<String>> getGarmentTypeSuggestions() =>
      garmentCatalogRepo.getTypeSuggestions();

  Future<void> deleteIntraOp(String intraOpId) => intraOpRepo.delete(intraOpId);

  // ==========================================
  // 5. POST-OP DETAILS CRUD
  // ==========================================
  Future<List<PostOpModel>> getAllPostOps() => postOpRepo.getAll();

  Future<void> insertPostOp(PostOpModel postOp) => postOpRepo.insert(postOp);

  Future<void> deletePostOp(String postOpId) => postOpRepo.delete(postOpId);

  // ==========================================
  // 6. COMPLICATIONS CRUD & CATALOG
  // ==========================================
  Future<List<ComplicationModel>> getAllComplications() =>
      complicationRepo.getAll(orderBy: '${ComplicationTable.columnPodDay} ASC');

  Future<void> addComplication(ComplicationModel complication) async {
    await complicationRepo.insert(complication);
    // Automatically learn and ensure complication is available in master catalog
    try {
      if (complication.description.trim().isNotEmpty) {
        await complicationCatalogRepo.getOrCreateComplication(
          complication.description,
          treatment: complication.treatment,
          grade: complication.grade,
        );
      }
    } catch (_) {}
  }

  Future<void> deleteComplication(String complicationId) =>
      complicationRepo.delete(complicationId);

  // Master Complications Catalog Methods
  Future<List<ComplicationCatalogModel>> getComplicationCatalog() =>
      complicationCatalogRepo.getAllComplications();

  Future<ComplicationCatalogModel> addComplicationToCatalog(
    String name, {
    required String treatment,
    String grade =
        'Grade I (Minor complication, no specific treatment required)',
    String category = 'General',
  }) =>
      complicationCatalogRepo.getOrCreateComplication(
        name,
        treatment: treatment,
        grade: grade,
        category: category,
      );

  Future<void> deleteComplicationFromCatalog(String id) =>
      complicationCatalogRepo.delete(id);

  // ==========================================
  // 7. BLOOD & LABS CRUD
  // ==========================================
  Future<List<BloodLabModel>> getAllBloodLabs() =>
      bloodLabRepo.getAll(orderBy: '${BloodLabTable.columnTestDate} DESC');

  Future<void> addBloodLab(BloodLabModel lab) =>
      bloodLabRepo.insert(lab);

  Future<void> deleteBloodLab(String labId) =>
      bloodLabRepo.delete(labId);

  // ==========================================
  // 8. SURVEYS CRUD
  // ==========================================
  Future<List<SurveyModel>> getAllSurveys() => surveyRepo.getAll();

  Future<void> addSurvey(SurveyModel survey) => surveyRepo.insert(survey);

  Future<void> deleteSurvey(String surveyId) => surveyRepo.delete(surveyId);

  // ==========================================
  // 9. DYNAMIC TEMPLATES CRUD
  // ==========================================
  Future<List<ResearchTemplateModel>> getAllTemplates() => templateRepo.getAll();

  Future<void> insertTemplate(ResearchTemplateModel template) => templateRepo.insert(template);

  Future<void> deleteTemplate(String templateId) => templateRepo.delete(templateId);

  // ==========================================
  // 10. RESEARCH ABSTRACTS CRUD
  // ==========================================
  Future<List<ResearchAbstractModel>> getAllAbstracts() =>
      abstractRepo.getAll(orderBy: '${ResearchAbstractTable.columnCreatedAt} DESC');

  Future<void> insertAbstract(ResearchAbstractModel abstractModel) =>
      abstractRepo.insert(abstractModel);

  Future<void> deleteAbstract(String abstractId) =>
      abstractRepo.delete(abstractId);

  // ==========================================
  // COMPLETE AGGREGATE CLINICAL CASES
  // ==========================================

  /// HIGH-PERFORMANCE Batch Bulk Loading
  /// Instead of N+1 sequential queries (3,500+ for 500 cases),
  /// fetches all data in 8 bulk queries and assembles via Map lookup.
  Future<List<CompleteClinicalCase>> getAllClinicalCases() async {
    final operations = await getAllOperations();
    if (operations.isEmpty) return [];

    // Batch fetch ALL records from each table in one query each
    final allPatients = await patientRepo.getAll();
    final allPreOps = await preOpRepo.getAll();
    final allIntraOps = await intraOpRepo.getAll();
    final allPostOps = await postOpRepo.getAll();
    final allComplications = await complicationRepo.getAll();
    final allLabs = await bloodLabRepo.getAll();
    final allSurveys = await surveyRepo.getAll();

    // Build fast-lookup Maps (O(1) access instead of O(n) per operation)
    final patientMap = <String, PatientModel>{};
    for (final p in allPatients) {
      patientMap[p.patientId] = p;
    }

    final preOpMap = <String, PreOpModel>{};
    for (final pre in allPreOps) {
      preOpMap[pre.operationId] = pre;
    }

    final intraOpMap = <String, IntraOpModel>{};
    for (final intra in allIntraOps) {
      intraOpMap[intra.operationId] = intra;
    }

    final postOpMap = <String, PostOpModel>{};
    for (final post in allPostOps) {
      postOpMap[post.operationId] = post;
    }

    final complicationsMap = <String, List<ComplicationModel>>{};
    for (final comp in allComplications) {
      complicationsMap.putIfAbsent(comp.operationId, () => []).add(comp);
    }

    final labsMap = <String, List<BloodLabModel>>{};
    for (final lab in allLabs) {
      labsMap.putIfAbsent(lab.operationId, () => []).add(lab);
    }

    final surveysMap = <String, List<SurveyModel>>{};
    for (final s in allSurveys) {
      surveysMap.putIfAbsent(s.operationId, () => []).add(s);
    }

    // Assemble CompleteClinicalCase objects using O(1) Map lookups
    final List<CompleteClinicalCase> cases = [];
    for (final op in operations) {
      final patient = patientMap[op.patientId];
      if (patient == null) continue;

      cases.add(CompleteClinicalCase(
        patient: patient,
        operation: op,
        preOp: preOpMap[op.operationId],
        intraOp: intraOpMap[op.operationId],
        postOp: postOpMap[op.operationId],
        complications: complicationsMap[op.operationId] ?? [],
        bloodLabs: labsMap[op.operationId] ?? [],
        surveys: surveysMap[op.operationId] ?? [],
      ));
    }

    return cases;
  }

  // ==========================================
  // SQL-POWERED SEARCH (returns matching operation IDs)
  // ==========================================

  /// Search clinical cases using SQL WHERE clauses built by SqlCaseQueryBuilder.
  /// Returns the list of matching operation IDs for case assembly.
  Future<List<String>> searchOperationIdsSql(SqlSearchCriteria criteria) async {
    final queryParts = SqlCaseQueryBuilder.buildSearchQuery(criteria);
    final sql = SqlCaseQueryBuilder.buildOperationIdsQuery(queryParts);
    final database = await _db;
    final results = await database.rawQuery(sql, queryParts.whereArgs);
    return results
        .map((row) => row[OperationTable.columnOperationId] as String)
        .toList();
  }

  /// Search and return full CompleteClinicalCase objects matching criteria.
  /// Uses SQL to find matching IDs, then assembles from the bulk-loaded cache.
  Future<List<CompleteClinicalCase>> searchCasesSql(
    SqlSearchCriteria criteria,
    List<CompleteClinicalCase> cachedCases,
  ) async {
    if (!criteria.hasAnyFilter) return cachedCases;

    final matchingIds = await searchOperationIdsSql(criteria);
    final idSet = matchingIds.toSet();
    return cachedCases
        .where((c) => idSet.contains(c.operation.operationId))
        .toList();
  }

  // ==========================================
  // SQL-POWERED ANALYTICS (Aggregate Queries)
  // ==========================================

  /// Compute KPI statistics directly via SQL aggregate functions.
  /// Returns TimeFrameStats with totalCases, complicationRate, meanAge, etc.
  Future<TimeFrameStats> getAnalyticsStatsSql(SqlSearchCriteria criteria) async {
    final queryParts = SqlCaseQueryBuilder.buildSearchQuery(criteria);
    final database = await _db;

    // 1. KPI Summary (single row: total, complications, mean age, garment)
    final kpiSql = SqlCaseQueryBuilder.buildKpiQuery(queryParts);
    final kpiResult = await database.rawQuery(kpiSql, queryParts.whereArgs);

    int totalCases = 0;
    int casesWithComplications = 0;
    double meanAge = 0.0;
    int garmentCases = 0;

    if (kpiResult.isNotEmpty) {
      final row = kpiResult.first;
      totalCases = (row['total_cases'] as num?)?.toInt() ?? 0;
      casesWithComplications = (row['cases_with_complications'] as num?)?.toInt() ?? 0;
      meanAge = (row['mean_age'] as num?)?.toDouble() ?? 0.0;
      garmentCases = (row['garment_cases'] as num?)?.toInt() ?? 0;
    }

    // 2. Procedures Distribution (GROUP BY operation_type)
    final procSql = SqlCaseQueryBuilder.buildProceduresDistributionQuery(queryParts);
    final procResult = await database.rawQuery(procSql, queryParts.whereArgs);
    final Map<String, int> surgeryTypeDistribution = {};
    for (final row in procResult) {
      final name = row['procedure_name'] as String? ?? 'Unknown';
      final count = (row['case_count'] as num?)?.toInt() ?? 0;
      surgeryTypeDistribution[name] = count;
    }

    // 3. Complications Grade Distribution (GROUP BY grade)
    final compSql = SqlCaseQueryBuilder.buildComplicationsDistributionQuery(queryParts);
    final compResult = await database.rawQuery(compSql, queryParts.whereArgs);
    final Map<String, int> gradeDistribution = {};
    for (final row in compResult) {
      final grade = row['grade'] as String? ?? 'Ungraded';
      final count = (row['count'] as num?)?.toInt() ?? 0;
      gradeDistribution[grade] = count;
    }

    return TimeFrameStats(
      totalCases: totalCases,
      casesWithComplications: casesWithComplications,
      complicationRate: totalCases > 0 ? (casesWithComplications / totalCases) * 100 : 0.0,
      meanAge: meanAge,
      garmentUsageCount: garmentCases,
      garmentUsageRate: totalCases > 0 ? (garmentCases / totalCases) * 100 : 0.0,
      gradeDistribution: gradeDistribution,
      surgeryTypeDistribution: surgeryTypeDistribution,
    );
  }

  Future<void> insertCompleteCase(CompleteClinicalCase clinicalCase) async {
    final database = await _db;
    await database.transaction((txn) async {
      await txn.insert(
        PatientTable.tableName,
        clinicalCase.patient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        OperationTable.tableName,
        clinicalCase.operation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (clinicalCase.preOp != null) {
        await txn.insert(
          PreOpTable.tableName,
          clinicalCase.preOp!.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      if (clinicalCase.intraOp != null) {
        await txn.insert(
          IntraOpTable.tableName,
          clinicalCase.intraOp!.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      if (clinicalCase.postOp != null) {
        await txn.insert(
          PostOpTable.tableName,
          clinicalCase.postOp!.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (var comp in clinicalCase.complications) {
        await txn.insert(
          ComplicationTable.tableName,
          comp.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (var lab in clinicalCase.bloodLabs) {
        await txn.insert(
          BloodLabTable.tableName,
          lab.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (var s in clinicalCase.surveys) {
        await txn.insert(
          SurveyTable.tableName,
          s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteCase(String operationId, String patientId) async {
    final database = await _db;
    await database.transaction((txn) async {
      await txn.delete(
        OperationTable.tableName,
        where: '${OperationTable.columnOperationId} = ?',
        whereArgs: [operationId],
      );
      await txn.delete(
        PatientTable.tableName,
        where: '${PatientTable.columnPatientId} = ?',
        whereArgs: [patientId],
      );
    });
  }

  Future<void> clearAllData() async {
    await _connection.clearAllTables();
  }

  Future<void> seedDemoData() async {
    await AppDatabase.seedInitialData();
  }

  // ==========================================
  // 11. MOCK DATA RESEARCH SUITE
  // ==========================================
  Future<MockDataResult> seedMockData({bool force = false}) =>
      mockDataService.seedMockData(force: force);

  Future<int> clearMockData() => mockDataService.clearMockData();

  Future<bool> isMockDataSeeded() => mockDataService.isMockDataSeeded();

  Future<int> getSeededMockCount() => mockDataService.getSeededMockCount();
}

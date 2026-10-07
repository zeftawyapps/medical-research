import 'dart:convert';
import 'base/data_model.dart';
import 'operation_model.dart';

/// Database Table Constants for Pre-Op Table
class PreOpTable {
  static const String tableName = 'pre_op_assessments';

  static const String columnPreOpId = 'pre_op_id';
  static const String columnOperationId = 'operation_id';
  static const String columnPastMedicalHistory = 'past_medical_history';
  static const String columnOccupation = 'occupation';
  static const String columnIsSmoker = 'is_smoker';
  static const String columnCigarettesPerDay = 'cigarettes_per_day';
  static const String columnSmokingYears = 'smoking_years';
  static const String columnWeightKg = 'weight_kg';
  static const String columnHeightM = 'height_m';
  static const String columnHemoglobin = 'hemoglobin';
  static const String columnT3 = 't3';
  static const String columnT4 = 't4';
  static const String columnScanPictures = 'scan_pictures';
  static const String columnPreOpPictures = 'pre_op_pictures';
  static const String columnCaseDescription = 'case_description';
  static const String columnBloodGroup = 'blood_group';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnPreOpId TEXT PRIMARY KEY,
      $columnOperationId TEXT NOT NULL,
      $columnPastMedicalHistory TEXT NOT NULL,
      $columnOccupation TEXT NOT NULL,
      $columnIsSmoker INTEGER NOT NULL DEFAULT 0,
      $columnCigarettesPerDay INTEGER,
      $columnSmokingYears INTEGER,
      $columnWeightKg REAL,
      $columnHeightM REAL,
      $columnHemoglobin REAL,
      $columnT3 REAL,
      $columnT4 REAL,
      $columnScanPictures TEXT,
      $columnPreOpPictures TEXT,
      $columnCaseDescription TEXT,
      $columnBloodGroup TEXT,
      FOREIGN KEY ($columnOperationId) REFERENCES ${OperationTable.tableName} (${OperationTable.columnOperationId}) ON DELETE CASCADE
    )
  ''';
}

/// 3. Pre-Operative Assessment Model
class PreOpModel extends DataModel {
  final String preOpId; // UUID (PK)
  final String operationId; // UUID (FK)
  
  // 1/ Past Medical History **
  final String pastMedicalHistory;
  
  // 2/ Occupation **
  final String occupation;
  
  // 3/ Smoking: Y or N **
  final bool isSmoker;
  final int? cigarettesPerDay;
  final int? smokingYears;
  
  // 4/ Weight (Kg) & 5/ Height (metre)
  final double? weightKg;
  final double? heightM;
  
  // 6/ Investigations
  final double? hemoglobin; // 6.a) Hemoglobin
  final double? t3; // 6.b) T3
  final double? t4; // 6.c) T4
  final List<String> scanPictures; // 6.d) Scan picture (photo paths/URLs)
  
  // 7) Pre-operative picture
  final List<String> preOpPictures; // Pre-operative clinical photos

  // Optional extra description
  final String caseDescription;

  // Compatibility getters for legacy code
  String get bloodGroup => '';
  String get radiologyReports => caseDescription;
  List<String> get clinicalImages => preOpPictures;
  List<String> get radiologyImages => scanPictures;
  List<String> get labFiles => const [];

  PreOpModel({
    required this.preOpId,
    required this.operationId,
    this.pastMedicalHistory = '',
    this.occupation = '',
    this.isSmoker = false,
    this.cigarettesPerDay,
    this.smokingYears,
    this.weightKg,
    this.heightM,
    this.hemoglobin,
    this.t3,
    this.t4,
    String? bloodGroup,
    List<String>? scanPictures,
    List<String>? preOpPictures,
    String? caseDescription,
    // Legacy parameter fallbacks
    List<String>? clinicalImages,
    String? radiologyReports,
    List<String>? radiologyImages,
    List<String>? labFiles,
  })  : scanPictures = scanPictures ?? radiologyImages ?? const [],
        preOpPictures = preOpPictures ?? clinicalImages ?? const [],
        caseDescription = caseDescription ?? radiologyReports ?? '';

  @override
  String get tableName => PreOpTable.tableName;

  @override
  String get primaryKeyColumn => PreOpTable.columnPreOpId;

  @override
  dynamic get primaryKeyValue => preOpId;

  static String get createTableSql => PreOpTable.createTableSql;

  /// Automatic BMI Calculation: Weight (kg) / [Height (m) ^ 2]
  double? get bmi {
    if (weightKg == null || heightM == null || heightM! <= 0 || weightKg! <= 0) {
      return null;
    }
    final calc = weightKg! / (heightM! * heightM!);
    return double.parse(calc.toStringAsFixed(2));
  }

  /// Categorization of the BMI score
  String get bmiCategory {
    final val = bmi;
    if (val == null) return 'N/A';
    if (val < 18.5) return 'Underweight';
    if (val < 25.0) return 'Normal Weight';
    if (val < 30.0) return 'Overweight';
    if (val < 35.0) return 'Obese Class I';
    if (val < 40.0) return 'Obese Class II';
    return 'Severe Obesity (Class III)';
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      PreOpTable.columnPreOpId: preOpId,
      PreOpTable.columnOperationId: operationId,
      PreOpTable.columnPastMedicalHistory: pastMedicalHistory,
      PreOpTable.columnOccupation: occupation,
      PreOpTable.columnIsSmoker: isSmoker ? 1 : 0,
      PreOpTable.columnCigarettesPerDay: cigarettesPerDay,
      PreOpTable.columnSmokingYears: smokingYears,
      PreOpTable.columnWeightKg: weightKg,
      PreOpTable.columnHeightM: heightM,
      PreOpTable.columnHemoglobin: hemoglobin,
      PreOpTable.columnT3: t3,
      PreOpTable.columnT4: t4,
      PreOpTable.columnScanPictures: jsonEncode(scanPictures),
      PreOpTable.columnPreOpPictures: jsonEncode(preOpPictures),
      PreOpTable.columnCaseDescription: caseDescription,
      PreOpTable.columnBloodGroup: '',
    };
  }

  factory PreOpModel.fromMap(Map<String, dynamic> map) {
    return PreOpModel(
      preOpId: map[PreOpTable.columnPreOpId] as String,
      operationId: map[PreOpTable.columnOperationId] as String,
      pastMedicalHistory: map[PreOpTable.columnPastMedicalHistory] as String? ??
          map['case_description'] as String? ??
          '',
      occupation: map[PreOpTable.columnOccupation] as String? ?? '',
      isSmoker: (map[PreOpTable.columnIsSmoker] as num?)?.toInt() == 1,
      cigarettesPerDay: (map[PreOpTable.columnCigarettesPerDay] as num?)?.toInt(),
      smokingYears: (map[PreOpTable.columnSmokingYears] as num?)?.toInt(),
      weightKg: (map[PreOpTable.columnWeightKg] as num?)?.toDouble(),
      heightM: (map[PreOpTable.columnHeightM] as num?)?.toDouble(),
      hemoglobin: (map[PreOpTable.columnHemoglobin] as num?)?.toDouble(),
      t3: (map[PreOpTable.columnT3] as num?)?.toDouble(),
      t4: (map[PreOpTable.columnT4] as num?)?.toDouble(),
      scanPictures: _parseStringList(map[PreOpTable.columnScanPictures] ?? map['radiology_images']),
      preOpPictures: _parseStringList(map[PreOpTable.columnPreOpPictures] ?? map['clinical_images']),
      caseDescription: map[PreOpTable.columnCaseDescription] as String? ??
          map['radiology_reports'] as String? ??
          '',
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        if (raw.isNotEmpty) return [raw];
      }
    }
    return [];
  }

  PreOpModel copyWith({
    String? preOpId,
    String? operationId,
    String? pastMedicalHistory,
    String? occupation,
    bool? isSmoker,
    int? cigarettesPerDay,
    int? smokingYears,
    double? weightKg,
    double? heightM,
    double? hemoglobin,
    double? t3,
    double? t4,
    List<String>? scanPictures,
    List<String>? preOpPictures,
    String? caseDescription,
  }) {
    return PreOpModel(
      preOpId: preOpId ?? this.preOpId,
      operationId: operationId ?? this.operationId,
      pastMedicalHistory: pastMedicalHistory ?? this.pastMedicalHistory,
      occupation: occupation ?? this.occupation,
      isSmoker: isSmoker ?? this.isSmoker,
      cigarettesPerDay: cigarettesPerDay ?? this.cigarettesPerDay,
      smokingYears: smokingYears ?? this.smokingYears,
      weightKg: weightKg ?? this.weightKg,
      heightM: heightM ?? this.heightM,
      hemoglobin: hemoglobin ?? this.hemoglobin,
      t3: t3 ?? this.t3,
      t4: t4 ?? this.t4,
      scanPictures: scanPictures ?? this.scanPictures,
      preOpPictures: preOpPictures ?? this.preOpPictures,
      caseDescription: caseDescription ?? this.caseDescription,
    );
  }
}

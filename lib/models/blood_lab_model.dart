import 'base/data_model.dart';
import 'operation_model.dart';

/// Database Table Constants for Blood & Labs Table
class BloodLabTable {
  static const String tableName = 'blood_labs';

  static const String columnLabId = 'lab_id';
  static const String columnOperationId = 'operation_id';
  static const String columnTestName = 'test_name';
  static const String columnResultValue = 'result_value';
  static const String columnTestDate = 'test_date';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnLabId TEXT PRIMARY KEY,
      $columnOperationId TEXT NOT NULL,
      $columnTestName TEXT NOT NULL,
      $columnResultValue TEXT NOT NULL,
      $columnTestDate TEXT NOT NULL,
      FOREIGN KEY ($columnOperationId) REFERENCES ${OperationTable.tableName} (${OperationTable.columnOperationId}) ON DELETE CASCADE
    )
  ''';
}

/// 7. Digital Lab Tests (Blood & Labs Table)
class BloodLabModel extends DataModel {
  final String labId; // UUID (PK)
  final String operationId; // UUID (FK)
  final String testName; // Name of test (e.g. Hemoglobin, CRP, Creatinine, Bilirubin)
  final String resultValue; // Value (e.g. "13.4 g/dL", "4.2 mg/L")
  final DateTime testDate;

  const BloodLabModel({
    required this.labId,
    required this.operationId,
    required this.testName,
    required this.resultValue,
    required this.testDate,
  });

  @override
  String get tableName => BloodLabTable.tableName;

  @override
  String get primaryKeyColumn => BloodLabTable.columnLabId;

  @override
  dynamic get primaryKeyValue => labId;

  static String get createTableSql => BloodLabTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      BloodLabTable.columnLabId: labId,
      BloodLabTable.columnOperationId: operationId,
      BloodLabTable.columnTestName: testName,
      BloodLabTable.columnResultValue: resultValue,
      BloodLabTable.columnTestDate: testDate.toIso8601String(),
    };
  }

  factory BloodLabModel.fromMap(Map<String, dynamic> map) {
    return BloodLabModel(
      labId: map[BloodLabTable.columnLabId] as String,
      operationId: map[BloodLabTable.columnOperationId] as String,
      testName: map[BloodLabTable.columnTestName] as String? ?? '',
      resultValue: map[BloodLabTable.columnResultValue] as String? ?? '',
      testDate: DateTime.tryParse(map[BloodLabTable.columnTestDate]?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

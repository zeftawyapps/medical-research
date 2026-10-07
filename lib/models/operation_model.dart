import 'base/data_model.dart';
import 'patient_model.dart';

/// Database Table Constants for Operation Table
class OperationTable {
  static const String tableName = 'operations';

  static const String columnOperationId = 'operation_id';
  static const String columnPatientId = 'patient_id';
  static const String columnDiagnosisDetails = 'diagnosis_details';
  static const String columnOperationType = 'operation_type';
  static const String columnHospital = 'hospital';
  static const String columnCreatedAt = 'created_at';

  static const String createTableSql =
      '''
    CREATE TABLE $tableName (
      $columnOperationId TEXT PRIMARY KEY,
      $columnPatientId TEXT NOT NULL,
      $columnDiagnosisDetails TEXT NOT NULL,
      $columnOperationType TEXT NOT NULL,
      $columnHospital TEXT,
      $columnCreatedAt TEXT NOT NULL,
      FOREIGN KEY ($columnPatientId) REFERENCES ${PatientTable.tableName} (${PatientTable.columnPatientId}) ON DELETE CASCADE
    )
  ''';
}

/// 2. Operation Model (Operations & Diagnosis Table)
class OperationModel extends DataModel {
  final String operationId; // UUID (PK)
  final String patientId; // UUID (FK)
  final String diagnosisDetails; // Initial comprehensive diagnosis / reason
  final String operationType; // Name and type of surgical procedure
  final String hospital; // Hospital or surgical facility
  final DateTime createdAt;

  const OperationModel({
    required this.operationId,
    required this.patientId,
    required this.diagnosisDetails,
    required this.operationType,
    this.hospital = '',
    required this.createdAt,
  });

  /// Surgery / Operation date
  DateTime get operationDate => createdAt;

  @override
  String get tableName => OperationTable.tableName;

  @override
  String get primaryKeyColumn => OperationTable.columnOperationId;

  @override
  dynamic get primaryKeyValue => operationId;

  static String get createTableSql => OperationTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      OperationTable.columnOperationId: operationId,
      OperationTable.columnPatientId: patientId,
      OperationTable.columnDiagnosisDetails: diagnosisDetails,
      OperationTable.columnOperationType: operationType,
      OperationTable.columnHospital: hospital,
      OperationTable.columnCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory OperationModel.fromMap(Map<String, dynamic> map) {
    return OperationModel(
      operationId: map[OperationTable.columnOperationId] as String,
      patientId: map[OperationTable.columnPatientId] as String,
      diagnosisDetails:
          map[OperationTable.columnDiagnosisDetails] as String? ?? '',
      operationType: map[OperationTable.columnOperationType] as String? ?? '',
      hospital:
          map[OperationTable.columnHospital] as String? ??
          map['hospital'] as String? ??
          '',
      createdAt:
          DateTime.tryParse(
            map[OperationTable.columnCreatedAt]?.toString() ??
                map['operation_date']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }

  OperationModel copyWith({
    String? operationId,
    String? patientId,
    String? diagnosisDetails,
    String? operationType,
    String? hospital,
    DateTime? createdAt,
  }) {
    return OperationModel(
      operationId: operationId ?? this.operationId,
      patientId: patientId ?? this.patientId,
      diagnosisDetails: diagnosisDetails ?? this.diagnosisDetails,
      operationType: operationType ?? this.operationType,
      hospital: hospital ?? this.hospital,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

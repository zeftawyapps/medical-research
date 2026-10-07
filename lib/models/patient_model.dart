import 'dart:convert';
import 'base/data_model.dart';

/// Database Table Constants for Patient Table
class PatientTable {
  static const String tableName = 'patients';

  static const String columnPatientId = 'patient_id';
  static const String columnMedicalRecordNumber = 'medical_record_number';
  static const String columnDemographics = 'demographics';
  static const String columnCreatedAt = 'created_at';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnPatientId TEXT PRIMARY KEY,
      $columnMedicalRecordNumber TEXT UNIQUE NOT NULL,
      $columnDemographics TEXT NOT NULL,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';
}

/// 1. Patient Model (Patients Table)
class PatientModel extends DataModel {
  final String patientId; // UUID (PK)
  final String medicalRecordNumber; // MRN (Unique)
  final Map<String, dynamic> demographics; // Age, Gender, Blood Group, Contact, etc.
  final DateTime createdAt;

  const PatientModel({
    required this.patientId,
    required this.medicalRecordNumber,
    required this.demographics,
    required this.createdAt,
  });

  @override
  String get tableName => PatientTable.tableName;

  @override
  String get primaryKeyColumn => PatientTable.columnPatientId;

  @override
  dynamic get primaryKeyValue => patientId;

  static String get createTableSql => PatientTable.createTableSql;

  String get name => demographics['name']?.toString() ?? 'Anonymous Patient';

  int get age {
    final dobStr = demographics['date_of_birth']?.toString() ??
        demographics['dob']?.toString() ??
        demographics['birth_date']?.toString();
    if (dobStr != null && dobStr.isNotEmpty) {
      DateTime? dob = DateTime.tryParse(dobStr);
      if (dob == null && dobStr.contains('/')) {
        final parts = dobStr.split('/');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            dob = DateTime.tryParse('${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}');
          } else if (parts[2].length == 4) {
            dob = DateTime.tryParse('${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}');
          }
        }
      }
      if (dob != null) {
        final now = DateTime.now();
        int calculatedAge = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          calculatedAge--;
        }
        return calculatedAge >= 0 ? calculatedAge : 0;
      }
    }
    return int.tryParse(demographics['age']?.toString() ?? '0') ?? 0;
  }

  String? get dateOfBirth => demographics['date_of_birth']?.toString() ?? demographics['dob']?.toString();
  String get gender => demographics['gender']?.toString() ?? 'Unknown';
  String get bloodGroup => demographics['blood_group']?.toString() ?? 'N/A';
  String get phone => demographics['phone']?.toString() ?? 'N/A';
  String get country => demographics['country']?.toString() ?? '';
  String get notes => demographics['notes']?.toString() ?? '';

  @override
  Map<String, dynamic> toMap() {
    return {
      PatientTable.columnPatientId: patientId,
      PatientTable.columnMedicalRecordNumber: medicalRecordNumber,
      PatientTable.columnDemographics: jsonEncode(demographics),
      PatientTable.columnCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      patientId: map[PatientTable.columnPatientId] as String,
      medicalRecordNumber: map[PatientTable.columnMedicalRecordNumber] as String,
      demographics: map[PatientTable.columnDemographics] is String
          ? jsonDecode(map[PatientTable.columnDemographics] as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(map[PatientTable.columnDemographics] as Map),
      createdAt: DateTime.tryParse(map[PatientTable.columnCreatedAt]?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

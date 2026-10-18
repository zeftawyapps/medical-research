import 'package:sqflite/sqflite.dart';
import '../../../models/patient_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Patients Table CRUD using JoDija BaseCrudRepository
class PatientRepository extends BaseCrudRepository<PatientModel> {
  PatientRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => PatientModel.fromMap(map),
          tableName: PatientTable.tableName,
          primaryKeyColumn: PatientTable.columnPatientId,
        );

  /// Find a patient by Medical Record Number (MRN)
  Future<PatientModel?> getByMedicalRecordNumber(String mrn) async {
    final results = await query(
      where: '${PatientTable.columnMedicalRecordNumber} = ?',
      whereArgs: [mrn],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Safe insert that guarantees a new patient record is created without replacing existing records
  @override
  Future<int> insert(PatientModel model) async {
    final db = await DatabaseConnection().database;
    
    // Check if the MRN already exists in database
    String finalMrn = model.medicalRecordNumber.trim();
    final existingWithMrn = await db.query(
      PatientTable.tableName,
      where: '${PatientTable.columnMedicalRecordNumber} = ?',
      whereArgs: [finalMrn],
      limit: 1,
    );

    PatientModel toInsert = model;
    if (existingWithMrn.isNotEmpty) {
      // Collision detected! Generate guaranteed collision-free MRN from real SQLite records
      final allPatients = await getAll();
      final year = DateTime.now().year;
      int maxNum = 0;
      final regex = RegExp(r'MRN-\d{4}-(\d+)', caseSensitive: false);
      for (final p in allPatients) {
        final m = regex.firstMatch(p.medicalRecordNumber);
        if (m != null) {
          final n = int.tryParse(m.group(1) ?? '0') ?? 0;
          if (n > maxNum) maxNum = n;
        }
      }
      int candidateIndex = maxNum + 1;
      if (candidateIndex <= allPatients.length) candidateIndex = allPatients.length + 1;
      String newUniqueMrn = 'MRN-$year-${candidateIndex.toString().padLeft(4, '0')}';

      while (allPatients.any((p) => p.medicalRecordNumber.trim().toUpperCase() == newUniqueMrn.toUpperCase())) {
        candidateIndex++;
        newUniqueMrn = 'MRN-$year-${candidateIndex.toString().padLeft(4, '0')}';
      }

      toInsert = PatientModel(
        patientId: model.patientId,
        medicalRecordNumber: newUniqueMrn,
        demographics: model.demographics,
        createdAt: model.createdAt,
      );
    }

    // Insert safely
    return await db.insert(
      PatientTable.tableName,
      toInsert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}


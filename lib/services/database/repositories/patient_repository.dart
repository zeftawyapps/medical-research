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
}

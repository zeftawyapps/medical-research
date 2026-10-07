import '../../../models/operation_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Operations Table CRUD using JoDija BaseCrudRepository
class OperationRepository extends BaseCrudRepository<OperationModel> {
  OperationRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => OperationModel.fromMap(map),
          tableName: OperationTable.tableName,
          primaryKeyColumn: OperationTable.columnOperationId,
        );

  /// Find all operations belonging to a patient
  Future<List<OperationModel>> getOperationsByPatientId(String patientId) async {
    return await query(
      where: '${OperationTable.columnPatientId} = ?',
      whereArgs: [patientId],
      orderBy: '${OperationTable.columnCreatedAt} DESC',
    );
  }
}

import '../../../models/blood_lab_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Blood Labs Table CRUD using JoDija BaseCrudRepository
class BloodLabRepository extends BaseCrudRepository<BloodLabModel> {
  BloodLabRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => BloodLabModel.fromMap(map),
          tableName: BloodLabTable.tableName,
          primaryKeyColumn: BloodLabTable.columnLabId,
        );

  /// Find all blood labs for an operation
  Future<List<BloodLabModel>> getByOperationId(String operationId) async {
    return await query(
      where: '${BloodLabTable.columnOperationId} = ?',
      whereArgs: [operationId],
    );
  }
}

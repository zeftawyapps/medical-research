import '../../../models/pre_op_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Pre-Op Assessment Table CRUD using JoDija BaseCrudRepository
class PreOpRepository extends BaseCrudRepository<PreOpModel> {
  PreOpRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => PreOpModel.fromMap(map),
          tableName: PreOpTable.tableName,
          primaryKeyColumn: PreOpTable.columnPreOpId,
        );

  /// Find pre-op record by operation id
  Future<PreOpModel?> getByOperationId(String operationId) async {
    final results = await query(
      where: '${PreOpTable.columnOperationId} = ?',
      whereArgs: [operationId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }
}

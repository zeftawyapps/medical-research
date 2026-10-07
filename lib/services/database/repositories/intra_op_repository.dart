import '../../../models/intra_op_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Intra-Op Details Table CRUD using JoDija BaseCrudRepository
class IntraOpRepository extends BaseCrudRepository<IntraOpModel> {
  IntraOpRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => IntraOpModel.fromMap(map),
          tableName: IntraOpTable.tableName,
          primaryKeyColumn: IntraOpTable.columnIntraOpId,
        );

  /// Find intra-op record by operation id
  Future<IntraOpModel?> getByOperationId(String operationId) async {
    final results = await query(
      where: '${IntraOpTable.columnOperationId} = ?',
      whereArgs: [operationId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }
}

import '../../../models/post_op_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Post-Op Details Table CRUD using JoDija BaseCrudRepository
class PostOpRepository extends BaseCrudRepository<PostOpModel> {
  PostOpRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => PostOpModel.fromMap(map),
          tableName: PostOpTable.tableName,
          primaryKeyColumn: PostOpTable.columnPostOpId,
        );

  /// Find post-op record by operation id
  Future<PostOpModel?> getByOperationId(String operationId) async {
    final results = await query(
      where: '${PostOpTable.columnOperationId} = ?',
      whereArgs: [operationId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }
}

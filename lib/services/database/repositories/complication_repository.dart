import '../../../models/complication_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Complications Table CRUD using JoDija BaseCrudRepository
class ComplicationRepository extends BaseCrudRepository<ComplicationModel> {
  ComplicationRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => ComplicationModel.fromMap(map),
          tableName: ComplicationTable.tableName,
          primaryKeyColumn: ComplicationTable.columnComplicationId,
        );

  /// Find all complications for an operation
  Future<List<ComplicationModel>> getByOperationId(String operationId) async {
    return await query(
      where: '${ComplicationTable.columnOperationId} = ?',
      whereArgs: [operationId],
      orderBy: '${ComplicationTable.columnPodDay} ASC',
    );
  }

  /// Find complications by Clavien-Dindo Grade
  Future<List<ComplicationModel>> getByGrade(String grade) async {
    return await query(
      where: '${ComplicationTable.columnGrade} = ?',
      whereArgs: [grade],
    );
  }
}

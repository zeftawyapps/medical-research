import '../../../models/survey_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Surveys Table CRUD using JoDija BaseCrudRepository
class SurveyRepository extends BaseCrudRepository<SurveyModel> {
  SurveyRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => SurveyModel.fromMap(map),
          tableName: SurveyTable.tableName,
          primaryKeyColumn: SurveyTable.columnSurveyId,
        );

  /// Find all surveys for an operation
  Future<List<SurveyModel>> getByOperationId(String operationId) async {
    return await query(
      where: '${SurveyTable.columnOperationId} = ?',
      whereArgs: [operationId],
    );
  }
}

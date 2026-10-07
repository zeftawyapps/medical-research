import '../../../models/research_template_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Research Templates Table CRUD using JoDija BaseCrudRepository
class ResearchTemplateRepository extends BaseCrudRepository<ResearchTemplateModel> {
  ResearchTemplateRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => ResearchTemplateModel.fromMap(map),
          tableName: ResearchTemplateTable.tableName,
          primaryKeyColumn: ResearchTemplateTable.columnTemplateId,
        );

  /// Find template by name
  Future<ResearchTemplateModel?> getByName(String name) async {
    final results = await query(
      where: '${ResearchTemplateTable.columnTemplateName} = ?',
      whereArgs: [name],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }
}

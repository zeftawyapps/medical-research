import '../../../models/research_abstract_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Research Abstracts Table CRUD using JoDija BaseCrudRepository
class ResearchAbstractRepository extends BaseCrudRepository<ResearchAbstractModel> {
  ResearchAbstractRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => ResearchAbstractModel.fromMap(map),
          tableName: ResearchAbstractTable.tableName,
          primaryKeyColumn: ResearchAbstractTable.columnAbstractId,
        );

  /// Find abstracts matching a title keyword
  Future<List<ResearchAbstractModel>> searchByTitle(String keyword) async {
    return await query(
      where: '${ResearchAbstractTable.columnAbstractTitle} LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: '${ResearchAbstractTable.columnCreatedAt} DESC',
    );
  }
}

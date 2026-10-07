import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../models/complication_catalog_model.dart';
import '../../../models/complication_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Master Complications Catalog CRUD
/// Exclusively depends on database records - NO hardcoded preset/mock lists
/// Only stores and syncs real data entered by the user.
class ComplicationCatalogRepository
    extends BaseCrudRepository<ComplicationCatalogModel> {
  static const Uuid _uuid = Uuid();

  ComplicationCatalogRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => ComplicationCatalogModel.fromMap(map),
          tableName: ComplicationCatalogTable.tableName,
          primaryKeyColumn: ComplicationCatalogTable.columnId,
        );

  Future<Database> get _db => DatabaseConnection().database;

  /// Get all complications in alphabetical order from database records only
  Future<List<ComplicationCatalogModel>> getAllComplications() async {
    await syncFromComplicationsTable();
    return await getAll(orderBy: '${ComplicationCatalogTable.columnName} ASC');
  }

  /// Search complication by name (case-insensitive)
  Future<ComplicationCatalogModel?> getByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final results = await query(
      where: 'LOWER(${ComplicationCatalogTable.columnName}) = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Find or create a complication in the catalog from user input
  Future<ComplicationCatalogModel> getOrCreateComplication(
    String name, {
    required String treatment,
    String grade =
        'Grade I (Minor complication, no specific treatment required)',
    String category = 'General',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Complication name cannot be empty');
    }

    final existing = await getByName(trimmedName);
    if (existing != null) {
      if (existing.treatment.isEmpty && treatment.isNotEmpty) {
        final updated = existing.copyWith(treatment: treatment, grade: grade);
        await update(updated);
        return updated;
      }
      return existing;
    }

    final newComp = ComplicationCatalogModel(
      id: _uuid.v4(),
      name: trimmedName,
      treatment: treatment,
      grade: grade,
      category: category,
      createdAt: DateTime.now(),
    );

    await insert(newComp);
    return newComp;
  }

  /// Synchronize complication names and treatments from existing logged complications in database
  /// Does NOT use any hardcoded preset lists
  Future<void> syncFromComplicationsTable() async {
    try {
      final db = await _db;
      final existingComps = await db.rawQuery(
        'SELECT DISTINCT ${ComplicationTable.columnDescription}, ${ComplicationTable.columnTreatment}, ${ComplicationTable.columnGrade} '
        'FROM ${ComplicationTable.tableName} '
        'WHERE ${ComplicationTable.columnDescription} IS NOT NULL AND TRIM(${ComplicationTable.columnDescription}) != ""',
      );

      for (final row in existingComps) {
        final desc =
            (row[ComplicationTable.columnDescription] as String? ?? '').trim();
        final treatment =
            (row[ComplicationTable.columnTreatment] as String? ?? '').trim();
        final grade =
            (row[ComplicationTable.columnGrade] as String? ?? '').trim();

        if (desc.isNotEmpty) {
          final found = await getByName(desc);
          if (found == null) {
            await insert(
              ComplicationCatalogModel(
                id: _uuid.v4(),
                name: desc,
                treatment: treatment,
                grade: grade.isNotEmpty
                    ? grade
                    : 'Grade I (Minor complication, no specific treatment required)',
                category: 'Clinical',
                createdAt: DateTime.now(),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../models/operation_model.dart';
import '../../../models/procedure_catalog_model.dart';
import '../connection/database_connection.dart';
import '../core/base_crud_repository.dart';

/// Repository for Master Procedure Catalog CRUD
/// Exclusively depends on database records - NO hardcoded preset lists
class ProcedureCatalogRepository
    extends BaseCrudRepository<ProcedureCatalogModel> {
  static const Uuid _uuid = Uuid();

  ProcedureCatalogRepository()
      : super(
          databaseProvider: () => DatabaseConnection().database,
          fromMap: (map) => ProcedureCatalogModel.fromMap(map),
          tableName: ProcedureCatalogTable.tableName,
          primaryKeyColumn: ProcedureCatalogTable.columnId,
        );

  Future<Database> get _db => DatabaseConnection().database;

  /// Get all procedures in alphabetical order
  Future<List<ProcedureCatalogModel>> getAllProcedures() async {
    await syncFromOperationsTable();
    return await getAll(orderBy: '${ProcedureCatalogTable.columnName} ASC');
  }

  /// Search procedure by name (case-insensitive)
  Future<ProcedureCatalogModel?> getByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final results = await query(
      where: 'LOWER(${ProcedureCatalogTable.columnName}) = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Find or create a procedure in the catalog
  Future<ProcedureCatalogModel> getOrCreateProcedure(
    String name, {
    String description = '',
    String pastMedicalHistory = '',
    String occupation = '',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Procedure name cannot be empty');
    }

    final existing = await getByName(trimmedName);
    if (existing != null) {
      // Update fields if non-empty details provided
      if ((existing.description.isEmpty && description.isNotEmpty) ||
          (existing.pastMedicalHistory.isEmpty &&
              pastMedicalHistory.isNotEmpty) ||
          (existing.occupation.isEmpty && occupation.isNotEmpty)) {
        final updated = existing.copyWith(
          description:
              description.isNotEmpty ? description : existing.description,
          pastMedicalHistory: pastMedicalHistory.isNotEmpty
              ? pastMedicalHistory
              : existing.pastMedicalHistory,
          occupation:
              occupation.isNotEmpty ? occupation : existing.occupation,
        );
        await update(updated);
        return updated;
      }
      return existing;
    }

    final newProcedure = ProcedureCatalogModel(
      id: _uuid.v4(),
      name: trimmedName,
      description: description,
      pastMedicalHistory: pastMedicalHistory,
      occupation: occupation,
      createdAt: DateTime.now(),
    );

    await insert(newProcedure);
    return newProcedure;
  }

  /// Synchronize procedure names from existing operations in the database
  /// Does NOT use any hardcoded preset lists
  Future<void> syncFromOperationsTable() async {
    try {
      final db = await _db;
      final existingOps = await db.rawQuery(
        'SELECT DISTINCT ${OperationTable.columnOperationType}, ${OperationTable.columnDiagnosisDetails} '
        'FROM ${OperationTable.tableName} '
        'WHERE ${OperationTable.columnOperationType} IS NOT NULL AND TRIM(${OperationTable.columnOperationType}) != ""',
      );

      for (final row in existingOps) {
        final opType =
            (row[OperationTable.columnOperationType] as String? ?? '').trim();
        final diagnosis =
            (row[OperationTable.columnDiagnosisDetails] as String? ?? '').trim();

        if (opType.isNotEmpty) {
          final found = await getByName(opType);
          if (found == null) {
            await insert(
              ProcedureCatalogModel(
                id: _uuid.v4(),
                name: opType,
                description: diagnosis,
                pastMedicalHistory: '',
                occupation: '',
                createdAt: DateTime.now(),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }
}

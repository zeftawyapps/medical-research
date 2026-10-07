import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../models/garment_catalog_models.dart';
import '../connection/database_connection.dart';

/// Repository managing self-learning catalogs for Garment Brands and Types/Areas
class GarmentCatalogRepository {
  static const Uuid _uuid = Uuid();

  Future<Database> get _db => DatabaseConnection().database;

  // Initial standard medical compression garment brands
  static const List<String> defaultBrands = [
    'Marena',
    'Lipoelastic',
    'VOE',
    'Leonisa',
    'Contour',
    'Isavela',
    'Cerecare',
    'ClearPoint',
  ];

  // Initial standard garment types / anatomical areas
  static const List<String> defaultTypes = [
    'Abdomen',
    'Chest',
    'Arms',
    'Thighs & Flanks',
    'Full Body Suit',
    'Face & Neck',
  ];

  bool _initialized = false;

  /// Ensures initial seeds exist in the database
  Future<void> ensureSeeded() async {
    if (_initialized) return;
    final db = await _db;

    // Check brands
    final brandCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${GarmentBrandTable.tableName}'),
    ) ?? 0;

    if (brandCount == 0) {
      final now = DateTime.now().toIso8601String();
      final batch = db.batch();
      for (final b in defaultBrands) {
        batch.insert(
          GarmentBrandTable.tableName,
          {
            GarmentBrandTable.columnId: _uuid.v4(),
            GarmentBrandTable.columnName: b,
            GarmentBrandTable.columnCreatedAt: now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }

    // Check types
    final typeCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${GarmentTypeTable.tableName}'),
    ) ?? 0;

    if (typeCount == 0) {
      final now = DateTime.now().toIso8601String();
      final batch = db.batch();
      for (final t in defaultTypes) {
        batch.insert(
          GarmentTypeTable.tableName,
          {
            GarmentTypeTable.columnId: _uuid.v4(),
            GarmentTypeTable.columnName: t,
            GarmentTypeTable.columnCreatedAt: now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }

    _initialized = true;
  }

  /// Get all brand suggestions
  Future<List<String>> getBrandSuggestions() async {
    await ensureSeeded();
    final db = await _db;
    final rows = await db.query(
      GarmentBrandTable.tableName,
      columns: [GarmentBrandTable.columnName],
      orderBy: '${GarmentBrandTable.columnName} ASC',
    );
    return rows.map((r) => r[GarmentBrandTable.columnName] as String).toList();
  }

  /// Get all type/area suggestions
  Future<List<String>> getTypeSuggestions() async {
    await ensureSeeded();
    final db = await _db;
    final rows = await db.query(
      GarmentTypeTable.tableName,
      columns: [GarmentTypeTable.columnName],
      orderBy: '${GarmentTypeTable.columnName} ASC',
    );
    return rows.map((r) => r[GarmentTypeTable.columnName] as String).toList();
  }

  /// Self-learn and store a new brand if not already present
  Future<void> saveBrand(String brandName) async {
    final trimmed = brandName.trim();
    if (trimmed.isEmpty) return;

    final db = await _db;
    final existing = await db.query(
      GarmentBrandTable.tableName,
      where: 'LOWER(${GarmentBrandTable.columnName}) = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert(
        GarmentBrandTable.tableName,
        {
          GarmentBrandTable.columnId: _uuid.v4(),
          GarmentBrandTable.columnName: trimmed,
          GarmentBrandTable.columnCreatedAt: DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Self-learn and store a new garment type/area if not already present
  Future<void> saveType(String typeName) async {
    final trimmed = typeName.trim();
    if (trimmed.isEmpty) return;

    final db = await _db;
    final existing = await db.query(
      GarmentTypeTable.tableName,
      where: 'LOWER(${GarmentTypeTable.columnName}) = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert(
        GarmentTypeTable.tableName,
        {
          GarmentTypeTable.columnId: _uuid.v4(),
          GarmentTypeTable.columnName: trimmed,
          GarmentTypeTable.columnCreatedAt: DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}

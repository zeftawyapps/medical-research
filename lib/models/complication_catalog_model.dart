import 'base/data_model.dart';

/// Database Table Constants for Complication Catalog Table (Master Complications Registry)
class ComplicationCatalogTable {
  static const String tableName = 'complication_catalog';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnTreatment = 'treatment';
  static const String columnGrade = 'grade';
  static const String columnCategory = 'category';
  static const String columnCreatedAt = 'created_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT UNIQUE NOT NULL,
      $columnTreatment TEXT NOT NULL,
      $columnGrade TEXT,
      $columnCategory TEXT,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';
}

/// Master Surgical Complication Catalog Model
/// Represents standard complications independent of individual cases
/// Allows auto-filling complication name, recognized treatment protocol, and Clavien-Dindo severity grade
class ComplicationCatalogModel extends DataModel {
  final String id; // UUID (PK)
  final String name; // Name of complication (e.g. 'Seroma', 'Hematoma', 'Surgical Site Infection (SSI)')
  final String treatment; // Standard treatment protocol / action plan
  final String grade; // Clavien-Dindo Classification
  final String category; // e.g. 'Wound', 'Vascular', 'Systemic', 'General'
  final DateTime createdAt;

  const ComplicationCatalogModel({
    required this.id,
    required this.name,
    required this.treatment,
    this.grade = 'Grade I (Minor complication, no specific treatment required)',
    this.category = 'General',
    required this.createdAt,
  });

  @override
  String get tableName => ComplicationCatalogTable.tableName;

  @override
  String get primaryKeyColumn => ComplicationCatalogTable.columnId;

  @override
  dynamic get primaryKeyValue => id;

  static String get createTableSql => ComplicationCatalogTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      ComplicationCatalogTable.columnId: id,
      ComplicationCatalogTable.columnName: name,
      ComplicationCatalogTable.columnTreatment: treatment,
      ComplicationCatalogTable.columnGrade: grade,
      ComplicationCatalogTable.columnCategory: category,
      ComplicationCatalogTable.columnCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory ComplicationCatalogModel.fromMap(Map<String, dynamic> map) {
    return ComplicationCatalogModel(
      id: map[ComplicationCatalogTable.columnId] as String? ?? '',
      name: map[ComplicationCatalogTable.columnName] as String? ?? '',
      treatment: map[ComplicationCatalogTable.columnTreatment] as String? ?? '',
      grade: map[ComplicationCatalogTable.columnGrade] as String? ??
          'Grade I (Minor complication, no specific treatment required)',
      category:
          map[ComplicationCatalogTable.columnCategory] as String? ?? 'General',
      createdAt: DateTime.tryParse(
            map[ComplicationCatalogTable.columnCreatedAt]?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  ComplicationCatalogModel copyWith({
    String? id,
    String? name,
    String? treatment,
    String? grade,
    String? category,
    DateTime? createdAt,
  }) {
    return ComplicationCatalogModel(
      id: id ?? this.id,
      name: name ?? this.name,
      treatment: treatment ?? this.treatment,
      grade: grade ?? this.grade,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

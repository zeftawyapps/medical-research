import 'base/data_model.dart';

/// Database Table Constants for Garment Brand / Manufacturer Catalog Table
class GarmentBrandTable {
  static const String tableName = 'garment_brand_catalog';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnCreatedAt = 'created_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT UNIQUE NOT NULL,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';
}

/// Master Garment Brand / Manufacturer Model for self-learning autocompletion
class GarmentBrandModel extends DataModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const GarmentBrandModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  @override
  String get tableName => GarmentBrandTable.tableName;

  @override
  String get primaryKeyColumn => GarmentBrandTable.columnId;

  @override
  dynamic get primaryKeyValue => id;

  static String get createTableSql => GarmentBrandTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      GarmentBrandTable.columnId: id,
      GarmentBrandTable.columnName: name,
      GarmentBrandTable.columnCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory GarmentBrandModel.fromMap(Map<String, dynamic> map) {
    return GarmentBrandModel(
      id: map[GarmentBrandTable.columnId] as String,
      name: map[GarmentBrandTable.columnName] as String,
      createdAt: DateTime.tryParse(
            map[GarmentBrandTable.columnCreatedAt] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  GarmentBrandModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return GarmentBrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Database Table Constants for Garment Type / Anatomical Area Catalog Table
class GarmentTypeTable {
  static const String tableName = 'garment_type_catalog';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnCreatedAt = 'created_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT UNIQUE NOT NULL,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';
}

/// Master Garment Type / Area Model for self-learning autocompletion
class GarmentTypeModel extends DataModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const GarmentTypeModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  @override
  String get tableName => GarmentTypeTable.tableName;

  @override
  String get primaryKeyColumn => GarmentTypeTable.columnId;

  @override
  dynamic get primaryKeyValue => id;

  static String get createTableSql => GarmentTypeTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      GarmentTypeTable.columnId: id,
      GarmentTypeTable.columnName: name,
      GarmentTypeTable.columnCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory GarmentTypeModel.fromMap(Map<String, dynamic> map) {
    return GarmentTypeModel(
      id: map[GarmentTypeTable.columnId] as String,
      name: map[GarmentTypeTable.columnName] as String,
      createdAt: DateTime.tryParse(
            map[GarmentTypeTable.columnCreatedAt] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  GarmentTypeModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return GarmentTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

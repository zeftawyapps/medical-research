import 'base/data_model.dart';

/// Database Table Constants for Procedure Catalog Table (Master Operations Registry)
class ProcedureCatalogTable {
  static const String tableName = 'procedure_catalog';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnDescription = 'description';
  static const String columnPastMedicalHistory = 'past_medical_history';
  static const String columnOccupation = 'occupation';
  static const String columnCreatedAt = 'created_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT UNIQUE NOT NULL,
      $columnDescription TEXT,
      $columnPastMedicalHistory TEXT,
      $columnOccupation TEXT,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';
}

/// Master Surgical Procedure Catalog Model
/// Represents standard procedures independent of individual patients
/// Allows auto-filling procedure name, diagnosis, past medical history, and occupation
class ProcedureCatalogModel extends DataModel {
  final String id; // UUID (PK)
  final String name; // Unique surgical procedure name (e.g. 'بواسير', 'فتق إربي')
  final String description; // Default diagnosis / indication
  final String pastMedicalHistory; // Default / common past medical history
  final String occupation; // Default / typical occupation
  final DateTime createdAt;

  const ProcedureCatalogModel({
    required this.id,
    required this.name,
    this.description = '',
    this.pastMedicalHistory = '',
    this.occupation = '',
    required this.createdAt,
  });

  @override
  String get tableName => ProcedureCatalogTable.tableName;

  @override
  String get primaryKeyColumn => ProcedureCatalogTable.columnId;

  @override
  dynamic get primaryKeyValue => id;

  static String get createTableSql => ProcedureCatalogTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      ProcedureCatalogTable.columnId: id,
      ProcedureCatalogTable.columnName: name,
      ProcedureCatalogTable.columnDescription: description,
      ProcedureCatalogTable.columnPastMedicalHistory: pastMedicalHistory,
      ProcedureCatalogTable.columnOccupation: occupation,
      ProcedureCatalogTable.columnCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory ProcedureCatalogModel.fromMap(Map<String, dynamic> map) {
    return ProcedureCatalogModel(
      id: map[ProcedureCatalogTable.columnId] as String? ?? '',
      name: map[ProcedureCatalogTable.columnName] as String? ?? '',
      description: map[ProcedureCatalogTable.columnDescription] as String? ?? '',
      pastMedicalHistory:
          map[ProcedureCatalogTable.columnPastMedicalHistory] as String? ?? '',
      occupation:
          map[ProcedureCatalogTable.columnOccupation] as String? ?? '',
      createdAt: DateTime.tryParse(
            map[ProcedureCatalogTable.columnCreatedAt]?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  ProcedureCatalogModel copyWith({
    String? id,
    String? name,
    String? description,
    String? pastMedicalHistory,
    String? occupation,
    DateTime? createdAt,
  }) {
    return ProcedureCatalogModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pastMedicalHistory: pastMedicalHistory ?? this.pastMedicalHistory,
      occupation: occupation ?? this.occupation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

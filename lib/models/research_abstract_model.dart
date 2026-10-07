import 'dart:convert';
import 'base/data_model.dart';

/// Database Table Constants for Research Abstracts Table
class ResearchAbstractTable {
  static const String tableName = 'research_abstracts';

  static const String columnAbstractId = 'abstract_id';
  static const String columnOperationIds = 'operation_ids';
  static const String columnAbstractTitle = 'abstract_title';
  static const String columnAbstractText = 'abstract_text';
  static const String columnCreatedAt = 'created_at';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnAbstractId TEXT PRIMARY KEY,
      $columnOperationIds TEXT NOT NULL,
      $columnAbstractTitle TEXT NOT NULL,
      $columnAbstractText TEXT NOT NULL,
      $columnCreatedAt TEXT NOT NULL
    )
  ''';
}

/// 10. Research Abstract (Abstracts Collection)
class ResearchAbstractModel extends DataModel {
  final String abstractId;
  final List<String> operationIds;
  final String abstractTitle;
  final String abstractText; // Markdown Format
  final DateTime createdAt;

  const ResearchAbstractModel({
    required this.abstractId,
    required this.operationIds,
    required this.abstractTitle,
    required this.abstractText,
    required this.createdAt,
  });

  @override
  String get tableName => ResearchAbstractTable.tableName;

  @override
  String get primaryKeyColumn => ResearchAbstractTable.columnAbstractId;

  @override
  dynamic get primaryKeyValue => abstractId;

  static String get createTableSql => ResearchAbstractTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      ResearchAbstractTable.columnAbstractId: abstractId,
      ResearchAbstractTable.columnOperationIds: jsonEncode(operationIds),
      ResearchAbstractTable.columnAbstractTitle: abstractTitle,
      ResearchAbstractTable.columnAbstractText: abstractText,
      ResearchAbstractTable.columnCreatedAt: createdAt.toIso8601String(),
    };
  }

  factory ResearchAbstractModel.fromMap(Map<String, dynamic> map) {
    return ResearchAbstractModel(
      abstractId: map[ResearchAbstractTable.columnAbstractId] as String,
      operationIds: _parseStringList(map[ResearchAbstractTable.columnOperationIds]),
      abstractTitle: map[ResearchAbstractTable.columnAbstractTitle] as String? ?? 'Research Abstract',
      abstractText: map[ResearchAbstractTable.columnAbstractText] as String? ?? '',
      createdAt: DateTime.tryParse(map[ResearchAbstractTable.columnCreatedAt]?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        if (raw.isNotEmpty) return [raw];
      }
    }
    return [];
  }
}

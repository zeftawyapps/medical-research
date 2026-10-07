import 'dart:convert';
import 'base/data_model.dart';

/// Template Field for dynamic schemas
class TemplateField {
  final String fieldName;
  final String fieldType; // String, Number, Date, Image, Dropdown

  const TemplateField({
    required this.fieldName,
    required this.fieldType,
  });

  Map<String, dynamic> toMap() => {
    'field_name': fieldName,
    'field_type': fieldType,
  };

  factory TemplateField.fromMap(Map<String, dynamic> map) => TemplateField(
    fieldName: map['field_name'] as String? ?? '',
    fieldType: map['field_type'] as String? ?? 'String',
  );
}

/// Database Table Constants for Research Templates Table
class ResearchTemplateTable {
  static const String tableName = 'research_templates';

  static const String columnTemplateId = 'template_id';
  static const String columnTemplateName = 'template_name';
  static const String columnFields = 'fields';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnTemplateId TEXT PRIMARY KEY,
      $columnTemplateName TEXT NOT NULL,
      $columnFields TEXT NOT NULL
    )
  ''';
}

/// 9. Dynamic Research Template (Dynamic Templates Collection)
class ResearchTemplateModel extends DataModel {
  final String templateId; // UUID / ObjectId
  final String templateName;
  final List<TemplateField> fields;

  const ResearchTemplateModel({
    required this.templateId,
    required this.templateName,
    required this.fields,
  });

  @override
  String get tableName => ResearchTemplateTable.tableName;

  @override
  String get primaryKeyColumn => ResearchTemplateTable.columnTemplateId;

  @override
  dynamic get primaryKeyValue => templateId;

  static String get createTableSql => ResearchTemplateTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      ResearchTemplateTable.columnTemplateId: templateId,
      ResearchTemplateTable.columnTemplateName: templateName,
      ResearchTemplateTable.columnFields: jsonEncode(fields.map((f) => f.toMap()).toList()),
    };
  }

  factory ResearchTemplateModel.fromMap(Map<String, dynamic> map) {
    final rawFields = map[ResearchTemplateTable.columnFields];
    List<dynamic> list = [];
    if (rawFields is String) {
      list = jsonDecode(rawFields) as List<dynamic>;
    } else if (rawFields is List) {
      list = rawFields;
    }
    return ResearchTemplateModel(
      templateId: map[ResearchTemplateTable.columnTemplateId] as String,
      templateName: map[ResearchTemplateTable.columnTemplateName] as String,
      fields: list.map((item) => TemplateField.fromMap(Map<String, dynamic>.from(item as Map))).toList(),
    );
  }
}

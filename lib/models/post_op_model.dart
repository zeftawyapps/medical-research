import 'dart:convert';
import 'base/data_model.dart';
import 'operation_model.dart';

/// Database Table Constants for Post-Op Table
class PostOpTable {
  static const String tableName = 'post_op_details';

  static const String columnPostOpId = 'post_op_id';
  static const String columnOperationId = 'operation_id';
  static const String columnPostOpDescription = 'post_op_description';
  static const String columnPostOpPictures = 'post_op_pictures';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnPostOpId TEXT PRIMARY KEY,
      $columnOperationId TEXT NOT NULL,
      $columnPostOpDescription TEXT,
      $columnPostOpPictures TEXT,
      FOREIGN KEY ($columnOperationId) REFERENCES ${OperationTable.tableName} (${OperationTable.columnOperationId}) ON DELETE CASCADE
    )
  ''';
}

/// 5. Post-Operative Follow-up & Pictures Model
class PostOpModel extends DataModel {
  final String postOpId; // UUID (PK)
  final String operationId; // UUID (FK)
  final String postOpDescription; // Recovery progression & evolution
  final List<String> postOpPictures; // Post-op follow-up photos

  // Compatibility getter
  List<String> get postOpImages => postOpPictures;

  PostOpModel({
    required this.postOpId,
    required this.operationId,
    this.postOpDescription = '',
    List<String>? postOpPictures,
    List<String>? postOpImages,
  }) : postOpPictures = postOpPictures ?? postOpImages ?? const [];

  @override
  String get tableName => PostOpTable.tableName;

  @override
  String get primaryKeyColumn => PostOpTable.columnPostOpId;

  @override
  dynamic get primaryKeyValue => postOpId;

  static String get createTableSql => PostOpTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      PostOpTable.columnPostOpId: postOpId,
      PostOpTable.columnOperationId: operationId,
      PostOpTable.columnPostOpDescription: postOpDescription,
      PostOpTable.columnPostOpPictures: jsonEncode(postOpPictures),
    };
  }

  factory PostOpModel.fromMap(Map<String, dynamic> map) {
    return PostOpModel(
      postOpId: map[PostOpTable.columnPostOpId] as String,
      operationId: map[PostOpTable.columnOperationId] as String,
      postOpDescription: map[PostOpTable.columnPostOpDescription] as String? ?? '',
      postOpPictures: _parseStringList(map[PostOpTable.columnPostOpPictures] ?? map['post_op_images']),
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

  PostOpModel copyWith({
    String? postOpId,
    String? operationId,
    String? postOpDescription,
    List<String>? postOpPictures,
  }) {
    return PostOpModel(
      postOpId: postOpId ?? this.postOpId,
      operationId: operationId ?? this.operationId,
      postOpDescription: postOpDescription ?? this.postOpDescription,
      postOpPictures: postOpPictures ?? this.postOpPictures,
    );
  }
}

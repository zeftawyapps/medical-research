import 'base/data_model.dart';
import 'operation_model.dart';

/// Database Table Constants for Complications Table
class ComplicationTable {
  static const String tableName = 'complications';

  static const String columnComplicationId = 'complication_id';
  static const String columnOperationId = 'operation_id';
  static const String columnDescription = 'description';
  static const String columnDateOfComplication = 'date_of_complication';
  static const String columnPodDay = 'pod_day';
  static const String columnTreatment = 'treatment';
  static const String columnGrade = 'grade';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnComplicationId TEXT PRIMARY KEY,
      $columnOperationId TEXT NOT NULL,
      $columnDescription TEXT NOT NULL,
      $columnDateOfComplication TEXT NOT NULL,
      $columnPodDay INTEGER NOT NULL DEFAULT 0,
      $columnTreatment TEXT NOT NULL,
      $columnGrade TEXT,
      FOREIGN KEY ($columnOperationId) REFERENCES ${OperationTable.tableName} (${OperationTable.columnOperationId}) ON DELETE CASCADE
    )
  ''';
}

/// 6. Complication Item Model (Part of the dedicated Complications List)
class ComplicationModel extends DataModel {
  final String complicationId; // UUID (PK)
  final String operationId; // UUID (FK)
  
  // 1/ Complications
  final String description; // Description of complication (e.g. Seroma, Infection)
  
  // 2/ Date of complications
  final DateTime dateOfComplication;
  
  // (Automatic) Post operative Day (Calculated relative to operation date)
  final int podDay;
  
  // 3/ Treatment
  final String treatment;
  
  // Optional Grade/Severity
  final String grade;

  // Compatibility getter
  String get management => treatment;

  ComplicationModel({
    required this.complicationId,
    required this.operationId,
    this.description = 'Clinical complication',
    DateTime? dateOfComplication,
    required this.podDay,
    String? treatment,
    String? management,
    this.grade = 'General',
  })  : dateOfComplication = dateOfComplication ?? DateTime.now(),
        treatment = treatment ?? management ?? '';

  @override
  String get tableName => ComplicationTable.tableName;

  @override
  String get primaryKeyColumn => ComplicationTable.columnComplicationId;

  @override
  dynamic get primaryKeyValue => complicationId;

  static String get createTableSql => ComplicationTable.createTableSql;

  /// Automatically computes the Post-Operative Day (POD) from the operation's date
  static int computePod(DateTime operationDate, DateTime complicationDate) {
    final opDateOnly = DateTime(operationDate.year, operationDate.month, operationDate.day);
    final compDateOnly = DateTime(complicationDate.year, complicationDate.month, complicationDate.day);
    final difference = compDateOnly.difference(opDateOnly).inDays;
    return difference >= 0 ? difference : 0;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ComplicationTable.columnComplicationId: complicationId,
      ComplicationTable.columnOperationId: operationId,
      ComplicationTable.columnDescription: description,
      ComplicationTable.columnDateOfComplication: dateOfComplication.toIso8601String(),
      ComplicationTable.columnPodDay: podDay,
      ComplicationTable.columnTreatment: treatment,
      ComplicationTable.columnGrade: grade,
    };
  }

  factory ComplicationModel.fromMap(Map<String, dynamic> map) {
    final rawDate = map[ComplicationTable.columnDateOfComplication] ?? map['created_at'];
    final rawMgmt = map[ComplicationTable.columnTreatment] ?? map['management'];
    final rawDesc = map[ComplicationTable.columnDescription] ?? rawMgmt;

    return ComplicationModel(
      complicationId: map[ComplicationTable.columnComplicationId] as String,
      operationId: map[ComplicationTable.columnOperationId] as String,
      description: rawDesc as String? ?? 'Clinical complication',
      dateOfComplication: DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now(),
      podDay: int.tryParse(map[ComplicationTable.columnPodDay]?.toString() ?? '0') ?? 0,
      treatment: rawMgmt as String? ?? '',
      grade: map[ComplicationTable.columnGrade] as String? ?? 'General',
    );
  }

  ComplicationModel copyWith({
    String? complicationId,
    String? operationId,
    String? description,
    DateTime? dateOfComplication,
    int? podDay,
    String? treatment,
    String? grade,
  }) {
    return ComplicationModel(
      complicationId: complicationId ?? this.complicationId,
      operationId: operationId ?? this.operationId,
      description: description ?? this.description,
      dateOfComplication: dateOfComplication ?? this.dateOfComplication,
      podDay: podDay ?? this.podDay,
      treatment: treatment ?? this.treatment,
      grade: grade ?? this.grade,
    );
  }
}

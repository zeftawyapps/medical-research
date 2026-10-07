import 'dart:convert';
import 'base/data_model.dart';
import 'operation_model.dart';

/// Database Table Constants for Surveys Table
class SurveyTable {
  static const String tableName = 'surveys';

  static const String columnSurveyId = 'survey_id';
  static const String columnOperationId = 'operation_id';
  static const String columnSurveyType = 'survey_type';
  static const String columnEvaluationQuestions = 'evaluation_questions';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnSurveyId TEXT PRIMARY KEY,
      $columnOperationId TEXT NOT NULL,
      $columnSurveyType TEXT NOT NULL,
      $columnEvaluationQuestions TEXT NOT NULL,
      FOREIGN KEY ($columnOperationId) REFERENCES ${OperationTable.tableName} (${OperationTable.columnOperationId}) ON DELETE CASCADE
    )
  ''';
}

/// 8. Surveys & Evaluations (Surveys Table)
class SurveyModel extends DataModel {
  final String surveyId; // UUID (PK)
  final String operationId; // UUID (FK)
  final String surveyType; // e.g. Pain VAS Score, Quality of Life EQ-5D, SF-36
  final Map<String, dynamic> evaluationQuestions; // Questionnaire JSON

  const SurveyModel({
    required this.surveyId,
    required this.operationId,
    required this.surveyType,
    required this.evaluationQuestions,
  });

  @override
  String get tableName => SurveyTable.tableName;

  @override
  String get primaryKeyColumn => SurveyTable.columnSurveyId;

  @override
  dynamic get primaryKeyValue => surveyId;

  static String get createTableSql => SurveyTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      SurveyTable.columnSurveyId: surveyId,
      SurveyTable.columnOperationId: operationId,
      SurveyTable.columnSurveyType: surveyType,
      SurveyTable.columnEvaluationQuestions: jsonEncode(evaluationQuestions),
    };
  }

  factory SurveyModel.fromMap(Map<String, dynamic> map) {
    return SurveyModel(
      surveyId: map[SurveyTable.columnSurveyId] as String,
      operationId: map[SurveyTable.columnOperationId] as String,
      surveyType: map[SurveyTable.columnSurveyType] as String? ?? 'General Survey',
      evaluationQuestions: map[SurveyTable.columnEvaluationQuestions] is String
          ? jsonDecode(map[SurveyTable.columnEvaluationQuestions] as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(map[SurveyTable.columnEvaluationQuestions] as Map? ?? {}),
    );
  }
}

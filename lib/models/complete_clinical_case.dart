import 'blood_lab_model.dart';
import 'complication_model.dart';
import 'intra_op_model.dart';
import 'operation_model.dart';
import 'patient_model.dart';
import 'post_op_model.dart';
import 'pre_op_model.dart';
import 'survey_model.dart';

/// Aggregate Clinical Case uniting all 8 relational tables for a single surgery
class CompleteClinicalCase {
  final PatientModel patient;
  final OperationModel operation;
  final PreOpModel? preOp;
  final IntraOpModel? intraOp;
  final PostOpModel? postOp;
  final List<ComplicationModel> complications;
  final List<BloodLabModel> bloodLabs;
  final List<SurveyModel> surveys;

  const CompleteClinicalCase({
    required this.patient,
    required this.operation,
    this.preOp,
    this.intraOp,
    this.postOp,
    this.complications = const [],
    this.bloodLabs = const [],
    this.surveys = const [],
  });

  bool get hasComplications => complications.isNotEmpty;
  int get complicationCount => complications.length;
  String get highestComplicationGrade {
    if (complications.isEmpty) return 'None';
    return complications.map((c) => c.grade).first;
  }
}

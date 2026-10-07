import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/patient_record_brd.dart';
import '../providers/research_provider.dart';
import '../theme/app_theme.dart';
import 'sections/intake_complications_section.dart';
import 'sections/intake_demographics_section.dart';
import 'sections/intake_intra_op_section.dart';
import 'sections/intake_labs_surveys_section.dart';
import 'sections/intake_operation_section.dart';
import 'sections/intake_post_op_section.dart';
import 'sections/intake_pre_op_section.dart';
import 'sections/intake_submit_button.dart';

class CaseIntakeFormScreen extends StatefulWidget {
  const CaseIntakeFormScreen({super.key});

  @override
  State<CaseIntakeFormScreen> createState() => _CaseIntakeFormScreenState();
}

class _CaseIntakeFormScreenState extends State<CaseIntakeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Patient Controllers
  final _mrnController = TextEditingController(
    text: 'MRN-2026-${1000 + DateTime.now().millisecond}',
  );
  final _nameController = TextEditingController();
  DateTime? _dob = DateTime(1985, 5, 20);
  final _dobController = TextEditingController(text: '1985-05-20');
  final _ageController = TextEditingController(text: '41');
  String _gender = 'Male';
  String? _country;
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  // Operation Controllers
  final _diagnosisController = TextEditingController();
  final _operationTypeController = TextEditingController();
  final _hospitalController = TextEditingController();
  DateTime _operationDate = DateTime.now();

  // Pre-Op Controllers
  final _preOpDescController = TextEditingController();
  final _radiologyReportController = TextEditingController();

  // Intra-Op Controllers
  final _intraOpDescController = TextEditingController();

  // Post-Op Controllers
  final _postOpDescController = TextEditingController();

  // Complication State
  bool _hasComplication = false;
  final _podController = TextEditingController(text: '2');
  String _grade = 'Clavien-Dindo Grade I';
  final _mgmtController = TextEditingController();

  // Lab State
  final _labNameController = TextEditingController(text: 'Hemoglobin');
  final _labValueController = TextEditingController(text: '13.5 g/dL');

  // Survey State
  final _surveyTypeController = TextEditingController(text: 'VAS Pain Score');
  final _surveyAnsController = TextEditingController(
    text: 'Score: 2/10, Good Mobility',
  );

  @override
  void dispose() {
    _mrnController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _diagnosisController.dispose();
    _operationTypeController.dispose();
    _preOpDescController.dispose();
    _radiologyReportController.dispose();
    _intraOpDescController.dispose();
    _postOpDescController.dispose();
    _podController.dispose();
    _mgmtController.dispose();
    _labNameController.dispose();
    _labValueController.dispose();
    _surveyTypeController.dispose();
    _surveyAnsController.dispose();
    super.dispose();
  }

  void _onDobSelected(DateTime picked) {
    setState(() {
      _dob = picked;
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      final now = DateTime.now();
      int calculatedAge = now.year - picked.year;
      if (now.month < picked.month ||
          (now.month == picked.month && now.day < picked.day)) {
        calculatedAge--;
      }
      _ageController.text = (calculatedAge >= 0 ? calculatedAge : 0).toString();
    });
  }

  Future<void> _saveCase() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ResearchProvider>();

    final demographics = {
      'name': _nameController.text.trim(),
      'date_of_birth': _dob != null
          ? DateFormat('yyyy-MM-dd').format(_dob!)
          : _dobController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'gender': _gender,
      'country': _country ?? '',
      'notes': _notesController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    List<ComplicationModel>? complications;
    if (_hasComplication && _mgmtController.text.isNotEmpty) {
      complications = [
        ComplicationModel(
          complicationId: const Uuid().v4(),
          operationId: '', // Filled in repository
          podDay: int.tryParse(_podController.text.trim()) ?? 1,
          grade: _grade,
          management: _mgmtController.text.trim(),
        ),
      ];
    }

    List<BloodLabModel>? labs;
    if (_labNameController.text.isNotEmpty &&
        _labValueController.text.isNotEmpty) {
      labs = [
        BloodLabModel(
          labId: const Uuid().v4(),
          operationId: '',
          testName: _labNameController.text.trim(),
          resultValue: _labValueController.text.trim(),
          testDate: _operationDate,
        ),
      ];
    }

    List<SurveyModel>? surveys;
    if (_surveyTypeController.text.isNotEmpty) {
      surveys = [
        SurveyModel(
          surveyId: const Uuid().v4(),
          operationId: '',
          surveyType: _surveyTypeController.text.trim(),
          evaluationQuestions: {
            'Patient_Feedback': _surveyAnsController.text.trim(),
          },
        ),
      ];
    }

    await provider.createClinicalCase(
      mrn: _mrnController.text.trim(),
      demographics: demographics,
      diagnosis: _diagnosisController.text.trim(),
      operationType: _operationTypeController.text.trim(),
      operationDate: _operationDate,
      hospital: _hospitalController.text.trim(),
      preOpDescription: _preOpDescController.text.trim(),
      clinicalImages: ['assets/images/clinical_intake.png'],
      radiologyReports: _radiologyReportController.text.trim(),
      radiologyImages: ['assets/images/rad_intake.png'],
      labFiles: ['assets/labs/intake_lab.pdf'],
      intraOpDescription: _intraOpDescController.text.trim(),
      intraOpImages: ['assets/images/intra_intake.png'],
      postOpDescription: _postOpDescController.text.trim(),
      postOpImages: ['assets/images/post_intake.png'],
      complications: complications,
      bloodLabs: labs,
      surveys: surveys,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Surgery case ${_mrnController.text} saved successfully into SQLite database!',
          ),
          backgroundColor: AppTheme.primaryTeal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: isLandscape ? 44 : kToolbarHeight,
        title: Text(
          'New Clinical Surgery Intake',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: isLandscape ? 15 : 17,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Save Record to SQLite',
            icon: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.primaryCyan,
              size: 24,
            ),
            onPressed: _saveCase,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 16 : 24,
            vertical: isLandscape ? 10 : 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Patient Demographics Section
                IntakeDemographicsSection(
                  mrnController: _mrnController,
                  nameController: _nameController,
                  dobController: _dobController,
                  ageController: _ageController,
                  phoneController: _phoneController,
                  notesController: _notesController,
                  gender: _gender,
                  country: _country,
                  dob: _dob,
                  isDark: isDark,
                  onDobSelected: _onDobSelected,
                  onGenderChanged: (val) => setState(() => _gender = val),
                  onCountryChanged: (val) => setState(() => _country = val),
                ),
                const SizedBox(height: 20),

                // 2. Operation & Primary Diagnosis
                IntakeOperationSection(
                  operationTypeController: _operationTypeController,
                  diagnosisController: _diagnosisController,
                  hospitalController: _hospitalController,
                  operationDate: _operationDate,
                  isDark: isDark,
                  onDateSelected: (val) =>
                      setState(() => _operationDate = val),
                ),
                const SizedBox(height: 20),

                // 3. Pre-Operative Assessment
                IntakePreOpSection(
                  preOpDescController: _preOpDescController,
                  radiologyReportController: _radiologyReportController,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // 4. Intra-Operative Details & Notes
                IntakeIntraOpSection(
                  intraOpDescController: _intraOpDescController,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // 5. Post-Operative Follow-Up & Evolution
                IntakePostOpSection(
                  postOpDescController: _postOpDescController,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // 6. Complications Tracking
                IntakeComplicationsSection(
                  hasComplication: _hasComplication,
                  onHasComplicationChanged: (val) =>
                      setState(() => _hasComplication = val),
                  podController: _podController,
                  grade: _grade,
                  onGradeChanged: (val) => setState(() => _grade = val),
                  mgmtController: _mgmtController,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // 7. Digital Labs & Patient Survey Intake
                IntakeLabsSurveysSection(
                  labNameController: _labNameController,
                  labValueController: _labValueController,
                  surveyTypeController: _surveyTypeController,
                  surveyAnsController: _surveyAnsController,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),

                // Submit Button
                IntakeSubmitButton(
                  onPressed: _saveCase,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/patient_record_brd.dart';
import '../services/database/clinical_repository.dart';
import '../services/garment_preferences_service.dart';
import 'add_operation_screen.dart';
import 'sections/add_patient_dialog.dart' as patient_dialog;
import 'sections/clinical_expandable_section.dart';
import 'sections/operations_list_tab.dart';
import 'sections/patient_profile_header.dart';
import 'sections/patient_search_dialog.dart' as patient_search;
import 'sections/post_op_tab.dart';
import 'package:JoDija_tamplites/JoDija_tamplites.dart';

import 'sections/pre_op_tab.dart';

/// Clinical case and surgical operation management screen
class ClinicalCaseManagementScreen extends StatefulWidget {
  static final GlobalKey<ClinicalCaseManagementScreenState> caseManagementKey =
      GlobalKey<ClinicalCaseManagementScreenState>();

  /// Pending patient ID to select if navigation happens before or during mounting
  static String? pendingPatientId;

  /// Pending operation ID to select upon arrival
  static String? pendingOperationId;

  /// Flag to automatically trigger Add Patient dialog on arrival
  static bool autoOpenAddPatientDialog = false;

  /// Selects a patient and transitions route to Case Management (/surgical_hub)
  static void navigateAndSelectPatient(
    BuildContext context,
    PatientModel patient, {
    String? operationId,
  }) {
    pendingPatientId = patient.patientId;
    pendingOperationId = operationId;
    if (caseManagementKey.currentState != null) {
      caseManagementKey.currentState!.selectPatientById(
        patient.patientId,
        operationId: operationId,
      );
    }
    try {
      final router = Provider.of<AppShellRouterProvider>(
        context,
        listen: false,
      );
      try {
        (router as dynamic).handleItemTapByPath(context, '/surgical_hub');
      } catch (_) {
        try {
          (router as dynamic).handleItemTapByPath(
            context,
            '/surgical_hub',
            null,
          );
        } catch (_) {}
      }
    } catch (_) {
      try {
        context.go('/surgical_hub');
      } catch (_) {}
    }
  }

  /// Navigates first to Case Management (/surgical_hub) and then automatically opens Add Patient dialog
  static void navigateAndOpenAddPatientDialog(BuildContext context) {
    autoOpenAddPatientDialog = true;
    try {
      final router = Provider.of<AppShellRouterProvider>(
        context,
        listen: false,
      );
      try {
        (router as dynamic).handleItemTapByPath(context, '/surgical_hub');
      } catch (_) {
        try {
          (router as dynamic).handleItemTapByPath(
            context,
            '/surgical_hub',
            null,
          );
        } catch (_) {}
      }
    } catch (_) {
      try {
        context.go('/surgical_hub');
      } catch (_) {}
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (caseManagementKey.currentState != null && autoOpenAddPatientDialog) {
        autoOpenAddPatientDialog = false;
        caseManagementKey.currentState!.openAddPatientDialog();
      }
    });
  }

  /// Navigates to the Home / Clinical Query screen (/clinical_query)
  static void navigateToHome(BuildContext context) {
    try {
      final router = Provider.of<AppShellRouterProvider>(
        context,
        listen: false,
      );
      try {
        (router as dynamic).handleItemTapByPath(context, '/clinical_query');
      } catch (_) {
        try {
          (router as dynamic).handleItemTapByPath(
            context,
            '/clinical_query',
            null,
          );
        } catch (_) {}
      }
    } catch (_) {
      try {
        context.go('/clinical_query');
      } catch (_) {}
    }
  }

  const ClinicalCaseManagementScreen({super.key});

  @override
  State<ClinicalCaseManagementScreen> createState() =>
      ClinicalCaseManagementScreenState();
}

class ClinicalCaseManagementScreenState
    extends State<ClinicalCaseManagementScreen> {
  final ClinicalRepository _repository = ClinicalRepository();

  // State
  bool _isLoading = true;
  List<PatientModel> _patients = [];
  PatientModel? _selectedPatient;

  List<OperationModel> _patientOperations = [];
  OperationModel? _selectedOperation;

  // Scroll & Expansion Keys
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _operationsKey = GlobalKey();
  final GlobalKey _preOpKey = GlobalKey();
  final GlobalKey _postOpKey = GlobalKey();

  // Post-Op & Complications State
  List<ComplicationModel> _operationComplications = [];
  final TextEditingController _postOpNotesController = TextEditingController();
  List<String> _postOpPictures = [];

  // Expansion state for the main clinical sections
  bool _isOperationsExpanded = true;
  bool _isPreOpExpanded = false;
  bool _isPostOpExpanded = false;

  final TextEditingController _opTypeController = TextEditingController();
  final TextEditingController _opReasonController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  DateTime _opDate = DateTime.now();

  // Controllers for Pre-Op
  final TextEditingController _pastHistoryController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  bool _isSmoker = false;
  final TextEditingController _cigsPerDayController = TextEditingController();
  final TextEditingController _smokingYearsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _hbController = TextEditingController();
  final TextEditingController _tshController = TextEditingController();
  final TextEditingController _hba1cController = TextEditingController();
  List<String> _scanPictures = [];
  List<String> _preOpPictures = [];

  // Controllers for Operative Details
  final TextEditingController _opNotesController = TextEditingController();
  final TextEditingController _fatVolumeController = TextEditingController();
  String _selectedCorset = 'Abdominal Garment';
  bool _isGarmentRequired = false;
  final TextEditingController _garmentTypeController = TextEditingController();
  final TextEditingController _garmentBrandController = TextEditingController();
  List<String> _garmentBrandSuggestions = [];
  List<String> _garmentTypeSuggestions = [];
  bool _showGarmentValidationErrors = false;
  List<String> _operativePictures = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _opTypeController.dispose();
    _opReasonController.dispose();
    _hospitalController.dispose();
    _pastHistoryController.dispose();
    _occupationController.dispose();
    _cigsPerDayController.dispose();
    _smokingYearsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _hbController.dispose();
    _tshController.dispose();
    _hba1cController.dispose();
    _opNotesController.dispose();
    _fatVolumeController.dispose();
    _garmentTypeController.dispose();
    _garmentBrandController.dispose();
    _postOpNotesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _expandSection(int section) {
    setState(() {
      _isOperationsExpanded = section == 0;
      _isPreOpExpanded = section == 1;
      _isPostOpExpanded = section == 2;
    });

    GlobalKey? targetKey;
    if (section == 0) targetKey = _operationsKey;
    if (section == 1) targetKey = _preOpKey;
    if (section == 2) targetKey = _postOpKey;

    if (targetKey != null) {
      _scrollToSection(targetKey);
    }
  }

  void _scrollToSection(GlobalKey key) {
    // 1. Initial scroll trigger right after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: 0.0,
        );
      }
    });

    // 2. Final alignment after expansion animation settles
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: 0.0,
        );
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final patientsList = await _repository.getAllPatients();
      _patients = patientsList;
      try {
        final prefTypes = await GarmentPreferencesService.getAllTypes();
        final prefBrands = await GarmentPreferencesService.getAllBrands();
        final dbBrands = await _repository.getGarmentBrandSuggestions();
        final dbTypes = await _repository.getGarmentTypeSuggestions();
        final combinedTypes = <String>[...prefTypes];
        for (final t in dbTypes) {
          if (!combinedTypes.any((e) => e.toLowerCase() == t.toLowerCase())) {
            combinedTypes.add(t);
          }
        }
        final combinedBrands = <String>[...prefBrands];
        for (final b in dbBrands) {
          if (!combinedBrands.any((e) => e.toLowerCase() == b.toLowerCase())) {
            combinedBrands.add(b);
          }
        }
        _garmentTypeSuggestions = combinedTypes;
        _garmentBrandSuggestions = combinedBrands;
      } catch (_) {}
      if (_patients.isNotEmpty) {
        if (ClinicalCaseManagementScreen.pendingPatientId != null) {
          final target = _patients.where(
            (p) => p.patientId == ClinicalCaseManagementScreen.pendingPatientId,
          );
          if (target.isNotEmpty) {
            _selectedPatient = target.first;
          } else {
            _selectedPatient = _patients.first;
          }
          ClinicalCaseManagementScreen.pendingPatientId = null;
        } else if (_selectedPatient == null ||
            !_patients.any((p) => p.patientId == _selectedPatient!.patientId)) {
          _selectedPatient = _patients.first;
        }
        await _loadOperationsForPatient(
          _selectedPatient!.patientId,
          targetOperationId: ClinicalCaseManagementScreen.pendingOperationId,
        );
        ClinicalCaseManagementScreen.pendingOperationId = null;
      } else {
        _selectedPatient = null;
        _patientOperations = [];
        _selectedOperation = null;
        _clearOperationForm();
      }
    } catch (e) {
      debugPrint('Error loading clinical cases: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (ClinicalCaseManagementScreen.autoOpenAddPatientDialog) {
          ClinicalCaseManagementScreen.autoOpenAddPatientDialog = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              openAddPatientDialog();
            }
          });
        }
      }
    }
  }

  /// Public method to select patient by ID programmatically from external screens
  Future<void> selectPatientById(
    String patientId, {
    String? operationId,
  }) async {
    await _loadInitialData();
    final matching = _patients.where((p) => p.patientId == patientId);
    if (matching.isNotEmpty) {
      setState(() {
        _selectedPatient = matching.first;
        _isOperationsExpanded = true;
      });
      await _loadOperationsForPatient(
        matching.first.patientId,
        targetOperationId: operationId,
      );
    }
  }

  Future<void> _loadOperationsForPatient(
    String patientId, {
    String? targetOperationId,
  }) async {
    final ops = await _repository.operationRepo.getOperationsByPatientId(
      patientId,
    );
    _patientOperations = ops;
    if (ops.isNotEmpty) {
      if (targetOperationId != null) {
        final match = ops.where((o) => o.operationId == targetOperationId);
        if (match.isNotEmpty) {
          await _selectOperation(match.first);
          return;
        }
      }
      await _selectOperation(ops.first);
    } else {
      _selectedOperation = null;
      _clearOperationForm();
      setState(() {});
    }
  }

  Future<void> _selectOperation(OperationModel op) async {
    _selectedOperation = op;
    _opTypeController.text = op.operationType;
    _opReasonController.text = op.diagnosisDetails;
    _hospitalController.text = op.hospital;
    _opDate = op.createdAt;

    // Load Pre-Op
    final preOp = await _repository.preOpRepo.getByOperationId(op.operationId);
    if (preOp != null) {
      _pastHistoryController.text = preOp.pastMedicalHistory;
      _occupationController.text = preOp.occupation;
      _isSmoker = preOp.isSmoker;
      _cigsPerDayController.text = preOp.cigarettesPerDay?.toString() ?? '';
      _smokingYearsController.text = preOp.smokingYears?.toString() ?? '';
      _weightController.text = preOp.weightKg?.toString() ?? '';
      _heightController.text = preOp.heightM?.toString() ?? '';
      _hbController.text = preOp.hemoglobin?.toString() ?? '';
      _tshController.text = preOp.tsh?.toString() ?? (preOp.t3?.toString() ?? '');
      _hba1cController.text = preOp.hba1c?.toString() ?? (preOp.t4?.toString() ?? '');
      _scanPictures = List<String>.from(preOp.scanPictures);
      _preOpPictures = List<String>.from(preOp.preOpPictures);
    } else {
      _clearPreOpForm();
    }

    // Load Intra-Op
    final intraOp = await _repository.intraOpRepo.getByOperationId(
      op.operationId,
    );
    if (intraOp != null) {
      _opNotesController.text = intraOp.operativeNotes;
      _fatVolumeController.text = intraOp.amountOfFatLiters?.toString() ?? '';
      _isGarmentRequired = intraOp.isGarmentRequired;
      _garmentTypeController.text = intraOp.garmentType;
      _garmentBrandController.text = intraOp.garmentBrandModel;
      _selectedCorset = intraOp.corsetType.isNotEmpty
          ? intraOp.corsetType
          : (intraOp.garmentType.isNotEmpty
                ? intraOp.garmentType
                : 'Abdominal Garment');
      _operativePictures = List<String>.from(intraOp.operativePictures);
    } else {
      _opNotesController.clear();
      _fatVolumeController.clear();
      _isGarmentRequired = false;
      _garmentTypeController.clear();
      _garmentBrandController.clear();
      _selectedCorset = 'Abdominal Garment';
      _operativePictures = [];
    }
    _showGarmentValidationErrors = false;

    // Load Complications
    _operationComplications = await _repository.complicationRepo
        .getByOperationId(op.operationId);

    // Load Post-Op notes & pictures
    final postOp = await _repository.postOpRepo.getByOperationId(
      op.operationId,
    );
    if (postOp != null) {
      _postOpNotesController.text = postOp.postOpDescription;
      _postOpPictures = List<String>.from(postOp.postOpPictures);
    } else {
      _postOpNotesController.clear();
      _postOpPictures = [];
    }

    setState(() {});
  }

  void _clearOperationForm() {
    _opTypeController.clear();
    _opReasonController.clear();
    _hospitalController.clear();
    _opDate = DateTime.now();
    _clearPreOpForm();
    _opNotesController.clear();
    _fatVolumeController.clear();
    _isGarmentRequired = false;
    _garmentTypeController.clear();
    _garmentBrandController.clear();
    _showGarmentValidationErrors = false;
    _selectedCorset = 'Abdominal Garment';
    _operativePictures = [];
    _operationComplications = [];
    _postOpNotesController.clear();
    _postOpPictures = [];
  }

  void _clearPreOpForm() {
    _pastHistoryController.clear();
    _occupationController.clear();
    _isSmoker = false;
    _cigsPerDayController.clear();
    _smokingYearsController.clear();
    _weightController.clear();
    _heightController.clear();
    _hbController.clear();
    _tshController.clear();
    _hba1cController.clear();
    _scanPictures = [];
    _preOpPictures = [];
  }

  // Add new patient dialog (extracted to lib/screens/sections/add_patient_dialog.dart)
  void openAddPatientDialog() {
    patient_dialog.openAddPatientDialog(
      context: context,
      repository: _repository,
      existingPatients: _patients,
      onPatientAdded: (newPatient) async {
        await _loadInitialData();
        setState(() {
          _selectedPatient = newPatient;
        });
        await _loadOperationsForPatient(newPatient.patientId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openAddOperationScreen();
        });
      },
    );
  }

  // Edit existing patient details dialog
  void openEditPatientDialog() {
    if (_selectedPatient == null) return;
    patient_dialog.openAddPatientDialog(
      context: context,
      repository: _repository,
      existingPatients: _patients,
      initialPatient: _selectedPatient,
      onPatientAdded: (savedPatient) async {
        await _loadInitialData();
        setState(() {
          _selectedPatient = savedPatient;
        });
        await _loadOperationsForPatient(savedPatient.patientId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Patient "${savedPatient.name}" updated successfully.'),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  // Open dedicated screen to add a surgical operation
  Future<void> _openAddOperationScreen() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select or add a patient first.'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final createdOp = await Navigator.push<OperationModel>(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddOperationScreen(patient: _selectedPatient!),
      ),
    );

    if (createdOp != null && mounted) {
      await _loadOperationsForPatient(_selectedPatient!.patientId);
      await _selectOperation(createdOp);
      if (!mounted) return;
      _expandSection(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Operation "${createdOp.operationType}" created! Now enter clinical details below.',
              ),
            ],
          ),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Save Pre-Op and Operative Details
  Future<void> _savePreOpAndOperative() async {
    if (_selectedOperation == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 700),
          content: Text('Please select or create an operation first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    const uuid = Uuid();
    final opId = _selectedOperation!.operationId;

    // Validation for Garment: Required when isGarmentRequired is true
    if (_isGarmentRequired) {
      final gType = _garmentTypeController.text.trim();
      final gBrand = _garmentBrandController.text.trim();
      if (gType.isEmpty || gBrand.isEmpty) {
        setState(() => _showGarmentValidationErrors = true);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Please enter both Garment Type/Area and Brand/Model'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(milliseconds: 700),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // 1. Update Operation
    final updatedOp = _selectedOperation!.copyWith(
      operationType: _opTypeController.text.trim(),
      diagnosisDetails: _opReasonController.text.trim(),
      hospital: _hospitalController.text.trim(),
    );
    await _repository.updateOperation(updatedOp);
    _selectedOperation = updatedOp;

    // 2. Save / Update Pre-Op
    final existingPreOp = await _repository.preOpRepo.getByOperationId(opId);
    final preOpToSave = PreOpModel(
      preOpId: existingPreOp?.preOpId ?? uuid.v4(),
      operationId: opId,
      pastMedicalHistory: _pastHistoryController.text.trim(),
      occupation: _occupationController.text.trim(),
      isSmoker: _isSmoker,
      cigarettesPerDay: int.tryParse(_cigsPerDayController.text.trim()),
      smokingYears: int.tryParse(_smokingYearsController.text.trim()),
      weightKg: double.tryParse(_weightController.text.trim()),
      heightM: double.tryParse(_heightController.text.trim()),
      hemoglobin: double.tryParse(_hbController.text.trim()),
      tsh: double.tryParse(_tshController.text.trim()),
      hba1c: double.tryParse(_hba1cController.text.trim()),
      scanPictures: _scanPictures,
      preOpPictures: _preOpPictures,
    );

    await _repository.insertPreOp(preOpToSave);

    // 3. Save / Update Intra-Op
    final existingIntraOp = await _repository.intraOpRepo.getByOperationId(
      opId,
    );
    final intraOpToSave = IntraOpModel(
      intraOpId: existingIntraOp?.intraOpId ?? uuid.v4(),
      operationId: opId,
      operativeNotes: _opNotesController.text.trim(),
      operativePictures: _operativePictures,
      amountOfFatLiters: double.tryParse(_fatVolumeController.text.trim()),
      isGarmentRequired: _isGarmentRequired,
      garmentType: _isGarmentRequired ? _garmentTypeController.text.trim() : '',
      garmentBrandModel: _isGarmentRequired
          ? _garmentBrandController.text.trim()
          : '',
      corsetType: _isGarmentRequired
          ? (_garmentBrandController.text.trim().isNotEmpty
                ? '${_garmentTypeController.text.trim()} (${_garmentBrandController.text.trim()})'
                : _garmentTypeController.text.trim())
          : 'No',
    );

    await _repository.insertIntraOp(intraOpToSave);
    try {
      if (_isGarmentRequired) {
        if (_garmentTypeController.text.trim().isNotEmpty) {
          await GarmentPreferencesService.saveCustomType(
            _garmentTypeController.text.trim(),
          );
        }
        if (_garmentBrandController.text.trim().isNotEmpty) {
          await GarmentPreferencesService.saveCustomBrand(
            _garmentBrandController.text.trim(),
          );
        }
      }
      final prefTypes = await GarmentPreferencesService.getAllTypes();
      final prefBrands = await GarmentPreferencesService.getAllBrands();
      _garmentTypeSuggestions = prefTypes;
      _garmentBrandSuggestions = prefBrands;
    } catch (_) {}
    _showGarmentValidationErrors = false;

    // Reload operations list
    await _loadOperationsForPatient(_selectedPatient!.patientId);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Pre-Op and operative details saved successfully!'),
              ),
            ],
          ),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Save Post-Op Details
  Future<void> _savePostOp() async {
    if (_selectedOperation == null) return;

    const uuid = Uuid();
    final opId = _selectedOperation!.operationId;

    final existingPostOp = await _repository.postOpRepo.getByOperationId(opId);
    final postOpToSave = PostOpModel(
      postOpId: existingPostOp?.postOpId ?? uuid.v4(),
      operationId: opId,
      postOpDescription: _postOpNotesController.text.trim(),
      postOpPictures: _postOpPictures,
    );

    await _repository.insertPostOp(postOpToSave);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Post-operative follow-up and pictures saved successfully!'),
              ),
            ],
          ),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Complication Handlers
  Future<void> _handleAddComplication(ComplicationModel comp) async {
    if (_selectedOperation == null) return;

    final compWithOp = comp.copyWith(
      operationId: _selectedOperation!.operationId,
    );
    await _repository.addComplication(compWithOp);
    _operationComplications = await _repository.complicationRepo
        .getByOperationId(_selectedOperation!.operationId);
    setState(() {});
  }

  Future<void> _handleDeleteComplication(String compId) async {
    await _repository.deleteComplication(compId);
    if (_selectedOperation != null) {
      _operationComplications = await _repository.complicationRepo
          .getByOperationId(_selectedOperation!.operationId);
      setState(() {});
    }
  }

  // Confirm clear all database
  Future<void> confirmClearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Reset & Purge All Data'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all patient records and surgeries? This action cannot be undone and will reset the database completely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Purge Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await _repository.clearAllData();
      await _loadInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Database has been purged successfully! Starting clean.'),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Clinical Case Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Return to Home / Research Query',
            icon: const Icon(Icons.home_rounded),
            onPressed: () => ClinicalCaseManagementScreen.navigateToHome(context),
          ),
          IconButton(
            tooltip: 'Find / Search Patient',
            icon: const Icon(Icons.person_search_rounded),
            onPressed: openPatientSearchDialog,
          ),
          IconButton(
            tooltip: 'Register New Patient',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: openAddPatientDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
            onSelected: (val) {
              if (val == 'search_patient') {
                openPatientSearchDialog();
              } else if (val == 'new_patient') {
                openAddPatientDialog();
              } else if (val == 'refresh') {
                _loadInitialData();
              } else if (val == 'reset') {
                confirmClearDatabase();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'new_patient',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.teal,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('New Patient'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('Reset Database', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Patient Profile Header & Quick Switcher
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: PatientProfileHeader(
                  selectedPatient: _selectedPatient,
                  hasPatients: _patients.isNotEmpty,
                  isDark: isDark,
                  onFindPatient: openPatientSearchDialog,
                  onNewPatient: openAddPatientDialog,
                  onChangePatient: openPatientSearchDialog,
                  onEditPatient: openEditPatientDialog,
                  onAddOperation: _openAddOperationScreen,
                ),
              ),

              // 2. Expandable clinical sections
              ClinicalExpandableSection(
                key: _operationsKey,
                isDark: isDark,
                title: 'Operations (${_patientOperations.length})',
                icon: Icons.workspaces_rounded,
                initiallyExpanded: _isOperationsExpanded,
                onExpansionChanged: (expanded) {
                  if (expanded) {
                    _expandSection(0);
                  } else {
                    setState(() => _isOperationsExpanded = false);
                  }
                },
                child: OperationsListTab(
                  selectedPatient: _selectedPatient,
                  patientOperations: _patientOperations,
                  selectedOperation: _selectedOperation,
                  isDark: isDark,
                  onSearchPatient: openPatientSearchDialog,
                  onAddOperation: _openAddOperationScreen,
                  onSelectOperation: _selectOperation,
                  onExpandSection: _expandSection,
                ),
              ),
              ClinicalExpandableSection(
                key: _preOpKey,
                isDark: isDark,
                title: 'Pre-Op & Intra-Op',
                icon: Icons.medical_services_rounded,
                initiallyExpanded: _isPreOpExpanded,
                onExpansionChanged: (expanded) {
                  if (expanded) {
                    _expandSection(1);
                  } else {
                    setState(() => _isPreOpExpanded = false);
                  }
                },
                child: PreOpTab(
                  selectedOperation: _selectedOperation,
                  selectedPatient: _selectedPatient,
                  opDate: _opDate,
                  onOpDateChanged: (val) => setState(() => _opDate = val),
                  opTypeController: _opTypeController,
                  opReasonController: _opReasonController,
                  hospitalController: _hospitalController,
                  pastHistoryController: _pastHistoryController,
                  occupationController: _occupationController,
                  isSmoker: _isSmoker,
                  onSmokerChanged: (val) => setState(() => _isSmoker = val),
                  cigsPerDayController: _cigsPerDayController,
                  smokingYearsController: _smokingYearsController,
                  weightController: _weightController,
                  heightController: _heightController,
                  hbController: _hbController,
                  tshController: _tshController,
                  hba1cController: _hba1cController,
                  scanPictures: _scanPictures,
                  onScanPicturesChanged: (val) => _scanPictures = val,
                  preOpPictures: _preOpPictures,
                  onPreOpPicturesChanged: (val) => _preOpPictures = val,
                  opNotesController: _opNotesController,
                  operativePictures: _operativePictures,
                  onOperativePicturesChanged: (val) => _operativePictures = val,
                  fatVolumeController: _fatVolumeController,
                  selectedCorset: _selectedCorset,
                  onCorsetChanged: (val) =>
                      setState(() => _selectedCorset = val),
                  isGarmentRequired: _isGarmentRequired,
                  onGarmentRequiredChanged: (val) {
                    setState(() {
                      _isGarmentRequired = val;
                      if (!val) _showGarmentValidationErrors = false;
                    });
                  },
                  garmentTypeController: _garmentTypeController,
                  garmentBrandController: _garmentBrandController,
                  garmentBrandSuggestions: _garmentBrandSuggestions,
                  garmentTypeSuggestions: _garmentTypeSuggestions,
                  onGarmentTypeAdded: (newType) async {
                    await GarmentPreferencesService.saveCustomType(newType);
                    final updated =
                        await GarmentPreferencesService.getAllTypes();
                    setState(() => _garmentTypeSuggestions = updated);
                  },
                  onGarmentBrandAdded: (newBrand) async {
                    await GarmentPreferencesService.saveCustomBrand(newBrand);
                    final updated =
                        await GarmentPreferencesService.getAllBrands();
                    setState(() => _garmentBrandSuggestions = updated);
                  },
                  showGarmentValidationErrors: _showGarmentValidationErrors,
                  onSave: _savePreOpAndOperative,
                  onGoToOperations: () => _expandSection(0),
                  onWeightHeightChanged: () => setState(() {}),
                  isDark: isDark,
                ),
              ),
              ClinicalExpandableSection(
                key: _postOpKey,
                isDark: isDark,
                title: 'Post-Op & Complications',
                icon: Icons.healing_rounded,
                initiallyExpanded: _isPostOpExpanded,
                onExpansionChanged: (expanded) {
                  if (expanded) {
                    _expandSection(2);
                  } else {
                    setState(() => _isPostOpExpanded = false);
                  }
                },
                child: PostOpTab(
                  selectedOperation: _selectedOperation,
                  opDate: _opDate,
                  operationComplications: _operationComplications,
                  onAddComplication: _handleAddComplication,
                  onDeleteComplication: _handleDeleteComplication,
                  postOpNotesController: _postOpNotesController,
                  postOpPictures: _postOpPictures,
                  onPostOpPicturesChanged: (val) => _postOpPictures = val,
                  onSavePostOp: _savePostOp,
                  onGoToOperations: () => _expandSection(0),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Patient Search Dialog
  void openPatientSearchDialog() {
    patient_search.openPatientSearchDialog(
      context: context,
      patients: _patients,
      selectedPatient: _selectedPatient,
      onPatientSelected: (pat) async {
        setState(() => _selectedPatient = pat);
        await _loadOperationsForPatient(pat.patientId);
      },
    );
  }
}

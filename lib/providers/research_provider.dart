import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/patient_record_brd.dart';
import '../services/backup/clinical_backup_service.dart';
import '../services/database/clinical_repository.dart';
import '../services/database/mock_data_service.dart';
import '../services/export/clinical_export_service.dart';
import '../services/import/clinical_import_service.dart';
import '../services/search_engine/research_search_engine.dart';
import '../theme/app_theme.dart';

class ResearchProvider extends ChangeNotifier {
  final ClinicalRepository _repository = ClinicalRepository();
  final Uuid _uuid = const Uuid();

  // Theme & Palette State
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppThemePalette _selectedPalette = AppThemePalette.medicalTeal;
  AppThemePalette get selectedPalette => _selectedPalette;
  PaletteConfig get currentPaletteConfig =>
      AppTheme.palettes[_selectedPalette] ??
      AppTheme.palettes[AppThemePalette.medicalTeal]!;

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', isDarkMode);
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', mode == ThemeMode.dark);
    } catch (_) {}
  }

  void setThemePalette(AppThemePalette palette) async {
    _selectedPalette = palette;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_palette', palette.name);
    } catch (_) {}
  }

  // Active Navigation
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // Clinical Query Tab Preference (0: Analytics Dashboard, 1: Cohort Search & Cases)
  int _clinicalQueryTabIndex = 0;
  int get clinicalQueryTabIndex => _clinicalQueryTabIndex;

  void setClinicalQueryTabIndex(int index) async {
    if (index < 0 || index > 1) return;
    _clinicalQueryTabIndex = index;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('clinical_query_last_tab_index', index);
    } catch (_) {}
  }

  // Export & Backup Paths Preferences
  String _customExportDirectory = '';
  String get customExportDirectory => _customExportDirectory;

  String _customBackupDirectory = '';
  String get customBackupDirectory => _customBackupDirectory;

  Future<void> setCustomExportDirectory(String path) async {
    _customExportDirectory = path.trim();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customExportDirectory.isEmpty) {
        await prefs.remove(ClinicalExportService.prefExportDirectoryKey);
      } else {
        await prefs.setString(
            ClinicalExportService.prefExportDirectoryKey, _customExportDirectory);
      }
    } catch (_) {}
  }

  Future<void> resetExportDirectory() async {
    await setCustomExportDirectory('');
  }

  Future<void> setCustomBackupDirectory(String path) async {
    _customBackupDirectory = path.trim();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customBackupDirectory.isEmpty) {
        await prefs.remove(ClinicalBackupService.prefBackupDirectoryKey);
      } else {
        await prefs.setString(
            ClinicalBackupService.prefBackupDirectoryKey, _customBackupDirectory);
      }
    } catch (_) {}
  }

  Future<void> resetBackupDirectory() async {
    await setCustomBackupDirectory('');
  }

  Future<BackupResult> createDatabaseBackup({String? customPath}) async {
    return await ClinicalBackupService.createDatabaseBackup(
      repository: _repository,
      customDirectoryPath: customPath ??
          (_customBackupDirectory.isNotEmpty ? _customBackupDirectory : null),
    );
  }

  // --- SQLite Separate CRUD Entities ---
  List<PatientModel> _patients = [];
  List<PatientModel> get patients => _patients;

  List<OperationModel> _operations = [];
  List<OperationModel> get operations => _operations;

  List<ProcedureCatalogModel> _procedureCatalog = [];
  List<ProcedureCatalogModel> get procedureCatalog => _procedureCatalog;

  List<PreOpModel> _preOps = [];
  List<PreOpModel> get preOps => _preOps;

  List<IntraOpModel> _intraOps = [];
  List<IntraOpModel> get intraOps => _intraOps;

  List<PostOpModel> _postOps = [];
  List<PostOpModel> get postOps => _postOps;

  List<ComplicationModel> _complications = [];
  List<ComplicationModel> get complications => _complications;

  List<BloodLabModel> _bloodLabs = [];
  List<BloodLabModel> get bloodLabs => _bloodLabs;

  List<SurveyModel> _surveys = [];
  List<SurveyModel> get surveys => _surveys;

  List<CompleteClinicalCase> _allClinicalCases = [];
  List<CompleteClinicalCase> get allClinicalCases => _allClinicalCases;

  CompleteClinicalCase? _selectedClinicalCase;
  CompleteClinicalCase? get selectedClinicalCase => _selectedClinicalCase;

  // Time Frame Engine State
  TimeFramePreset _timeFramePreset = TimeFramePreset.allTime;
  TimeFramePreset get timeFramePreset => _timeFramePreset;

  DateTimeRange? _customDateRange;
  DateTimeRange? get customDateRange => _customDateRange;

  PodFilter _podFilter = PodFilter.allPod;
  PodFilter get podFilter => _podFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoadingDatabase = true;
  bool get isLoadingDatabase => _isLoadingDatabase;

  // Mock Data Testing Suite State
  bool _isMockDataSeeded = false;
  bool get isMockDataSeeded => _isMockDataSeeded;

  int _seededMockCount = 0;
  int get seededMockCount => _seededMockCount;

  // Dynamic Templates & Abstracts
  List<ResearchTemplateModel> _templates = [];
  List<ResearchTemplateModel> get templates => _templates;

  List<ResearchAbstractModel> _abstracts = [];
  List<ResearchAbstractModel> get abstracts => _abstracts;

  ResearchProvider() {
    _initData();
  }

  Future<void> _initData() async {
    _isLoadingDatabase = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark_mode') ?? true;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      final paletteName = prefs.getString('selected_palette');
      if (paletteName != null) {
        _selectedPalette = AppThemePalette.values.firstWhere(
          (p) => p.name == paletteName,
          orElse: () => AppThemePalette.medicalTeal,
        );
      }

      final savedQueryTab = prefs.getInt('clinical_query_last_tab_index');
      if (savedQueryTab != null && savedQueryTab >= 0 && savedQueryTab <= 1) {
        _clinicalQueryTabIndex = savedQueryTab;
      }

      final savedExportPath = prefs.getString(ClinicalExportService.prefExportDirectoryKey);
      if (savedExportPath != null) {
        _customExportDirectory = savedExportPath;
      }

      final savedBackupPath = prefs.getString(ClinicalBackupService.prefBackupDirectoryKey);
      if (savedBackupPath != null) {
        _customBackupDirectory = savedBackupPath;
      }
    } catch (_) {}

    try {
      await reloadAllData();
    } catch (e) {
      debugPrint('Error loading SQLite data: $e');
    }

    _isLoadingDatabase = false;
    notifyListeners();
  }

  Future<void> reloadAllData() async {
    _patients = await _repository.getAllPatients();
    _operations = await _repository.getAllOperations();
    _preOps = await _repository.getAllPreOps();
    _intraOps = await _repository.getAllIntraOps();
    _postOps = await _repository.getAllPostOps();
    _complications = await _repository.getAllComplications();
    _bloodLabs = await _repository.getAllBloodLabs();
    _surveys = await _repository.getAllSurveys();
    _allClinicalCases = await _repository.getAllClinicalCases();
    if (_allClinicalCases.isNotEmpty && _selectedClinicalCase == null) {
      _selectedClinicalCase = _allClinicalCases.first;
    }
    _templates = await _repository.getAllTemplates();
    _abstracts = await _repository.getAllAbstracts();
    _procedureCatalog = await _repository.getProcedureCatalog();
    _complicationCatalog = await _repository.getComplicationCatalog();
    
    // Check mock data status quietly
    try {
      _isMockDataSeeded = await _repository.isMockDataSeeded();
      _seededMockCount = await _repository.getSeededMockCount();
    } catch (_) {}

    notifyListeners();
  }

  List<ComplicationCatalogModel> _complicationCatalog = [];
  List<ComplicationCatalogModel> get complicationCatalog => _complicationCatalog;

  Future<void> addProcedureToCatalog(
    String name, {
    String description = '',
    String pastMedicalHistory = '',
    String occupation = '',
  }) async {
    await _repository.addProcedureToCatalog(
      name,
      description: description,
      pastMedicalHistory: pastMedicalHistory,
      occupation: occupation,
    );
    _procedureCatalog = await _repository.getProcedureCatalog();
    notifyListeners();
  }

  Future<void> deleteProcedureFromCatalog(String id) async {
    await _repository.deleteProcedureFromCatalog(id);
    _procedureCatalog = await _repository.getProcedureCatalog();
    notifyListeners();
  }

  Future<void> addComplicationToCatalog(
    String name, {
    required String treatment,
    String grade =
        'Grade I (Minor complication, no specific treatment required)',
    String category = 'General',
  }) async {
    await _repository.addComplicationToCatalog(
      name,
      treatment: treatment,
      grade: grade,
      category: category,
    );
    _complicationCatalog = await _repository.getComplicationCatalog();
    notifyListeners();
  }

  Future<void> deleteComplicationFromCatalog(String id) async {
    await _repository.deleteComplicationFromCatalog(id);
    _complicationCatalog = await _repository.getComplicationCatalog();
    notifyListeners();
  }

  Future<void> clearDatabase() async {
    _isLoadingDatabase = true;
    notifyListeners();
    await _repository.clearAllData();
    _selectedClinicalCase = null;
    await reloadAllData();
    _isLoadingDatabase = false;
    notifyListeners();
  }

  Future<void> loadDemoData() async {
    _isLoadingDatabase = true;
    notifyListeners();
    await _repository.seedDemoData();
    await reloadAllData();
    _isLoadingDatabase = false;
    notifyListeners();
  }

  // ==========================================
  // MOCK RESEARCH DATASET ACTIONS
  // ==========================================
  Future<MockDataResult> seedMockData({bool force = false}) async {
    _isLoadingDatabase = true;
    notifyListeners();
    final result = await _repository.seedMockData(force: force);
    await reloadAllData();
    _isLoadingDatabase = false;
    notifyListeners();
    return result;
  }

  Future<int> clearMockData() async {
    _isLoadingDatabase = true;
    notifyListeners();
    final count = await _repository.clearMockData();
    await reloadAllData();
    _isLoadingDatabase = false;
    notifyListeners();
    return count;
  }

  // ==========================================
  // 1. PATIENTS CRUD ACTIONS
  // ==========================================
  Future<void> addPatient({
    required String mrn,
    required String name,
    required String dateOfBirth,
    required String gender,
    required String bloodGroup,
    required String phone,
    String? country,
    String? notes,
    int? age,
    String? bmi,
    String? asaScore,
  }) async {
    // Auto-calculate exact age directly from birth date
    int calculatedAge = age ?? 0;
    if (dateOfBirth.isNotEmpty) {
      final dob = DateTime.tryParse(dateOfBirth);
      if (dob != null) {
        final now = DateTime.now();
        calculatedAge = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          calculatedAge--;
        }
        if (calculatedAge < 0) calculatedAge = 0;
      }
    }

    final patient = PatientModel(
      patientId: _uuid.v4(),
      medicalRecordNumber: mrn,
      demographics: {
        'name': name,
        'date_of_birth': dateOfBirth,
        'age': calculatedAge,
        'gender': gender,
        'blood_group': bloodGroup,
        'phone': phone,
        'country': country ?? '',
        'notes': notes ?? '',
        'bmi': ?bmi,
        'asa_score': ?asaScore,
      },
      createdAt: DateTime.now(),
    );
    await _repository.insertPatient(patient);
    await reloadAllData();
  }

  Future<void> deletePatient(String patientId) async {
    await _repository.deletePatient(patientId);
    await reloadAllData();
  }

  // ==========================================
  // 2. OPERATIONS CRUD ACTIONS
  // ==========================================
  Future<void> addOperation({
    required String patientId,
    required String operationType,
    required String diagnosis,
    String? hospital,
    DateTime? operationDate,
  }) async {
    final op = OperationModel(
      operationId: _uuid.v4(),
      patientId: patientId,
      diagnosisDetails: diagnosis,
      operationType: operationType,
      hospital: hospital ?? '',
      createdAt: operationDate ?? DateTime.now(),
    );
    await _repository.insertOperation(op);
    await reloadAllData();
  }

  Future<void> deleteOperation(String operationId) async {
    await _repository.deleteOperation(operationId);
    await reloadAllData();
  }

  // ==========================================
  // 3. PRE-OP ASSESSMENTS CRUD ACTIONS
  // ==========================================
  Future<void> addPreOp({
    required String operationId,
    required String caseDescription,
    required String radiologyReports,
    List<String>? clinicalImages,
    List<String>? radiologyImages,
    List<String>? labFiles,
  }) async {
    final preOp = PreOpModel(
      preOpId: _uuid.v4(),
      operationId: operationId,
      caseDescription: caseDescription,
      clinicalImages: clinicalImages ?? ['assets/images/clinical_preop.png'],
      radiologyReports: radiologyReports,
      radiologyImages: radiologyImages ?? ['assets/images/radiology_scan.png'],
      labFiles: labFiles ?? ['assets/labs/baseline_lab.pdf'],
    );
    await _repository.insertPreOp(preOp);
    await reloadAllData();
  }

  Future<void> deletePreOp(String preOpId) async {
    await _repository.deletePreOp(preOpId);
    await reloadAllData();
  }

  // ==========================================
  // 4. INTRA-OP DETAILS CRUD ACTIONS
  // ==========================================
  Future<void> addIntraOp({
    required String operationId,
    required String description,
    List<String>? images,
  }) async {
    final intraOp = IntraOpModel(
      intraOpId: _uuid.v4(),
      operationId: operationId,
      operationDescription: description,
      intraOpImages: images ?? ['assets/images/intra_surgical.png'],
    );
    await _repository.insertIntraOp(intraOp);
    await reloadAllData();
  }

  Future<void> deleteIntraOp(String intraOpId) async {
    await _repository.deleteIntraOp(intraOpId);
    await reloadAllData();
  }

  // ==========================================
  // 5. POST-OP DETAILS CRUD ACTIONS
  // ==========================================
  Future<void> addPostOp({
    required String operationId,
    required String description,
    List<String>? images,
  }) async {
    final postOp = PostOpModel(
      postOpId: _uuid.v4(),
      operationId: operationId,
      postOpDescription: description,
      postOpImages: images ?? ['assets/images/post_recovery.png'],
    );
    await _repository.insertPostOp(postOp);
    await reloadAllData();
  }

  Future<void> deletePostOp(String postOpId) async {
    await _repository.deletePostOp(postOpId);
    await reloadAllData();
  }

  // ==========================================
  // 6. COMPLICATIONS CRUD ACTIONS
  // ==========================================
  Future<void> addComplicationToCase(
    String operationId,
    int podDay,
    String grade,
    String management, {
    String description = 'Clinical complication',
  }) async {
    final comp = ComplicationModel(
      complicationId: _uuid.v4(),
      operationId: operationId,
      description: description,
      podDay: podDay,
      grade: grade,
      management: management,
    );
    await _repository.addComplication(comp);
    await reloadAllData();
  }

  Future<void> deleteComplication(String complicationId) async {
    await _repository.deleteComplication(complicationId);
    await reloadAllData();
  }

  // ==========================================
  // 7. BLOOD & LABS CRUD ACTIONS
  // ==========================================
  Future<void> addBloodLabToCase(String operationId, String testName, String resultValue) async {
    final lab = BloodLabModel(
      labId: _uuid.v4(),
      operationId: operationId,
      testName: testName,
      resultValue: resultValue,
      testDate: DateTime.now(),
    );
    await _repository.addBloodLab(lab);
    await reloadAllData();
  }

  Future<void> deleteBloodLab(String labId) async {
    await _repository.deleteBloodLab(labId);
    await reloadAllData();
  }

  // ==========================================
  // 8. SURVEYS CRUD ACTIONS
  // ==========================================
  Future<void> addSurveyToCase(String operationId, String surveyType, Map<String, dynamic> questions) async {
    final survey = SurveyModel(
      surveyId: _uuid.v4(),
      operationId: operationId,
      surveyType: surveyType,
      evaluationQuestions: questions,
    );
    await _repository.addSurvey(survey);
    await reloadAllData();
  }

  Future<void> deleteSurvey(String surveyId) async {
    await _repository.deleteSurvey(surveyId);
    await reloadAllData();
  }

  // ==========================================
  // 9. DYNAMIC TEMPLATES & ABSTRACTS ACTIONS
  // ==========================================
  Future<void> createTemplate(String name, List<TemplateField> fields) async {
    final template = ResearchTemplateModel(
      templateId: _uuid.v4(),
      templateName: name,
      fields: fields,
    );
    await _repository.insertTemplate(template);
    await reloadAllData();
  }

  Future<void> deleteTemplate(String templateId) async {
    await _repository.deleteTemplate(templateId);
    await reloadAllData();
  }

  Future<ResearchAbstractModel> generateAbstractFromCases(List<CompleteClinicalCase> selectedCases, String title) async {
    final total = selectedCases.length;
    final compCases = selectedCases.where((c) => c.hasComplications).length;
    final compRate = total > 0 ? (compCases / total * 100).toStringAsFixed(1) : '0';
    final procedures = selectedCases.map((c) => c.operation.operationType).toSet().join(', ');

    final abstractText = '''### $title

**Objective & Scope:** To evaluate surgical precision, multi-phase clinical outcomes (pre-, intra-, post-operative), and complication kinetics across $total documented surgical cohorts.

**Procedures Investigated:** $procedures

**Methods:** Longitudinal clinical study with granular data captured via Medectal Research. Endpoints tracked included Pre-Op imaging, intra-operative operative notes, post-operative complications by Post-Op Day (POD), and serial blood/lab biomarkers.

**Results:** In this cohort of $total patients, complications were documented in $compRate% of cases. The most frequent complications were successfully managed without requiring emergency re-intervention. Digital lab monitoring verified hemodynamic stability across follow-ups.

**Conclusion:** Multi-phase clinical registry tracking provides high-yield analytical integrity for surgical audits, benchmark comparisons, and multicenter research synthesis.''';

    final abstractModel = ResearchAbstractModel(
      abstractId: _uuid.v4(),
      operationIds: selectedCases.map((c) => c.operation.operationId).toList(),
      abstractTitle: title,
      abstractText: abstractText,
      createdAt: DateTime.now(),
    );

    await _repository.insertAbstract(abstractModel);
    await reloadAllData();
    return abstractModel;
  }

  Future<void> deleteAbstract(String abstractId) async {
    await _repository.deleteAbstract(abstractId);
    await reloadAllData();
  }

  // --- Search & Time Frame Engine Methods ---
  void setTimeFramePreset(TimeFramePreset preset, {DateTimeRange? customRange}) {
    _timeFramePreset = preset;
    if (preset == TimeFramePreset.customRange) {
      _customDateRange = customRange;
    } else {
      _customDateRange = null;
    }
    notifyListeners();
  }

  void setPodFilter(PodFilter filter) {
    _podFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectClinicalCase(CompleteClinicalCase c) {
    _selectedClinicalCase = c;
    notifyListeners();
  }

  List<CompleteClinicalCase> get timeFrameFilteredCases {
    final timeFiltered = ResearchSearchEngine.filterByTimeFrame(
      _allClinicalCases,
      preset: _timeFramePreset,
      customRange: _customDateRange,
    );
    return ResearchSearchEngine.filterByPod(timeFiltered, _podFilter);
  }

  List<SearchMatchResult> get searchResults {
    return ResearchSearchEngine.searchAllFields(timeFrameFilteredCases, _searchQuery);
  }

  TimeFrameStats get activeStats {
    return ResearchSearchEngine.calculateStats(timeFrameFilteredCases);
  }

  // --- Complete Intake Form Helper ---
  Future<void> createClinicalCase({
    required String mrn,
    required Map<String, dynamic> demographics,
    required String diagnosis,
    required String operationType,
    required DateTime operationDate,
    String? hospital,
    String? bloodGroup,
    String? preOpDescription,
    List<String>? clinicalImages,
    String? radiologyReports,
    List<String>? radiologyImages,
    List<String>? labFiles,
    String? intraOpDescription,
    List<String>? intraOpImages,
    String? postOpDescription,
    List<String>? postOpImages,
    List<ComplicationModel>? complications,
    List<BloodLabModel>? bloodLabs,
    List<SurveyModel>? surveys,
  }) async {
    final patientId = _uuid.v4();
    final operationId = _uuid.v4();
    final now = DateTime.now();

    final patient = PatientModel(
      patientId: patientId,
      medicalRecordNumber: mrn,
      demographics: demographics,
      createdAt: now,
    );

    final operation = OperationModel(
      operationId: operationId,
      patientId: patientId,
      diagnosisDetails: diagnosis,
      operationType: operationType,
      hospital: hospital ?? '',
      createdAt: operationDate,
    );

    final preOp = PreOpModel(
      preOpId: _uuid.v4(),
      operationId: operationId,
      caseDescription: preOpDescription ?? '',
      clinicalImages: clinicalImages ?? [],
      radiologyReports: radiologyReports ?? '',
      radiologyImages: radiologyImages ?? [],
      labFiles: labFiles ?? [],
    );

    final intraOp = IntraOpModel(
      intraOpId: _uuid.v4(),
      operationId: operationId,
      operationDescription: intraOpDescription ?? '',
      intraOpImages: intraOpImages ?? [],
    );

    final postOp = PostOpModel(
      postOpId: _uuid.v4(),
      operationId: operationId,
      postOpDescription: postOpDescription ?? '',
      postOpImages: postOpImages ?? [],
    );

    final newCase = CompleteClinicalCase(
      patient: patient,
      operation: operation,
      preOp: preOp,
      intraOp: intraOp,
      postOp: postOp,
      complications: complications ?? [],
      bloodLabs: bloodLabs ?? [],
      surveys: surveys ?? [],
    );

    await _repository.insertCompleteCase(newCase);
    await reloadAllData();
  }

  Future<void> deleteCase(CompleteClinicalCase c) async {
    await _repository.deleteCase(c.operation.operationId, c.patient.patientId);
    await reloadAllData();
  }

  /// Imports external clinical data from Excel (.xlsx), CSV (.csv), or JSON backup files
  Future<ImportResult> importClinicalDataFromFile(
    File file, {
    bool skipDuplicateMrn = true,
  }) async {
    _isLoadingDatabase = true;
    notifyListeners();

    try {
      final result = await ClinicalImportService.importFromFile(
        file,
        repository: _repository,
        skipDuplicateMrn: skipDuplicateMrn,
      );
      await reloadAllData();
      return result;
    } finally {
      _isLoadingDatabase = false;
      notifyListeners();
    }
  }
}


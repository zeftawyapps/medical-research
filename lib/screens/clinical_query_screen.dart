import 'package:flutter/material.dart';
import '../models/patient_record_brd.dart';
import '../services/database/clinical_repository.dart';
import '../services/search_engine/research_search_engine.dart';
import '../services/search_engine/sql_query_builder.dart';
import 'clinical_case_management_screen.dart';
import 'clinical_query/dialogs/clinical_query_advanced_search_dialog.dart';
import 'clinical_query/dialogs/clinical_query_between_cases_dialog.dart';
import 'clinical_query/models/clinical_query_models.dart';
import 'clinical_query/tabs/analytics_dashboard_tab.dart';
import 'clinical_query/tabs/cohort_search_tab.dart';
import 'clinical_query/widgets/query_tab_bar.dart';

/// Clinical Query & Research Search Screen
/// Modular Architecture:
/// - Tab 1: Analytics & Research Dashboard ([AnalyticsDashboardTab])
/// - Tab 2: Cohort Search & Cases ([CohortSearchTab])
/// - Advanced Filter with BMI, Medical History LIKE, & Fat Volume ([ClinicalQueryAdvancedSearchDialog])
/// - Between Cases Operation Date Selector ([ClinicalQueryBetweenCasesDialog])
class ClinicalQueryScreen extends StatefulWidget {
  static final GlobalKey<ClinicalQueryScreenState> queryKey =
      GlobalKey<ClinicalQueryScreenState>();

  final List<CompleteClinicalCase>? initialCases;
  final ClinicalRepository? repository;

  const ClinicalQueryScreen({super.key, this.initialCases, this.repository});

  @override
  State<ClinicalQueryScreen> createState() => ClinicalQueryScreenState();
}

class ClinicalQueryScreenState extends State<ClinicalQueryScreen>
    with SingleTickerProviderStateMixin {
  late final ClinicalRepository _repository;
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<CompleteClinicalCase> _allCases = [];
  bool _isLoading = true;

  // Time Frame State (strictly filtering by Date of Operation)
  TimeFramePreset _selectedPreset = TimeFramePreset.allTime;
  DateTimeRange? _customDateRange;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  TimeOfDay? _customStartTime;
  TimeOfDay? _customEndTime;
  String? _betweenCasesLabel;

  // Search & Filter State
  PodFilter _selectedPodFilter = PodFilter.allPod;
  bool _complicationsOnly = false;
  String _searchQuery = '';

  // Advanced Filter Criteria (Procedure, Gender, Age, Complication Grade, Garment, BMI, History LIKE, Fat Volume)
  AdvancedFilterCriteria _advancedCriteria = const AdvancedFilterCriteria();

  bool get isAdvancedFilterActive => _advancedCriteria.isActive;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ClinicalRepository();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.initialCases != null) {
      _allCases = widget.initialCases!;
      _isLoading = false;
      // Trigger initial SQL analytics & search after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshAnalytics();
        _refreshSearch();
      });
    } else {
      _loadCases();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Data Loading ---

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    try {
      final cases = await _repository.getAllClinicalCases();
      if (mounted) {
        setState(() {
          _allCases = cases;
          _isLoading = false;
        });
        // Trigger SQL-powered analytics & search refresh
        _refreshAnalytics();
        _refreshSearch();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load clinical cases: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // --- Public Action APIs (Called from Top AppBar & GlobalKey) ---

  /// Public action called from top AppBar to refresh cases
  Future<void> refreshCases() async {
    await _loadCases();
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clinical cases refreshed successfully'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Public action called from top AppBar to open Advanced Search Dialog
  void openAdvancedSearchDialog() {
    ClinicalQueryAdvancedSearchDialog.show(
      context,
      currentCriteria: _advancedCriteria,
      allCases: _allCases,
      onApply: (criteria) {
        setState(() => _advancedCriteria = criteria);
        _refreshAnalytics();
        _refreshSearch();
      },
    );
  }

  /// Public method to programmatically set or update advanced filter criteria
  void applyAdvancedFilter(AdvancedFilterCriteria criteria) {
    setState(() {
      _advancedCriteria = criteria;
    });
    _refreshAnalytics();
    _refreshSearch();
  }

  /// Public action called from top AppBar for the 3rd upcoming feature
  void handleUpcomingAction() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.more_horiz_rounded, color: Colors.amber, size: 20),
            SizedBox(width: 10),
            Text('Action reserved for upcoming phase'),
          ],
        ),
        duration: Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Navigates first to Case Management screen and automatically opens the Add Patient dialog
  void _openAddPatientAndNavigate() {
    ClinicalCaseManagementScreen.navigateAndOpenAddPatientDialog(context);
  }

  // --- Between Cases & Custom Date Pickers ---

  void _showBetweenCasesDialog() {
    ClinicalQueryBetweenCasesDialog.show(
      context,
      allCases: _allCases,
      onApply: (startCase, endCase, minOp, maxOp) {
        setState(() {
          _customStartDate = minOp;
          _customEndDate = maxOp;
          _betweenCasesLabel =
              '${startCase.patient.name} (${startCase.patient.medicalRecordNumber}) ➔ ${endCase.patient.name} (${endCase.patient.medicalRecordNumber})';
          _selectedPreset = TimeFramePreset.customRange;
          _customDateRange = DateTimeRange(
            start: DateTime(minOp.year, minOp.month, minOp.day, 0, 0, 0),
            end: DateTime(maxOp.year, maxOp.month, maxOp.day, 23, 59, 59),
          );
        });
        _refreshAnalytics();
        _refreshSearch();
      },
    );
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _customDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      helpText: 'Filter strictly by Operation Date',
      saveText: 'Apply Op Date',
    );

    if (picked != null) {
      setState(() {
        _selectedPreset = TimeFramePreset.customRange;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _customDateRange = picked;
        _betweenCasesLabel = null;
      });
      _refreshAnalytics();
      _refreshSearch();
    }
  }

  Future<void> _pickStartDate() async {
    final current = _customStartDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Start Operation Date',
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked;
        final end = _customEndDate ?? picked.add(const Duration(days: 7));
        _customDateRange = DateTimeRange(
          start: picked.isAfter(end) ? end : picked,
          end: picked.isAfter(end) ? picked : end,
        );
        _selectedPreset = TimeFramePreset.customRange;
        _betweenCasesLabel = null;
      });
      _refreshAnalytics();
      _refreshSearch();
    }
  }

  Future<void> _pickEndDate() async {
    final current = _customEndDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select End Operation Date',
    );
    if (picked != null) {
      setState(() {
        _customEndDate = picked;
        final start =
            _customStartDate ?? picked.subtract(const Duration(days: 7));
        _customDateRange = DateTimeRange(
          start: start.isAfter(picked) ? picked : start,
          end: start.isAfter(picked) ? start : picked,
        );
        _selectedPreset = TimeFramePreset.customRange;
        _betweenCasesLabel = null;
      });
      _refreshAnalytics();
      _refreshSearch();
    }
  }

  Future<void> _pickSpecificTime(bool isStart) async {
    final initial = isStart
        ? (_customStartTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_customEndTime ?? const TimeOfDay(hour: 18, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart
          ? 'Select Start Surgery Time (HH:mm)'
          : 'Select End Surgery Time (HH:mm)',
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStartTime = picked;
        } else {
          _customEndTime = picked;
        }
        _selectedPreset = TimeFramePreset.customRange;
      });
      _refreshAnalytics();
      _refreshSearch();
    }
  }

  void _resetTimeFrameToAllTime() {
    setState(() {
      _selectedPreset = TimeFramePreset.allTime;
      _customDateRange = null;
      _customStartDate = null;
      _customEndDate = null;
      _customStartTime = null;
      _customEndTime = null;
      _betweenCasesLabel = null;
    });
    _refreshAnalytics();
    _refreshSearch();
  }

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedPodFilter = PodFilter.allPod;
      _complicationsOnly = false;
      _advancedCriteria = const AdvancedFilterCriteria();
      _resetTimeFrameToAllTime();
    });
    // Note: _resetTimeFrameToAllTime already triggers refreshes
  }

  // --- Filter Computations ---

  DateTimeRange? get _effectiveCustomDateRange {
    if (_selectedPreset != TimeFramePreset.customRange) return null;
    if (_customDateRange == null &&
        _customStartDate == null &&
        _customEndDate == null) {
      return null;
    }

    final s = _customStartDate ?? _customDateRange?.start ?? DateTime.now();
    final e = _customEndDate ?? _customDateRange?.end ?? DateTime.now();

    final sHour = _customStartTime?.hour ?? 0;
    final sMin = _customStartTime?.minute ?? 0;
    final eHour = _customEndTime?.hour ?? 23;
    final eMin = _customEndTime?.minute ?? 59;

    return DateTimeRange(
      start: DateTime(s.year, s.month, s.day, sHour, sMin, 0),
      end: DateTime(e.year, e.month, e.day, eHour, eMin, 59),
    );
  }

  /// Build SqlSearchCriteria from current UI filter state
  SqlSearchCriteria _buildSqlCriteria({bool includeSearchQuery = false}) {
    // Date range from TimeFrame preset
    DateTime? dateFrom;
    DateTime? dateTo;
    final now = DateTime.now();

    switch (_selectedPreset) {
      case TimeFramePreset.allTime:
        break;
      case TimeFramePreset.last7Days:
        final d = now.subtract(const Duration(days: 7));
        dateFrom = DateTime(d.year, d.month, d.day, 0, 0, 0);
        dateTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case TimeFramePreset.last30Days:
        final d = now.subtract(const Duration(days: 30));
        dateFrom = DateTime(d.year, d.month, d.day, 0, 0, 0);
        dateTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case TimeFramePreset.last90Days:
        final d = now.subtract(const Duration(days: 90));
        dateFrom = DateTime(d.year, d.month, d.day, 0, 0, 0);
        dateTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case TimeFramePreset.lastYear:
        final d = now.subtract(const Duration(days: 365));
        dateFrom = DateTime(d.year, d.month, d.day, 0, 0, 0);
        dateTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case TimeFramePreset.customRange:
        final range = _effectiveCustomDateRange;
        if (range != null) {
          dateFrom = range.start;
          dateTo = range.end;
        }
        break;
    }

    // POD filter mapping
    int? podDayMin;
    int? podDayMax;
    bool podActive = _selectedPodFilter != PodFilter.allPod;
    switch (_selectedPodFilter) {
      case PodFilter.allPod:
        break;
      case PodFilter.pod0To3:
        podDayMin = 0;
        podDayMax = 3;
        break;
      case PodFilter.pod4To7:
        podDayMin = 4;
        podDayMax = 7;
        break;
      case PodFilter.pod8To30:
        podDayMin = 8;
        podDayMax = 30;
        break;
      case PodFilter.pod30Plus:
        podDayMin = 31;
        break;
    }

    return SqlSearchCriteria(
      searchQuery: includeSearchQuery && _searchQuery.isNotEmpty ? _searchQuery : null,
      dateFrom: dateFrom,
      dateTo: dateTo,
      podDayMin: podDayMin,
      podDayMax: podDayMax,
      podFilterActive: podActive,
      complicationsOnly: _complicationsOnly ? true : null,
      procedure: _advancedCriteria.procedure,
      gender: _advancedCriteria.gender,
      ageMin: _advancedCriteria.ageRange?.start,
      ageMax: _advancedCriteria.ageRange?.end,
      complicationGrade: _advancedCriteria.complicationGrade,
      garmentRequired: _advancedCriteria.garmentRequired,
      bmiMin: _advancedCriteria.bmiRange?.start,
      bmiMax: _advancedCriteria.bmiRange?.end,
      medicalHistoryQuery: _advancedCriteria.medicalHistoryQuery,
      fatVolumeMin: _advancedCriteria.fatVolumeRange?.start,
      fatVolumeMax: _advancedCriteria.fatVolumeRange?.end,
      patientNameQuery: _advancedCriteria.patientNameQuery,
      operativeProcedureQuery: _advancedCriteria.operativeProcedureQuery,
      procedureTechniqueQuery: _advancedCriteria.procedureTechniqueQuery,
    );
  }

  // ==========================================
  // SQL-POWERED ANALYTICS (Dashboard KPIs)
  // ==========================================

  /// Cached stats for the current filter state (loaded asynchronously)
  TimeFrameStats _cachedStats = const TimeFrameStats(
    totalCases: 0,
    casesWithComplications: 0,
    complicationRate: 0.0,
    meanAge: 0.0,
    gradeDistribution: {},
    surgeryTypeDistribution: {},
  );

  /// Active TimeFrame statistics for Dashboard (SQL-powered)
  TimeFrameStats get _currentStats => _cachedStats;

  /// Trigger async SQL analytics refresh
  void _refreshAnalytics() {
    final criteria = _buildSqlCriteria();
    _repository.getAnalyticsStatsSql(criteria).then((stats) {
      if (mounted) {
        setState(() => _cachedStats = stats);
      }
    }).catchError((e) {
      debugPrint('SQL Analytics error, falling back to in-memory: $e');
      // Fallback to in-memory calculation
      final timeFiltered = ResearchSearchEngine.filterByTimeFrame(
        _allCases,
        preset: _selectedPreset,
        customRange: _effectiveCustomDateRange,
      );
      if (mounted) {
        setState(() => _cachedStats = ResearchSearchEngine.calculateStats(timeFiltered));
      }
    });
  }

  // ==========================================
  // SQL-POWERED COHORT SEARCH
  // ==========================================

  /// Cached search results for the current filter + search state
  List<SearchMatchResult> _cachedSearchResults = [];

  /// Filtered cases for Tab 2 (Search & Cohort list) — SQL-powered
  List<SearchMatchResult> get _cohortSearchResults => _cachedSearchResults;

  /// Trigger async SQL search refresh
  void _refreshSearch() {
    final criteria = _buildSqlCriteria(includeSearchQuery: true);
    _repository.searchCasesSql(criteria, _allCases).then((filteredCases) {
      if (mounted) {
        // Apply in-memory searchAllFields for field-level match highlighting
        final results = ResearchSearchEngine.searchAllFields(
          filteredCases,
          _searchQuery,
          patientNameQuery: _advancedCriteria.patientNameQuery,
          medicalHistoryQuery: _advancedCriteria.medicalHistoryQuery,
          operativeProcedureQuery: _advancedCriteria.operativeProcedureQuery,
          procedureTechniqueQuery: _advancedCriteria.procedureTechniqueQuery,
        );
        setState(() => _cachedSearchResults = results);
      }
    }).catchError((e) {
      debugPrint('SQL Search error, falling back to in-memory: $e');
      // Fallback: run the entire pipeline in-memory
      var cases = ResearchSearchEngine.filterByTimeFrame(
        _allCases, preset: _selectedPreset, customRange: _effectiveCustomDateRange,
      );
      cases = ResearchSearchEngine.filterByPod(cases, _selectedPodFilter);
      if (_complicationsOnly) {
        cases = cases.where((c) => c.hasComplications).toList();
      }
      if (mounted) {
        setState(() {
          _cachedSearchResults = ResearchSearchEngine.searchAllFields(
            cases,
            _searchQuery,
            patientNameQuery: _advancedCriteria.patientNameQuery,
            medicalHistoryQuery: _advancedCriteria.medicalHistoryQuery,
            operativeProcedureQuery: _advancedCriteria.operativeProcedureQuery,
            procedureTechniqueQuery: _advancedCriteria.procedureTechniqueQuery,
          );
        });
      }
    });
  }

  // --- Main Scaffold Build ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar Switcher
            QueryTabBar(controller: _tabController),

            // Main Tab Views
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Analytics & Research Dashboard
                        AnalyticsDashboardTab(
                          stats: _currentStats,
                          onRefresh: _loadCases,
                          selectedPreset: _selectedPreset,
                          customDateRange: _customDateRange,
                          customStartDate: _customStartDate,
                          customEndDate: _customEndDate,
                          customStartTime: _customStartTime,
                          customEndTime: _customEndTime,
                          betweenCasesLabel: _betweenCasesLabel,
                          onPresetSelected: (preset) {
                            setState(() {
                              _selectedPreset = preset;
                              if (preset != TimeFramePreset.customRange) {
                                _customDateRange = null;
                                _customStartDate = null;
                                _customEndDate = null;
                                _customStartTime = null;
                                _customEndTime = null;
                                _betweenCasesLabel = null;
                              }
                            });
                            _refreshAnalytics();
                            _refreshSearch();
                          },
                          onResetAllTime: _resetTimeFrameToAllTime,
                          onPickCustomDateRange: _pickCustomDateRange,
                          onPickStartDate: _pickStartDate,
                          onPickEndDate: _pickEndDate,
                          onPickSpecificTime: _pickSpecificTime,
                          onOpenBetweenCasesDialog: _showBetweenCasesDialog,
                        ),

                        // Tab 2: Cohort Search & Cases
                        CohortSearchTab(
                          results: _cohortSearchResults,
                          searchController: _searchController,
                          onSearchChanged: (val) {
                            setState(() => _searchQuery = val);
                            _refreshSearch();
                          },
                          selectedPodFilter: _selectedPodFilter,
                          onPodFilterSelected: (filter) {
                            setState(() => _selectedPodFilter = filter);
                            _refreshAnalytics();
                            _refreshSearch();
                          },
                          complicationsOnly: _complicationsOnly,
                          onComplicationsOnlyChanged: (val) {
                            setState(() => _complicationsOnly = val);
                            _refreshSearch();
                          },
                          selectedPreset: _selectedPreset,
                          effectiveCustomDateRange: _effectiveCustomDateRange,
                          onResetTimeFrame: _resetTimeFrameToAllTime,
                          advancedFilterCriteria: _advancedCriteria,
                          onClearAdvancedFilter: () {
                            setState(() {
                              _advancedCriteria =
                                  const AdvancedFilterCriteria();
                            });
                            _refreshAnalytics();
                            _refreshSearch();
                          },
                          onUpdateAdvancedFilter: (criteria) {
                            setState(() {
                              _advancedCriteria = criteria;
                            });
                            _refreshAnalytics();
                            _refreshSearch();
                          },
                          onResetAllFilters: _resetAllFilters,
                          onPickCustomDateRange: _pickCustomDateRange,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_register_patient_query',
        onPressed: _openAddPatientAndNavigate,
        elevation: theme.floatingActionButtonTheme.elevation ?? 4,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text(
          'Register Patient',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

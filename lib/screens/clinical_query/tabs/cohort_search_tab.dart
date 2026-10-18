import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/search_engine/research_search_engine.dart';
import '../../../widgets/clinical_case_card.dart';
import '../../../widgets/clinical_research_table_widget.dart';
import '../../clinical_case_management_screen.dart';
import '../models/clinical_query_models.dart';

enum CohortViewMode { cards, researchTable }

/// Tab 2: Cohort Search & Cases (Deep search, POD filters, Active chips, Research Table, Case Navigation)
class CohortSearchTab extends StatefulWidget {
  final List<SearchMatchResult> results;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  final PodFilter selectedPodFilter;
  final ValueChanged<PodFilter> onPodFilterSelected;

  final bool complicationsOnly;
  final ValueChanged<bool> onComplicationsOnlyChanged;

  final TimeFramePreset selectedPreset;
  final DateTimeRange? effectiveCustomDateRange;
  final VoidCallback onResetTimeFrame;

  final AdvancedFilterCriteria advancedFilterCriteria;
  final VoidCallback onClearAdvancedFilter;
  final ValueChanged<AdvancedFilterCriteria>? onUpdateAdvancedFilter;
  final VoidCallback onResetAllFilters;
  final VoidCallback onPickCustomDateRange;
  final VoidCallback? onExportExcel;
  final VoidCallback? onExportCsv;

  const CohortSearchTab({
    super.key,
    required this.results,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedPodFilter,
    required this.onPodFilterSelected,
    required this.complicationsOnly,
    required this.onComplicationsOnlyChanged,
    required this.selectedPreset,
    this.effectiveCustomDateRange,
    required this.onResetTimeFrame,
    required this.advancedFilterCriteria,
    required this.onClearAdvancedFilter,
    this.onUpdateAdvancedFilter,
    required this.onResetAllFilters,
    required this.onPickCustomDateRange,
    this.onExportExcel,
    this.onExportCsv,
  });

  @override
  State<CohortSearchTab> createState() => _CohortSearchTabState();
}

class _CohortSearchTabState extends State<CohortSearchTab> {
  CohortViewMode _viewMode = CohortViewMode.cards;
  final ExpansibleController _expansionController = ExpansibleController();
  bool _isSearchToolsExpanded = false;

  static const List<String> _quickProcedures = [
    'Lymphedema',
    'Liposuction',
    'Abdominoplasty',
    'Body Contouring',
    'Breast',
  ];

  @override
  void initState() {
    super.initState();
    // Keep collapsed if cases already exist so records are prominently visible.
    // Expand only if initial results are empty so user can set filters.
    _isSearchToolsExpanded = widget.results.isEmpty;
  }

  bool get _hasActiveFiltersOrSearch =>
      widget.searchController.text.trim().isNotEmpty ||
      widget.selectedPodFilter != PodFilter.allPod ||
      widget.complicationsOnly ||
      widget.selectedPreset != TimeFramePreset.allTime ||
      widget.advancedFilterCriteria.isActive;

  int get _activeFiltersCount {
    int count = 0;
    if (widget.searchController.text.trim().isNotEmpty) count++;
    if (widget.selectedPodFilter != PodFilter.allPod) count++;
    if (widget.complicationsOnly) count++;
    if (widget.selectedPreset != TimeFramePreset.allTime) count++;
    if (widget.advancedFilterCriteria.isActive) {
      count += widget.advancedFilterCriteria.activeFiltersCount;
    }
    return count;
  }

  String _buildActiveFiltersSummary() {
    final List<String> parts = [];
    if (widget.searchController.text.trim().isNotEmpty) {
      parts.add('"${widget.searchController.text.trim()}"');
    }
    final proc = widget.advancedFilterCriteria.operativeProcedureQuery;
    if (proc != null && proc.trim().isNotEmpty) {
      parts.add(proc.trim());
    }
    if (widget.selectedPodFilter != PodFilter.allPod) {
      final podMap = {
        PodFilter.pod0To3: 'POD 0-3',
        PodFilter.pod4To7: 'POD 4-7',
        PodFilter.pod8To30: 'POD 8-30',
        PodFilter.pod30Plus: 'POD >30',
      };
      final label = podMap[widget.selectedPodFilter];
      if (label != null) parts.add(label);
    }
    if (widget.complicationsOnly) {
      parts.add('Complications Only');
    }
    if (widget.selectedPreset != TimeFramePreset.allTime) {
      parts.add('Time Filter');
    }
    if (widget.advancedFilterCriteria.gender != null) {
      parts.add(widget.advancedFilterCriteria.gender!);
    }
    if (widget.advancedFilterCriteria.bmiRange != null) {
      parts.add('BMI Range');
    }
    return parts.join(' • ');
  }

  void _collapseSearchTools() {
    FocusScope.of(context).unfocus();
    if (_isSearchToolsExpanded) {
      _expansionController.collapse();
      setState(() => _isSearchToolsExpanded = false);
    }
  }




  Widget _buildExpandableSearchSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasActive = _hasActiveFiltersOrSearch;
    final activeCount = _activeFiltersCount;
    final summaryText = _buildActiveFiltersSummary();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasActive
              ? colorScheme.primary.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: hasActive ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          controller: _expansionController,
          initiallyExpanded: _isSearchToolsExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isSearchToolsExpanded = expanded);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (hasActive ? colorScheme.primary : colorScheme.surfaceContainerHighest)
                  .withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              hasActive ? Icons.filter_alt_rounded : Icons.search_rounded,
              color: hasActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text(
                '${widget.results.length} cases',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (widget.searchController.text.isNotEmpty) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '• "${widget.searchController.text}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ] else if (hasActive) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$activeCount filters',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            hasActive && summaryText.isNotEmpty
                ? summaryText
                : _isSearchToolsExpanded
                    ? 'Search by patient, surgery, labs, complications...'
                    : 'Tap to expand search tools & filters',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: hasActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasActive)
                IconButton(
                  tooltip: 'Reset All Filters',
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: colorScheme.error,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () {
                    widget.searchController.clear();
                    widget.onSearchChanged('');
                    widget.onResetAllFilters();
                  },
                ),
              // View Mode Switcher
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewModeButton(
                      context,
                      mode: CohortViewMode.cards,
                      icon: Icons.view_agenda_outlined,
                      tooltip: 'Cards View',
                    ),
                    _buildViewModeButton(
                      context,
                      mode: CohortViewMode.researchTable,
                      icon: Icons.table_chart_rounded,
                      tooltip: 'Research Table View',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isSearchToolsExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          children: [
            // Search Input Bar inside Expansion
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              child: TextField(
                controller: widget.searchController,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText:
                      'Search by Patient, MRN, Surgery (e.g. Lymphedema), Labs, Complications...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            widget.searchController.clear();
                            widget.onSearchChanged('');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        tooltip: 'Specific Search Dialog',
                        onPressed: () => _showAdvancedSearchPopup(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_circle_right_rounded, size: 22),
                        tooltip: 'Search & Collapse Tools',
                        color: colorScheme.primary,
                        onPressed: _collapseSearchTools,
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                      : colorScheme.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
                  ),
                ),
                onChanged: widget.onSearchChanged,
                onSubmitted: (_) => _collapseSearchTools(),
              ),
            ),

            // Quick Procedure Quick Buttons for Fast Conference Filtering
            _buildProcedureQuickBar(context),

            const SizedBox(height: 6),

            // Quick Filter Chips (POD Ranges, Complications Only, Op Date, Advanced)
            _buildSearchFilterChips(context),

            const SizedBox(height: 8),

            // Bottom Action Bar to Hide Tools and View Results with count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasActive)
                    InkWell(
                      onTap: () {
                        widget.searchController.clear();
                        widget.onSearchChanged('');
                        widget.onResetAllFilters();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_alt_off_rounded, size: 15, color: colorScheme.error),
                            const SizedBox(width: 4),
                            Text(
                              'Reset All Filters',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  FilledButton.tonalIcon(
                    onPressed: _collapseSearchTools,
                    icon: const Icon(Icons.unfold_less_rounded, size: 16),
                    label: Text(
                      'Hide Tools & Show Results (${widget.results.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Expandable Cohort Search & Filter Tools (with integrated Cases count & View Mode Switcher)
        _buildExpandableSearchSection(context),

        // Cases View (Cards or Research Table)
        Expanded(
          child: widget.results.isEmpty
              ? _buildEmptyResultsState(context)
              : _viewMode == CohortViewMode.researchTable
                  ? ClinicalResearchTableWidget(
                      results: widget.results,
                      isDark: isDark,
                      onCaseSelected: (clinicalCase) {
                        ClinicalCaseManagementScreen.navigateAndSelectPatient(
                          context,
                          clinicalCase.patient,
                          operationId: clinicalCase.operation.operationId,
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                      itemCount: widget.results.length,
                      itemBuilder: (context, index) {
                        final match = widget.results[index];
                        return ClinicalCaseCard(
                          clinicalCase: match.clinicalCase,
                          matchedFields: match.matchedFields,
                          onTap: () {
                            ClinicalCaseManagementScreen.navigateAndSelectPatient(
                              context,
                              match.clinicalCase.patient,
                              operationId: match.clinicalCase.operation.operationId,
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildViewModeButton(
    BuildContext context, {
    required CohortViewMode mode,
    required IconData icon,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildProcedureQuickBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeProc = widget.advancedFilterCriteria.operativeProcedureQuery ?? '';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Procedure:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          ..._quickProcedures.map((proc) {
            final isSelected = activeProc.toLowerCase() == proc.toLowerCase() ||
                (widget.searchController.text.trim().toLowerCase() == proc.toLowerCase());
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(proc),
                selected: isSelected,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
                selectedColor: colorScheme.primary,
                backgroundColor: theme.cardTheme.color ?? colorScheme.surface,
                onSelected: (selected) {
                  if (selected) {
                    if (widget.onUpdateAdvancedFilter != null) {
                      widget.onUpdateAdvancedFilter!(
                        widget.advancedFilterCriteria.copyWith(
                          operativeProcedureQuery: proc,
                        ),
                      );
                    } else {
                      widget.searchController.text = proc;
                      widget.onSearchChanged(proc);
                    }
                  } else {
                    if (widget.onUpdateAdvancedFilter != null) {
                      widget.onUpdateAdvancedFilter!(
                        widget.advancedFilterCriteria.copyWith(
                          clearOperativeProcedureQuery: true,
                        ),
                      );
                    } else {
                      widget.searchController.clear();
                      widget.onSearchChanged('');
                    }
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAdvancedSearchPopup(BuildContext context) {
    final nameCtrl = TextEditingController(text: widget.advancedFilterCriteria.patientNameQuery);
    final historyCtrl = TextEditingController(text: widget.advancedFilterCriteria.medicalHistoryQuery);
    final procCtrl = TextEditingController(text: widget.advancedFilterCriteria.operativeProcedureQuery);
    final techCtrl = TextEditingController(text: widget.advancedFilterCriteria.procedureTechniqueQuery);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Specific Search'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Patient Name / MRN', hintText: 'e.g. John Doe or MRN-123'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: historyCtrl,
                  decoration: const InputDecoration(labelText: 'Medical History', hintText: 'e.g. Diabetes'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: procCtrl,
                  decoration: const InputDecoration(labelText: 'Operative Procedure', hintText: 'e.g. Lymphedema, Vaser'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: techCtrl,
                  decoration: const InputDecoration(labelText: 'Procedure Technique', hintText: 'e.g. Tumescent'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.onUpdateAdvancedFilter != null) {
                  widget.onUpdateAdvancedFilter!(
                    widget.advancedFilterCriteria.copyWith(
                      patientNameQuery: nameCtrl.text,
                      medicalHistoryQuery: historyCtrl.text,
                      operativeProcedureQuery: procCtrl.text,
                      procedureTechniqueQuery: techCtrl.text,
                      clearPatientNameQuery: nameCtrl.text.isEmpty,
                      clearMedicalHistoryQuery: historyCtrl.text.isEmpty,
                      clearOperativeProcedureQuery: procCtrl.text.isEmpty,
                      clearProcedureTechniqueQuery: techCtrl.text.isEmpty,
                    ),
                  );
                }
                Navigator.pop(context);
                _collapseSearchTools();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchFilterChips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final podOptions = [
      {'label': 'All POD', 'filter': PodFilter.allPod},
      {'label': 'POD 0-3', 'filter': PodFilter.pod0To3},
      {'label': 'POD 4-7', 'filter': PodFilter.pod4To7},
      {'label': 'POD 8-30', 'filter': PodFilter.pod8To30},
      {'label': 'POD >30', 'filter': PodFilter.pod30Plus},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Operation Date active chip if filtered
          if (widget.selectedPreset != TimeFramePreset.allTime) ...[
            InputChip(
              avatar: Icon(
                Icons.event_available_rounded,
                size: 14,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                widget.selectedPreset == TimeFramePreset.customRange &&
                        widget.effectiveCustomDateRange != null
                    ? 'Op Date: ${DateFormat('MM/dd').format(widget.effectiveCustomDateRange!.start)} - ${DateFormat('MM/dd').format(widget.effectiveCustomDateRange!.end)}'
                    : 'Op Date: ${widget.selectedPreset == TimeFramePreset.last7Days ? '7D' : widget.selectedPreset == TimeFramePreset.last30Days ? '30D' : widget.selectedPreset == TimeFramePreset.last90Days ? '90D' : '1Y'}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
              ),
              selected: true,
              selectedColor: colorScheme.primary,
              onDeleted: widget.onResetTimeFrame,
              deleteIconColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Advanced Filter Active Chip (Overall count)
          if (widget.advancedFilterCriteria.isActive) ...[
            InputChip(
              avatar: Icon(
                Icons.tune_rounded,
                size: 14,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'Adv Filter (${widget.advancedFilterCriteria.activeFiltersCount})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
                softWrap: true,
              ),
              selected: true,
              selectedColor: colorScheme.primary,
              onDeleted: widget.onClearAdvancedFilter,
              deleteIconColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Specific BMI Range Chip
          if (widget.advancedFilterCriteria.bmiRange != null) ...[
            InputChip(
              avatar: Icon(
                Icons.monitor_weight_outlined,
                size: 14,
                color: colorScheme.onSecondary,
              ),
              label: Text(
                'BMI: ${widget.advancedFilterCriteria.bmiRange!.start.toStringAsFixed(1)} - ${widget.advancedFilterCriteria.bmiRange!.end.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSecondary,
                ),
                softWrap: true,
              ),
              selected: true,
              selectedColor: colorScheme.secondary,
              onDeleted: widget.onUpdateAdvancedFilter != null
                  ? () => widget.onUpdateAdvancedFilter!(
                        widget.advancedFilterCriteria.copyWith(clearBmiRange: true),
                      )
                  : widget.onClearAdvancedFilter,
              deleteIconColor: colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Specific Medical & Surgical History (LIKE) Chip
          if (widget.advancedFilterCriteria.medicalHistoryQuery != null &&
              widget.advancedFilterCriteria.medicalHistoryQuery!.trim().isNotEmpty) ...[
            InputChip(
              avatar: Icon(
                Icons.history_edu_rounded,
                size: 14,
                color: colorScheme.onSecondary,
              ),
              label: Text(
                'History: "${widget.advancedFilterCriteria.medicalHistoryQuery!.trim()}"',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSecondary,
                ),
                softWrap: true,
              ),
              selected: true,
              selectedColor: colorScheme.secondary,
              onDeleted: widget.onUpdateAdvancedFilter != null
                  ? () => widget.onUpdateAdvancedFilter!(
                        widget.advancedFilterCriteria.copyWith(
                          clearMedicalHistoryQuery: true,
                        ),
                      )
                  : widget.onClearAdvancedFilter,
              deleteIconColor: colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Specific Fat Volume Range Chip
          if (widget.advancedFilterCriteria.fatVolumeRange != null) ...[
            InputChip(
              avatar: Icon(
                Icons.opacity_rounded,
                size: 14,
                color: colorScheme.onSecondary,
              ),
              label: Text(
                'Fat: ${widget.advancedFilterCriteria.fatVolumeRange!.start.toStringAsFixed(1)} - ${widget.advancedFilterCriteria.fatVolumeRange!.end.toStringAsFixed(1)} L',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSecondary,
                ),
                softWrap: true,
              ),
              selected: true,
              selectedColor: colorScheme.secondary,
              onDeleted: widget.onUpdateAdvancedFilter != null
                  ? () => widget.onUpdateAdvancedFilter!(
                        widget.advancedFilterCriteria.copyWith(
                          clearFatVolumeRange: true,
                        ),
                      )
                  : widget.onClearAdvancedFilter,
              deleteIconColor: colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Complications Only Toggle Chip
          FilterChip(
            avatar: Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: widget.complicationsOnly
                  ? colorScheme.onError
                  : colorScheme.error,
            ),
            label: const Text('Complications Only'),
            selected: widget.complicationsOnly,
            onSelected: widget.onComplicationsOnlyChanged,
            selectedColor: colorScheme.error,
            backgroundColor: theme.cardTheme.color ?? colorScheme.surface,
            labelStyle: TextStyle(
              fontSize: 11.5,
              fontWeight: widget.complicationsOnly ? FontWeight.w700 : FontWeight.w500,
              color: widget.complicationsOnly
                  ? colorScheme.onError
                  : colorScheme.onSurface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: widget.complicationsOnly
                    ? colorScheme.error
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Op Date Custom Range Trigger Chip
          ActionChip(
            avatar: Icon(
              Icons.date_range_rounded,
              size: 14,
              color: colorScheme.onSurface,
            ),
            label: const Text('Op Date (Between)'),
            onPressed: widget.onPickCustomDateRange,
            backgroundColor: theme.cardTheme.color ?? colorScheme.surface,
            labelStyle: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // POD Options
          ...podOptions.map((opt) {
            final filter = opt['filter'] as PodFilter;
            final isSelected = widget.selectedPodFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: ChoiceChip(
                label: Text(opt['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    widget.onPodFilterSelected(filter);
                  }
                },
                selectedColor: colorScheme.primary,
                backgroundColor: theme.cardTheme.color ?? colorScheme.surface,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyResultsState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.saved_search_rounded,
              size: 56,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No Clinical Cases Found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No records match your active search terms or filters. Try resetting filters or register a new patient.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset All Filters'),
              onPressed: widget.onResetAllFilters,
            ),
          ],
        ),
      ),
    );
  }
}

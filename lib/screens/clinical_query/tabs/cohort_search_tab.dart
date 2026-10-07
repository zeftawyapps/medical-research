import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/search_engine/research_search_engine.dart';
import '../../../widgets/clinical_case_card.dart';
import '../../clinical_case_management_screen.dart';
import '../models/clinical_query_models.dart';

/// Tab 2: Cohort Search & Cases (Deep search, POD filters, Active chips, Case Navigation)
class CohortSearchTab extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Search Input Bar & Clear Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: searchController,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 13.5),
            decoration: InputDecoration(
              hintText:
                  'Search by Patient, MRN, Surgery, Notes, Labs, Complications...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.primary,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                    onPressed: () => _showAdvancedSearchPopup(context),
                  ),
                ],
              ),
              filled: true,
              fillColor: theme.cardTheme.color ?? colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),

        // Quick Filter Chips (POD Ranges, Complications Only, Op Date, Advanced)
        _buildSearchFilterChips(context),

        // Results Summary & Reset Action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${results.length} cases found',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (searchController.text.isNotEmpty ||
                  selectedPodFilter != PodFilter.allPod ||
                  complicationsOnly ||
                  selectedPreset != TimeFramePreset.allTime ||
                  advancedFilterCriteria.isActive)
                InkWell(
                  onTap: onResetAllFilters,
                  child: Text(
                    'Reset Filters',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Cases List View
        Expanded(
          child: results.isEmpty
              ? _buildEmptyResultsState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final match = results[index];
                    return ClinicalCaseCard(
                      clinicalCase: match.clinicalCase,
                      matchedFields: match.matchedFields,
                      onTap: () {
                        // Transitions directly to Case Management with this patient & operation selected
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

  void _showAdvancedSearchPopup(BuildContext context) {
    final nameCtrl = TextEditingController(text: advancedFilterCriteria.patientNameQuery);
    final historyCtrl = TextEditingController(text: advancedFilterCriteria.medicalHistoryQuery);
    final procCtrl = TextEditingController(text: advancedFilterCriteria.operativeProcedureQuery);
    final techCtrl = TextEditingController(text: advancedFilterCriteria.procedureTechniqueQuery);

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
                  decoration: const InputDecoration(labelText: 'Operative Procedure', hintText: 'e.g. Vaser'),
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
                if (onUpdateAdvancedFilter != null) {
                  onUpdateAdvancedFilter!(
                    advancedFilterCriteria.copyWith(
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
          if (selectedPreset != TimeFramePreset.allTime) ...[
            InputChip(
              avatar: Icon(
                Icons.event_available_rounded,
                size: 14,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                selectedPreset == TimeFramePreset.customRange &&
                        effectiveCustomDateRange != null
                    ? 'Op Date: ${DateFormat('MM/dd').format(effectiveCustomDateRange!.start)} - ${DateFormat('MM/dd').format(effectiveCustomDateRange!.end)}'
                    : 'Op Date: ${selectedPreset == TimeFramePreset.last7Days ? '7D' : selectedPreset == TimeFramePreset.last30Days ? '30D' : selectedPreset == TimeFramePreset.last90Days ? '90D' : '1Y'}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
              ),
              selected: true,
              selectedColor: colorScheme.primary,
              onDeleted: onResetTimeFrame,
              deleteIconColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Advanced Filter Active Chip (Overall count)
          if (advancedFilterCriteria.isActive) ...[
            InputChip(
              avatar: Icon(
                Icons.tune_rounded,
                size: 14,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'Adv Filter (${advancedFilterCriteria.activeFiltersCount})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
                softWrap: true,
              ),
              selected: true,
              selectedColor: colorScheme.primary,
              onDeleted: onClearAdvancedFilter,
              deleteIconColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Specific BMI Range Chip
          if (advancedFilterCriteria.bmiRange != null) ...[
            InputChip(
              avatar: Icon(
                Icons.monitor_weight_outlined,
                size: 14,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'BMI: ${advancedFilterCriteria.bmiRange!.start.toStringAsFixed(1)} - ${advancedFilterCriteria.bmiRange!.end.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
                softWrap: true,
              ),
              selected: true,
              selectedColor: colorScheme.secondary,
              onDeleted: onUpdateAdvancedFilter != null
                  ? () => onUpdateAdvancedFilter!(
                        advancedFilterCriteria.copyWith(clearBmiRange: true),
                      )
                  : onClearAdvancedFilter,
              deleteIconColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Specific Medical & Surgical History (LIKE) Chip
          if (advancedFilterCriteria.medicalHistoryQuery != null &&
              advancedFilterCriteria.medicalHistoryQuery!.trim().isNotEmpty) ...[
            InputChip(
              avatar: Icon(
                Icons.history_edu_rounded,
                size: 14,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'History: "${advancedFilterCriteria.medicalHistoryQuery!.trim()}"',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
                softWrap: true,
              ),
              selected: true,
              selectedColor: colorScheme.secondary,
              onDeleted: onUpdateAdvancedFilter != null
                  ? () => onUpdateAdvancedFilter!(
                        advancedFilterCriteria.copyWith(
                          clearMedicalHistoryQuery: true,
                        ),
                      )
                  : onClearAdvancedFilter,
              deleteIconColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Specific Fat Volume Range Chip
          if (advancedFilterCriteria.fatVolumeRange != null) ...[
            InputChip(
              avatar: Icon(
                Icons.opacity_rounded,
                size: 14,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'Fat: ${advancedFilterCriteria.fatVolumeRange!.start.toStringAsFixed(1)} - ${advancedFilterCriteria.fatVolumeRange!.end.toStringAsFixed(1)} L',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
                softWrap: true,
              ),
              selected: true,
              selectedColor: colorScheme.secondary,
              onDeleted: onUpdateAdvancedFilter != null
                  ? () => onUpdateAdvancedFilter!(
                        advancedFilterCriteria.copyWith(
                          clearFatVolumeRange: true,
                        ),
                      )
                  : onClearAdvancedFilter,
              deleteIconColor: colorScheme.onPrimary,
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
              color: complicationsOnly
                  ? colorScheme.onError
                  : colorScheme.error,
            ),
            label: const Text('Complications Only'),
            selected: complicationsOnly,
            onSelected: onComplicationsOnlyChanged,
            selectedColor: colorScheme.error,
            backgroundColor: theme.cardTheme.color ?? colorScheme.surface,
            labelStyle: TextStyle(
              fontSize: 11.5,
              fontWeight: complicationsOnly ? FontWeight.w700 : FontWeight.w500,
              color: complicationsOnly
                  ? colorScheme.onError
                  : colorScheme.onSurface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: complicationsOnly
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
            onPressed: onPickCustomDateRange,
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
            final isSelected = selectedPodFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: ChoiceChip(
                label: Text(opt['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onPodFilterSelected(filter);
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
              onPressed: onResetAllFilters,
            ),
          ],
        ),
      ),
    );
  }
}

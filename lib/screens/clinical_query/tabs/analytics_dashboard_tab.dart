import 'package:flutter/material.dart';
import '../../../services/search_engine/research_search_engine.dart';
import '../widgets/complications_breakdown_card.dart';
import '../widgets/kpi_grid_widget.dart';
import '../widgets/procedures_breakdown_card.dart';
import '../widgets/time_frame_selector_widget.dart';

/// Tab 1: Analytics & Research Dashboard (KPIs, Procedure distributions, Complications)
class AnalyticsDashboardTab extends StatelessWidget {
  final TimeFrameStats stats;
  final Future<void> Function() onRefresh;

  // Time Frame state & callbacks
  final TimeFramePreset selectedPreset;
  final DateTimeRange? customDateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final TimeOfDay? customStartTime;
  final TimeOfDay? customEndTime;
  final String? betweenCasesLabel;

  final ValueChanged<TimeFramePreset> onPresetSelected;
  final VoidCallback onResetAllTime;
  final VoidCallback onPickCustomDateRange;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final void Function(bool isStart) onPickSpecificTime;
  final VoidCallback onOpenBetweenCasesDialog;

  const AnalyticsDashboardTab({
    super.key,
    required this.stats,
    required this.onRefresh,
    required this.selectedPreset,
    this.customDateRange,
    this.customStartDate,
    this.customEndDate,
    this.customStartTime,
    this.customEndTime,
    this.betweenCasesLabel,
    required this.onPresetSelected,
    required this.onResetAllTime,
    required this.onPickCustomDateRange,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onPickSpecificTime,
    required this.onOpenBetweenCasesDialog,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
        children: [
          // Time Frame Presets & Operation Date Pickers
          TimeFrameSelectorWidget(
            selectedPreset: selectedPreset,
            customDateRange: customDateRange,
            customStartDate: customStartDate,
            customEndDate: customEndDate,
            customStartTime: customStartTime,
            customEndTime: customEndTime,
            betweenCasesLabel: betweenCasesLabel,
            onPresetSelected: onPresetSelected,
            onResetAllTime: onResetAllTime,
            onPickCustomDateRange: onPickCustomDateRange,
            onPickStartDate: onPickStartDate,
            onPickEndDate: onPickEndDate,
            onPickSpecificTime: onPickSpecificTime,
            onOpenBetweenCasesDialog: onOpenBetweenCasesDialog,
          ),
          const SizedBox(height: 16),

          // Key Performance Indicators (KPIs)
          KpiGridWidget(stats: stats),
          const SizedBox(height: 20),

          // Surgical Procedures Distribution Card
          ProceduresBreakdownCard(stats: stats),
          const SizedBox(height: 18),

          // Clavien-Dindo Complications Breakdown Card
          ComplicationsBreakdownCard(stats: stats),
        ],
      ),
    );
  }
}

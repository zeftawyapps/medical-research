import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/research_provider.dart';
import '../services/search_engine/research_search_engine.dart';
import '../theme/app_theme.dart';

class TimeFrameFilterBar extends StatelessWidget {
  final bool showPodFilter;

  const TimeFrameFilterBar({
    super.key,
    this.showPodFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Frame Presets Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 16, color: AppTheme.primaryCyan),
                    const SizedBox(width: 6),
                    Text(
                      'Time Frame: ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                _buildPresetChip(context, provider, 'All Time', TimeFramePreset.allTime, isDark),
                _buildPresetChip(context, provider, 'Last 7 Days', TimeFramePreset.last7Days, isDark),
                _buildPresetChip(context, provider, 'Last 30 Days', TimeFramePreset.last30Days, isDark),
                _buildPresetChip(context, provider, 'Last 90 Days', TimeFramePreset.last90Days, isDark),
                _buildPresetChip(context, provider, 'Last 1 Year', TimeFramePreset.lastYear, isDark),
                _buildCustomDateChip(context, provider, isDark),
              ],
            ),
          ),

          if (showPodFilter) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // POD Filter Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timelapse_rounded, size: 16, color: AppTheme.alertAmber),
                      const SizedBox(width: 6),
                      Text(
                        'Post-Op Day (POD): ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  _buildPodChip(context, provider, 'All PODs', PodFilter.allPod, isDark),
                  _buildPodChip(context, provider, 'POD 0 - 3 (Acute)', PodFilter.pod0To3, isDark),
                  _buildPodChip(context, provider, 'POD 4 - 7 (Early)', PodFilter.pod4To7, isDark),
                  _buildPodChip(context, provider, 'POD 8 - 30 (Subacute)', PodFilter.pod8To30, isDark),
                  _buildPodChip(context, provider, 'POD > 30 (Late)', PodFilter.pod30Plus, isDark),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    BuildContext context,
    ResearchProvider provider,
    String label,
    TimeFramePreset preset,
    bool isDark,
  ) {
    final isSelected = provider.timeFramePreset == preset;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setTimeFramePreset(preset),
        selectedColor: AppTheme.primaryCyan.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? AppTheme.primaryCyan
              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryCyan
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip(BuildContext context, ResearchProvider provider, bool isDark) {
    final isSelected = provider.timeFramePreset == TimeFramePreset.customRange;
    final rangeText = provider.customDateRange != null
        ? '${DateFormat('MM/dd').format(provider.customDateRange!.start)} - ${DateFormat('MM/dd').format(provider.customDateRange!.end)}'
        : 'Custom Range...';

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        avatar: Icon(
          Icons.calendar_month_outlined,
          size: 14,
          color: isSelected ? AppTheme.accentIndigo : null,
        ),
        label: Text(rangeText),
        onPressed: () async {
          final initialRange = provider.customDateRange ??
              DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 60)),
                end: DateTime.now(),
              );

          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            initialDateRange: initialRange,
          );

          if (picked != null) {
            provider.setTimeFramePreset(TimeFramePreset.customRange, customRange: picked);
          }
        },
        backgroundColor: isSelected
            ? AppTheme.accentIndigo.withValues(alpha: 0.2)
            : (isDark ? AppTheme.darkSurface : AppTheme.lightBackground),
        labelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? AppTheme.accentIndigo
              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? AppTheme.accentIndigo
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildPodChip(
    BuildContext context,
    ResearchProvider provider,
    String label,
    PodFilter filter,
    bool isDark,
  ) {
    final isSelected = provider.podFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setPodFilter(filter),
        selectedColor: AppTheme.alertAmber.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? AppTheme.alertAmber
              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? AppTheme.alertAmber
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
      ),
    );
  }
}

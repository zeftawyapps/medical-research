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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBg = theme.cardTheme.color ?? colorScheme.surface;
    final borderColor = theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.25);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
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
                    Icon(Icons.date_range_rounded, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Time Frame: ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                _buildPresetChip(context, provider, 'All Time', TimeFramePreset.allTime),
                _buildPresetChip(context, provider, 'Last 7 Days', TimeFramePreset.last7Days),
                _buildPresetChip(context, provider, 'Last 30 Days', TimeFramePreset.last30Days),
                _buildPresetChip(context, provider, 'Last 90 Days', TimeFramePreset.last90Days),
                _buildPresetChip(context, provider, 'Last 1 Year', TimeFramePreset.lastYear),
                _buildCustomDateChip(context, provider),
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
                      Icon(
                        Icons.timelapse_rounded,
                        size: 16,
                        color: isDark ? AppTheme.alertAmber : AppTheme.alertAmberDarkText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Post-Op Day (POD): ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  _buildPodChip(context, provider, 'All PODs', PodFilter.allPod),
                  _buildPodChip(context, provider, 'POD 0 - 3 (Acute)', PodFilter.pod0To3),
                  _buildPodChip(context, provider, 'POD 4 - 7 (Early)', PodFilter.pod4To7),
                  _buildPodChip(context, provider, 'POD 8 - 30 (Subacute)', PodFilter.pod8To30),
                  _buildPodChip(context, provider, 'POD > 30 (Late)', PodFilter.pod30Plus),
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
  ) {
    final isSelected = provider.timeFramePreset == preset;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textSecondary = colorScheme.onSurface.withValues(alpha: 0.65);
    final unselectedBg = theme.scaffoldBackgroundColor;
    final borderColor = theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.25);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setTimeFramePreset(preset),
        selectedColor: colorScheme.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? colorScheme.primary : textSecondary,
        ),
        backgroundColor: unselectedBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : borderColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip(BuildContext context, ResearchProvider provider) {
    final isSelected = provider.timeFramePreset == TimeFramePreset.customRange;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textSecondary = colorScheme.onSurface.withValues(alpha: 0.65);
    final unselectedBg = theme.scaffoldBackgroundColor;
    final borderColor = theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.25);
    final accent = colorScheme.secondary;

    final rangeText = provider.customDateRange != null
        ? '${DateFormat('MM/dd').format(provider.customDateRange!.start)} - ${DateFormat('MM/dd').format(provider.customDateRange!.end)}'
        : 'Custom Range...';

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        avatar: Icon(
          Icons.calendar_month_outlined,
          size: 14,
          color: isSelected ? accent : null,
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
            ? accent.withValues(alpha: 0.2)
            : unselectedBg,
        labelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? accent : textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? accent : borderColor,
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
  ) {
    final isSelected = provider.podFilter == filter;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final textSecondary = colorScheme.onSurfaceVariant;
    final unselectedBg = theme.scaffoldBackgroundColor;
    final borderColor = theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.25);
    final podActiveColor = isDark ? AppTheme.alertAmber : AppTheme.alertAmberDarkText;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setPodFilter(filter),
        selectedColor: (isDark ? AppTheme.alertAmber : const Color(0xFFD97706)).withValues(alpha: isDark ? 0.22 : 0.14),
        labelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? podActiveColor : textSecondary,
        ),
        backgroundColor: unselectedBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? podActiveColor : borderColor,
          ),
        ),
      ),
    );
  }
}

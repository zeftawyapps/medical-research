import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/search_engine/research_search_engine.dart';

/// Time Frame Selector Widget supporting:
/// - Operation Date Time Frame presets (All Time, 7D, 30D, 90D, 1Y)
/// - Custom Date Range picker
/// - Specific Time of Day (HH:mm) pickers
/// - Between Cases boundary selector
class TimeFrameSelectorWidget extends StatelessWidget {
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

  const TimeFrameSelectorWidget({
    super.key,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final f = DateFormat('yyyy-MM-dd');

    final presets = [
      {'label': 'All Time', 'preset': TimeFramePreset.allTime},
      {'label': 'Last 7 Days', 'preset': TimeFramePreset.last7Days},
      {'label': 'Last 30 Days', 'preset': TimeFramePreset.last30Days},
      {'label': 'Last 90 Days', 'preset': TimeFramePreset.last90Days},
      {'label': 'Last 1 Year', 'preset': TimeFramePreset.lastYear},
    ];

    final isCustom = selectedPreset == TimeFramePreset.customRange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Indicator Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    Text(
                      'Operation Date Time Frame',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                      softWrap: true,
                    ),
                    Text(
                      '• Surgery date filter only',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              if (isCustom)
                InkWell(
                  onTap: onResetAllTime,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      'Reset to All Time',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Presets & Picker Buttons Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ...presets.map((item) {
                  final preset = item['preset'] as TimeFramePreset;
                  final isSelected = selectedPreset == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(item['label'] as String),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          onPresetSelected(preset);
                        }
                      },
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                      ),
                    ),
                  );
                }),

                // Custom Date Range Picker Chip
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      Icons.date_range_rounded,
                      size: 15,
                      color: isCustom && betweenCasesLabel == null
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                    ),
                    label: Text(
                      isCustom &&
                              customDateRange != null &&
                              betweenCasesLabel == null
                          ? '${f.format(customDateRange!.start)} ➔ ${f.format(customDateRange!.end)}'
                          : 'Custom Date Range',
                    ),
                    selected: isCustom && betweenCasesLabel == null,
                    onSelected: (_) => onPickCustomDateRange(),
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isCustom && betweenCasesLabel == null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isCustom && betweenCasesLabel == null
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isCustom && betweenCasesLabel == null
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),

                // Between Cases Chip
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    Icons.compare_arrows_rounded,
                    size: 15,
                    color: isCustom && betweenCasesLabel != null
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                  label: const Text('Between Cases'),
                  selected: isCustom && betweenCasesLabel != null,
                  onSelected: (_) => onOpenBetweenCasesDialog(),
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isCustom && betweenCasesLabel != null
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isCustom && betweenCasesLabel != null
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isCustom && betweenCasesLabel != null
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom Date & Time Picker Controls (Visible when custom range or between cases is active)
          if (isCustom && customDateRange != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (betweenCasesLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Between Cases: $betweenCasesLabel',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // From Op Date Picker Button
                      InkWell(
                        onTap: onPickStartDate,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color ?? colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'From: ${f.format(customDateRange!.start)}',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (customStartTime != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  customStartTime!.format(context),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),

                      // To Op Date Picker Button
                      InkWell(
                        onTap: onPickEndDate,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color ?? colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 12,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'To: ${f.format(customDateRange!.end)}',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (customEndTime != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  customEndTime!.format(context),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Time of Day Picker Button (HH:mm)
                      InkWell(
                        onTap: () => onPickSpecificTime(true),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color ?? colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customStartTime != null || customEndTime != null
                                    ? 'Edit Time'
                                    : 'Set Time (HH:mm)',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pick Cases Shortcut Button
                      InkWell(
                        onTap: onOpenBetweenCasesDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.compare_arrows_rounded,
                                size: 12,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pick Cases',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

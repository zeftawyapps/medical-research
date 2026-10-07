import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/search_engine/research_search_engine.dart';

/// Clavien-Dindo Complications Breakdown Card with full text wrapping and progress indicators
class ComplicationsBreakdownCard extends StatelessWidget {
  final TimeFrameStats stats;

  const ComplicationsBreakdownCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sortedGrades = stats.gradeDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.healing_rounded,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Clavien-Dindo Complications',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${stats.casesWithComplications} Affected (${stats.complicationRate.toStringAsFixed(1)}%)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: stats.casesWithComplications > 0
                      ? colorScheme.error
                      : colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sortedGrades.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Zero complications recorded in this selected time range!',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            )
          else
            ...sortedGrades.map((gradeEntry) {
              final count = gradeEntry.value;
              final percent = stats.totalCases > 0
                  ? (count / stats.totalCases)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            gradeEntry.key.isEmpty
                                ? 'Unspecified Complication'
                                : gradeEntry.key,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$count cases (${(percent * 100).toStringAsFixed(0)}%)',
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        color: colorScheme.error,
                        backgroundColor: colorScheme.error.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

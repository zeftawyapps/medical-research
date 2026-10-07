import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/search_engine/research_search_engine.dart';

/// Key Performance Indicators (KPI) Grid for Clinical Analytics Dashboard
class KpiGridWidget extends StatelessWidget {
  final TimeFrameStats stats;

  const KpiGridWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        // Responsive column distribution
        int crossAxisCount = 4;
        if (screenWidth < 600) {
          crossAxisCount = 2;
        } else if (screenWidth < 900) {
          crossAxisCount = 4;
        }

        final cardWidth =
            (screenWidth - (12 * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                context,
                title: 'Total Cases',
                value: '${stats.totalCases}',
                subtitle: 'Cohort volume',
                icon: Icons.people_alt_rounded,
                iconColor: colorScheme.primary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                context,
                title: 'Complication Rate',
                value: '${stats.complicationRate.toStringAsFixed(1)}%',
                subtitle:
                    '${stats.casesWithComplications} of ${stats.totalCases} cases',
                icon: Icons.warning_amber_rounded,
                iconColor: stats.casesWithComplications > 0
                    ? colorScheme.error
                    : colorScheme.secondary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                context,
                title: 'Mean Patient Age',
                value: stats.totalCases > 0
                    ? '${stats.meanAge.toStringAsFixed(1)} yrs'
                    : 'N/A',
                subtitle: 'Cohort average',
                icon: Icons.cake_rounded,
                iconColor: colorScheme.tertiary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                context,
                title: 'Garment Adherence',
                value: stats.totalCases > 0
                    ? '${stats.garmentUsageRate.toStringAsFixed(1)}%'
                    : 'N/A',
                subtitle: '${stats.garmentUsageCount} cases required',
                icon: Icons.check_circle_outline_rounded,
                iconColor: colorScheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              height: 1.2,
            ),
            softWrap: true,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

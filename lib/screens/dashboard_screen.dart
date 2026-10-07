import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/research_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import '../widgets/clinical_case_card.dart';
import '../widgets/common_widgets.dart';
import '../widgets/time_frame_filter_bar.dart';
import 'case_intake_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    final stats = provider.activeStats;
    final cases = provider.timeFrameFilteredCases;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.horizontalPadding(context),
        vertical: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Hero Banner
          _buildHeroBanner(context, provider, isDark, isMobile),
          const SizedBox(height: 18),

          // Time Frame Filter Bar
          const TimeFrameFilterBar(),
          const SizedBox(height: 18),

          // High-level Stats Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final int crossAxisCount;
              final double aspectRatio;

              if (constraints.maxWidth < 560) {
                crossAxisCount = 1;
                aspectRatio = constraints.maxWidth < 360 ? 2.1 : 2.3;
              } else if (constraints.maxWidth < 1000) {
                crossAxisCount = 2;
                aspectRatio = 1.35;
              } else {
                crossAxisCount = 4;
                aspectRatio = 1.5;
              }

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: aspectRatio,
                children: [
                  MetricCard(
                    title: 'Total Surgeries',
                    value: '${stats.totalCases}',
                    subtitle: 'In active time frame',
                    icon: Icons.medical_services_rounded,
                    accentColor: AppTheme.primaryCyan,
                    trendText: 'Active Cohort',
                  ),
                  MetricCard(
                    title: 'Complications',
                    value: '${stats.complicationRate.toStringAsFixed(1)}%',
                    subtitle:
                        '${stats.casesWithComplications} of ${stats.totalCases} cases',
                    icon: Icons.warning_amber_rounded,
                    accentColor: AppTheme.alertAmber,
                    isTrendPositive: stats.casesWithComplications == 0,
                    trendText: 'Clavien-Dindo',
                  ),
                  MetricCard(
                    title: 'Mean Patient Age',
                    value: '${stats.meanAge.toStringAsFixed(1)} y',
                    subtitle: 'Baseline Demographics',
                    icon: Icons.person_search_rounded,
                    accentColor: AppTheme.accentIndigo,
                    trendText: 'Standard Cohort',
                  ),
                  MetricCard(
                    title: 'Research Abstracts',
                    value: '${provider.abstracts.length}',
                    subtitle: 'Auto-Synthesized Markdown',
                    icon: Icons.article_rounded,
                    accentColor: AppTheme.primaryTeal,
                    trendText: 'Ready to Export',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),

          // Analytics Charts (Surgery Timeline & Complication Breakdown)
          if (!isMobile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildSurgeryTimelineChart(context, cases, isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildComplicationGradesCard(context, stats, isDark),
                ),
              ],
            )
          else ...[
            _buildSurgeryTimelineChart(context, cases, isDark),
            const SizedBox(height: 16),
            _buildComplicationGradesCard(context, stats, isDark),
          ],

          const SizedBox(height: 26),

          // Recent Surgical Cases Feed Header
          SectionHeader(
            title: 'Surgical Registry Stream',
            subtitle:
                'Granular pre/intra/post-operative records in active time frame',
            trailing: TextButton.icon(
              onPressed: () => provider.setNavIndex(9), // Go to search screen
              icon: Text(
                isMobile
                    ? 'Explore All Records'
                    : 'Search & Explore All Records',
              ),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
            ),
          ),
          const SizedBox(height: 14),

          if (cases.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCard.withValues(alpha: 0.6)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 32,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No surgical cases in this time frame',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start by adding a patient case or load demo data to explore.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CaseIntakeFormScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: const Text('Add Surgery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await provider.loadDemoData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sample demo cases loaded!'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.download_rounded, size: 15),
                        label: const Text('Load Demo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            ...cases.take(4).map((c) {
              return ClinicalCaseCard(
                clinicalCase: c,
                onTap: () {
                  provider.selectClinicalCase(c);
                  provider.setNavIndex(9);
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    ResearchProvider provider,
    bool isDark,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F2027)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryCyan.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCyan.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line 1: Heading alone
          Text(
            'Surgical & Clinical Research Hub',
            style: GoogleFonts.outfit(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Line 2: Details alone (Badge & Subtitle)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storage_rounded,
                      size: 12,
                      color: AppTheme.primaryCyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CLINICAL SURGICAL REGISTRY',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Multi-phase tracking • Clavien-Dindo kinetics • Dynamic Markdown abstracts',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 11.5 : 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Line 3: Action Button alone
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CaseIntakeFormScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Intake New Surgery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurgeryTimelineChart(
    BuildContext context,
    List cases,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                'Surgical Case Volume & Progression',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Registry Active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Longitudinal surgical volume across timeline',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        const months = ['May', 'Jun', 'Jul', 'Aug'];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[idx],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 3,
                minY: 0,
                maxY: 8,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 2),
                      FlSpot(2, 3),
                      FlSpot(3, 3),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryCyan, AppTheme.primaryTeal],
                    ),
                    barWidth: 3.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryCyan.withValues(alpha: 0.25),
                          AppTheme.primaryTeal.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplicationGradesCard(
    BuildContext context,
    dynamic stats,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complications by Clavien-Dindo Grade',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Surgical quality audit breakdown',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _buildGradeBar(
            'Grade I (Minor / Effusion)',
            1,
            3,
            AppTheme.primaryTeal,
            isDark,
          ),
          _buildGradeBar(
            'Grade II (POAF / Pharmacological)',
            1,
            3,
            AppTheme.alertAmber,
            isDark,
          ),
          _buildGradeBar(
            'Grade IIIa/b (Interventions)',
            0,
            3,
            AppTheme.accentPurple,
            isDark,
          ),
          _buildGradeBar(
            'Grade IV/V (ICU / Mortality)',
            0,
            3,
            AppTheme.alertRed,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBar(
    String label,
    int count,
    int total,
    Color color,
    bool isDark,
  ) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count cases',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

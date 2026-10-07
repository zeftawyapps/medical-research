import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/research_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import '../widgets/clinical_case_card.dart';
import '../widgets/clinical_case_detail_view.dart';
import '../widgets/common_widgets.dart';
import '../widgets/time_frame_filter_bar.dart';

class UniversalSearchScreen extends StatefulWidget {
  const UniversalSearchScreen({super.key});

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _quickSearchTags = [
    'Hepatectomy',
    'Deep Brain',
    'Bypass',
    'Clavien-Dindo',
    'POD 3',
    'Hemoglobin',
    '3T MRI',
    'POAF',
    'Robotic',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final searchResults = provider.searchResults;
    final stats = provider.activeStats;

    if (!isDesktop) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.horizontalPadding(context),
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Engine Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C1B33), Color(0xFF132A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1: Heading alone
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.manage_search_rounded,
                          color: AppTheme.primaryCyan,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Time Frame & Search Engine',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Line 2: Details alone
                  Text(
                    'Multi-field search across MRN, Radiology, Notes, and Labs.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Time Frame Presets
            const TimeFrameFilterBar(),
            const SizedBox(height: 12),

            // Search Bar
            CustomSearchBar(
              controller: _searchController,
              hint: 'Search MRN, diagnosis, POAF, troponin...',
              onChanged: (val) => provider.setSearchQuery(val),
              onClear: () => provider.setSearchQuery(''),
            ),
            const SizedBox(height: 12),

            // Aggregated Metrics Bar
            Row(
              children: [
                _buildMiniKpi(
                  context,
                  'MATCHES',
                  '${searchResults.length}',
                  AppTheme.primaryCyan,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildMiniKpi(
                  context,
                  'COMPLICATIONS',
                  '${stats.complicationRate.toStringAsFixed(1)}%',
                  AppTheme.alertAmber,
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildMiniKpi(
                  context,
                  'MEAN AGE',
                  '${stats.meanAge.toStringAsFixed(1)} y',
                  AppTheme.accentIndigo,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (searchResults.isEmpty)
              const EmptyStateWidget(
                icon: Icons.search_off_rounded,
                title: 'No Clinical Records Matched',
                message:
                    'Try adjusting the keyword or Time Frame presets above.',
              )
            else
              ...searchResults.map((res) {
                return ClinicalCaseCard(
                  clinicalCase: res.clinicalCase,
                  matchedFields: res.matchedFields,
                  onTap: () {
                    provider.selectClinicalCase(res.clinicalCase);
                    _showMobileModal(context, provider);
                  },
                );
              }),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.horizontalPadding(context),
        vertical: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Engine Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C1B33), Color(0xFF132A4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.manage_search_rounded,
                    color: AppTheme.primaryCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Frame & Universal Clinical Search Engine',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Full-text multi-field scanning across MRN, Pre-Op Radiology, Surgical notes, POD Complications, and Labs.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Time Frame & POD Selector
          const TimeFrameFilterBar(),
          const SizedBox(height: 14),

          // Search Field
          CustomSearchBar(
            controller: _searchController,
            hint:
                'Type any keyword (e.g. "MRI", "Robotic", "Bilirubin", "POAF", "Grade II")...',
            onChanged: (val) => provider.setSearchQuery(val),
            onClear: () => provider.setSearchQuery(''),
          ),
          const SizedBox(height: 10),

          // Quick Tag Suggestions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Quick Index: ',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                ..._quickSearchTags.map((tag) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(tag),
                      onPressed: () {
                        _searchController.text = tag;
                        provider.setSearchQuery(tag);
                      },
                      backgroundColor: isDark
                          ? AppTheme.darkCard
                          : Colors.white,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Aggregated Metrics Bar for this Search/Time Frame Window
          Row(
            children: [
              _buildMiniKpi(
                context,
                'MATCHED SURGERIES',
                '${searchResults.length}',
                AppTheme.primaryCyan,
                isDark,
              ),
              const SizedBox(width: 10),
              _buildMiniKpi(
                context,
                'COMPLICATIONS RATE',
                '${stats.complicationRate.toStringAsFixed(1)}%',
                AppTheme.alertAmber,
                isDark,
              ),
              const SizedBox(width: 10),
              _buildMiniKpi(
                context,
                'MEAN PATIENT AGE',
                '${stats.meanAge.toStringAsFixed(1)} yrs',
                AppTheme.accentIndigo,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Results List / Master-Detail
          Expanded(
            child: searchResults.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'No Clinical Records Matched',
                    message:
                        'Try adjusting the keyword or changing the Time Frame date presets above.',
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, idx) {
                            final res = searchResults[idx];
                            return ClinicalCaseCard(
                              clinicalCase: res.clinicalCase,
                              isSelected:
                                  provider
                                      .selectedClinicalCase
                                      ?.operation
                                      .operationId ==
                                  res.clinicalCase.operation.operationId,
                              matchedFields: res.matchedFields,
                              onTap: () =>
                                  provider.selectClinicalCase(res.clinicalCase),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 7,
                        child: provider.selectedClinicalCase != null
                            ? ClinicalCaseDetailView(
                                clinicalCase: provider.selectedClinicalCase!,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKpi(
    BuildContext context,
    String title,
    String val,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileModal(BuildContext context, ResearchProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.sizeOf(context).height * 0.90,
          margin: const EdgeInsets.only(top: 30),
          child: ClinicalCaseDetailView(
            clinicalCase: provider.selectedClinicalCase!,
            onClose: () => Navigator.pop(ctx),
          ),
        );
      },
    );
  }
}

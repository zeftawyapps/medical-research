import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/research_provider.dart';
import '../services/backup/clinical_backup_service.dart';
import '../services/export/clinical_export_service.dart';
import '../services/import/clinical_import_service.dart';
import '../theme/app_theme.dart';

import '../widgets/database_inspector_dialog.dart';

/// Settings, Appearance (Dark/Light mode) & System Management Screen
class ClinicalSettingsScreen extends StatelessWidget {
  const ClinicalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final isDark = provider.isDarkMode;
    final isMockVisible = AppConfig.isMockDataAvailable;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Theme and Display
              _buildSectionHeader(
                context,
                icon: Icons.palette_outlined,
                title: 'Theme & Display Settings',
                subtitle: 'Select your preferred visual mode for clinical work',
              ),
              const SizedBox(height: 14),
              _buildThemeSelectorCard(context, provider, isDark),
              const SizedBox(height: 24),

              // 2. Clinical Query Navigation & Default Tab Preference
              _buildSectionHeader(
                context,
                icon: Icons.tab_rounded,
                title: 'Clinical Query Tab Preference',
                subtitle: 'Default & last active tab in Clinical Query screen (Saved in SharedPreferences)',
              ),
              const SizedBox(height: 14),
              _buildQueryNavigationCard(context, provider, isDark),
              const SizedBox(height: 24),

              // 3. Storage & Database Management
              _buildSectionHeader(
                context,
                icon: Icons.storage_rounded,
                title: 'Database & Local Storage',
                subtitle: 'Record statistics and SQLite database management',
              ),
              const SizedBox(height: 14),
              _buildStorageStatsCard(context, provider, isDark),
              const SizedBox(height: 24),

              // 4. Data Import & External Migration (Excel, CSV, JSON)
              _buildSectionHeader(
                context,
                icon: Icons.file_download_outlined,
                title: 'Data Import & Migration (Excel / CSV / JSON)',
                subtitle: 'Import external patient registries, Excel spreadsheets, or restore full database backups',
              ),
              const SizedBox(height: 14),
              _DataImportCard(provider: provider, isDark: isDark),
              const SizedBox(height: 24),

              // 5. Export & Backup Directory Paths
              _buildSectionHeader(
                context,
                icon: Icons.drive_file_move_rounded,
                title: 'Export & Backup Directory Paths',
                subtitle: 'Configure custom local paths for data exports (.xlsx, .csv) and full database backups',
              ),
              const SizedBox(height: 14),
              _ExportBackupPathsCard(provider: provider, isDark: isDark),
              const SizedBox(height: 24),

              // 5. Mock & Experimental Dataset (Guarded by enabliMockData / isenable in main.dart)
              if (isMockVisible) ...[
                _buildSectionHeader(
                  context,
                  icon: Icons.science_outlined,
                  title: 'Research Testing & Mock Dataset',
                  subtitle: '500+ English cases simulation for queries and statistics (Duplicate protected)',
                ),
                const SizedBox(height: 14),
                _buildMockDataCard(context, provider, isDark),
                const SizedBox(height: 24),
              ],

              // 4. System & Architecture Specs
              _buildSectionHeader(
                context,
                icon: Icons.info_outline_rounded,
                title: 'System & Platform Information',
                subtitle: 'Clinical infrastructure details and technical specifications',
              ),
              const SizedBox(height: 14),
              _buildSystemInfoCard(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 1. Theme Selector (Dark Mode / Light Mode & 8 Medical Palettes)
  // ===========================================================================
  Widget _buildThemeSelectorCard(BuildContext context, ResearchProvider provider, bool isDark) {
    final theme = Theme.of(context);
    final activePalette = provider.selectedPalette;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? AppTheme.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? (isDark ? AppTheme.darkBorder : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Selector (Dark / Light)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final darkOption = _buildThemeOptionTile(
                title: 'Dark Mode (AMOLED / Low Light)',
                subtitle: 'Ideal for surgery & reduced eye strain in dark environments',
                icon: Icons.dark_mode_rounded,
                accentColor: provider.currentPaletteConfig.primary,
                isSelected: isDark,
                cardBg: const Color(0xFF0F172A),
                onTap: () {
                  if (!isDark) provider.toggleTheme();
                },
              );
              final lightOption = _buildThemeOptionTile(
                title: 'Medical Paper Light Mode',
                subtitle: 'Soft, anti-glare comfortable tint for daylight reading',
                icon: Icons.light_mode_rounded,
                accentColor: Colors.amber.shade800,
                isSelected: !isDark,
                cardBg: const Color(0xFFF1F5F9),
                onTap: () {
                  if (isDark) provider.toggleTheme();
                },
              );

              if (isNarrow) {
                return Column(
                  children: [
                    darkOption,
                    const SizedBox(height: 10),
                    lightOption,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: darkOption),
                  const SizedBox(width: 14),
                  Expanded(child: lightOption),
                ],
              );
            },
          ),
          const Divider(height: 28),

          // 8 Medical Color Palettes Header
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_rounded, size: 18, color: provider.currentPaletteConfig.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Clinical Color Palettes (8 Options)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Active: ${provider.currentPaletteConfig.titleEn}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: provider.currentPaletteConfig.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Active: ${provider.currentPaletteConfig.titleEn}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: provider.currentPaletteConfig.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Grid of 8 Palettes
          LayoutBuilder(
            builder: (ctx, constraints) {
              final crossAxisCount = constraints.maxWidth > 700 ? 4 : (constraints.maxWidth > 340 ? 2 : 1);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AppThemePalette.values.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: crossAxisCount == 1 ? 3.3 : (crossAxisCount == 2 ? 1.85 : 2.2),
                ),
                itemBuilder: (ctx, idx) {
                  final pal = AppThemePalette.values[idx];
                  final cfg = AppTheme.palettes[pal]!;
                  final isSelected = pal == activePalette;

                  return InkWell(
                    onTap: () => provider.setThemePalette(pal),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? cfg.darkSurface : (isSelected ? cfg.getPrimary(false).withValues(alpha: 0.08) : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? cfg.getPrimary(isDark) : (isDark ? cfg.darkBorder : cfg.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Color Swatch Circles
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: cfg.getPrimary(isDark),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: AppTheme.getContrastTextColor(cfg.getPrimary(isDark)),
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: cfg.getSecondary(isDark),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cfg.titleEn,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isDark ? cfg.darkTextPrimary : cfg.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  cfg.titleAr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? cfg.darkTextSecondary : cfg.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required Color cardBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accentColor, size: 24),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: accentColor, size: 20)
                else
                  Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: cardBg == const Color(0xFF0F172A) ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: cardBg == const Color(0xFF0F172A) ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. Clinical Query Tab Preference Card
  // ===========================================================================
  Widget _buildQueryNavigationCard(BuildContext context, ResearchProvider provider, bool isDark) {
    final theme = Theme.of(context);
    final selectedTab = provider.clinicalQueryTabIndex;
    final primaryColor = provider.currentPaletteConfig.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? AppTheme.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? (isDark ? AppTheme.darkBorder : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app_rounded, size: 18, color: primaryColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Default Query Screen Tab',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            selectedTab == 0 ? 'Tab 1: Analytics' : 'Tab 2: Cohort Search',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          selectedTab == 0 ? 'Tab 1: Analytics' : 'Tab 2: Cohort Search',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Switching tabs in Clinical Query automatically saves the active tab to SharedPreferences, opening directly to it on your next visit.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final analyticsTile = _buildThemeOptionTile(
                title: 'Analytics Dashboard',
                subtitle: 'Statistical KPIs, procedure charts & complication rates',
                icon: Icons.insights_rounded,
                accentColor: primaryColor,
                isSelected: selectedTab == 0,
                cardBg: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                onTap: () {
                  provider.setClinicalQueryTabIndex(0);
                },
              );
              final cohortTile = _buildThemeOptionTile(
                title: 'Cohort Search & Cases',
                subtitle: 'Multi-criteria filters, search queries & case records',
                icon: Icons.saved_search_rounded,
                accentColor: Colors.blue.shade600,
                isSelected: selectedTab == 1,
                cardBg: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                onTap: () {
                  provider.setClinicalQueryTabIndex(1);
                },
              );

              if (isNarrow) {
                return Column(
                  children: [
                    analyticsTile,
                    const SizedBox(height: 10),
                    cohortTile,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: analyticsTile),
                  const SizedBox(width: 14),
                  Expanded(child: cohortTile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. Storage & DB Management Card
  // ===========================================================================
  Widget _buildStorageStatsCard(BuildContext context, ResearchProvider provider, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? colorScheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCounter(
                title: 'Patients',
                count: '${provider.patients.length}',
                color: Colors.teal,
              ),
              _buildStatCounter(
                title: 'Operations',
                count: '${provider.operations.length}',
                color: Colors.blue,
              ),
              _buildStatCounter(
                title: 'Pre-Op Forms',
                count: '${provider.preOps.length}',
                color: Colors.purple,
              ),
              _buildStatCounter(
                title: 'Complications',
                count: '${provider.complications.length}',
                color: Colors.amber.shade800,
              ),
            ],
          ),
          const Divider(height: 20),
          // Live Database Inspector Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.currentPaletteConfig.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => DatabaseInspectorDialog.show(context),
              icon: const Icon(Icons.plagiarism_outlined, size: 20),
              label: const Text(
                'Live SQLite Database Inspector',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 400;
              final descriptionCol = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reset Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 2),
                  Text(
                    'Erase all local patient and surgery records',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              );
              final purgeButton = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _confirmResetDatabase(context, provider),
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('Purge All Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    descriptionCol,
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: purgeButton),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: descriptionCol),
                  const SizedBox(width: 8),
                  purgeButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCounter({
    required String title,
    required String count,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetDatabase(BuildContext context, ResearchProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Confirm Database Reset')),
          ],
        ),
        content: const Text('Are you sure you want to permanently delete all records? This action cannot be undone and will purge all patients, operations, and clinical assessments.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearDatabase();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database cleared successfully!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // 3. Mock Data Testing Card (Controlled by enabliMockData with duplicate protection)
  // ===========================================================================
  Widget _buildMockDataCard(BuildContext context, ResearchProvider provider, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSeeded = provider.isMockDataSeeded;
    final count = provider.seededMockCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? colorScheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSeeded
              ? colorScheme.primary.withValues(alpha: 0.4)
              : (theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.2)),
          width: isSeeded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Status Badge
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final statusBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isSeeded ? Colors.teal : Colors.grey).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isSeeded ? Colors.teal : Colors.grey).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSeeded ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 13,
                      color: isSeeded ? Colors.teal : Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isSeeded ? 'Active ($count Cases)' : 'Not Installed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSeeded ? Colors.teal : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );

              final titleRow = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isSeeded ? Colors.teal : Colors.amber).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSeeded ? Icons.verified_rounded : Icons.science_rounded,
                      color: isSeeded ? Colors.teal : Colors.amber.shade800,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clinical Research Cohort (500+)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '100% English • Aesthetic & Reconstructive',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 8),
                    statusBadge,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 8),
                  statusBadge,
                ],
              );
            },
          ),

          const SizedBox(height: 14),
          Text(
            isSeeded
                ? 'Dataset is loaded and active. Anti-duplicate mechanism is locked: closing or reopening the application will NEVER re-insert or duplicate records.'
                : 'Generates 520 comprehensive clinical records (Liposuction, Abdominoplasty, Breast Augmentation, Rhinoplasty, etc.) with pre-op, intra-op garments, complications, labs, and surveys to test the Query & Research engine.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.4,
            ),
          ),

          const Divider(height: 24),

          // Actions
          if (provider.isLoadingDatabase)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Processing SQLite transaction...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            )
          else if (!isSeeded)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _installMockData(context, provider),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Install Mock Dataset (520 English Cases)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final protectedBtn = ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: null, // Strictly disabled to prevent duplicates
                  icon: const Icon(Icons.lock_outline_rounded, size: 16),
                  label: const Text(
                    'Seeded & Protected',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );

                final purgeBtn = OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _confirmResetMockData(context, provider),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text(
                    'Purge Mock Data',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: protectedBtn),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: purgeBtn),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: protectedBtn),
                    const SizedBox(width: 12),
                    purgeBtn,
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _installMockData(BuildContext context, ResearchProvider provider) async {
    final result = await provider.seedMockData();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.alreadySeeded
                    ? 'Protected: Mock data is already installed (${result.insertedCases} cases). No duplicates added.'
                    : 'Installed ${result.insertedCases} clinical research cases successfully!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _confirmResetMockData(BuildContext context, ResearchProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Purge Mock Research Cohort?')),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove the 520 mock cases? '
          'This will delete only the test dataset and reset the flag. '
          'Real patient cases will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge Cases'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final removed = await provider.clearMockData();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $removed mock cases and reset the seeding flag.'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===========================================================================
  // 4. Platform and Architecture Specs
  // ===========================================================================
  Widget _buildSystemInfoCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? colorScheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Core Platform Engine', 'JoDija Templates Engine v2.0', Icons.hub_outlined),
          const Divider(height: 16),
          _buildInfoRow('Local Database', 'SQLite v2 (medectal_research_v2.db)', Icons.data_object_rounded),
          const Divider(height: 16),
          _buildInfoRow('Security & Privacy', '100% Isolated Local Storage (Zero Cloud Leakage)', Icons.security_rounded),
          const Divider(height: 16),
          _buildInfoRow('Language & Direction', 'English (LTR) & Arabic (RTL) Supported', Icons.language_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: Colors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.teal),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dedicated Card for Importing External Data (Excel, CSV, JSON) into SQLite
class _DataImportCard extends StatefulWidget {
  final ResearchProvider provider;
  final bool isDark;

  const _DataImportCard({
    required this.provider,
    required this.isDark,
  });

  @override
  State<_DataImportCard> createState() => _DataImportCardState();
}

class _DataImportCardState extends State<_DataImportCard> {
  bool _isImporting = false;
  bool _skipDuplicates = true;

  Future<void> _pickAndImportFile({required String type}) async {
    List<String> allowedExtensions = [];
    if (type == 'excel') {
      allowedExtensions = ['xlsx', 'xls'];
    } else if (type == 'csv') {
      allowedExtensions = ['csv'];
    } else if (type == 'json') {
      allowedExtensions = ['json'];
    } else {
      allowedExtensions = ['xlsx', 'xls', 'csv', 'json'];
    }

    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (files.isNotEmpty) {
        final path = files.first.path;
        if (path != null && path.trim().isNotEmpty) {
          final file = File(path.trim());

          setState(() => _isImporting = true);

          final importResult = await widget.provider.importClinicalDataFromFile(
            file,
            skipDuplicateMrn: _skipDuplicates,
          );

          if (!mounted) return;

          _showImportResultDialog(importResult);
        }
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File picker requires a full app restart. Please restart the app.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showImportResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.isSuccess ? Icons.verified_rounded : Icons.error_outline_rounded,
              color: result.isSuccess ? Colors.teal : Colors.red,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.isSuccess ? 'Data Import Completed' : 'Data Import Error',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.isSuccess
                    ? 'Successfully parsed and merged records from ${result.fileName} into the SQLite registry.'
                    : 'An issue occurred while parsing ${result.fileName}.',
                style: const TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (result.isSuccess ? Colors.teal : Colors.red).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (result.isSuccess ? Colors.teal : Colors.red).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatPill('Patients', '${result.patientsImported}'),
                        _buildStatPill('Operations', '${result.operationsImported}'),
                        _buildStatPill('Complications', '${result.complicationsImported}'),
                        _buildStatPill('Skipped', '${result.duplicatesSkipped}'),
                      ],
                    ),
                  ],
                ),
              ),
              if (result.errorMessages.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Notices / Warnings:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange),
                ),
                const SizedBox(height: 4),
                ...result.errorMessages.take(3).map(
                      (msg) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Text(
                          '• $msg',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? colorScheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              final switchWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Skip Duplicate MRNs',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: _skipDuplicates,
                    activeThumbColor: Colors.teal,
                    onChanged: (val) => setState(() => _skipDuplicates = val),
                  ),
                ],
              );

              final headerContent = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.file_upload_outlined, color: Colors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Patient Data & Registries',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Supports Excel (.xlsx), CSV (.csv), and JSON backups',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerContent,
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(),
                        switchWidget,
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: headerContent),
                  const SizedBox(width: 12),
                  switchWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Load clinical registries or research datasets from another device or spreadsheet. The system automatically reads columns (MRN, Patient Name, Age, Gender, Procedure, BMI, Smoking, Complications, etc.) and maps them to the local SQLite database.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const Divider(height: 24),
          if (_isImporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Importing data and refreshing database...', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _pickAndImportFile(type: 'excel'),
                  icon: const Icon(Icons.table_chart_rounded, size: 18),
                  label: const Text(
                    'Import Excel (.xlsx)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _pickAndImportFile(type: 'csv'),
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: const Text(
                    'Import CSV (.csv)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _pickAndImportFile(type: 'json'),
                  icon: const Icon(Icons.restore_page_rounded, size: 18),
                  label: const Text(
                    'Restore JSON Backup',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Dedicated Card for Managing Custom Export & Database Backup Directory Paths
class _ExportBackupPathsCard extends StatefulWidget {
  final ResearchProvider provider;
  final bool isDark;

  const _ExportBackupPathsCard({
    required this.provider,
    required this.isDark,
  });

  @override
  State<_ExportBackupPathsCard> createState() => _ExportBackupPathsCardState();
}

class _ExportBackupPathsCardState extends State<_ExportBackupPathsCard> {
  late final TextEditingController _exportPathController;
  late final TextEditingController _backupPathController;
  String _effectiveExportDir = 'Resolving...';
  String _effectiveBackupDir = 'Resolving...';
  bool _isBackingUp = false;

  @override
  void initState() {
    super.initState();
    _exportPathController =
        TextEditingController(text: widget.provider.customExportDirectory);
    _backupPathController =
        TextEditingController(text: widget.provider.customBackupDirectory);
    _loadEffectivePaths();
  }

  @override
  void didUpdateWidget(covariant _ExportBackupPathsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.customExportDirectory != _exportPathController.text) {
      _exportPathController.text = widget.provider.customExportDirectory;
    }
    if (widget.provider.customBackupDirectory != _backupPathController.text) {
      _backupPathController.text = widget.provider.customBackupDirectory;
    }
    _loadEffectivePaths();
  }

  @override
  void dispose() {
    _exportPathController.dispose();
    _backupPathController.dispose();
    super.dispose();
  }

  Future<void> _loadEffectivePaths() async {
    try {
      final exportDir = await ClinicalExportService.getExportDirectory(
        customDirectoryPath: widget.provider.customExportDirectory.isNotEmpty
            ? widget.provider.customExportDirectory
            : null,
      );
      final backupDir = await ClinicalBackupService.getBackupDirectory(
        customDirectoryPath: widget.provider.customBackupDirectory.isNotEmpty
            ? widget.provider.customBackupDirectory
            : null,
      );
      if (mounted) {
        setState(() {
          _effectiveExportDir = exportDir.path;
          _effectiveBackupDir = backupDir.path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _effectiveExportDir = 'Default system documents folder';
          _effectiveBackupDir = 'Default system documents folder';
        });
      }
    }
  }

  Future<void> _browseExportDirectory() async {
    try {
      final selectedDirectory = await FilePickerPlatform.instance.getDirectoryPath(
        dialogTitle: 'Select Export Directory',
        initialDirectory: _exportPathController.text.isNotEmpty
            ? _exportPathController.text
            : _effectiveExportDir,
      );
      if (selectedDirectory != null && selectedDirectory.trim().isNotEmpty) {
        _exportPathController.text = selectedDirectory.trim();
        await widget.provider.setCustomExportDirectory(selectedDirectory.trim());
        await _loadEffectivePaths();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export directory selected: $selectedDirectory'),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Folder picker plugin requires a full app restart. Please stop and run the app again.',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open folder picker: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _browseBackupDirectory() async {
    try {
      final selectedDirectory = await FilePickerPlatform.instance.getDirectoryPath(
        dialogTitle: 'Select Backup Directory',
        initialDirectory: _backupPathController.text.isNotEmpty
            ? _backupPathController.text
            : _effectiveBackupDir,
      );
      if (selectedDirectory != null && selectedDirectory.trim().isNotEmpty) {
        _backupPathController.text = selectedDirectory.trim();
        await widget.provider.setCustomBackupDirectory(selectedDirectory.trim());
        await _loadEffectivePaths();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup directory selected: $selectedDirectory'),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Folder picker plugin requires a full app restart. Please stop and run the app again.',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open folder picker: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showCreateFolderDialog({required bool isExport}) async {
    final nameController = TextEditingController();
    final baseDir = isExport
        ? (_exportPathController.text.isNotEmpty ? _exportPathController.text : _effectiveExportDir)
        : (_backupPathController.text.isNotEmpty ? _backupPathController.text : _effectiveBackupDir);

    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.create_new_folder_rounded,
              color: isExport ? Colors.green : Colors.blueAccent,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isExport ? 'Create Export Folder' : 'Create Backup Folder',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Base Directory:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                baseDir,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Folder Name',
                hintText: isExport ? 'e.g. Clinical_Exports' : 'e.g. Clinical_Backups',
                prefixIcon: const Icon(Icons.folder_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isExport ? Colors.green.shade700 : Colors.blueAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, name);
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Create & Set Path'),
          ),
        ],
      ),
    );

    if (created != null && created.isNotEmpty) {
      try {
        final newDir = Directory('$baseDir/$created');
        if (!await newDir.exists()) {
          await newDir.create(recursive: true);
        }
        if (isExport) {
          _exportPathController.text = newDir.path;
          await widget.provider.setCustomExportDirectory(newDir.path);
        } else {
          _backupPathController.text = newDir.path;
          await widget.provider.setCustomBackupDirectory(newDir.path);
        }
        await _loadEffectivePaths();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created and set path: ${newDir.path}'),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create folder: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveExportPath() async {
    final text = _exportPathController.text.trim();
    await widget.provider.setCustomExportDirectory(text);
    await _loadEffectivePaths();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text.isEmpty
              ? 'Export directory reset to default system location.'
              : 'Export directory saved: $text'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetExportPath() async {
    _exportPathController.clear();
    await widget.provider.resetExportDirectory();
    await _loadEffectivePaths();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export path restored to default application documents.'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveBackupPath() async {
    final text = _backupPathController.text.trim();
    await widget.provider.setCustomBackupDirectory(text);
    await _loadEffectivePaths();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text.isEmpty
              ? 'Backup directory reset to default system location.'
              : 'Backup directory saved: $text'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetBackupPath() async {
    _backupPathController.clear();
    await widget.provider.resetBackupDirectory();
    await _loadEffectivePaths();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup path restored to default application documents.'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _triggerBackupNow() async {
    setState(() => _isBackingUp = true);
    try {
      final result = await widget.provider.createDatabaseBackup();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.teal, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Database Backup Created',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A complete, standalone database snapshot has been successfully generated and saved to your backup destination.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 16, color: Colors.teal),
                          const SizedBox(width: 6),
                          const Text(
                            'Saved File Path:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            tooltip: 'Copy File Path',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: result.filePath));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Backup path copied to clipboard!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        result.filePath,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailPill('File Size', result.formattedFileSize),
                          _buildDetailPill('Patients', '${result.patientCount}'),
                          _buildDetailPill('Operations', '${result.operationCount}'),
                          _buildDetailPill('Records', '${result.totalRecords}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Path'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.filePath));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup path copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate database backup: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Widget _buildDetailPill(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? colorScheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (Platform.isAndroid) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 420;
                  final bannerText = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'For custom folders (e.g. /storage/emulated/0/...), please ensure All Files Access is enabled.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  );

                  final grantBtn = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () async {
                      try {
                        await Permission.manageExternalStorage.request();
                        await Permission.storage.request();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Storage permissions requested.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.lock_open_rounded, size: 14),
                    label: const Text('Grant Access', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bannerText,
                        const SizedBox(height: 8),
                        SizedBox(width: double.infinity, child: grantBtn),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: bannerText),
                      const SizedBox(width: 8),
                      grantBtn,
                    ],
                  );
                },
              ),
            ),
          ],

          // Section 1: Data Export Destination Path
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.table_view_rounded, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Data Export Destination Path',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Folder where exported Excel (.xlsx) and CSV (.csv) patient spreadsheets are saved.',
            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _exportPathController,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Export Directory Path',
              hintText: 'e.g. /Users/username/Documents/MedicalExports or C:\\MedicalExports',
              prefixIcon: const Icon(Icons.folder_outlined, size: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open_rounded, color: Colors.green, size: 20),
                tooltip: 'Browse / Pick Folder',
                onPressed: _browseExportDirectory,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: Colors.teal),
                          SizedBox(width: 6),
                          Text(
                            'Active Destination:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _effectiveExportDir,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: Colors.teal),
                    const SizedBox(width: 6),
                    const Text(
                      'Active Destination: ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    Expanded(
                      child: Text(
                        _effectiveExportDir,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _browseExportDirectory,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Browse Folder', style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton.icon(
                onPressed: () => _showCreateFolderDialog(isExport: true),
                icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                label: const Text('New Folder', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: _resetExportPath,
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: const Text('Reset to Default', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveExportPath,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Save Export Path', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const Divider(height: 28),

          // Section 2: Database Backup Destination Path
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.backup_table_rounded, color: Colors.blueAccent, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Database Backup Destination Path',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Folder where standalone database snapshots and JSON backups are stored.',
            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _backupPathController,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Backup Directory Path',
              hintText: 'e.g. /Users/username/Backups/Clinical or D:\\Backups',
              prefixIcon: const Icon(Icons.folder_zip_outlined, size: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open_rounded, color: Colors.blueAccent, size: 20),
                tooltip: 'Browse / Pick Folder',
                onPressed: _browseBackupDirectory,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: Colors.blueAccent),
                          SizedBox(width: 6),
                          Text(
                            'Active Destination:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _effectiveBackupDir,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 6),
                    const Text(
                      'Active Destination: ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    Expanded(
                      child: Text(
                        _effectiveBackupDir,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _browseBackupDirectory,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Browse Folder', style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton.icon(
                onPressed: () => _showCreateFolderDialog(isExport: false),
                icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                label: const Text('New Folder', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: _resetBackupPath,
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: const Text('Reset to Default', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveBackupPath,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Save Backup Path', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const Divider(height: 28),

          // Section 3: Instant Database Backup Trigger
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final descriptionCol = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instant Database Backup',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Create an immediate timestamped backup of all clinical records',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              );

              final backupBtn = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isBackingUp ? null : _triggerBackupNow,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.backup_rounded, size: 16),
                label: Text(
                  _isBackingUp ? 'Creating Backup...' : 'Create Backup Now',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    descriptionCol,
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: backupBtn),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: descriptionCol),
                  const SizedBox(width: 8),
                  backupBtn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

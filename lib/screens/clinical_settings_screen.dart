import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/research_provider.dart';
import '../theme/app_theme.dart';

/// Settings, Appearance (Dark/Light mode) & System Management Screen
class ClinicalSettingsScreen extends StatelessWidget {
  const ClinicalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final isDark = provider.isDarkMode;
    final isMockVisible = AppConfig.isMockDataAvailable;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Theme and Display
              _buildSectionHeader(
                icon: Icons.palette_outlined,
                title: 'Theme & Display Settings',
                subtitle: 'Select your preferred visual mode for clinical work',
              ),
              const SizedBox(height: 14),
              _buildThemeSelectorCard(context, provider, isDark),
              const SizedBox(height: 24),

              // 2. Storage & Database Management
              _buildSectionHeader(
                icon: Icons.storage_rounded,
                title: 'Database & Local Storage',
                subtitle: 'Record statistics and SQLite database management',
              ),
              const SizedBox(height: 14),
              _buildStorageStatsCard(context, provider, isDark),
              const SizedBox(height: 24),

              // 3. Mock & Experimental Dataset (Guarded by enabliMockData / isenable in main.dart)
              if (isMockVisible) ...[
                _buildSectionHeader(
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
                icon: Icons.info_outline_rounded,
                title: 'System & Platform Information',
                subtitle: 'Clinical infrastructure details and technical specifications',
              ),
              const SizedBox(height: 14),
              _buildSystemInfoCard(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.teal, size: 20),
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 1. Theme Selector (Dark Mode / Light Mode)
  // ===========================================================================
  Widget _buildThemeSelectorCard(BuildContext context, ResearchProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildThemeOptionTile(
                  title: 'Dark Mode',
                  subtitle: 'Optimized for low-light environments, easy on the eyes',
                  icon: Icons.dark_mode_rounded,
                  accentColor: Colors.tealAccent.shade400,
                  isSelected: isDark,
                  cardBg: const Color(0xFF0F172A),
                  onTap: () {
                    if (!isDark) provider.toggleTheme();
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildThemeOptionTile(
                  title: 'Light Mode',
                  subtitle: 'Crisp, high-contrast display for daylight reading',
                  icon: Icons.light_mode_rounded,
                  accentColor: Colors.orange.shade800,
                  isSelected: !isDark,
                  cardBg: const Color(0xFFF1F5F9),
                  onTap: () {
                    if (isDark) provider.toggleTheme();
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    color: isDark ? Colors.tealAccent : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isDark ? 'Dark Mode is currently active' : 'Light Mode is currently active',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Switch.adaptive(
                value: isDark,
                activeTrackColor: Colors.teal,
                onChanged: (_) => provider.toggleTheme(),
              ),
            ],
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
            color: isSelected ? Colors.teal : Colors.transparent,
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
                  const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 20)
                else
                  Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: cardBg == const Color(0xFF0F172A) ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: cardBg == const Color(0xFF0F172A) ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. Storage & DB Management Card
  // ===========================================================================
  Widget _buildStorageStatsCard(BuildContext context, ResearchProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
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
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reset Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 2),
                  Text('Erase all local patient and surgery records', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _confirmResetDatabase(context, provider),
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('Purge All Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
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
            Text('Confirm Database Reset'),
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
    final isSeeded = provider.isMockDataSeeded;
    final count = provider.seededMockCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSeeded
              ? Colors.teal.withValues(alpha: 0.4)
              : (isDark ? AppTheme.darkBorder : Colors.grey.shade200),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clinical Research Cohort (500+)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '100% English • Aesthetic & Reconstructive',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
              // Status Badge
              Container(
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
              ),
            ],
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
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
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
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
                ),
              ],
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
            Text('Purge Mock Research Cohort?'),
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
  Widget _buildSystemInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
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
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.teal),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

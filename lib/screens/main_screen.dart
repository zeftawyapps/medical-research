import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/research_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import 'dashboard_screen.dart';
import 'sections/patients_section_screen.dart';
import 'sections/operations_section_screen.dart';
import 'sections/pre_op_section_screen.dart';
import 'sections/intra_op_section_screen.dart';
import 'sections/post_op_section_screen.dart';
import 'sections/complications_section_screen.dart';
import 'sections/labs_section_screen.dart';
import 'sections/surveys_section_screen.dart';
import 'universal_search_screen.dart';
import 'research_abstracts_screen.dart';
import 'case_intake_form_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool? _isRailExpandedOverride;

  static const List<Widget> _screens = [
    DashboardScreen(),
    PatientsSectionScreen(),
    OperationsSectionScreen(),
    PreOpSectionScreen(),
    IntraOpSectionScreen(),
    PostOpSectionScreen(),
    ComplicationsSectionScreen(),
    LabsSectionScreen(),
    SurveysSectionScreen(),
    UniversalSearchScreen(),
    ResearchAbstractsScreen(),
  ];

  static const List<String> _sectionTitles = [
    'Dashboard',
    'Patients',
    'Operations',
    'Pre-Op',
    'Intra-Op',
    'Post-Op',
    'Complications',
    'Blood Labs',
    'Surveys',
    'Search Engine',
    'Abstracts',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isWide = ResponsiveLayout.isWideDesktop(context);
    final isRailExpanded = _isRailExpandedOverride ?? isWide;

    return Scaffold(
      drawer: _buildAppDrawer(context, provider, isDark),
      appBar: AppBar(
        toolbarHeight: isMobile ? 56 : 64,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: !isDesktop
            ? Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Open Menu',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              )
            : null,
        titleSpacing: isMobile
            ? 0
            : (isDesktop ? ResponsiveLayout.horizontalPadding(context) : 8),
        title: isMobile
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MEDECTAL',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _sectionTitles[provider.currentNavIndex.clamp(
                          0,
                          _sectionTitles.length - 1,
                        )],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.biotech_rounded,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MEDECTAL',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'RESEARCH',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1.2,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Clinical Research & Surgical Registry',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          if (!isMobile) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaseIntakeFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.flash_on_rounded, size: 15),
              label: const Text('Quick Multi-Phase Intake'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              provider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: isDark ? AppTheme.alertAmber : colorScheme.onSurface.withValues(alpha: 0.7),
              size: 20,
            ),
            tooltip: provider.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () => provider.toggleTheme(),
          ),
          SizedBox(
            width: isMobile ? 8 : ResponsiveLayout.horizontalPadding(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: Row(
          children: [
            // Left Collapsible Sidebar for Desktop & Tablet
            if (isDesktop)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: theme.dividerTheme.color ??
                          colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: NavigationRail(
                  selectedIndex: provider.currentNavIndex.clamp(
                    0,
                    _screens.length - 1,
                  ),
                  onDestinationSelected: (index) => provider.setNavIndex(index),
                  extended: isRailExpanded,
                  minExtendedWidth: 230,
                  minWidth: 70,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: IconButton(
                      icon: Icon(
                        isRailExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      tooltip: isRailExpanded ? 'Collapse Sidebar' : 'Expand Sidebar',
                      onPressed: () {
                        setState(() {
                          _isRailExpandedOverride = !isRailExpanded;
                        });
                      },
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline_rounded),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: Text('1. Patients'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.medical_services_outlined),
                      selectedIcon: Icon(Icons.medical_services_rounded),
                      label: Text('2. Operations'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment_rounded),
                      label: Text('3. Pre-Op'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.precision_manufacturing_outlined),
                      selectedIcon: Icon(Icons.precision_manufacturing_rounded),
                      label: Text('4. Intra-Op'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.hotel_outlined),
                      selectedIcon: Icon(Icons.hotel_rounded),
                      label: Text('5. Post-Op'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.warning_amber_rounded),
                      selectedIcon: Icon(Icons.warning_rounded),
                      label: Text('6. Complications'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.water_drop_outlined),
                      selectedIcon: Icon(Icons.water_drop_rounded),
                      label: Text('7. Blood & Labs'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.poll_outlined),
                      selectedIcon: Icon(Icons.poll_rounded),
                      label: Text('8. Surveys'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.manage_search_rounded),
                      selectedIcon: Icon(Icons.manage_search_outlined),
                      label: Text('Search Engine'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.article_outlined),
                      selectedIcon: Icon(Icons.article_rounded),
                      label: Text('Abstracts & Templates'),
                    ),
                  ],
                ),
              ),

            // Main View Content
            Expanded(
              child: IndexedStack(
                index: provider.currentNavIndex.clamp(0, _screens.length - 1),
                children: _screens,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer(
    BuildContext context,
    ResearchProvider provider,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Brand Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [colorScheme.primary.withValues(alpha: 0.28), theme.scaffoldBackgroundColor]
                      : [colorScheme.primary.withValues(alpha: 0.15), colorScheme.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.biotech_rounded,
                      color: colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEDECTAL',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'CLINICAL RESEARCH',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SQLite Local Storage Registry',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation List Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                children: [
                  _buildDrawerTile(
                    context,
                    provider,
                    0,
                    'Dashboard Overview',
                    Icons.dashboard_rounded,
                    isDark,
                  ),

                  const SizedBox(height: 10),
                  _buildDrawerSectionHeader(context, 'CLINICAL CRUD SECTIONS', isDark),

                  _buildDrawerTile(
                    context,
                    provider,
                    1,
                    '1. Patients Registry',
                    Icons.people_rounded,
                    isDark,
                    count: provider.patients.length,
                  ),
                  _buildDrawerTile(
                    context,
                    provider,
                    2,
                    '2. Operations & Diagnosis',
                    Icons.medical_services_rounded,
                    isDark,
                    count: provider.operations.length,
                  ),
                  _buildDrawerTile(
                    context,
                    provider,
                    3,
                    '3. Pre-Op Assessments',
                    Icons.assignment_rounded,
                    isDark,
                    count: provider.preOps.length,
                  ),
                  _buildDrawerTile(
                    context,
                    provider,
                    4,
                    '4. Intra-Op Details',
                    Icons.precision_manufacturing_rounded,
                    isDark,
                    count: provider.intraOps.length,
                  ),
                  _buildDrawerTile(
                    context,
                    provider,
                    5,
                    '5. Post-Op Follow-up',
                    Icons.hotel_rounded,
                    isDark,
                    count: provider.postOps.length,
                  ),
                  _buildDrawerTile(
                    context,
                    provider,
                    6,
                    '6. Complications Tracker',
                    Icons.warning_rounded,
                    isDark,
                    count: provider.complications.length,
                  ),
                  _buildDrawerTile(
                    context,
                    provider,
                    7,
                    '7. Blood & Labs',
                    Icons.water_drop_rounded,
                    isDark,
                    count: provider.bloodLabs.length,
                  ),
                  _buildDrawerTile(
                    context,
                    provider,
                    8,
                    '8. Surveys & PROMs',
                    Icons.poll_rounded,
                    isDark,
                    count: provider.surveys.length,
                  ),

                  const SizedBox(height: 10),
                  _buildDrawerSectionHeader(context, 'SEARCH & RESEARCH', isDark),

                  _buildDrawerTile(
                    context,
                    provider,
                    9,
                    'Universal Search & Time Frame',
                    Icons.manage_search_rounded,
                    isDark,
                  ),
                  _buildDrawerTile(
                    context,
                    provider,
                    10,
                    'Abstracts & Dynamic Templates',
                    Icons.article_rounded,
                    isDark,
                    count: provider.abstracts.length,
                  ),

                  const SizedBox(height: 10),
                  _buildDrawerSectionHeader(context, 'DATABASE CONTROLS', isDark),

                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: Icon(
                      Icons.download_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    title: Text(
                      'Load Demo Surgical Data',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      'Sample multi-phase cases',
                      style: GoogleFonts.inter(fontSize: 10.5),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await provider.loadDemoData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Demo cases loaded on demand!'),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: const Icon(
                      Icons.delete_sweep_rounded,
                      color: AppTheme.alertRed,
                      size: 20,
                    ),
                    title: Text(
                      'Clear Registry (Empty DB)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.alertRed,
                      ),
                    ),
                    subtitle: Text(
                      'Reset database to clean state',
                      style: GoogleFonts.inter(fontSize: 10.5),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear All SQLite Records'),
                          content: const Text(
                            'Are you sure you want to delete all patients and operations from the local SQLite database?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.alertRed,
                              ),
                              child: const Text('Clear All Data'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await provider.clearDatabase();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Registry completely cleared (0 records).',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),

                  const Divider(height: 20),

                  // Quick Intake Action inside drawer
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: colorScheme.primary.withValues(alpha: 0.12),
                    leading: Icon(
                      Icons.flash_on_rounded,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      'Quick Multi-Phase Intake',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      'Full surgical intake form',
                      style: GoogleFonts.inter(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CaseIntakeFormScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerTheme.color ??
                        colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SQLite DB Active',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      provider.isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 18,
                      color: isDark
                          ? AppTheme.alertAmber
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    onPressed: () => provider.toggleTheme(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(BuildContext context, String title, bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context,
    ResearchProvider provider,
    int index,
    String title,
    IconData icon,
    bool isDark, {
    int? count,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = provider.currentNavIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected
            ? colorScheme.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
        ),
        trailing: count != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context); // Close Drawer
          provider.setNavIndex(index);
        },
      ),
    );
  }
}

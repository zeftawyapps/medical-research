import 'package:flutter/material.dart';
import 'package:JoDija_tamplites/JoDija_tamplites.dart' hide MainScreen;

import 'providers/research_provider.dart';
import 'screens/clinical_case_management_screen.dart';
import 'screens/clinical_query_screen.dart';
import 'screens/clinical_settings_screen.dart';
// import 'screens/main_screen.dart';
import 'widgets/database_inspector_dialog.dart';
import 'theme/app_theme.dart';

export 'config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ResearchProvider(),
      child: const MedecatResearchApp(),
    ),
  );
}

class MedecatResearchApp extends StatelessWidget {
  const MedecatResearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();

    return AdaptiveAppShell(
      key: const ValueKey('medecat-research-adaptive-shell'),
      titleApp: 'Clinical & Surgical Research',
      initRouter: '/clinical_query',
      languageCode: 'en',
      isDarkMode: provider.isDarkMode,
      lightTheme: AppTheme.getTheme(provider.selectedPalette, false),
      darkTheme: AppTheme.getTheme(provider.selectedPalette, true),
      loclizationLangs: {
        'ar': AppLocalizationsInit(),
        'en': AppLocalizationsInit(),
      },
      sidebarHeader: SidebarHeaderConfig(
        title: 'MEDECAT RESEARCH',
        logoAssetPath: 'assets/icon/app_icon.png',
        logoWidth: 36,
        logoHight: 36,
        logoRadius: BorderRadius.circular(9),
        titleStyle: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          color: provider.isDarkMode
              ? Colors.white
              : provider.currentPaletteConfig.lightTextPrimary,
        ),
        backgroundColor: Colors.transparent,
      ),
      sidebarBackgroundColor: AppTheme.getSidebarBg(
        provider.selectedPalette,
        provider.isDarkMode,
      ),
      sidebarSelectedColor: AppTheme.getSidebarSelectedColor(
        provider.selectedPalette,
        provider.isDarkMode,
      ),
      sidebarHoverColor: AppTheme.getSidebarHoverColor(
        provider.selectedPalette,
        provider.isDarkMode,
      ),
      sidebarTextColor: AppTheme.getSidebarTextColor(
        provider.selectedPalette,
        provider.isDarkMode,
      ),
      sidebarSelectedTextColor: AppTheme.getSidebarSelectedTextColor(
        provider.selectedPalette,
        provider.isDarkMode,
      ),
      sidebarIconColor: AppTheme.getSidebarIconColor(
        provider.selectedPalette,
        provider.isDarkMode,
      ),
      sidebarSelectedIconColor: AppTheme.getSidebarSelectedIconColor(
        provider.selectedPalette,
        provider.isDarkMode,
      ),
      sidebarItems: [
        RouteItem(
          id: 'clinical_query',
          path: '/clinical_query',
          label: 'Clinical Query & Search',
          icon: Icons.manage_search_rounded,
          content: ClinicalQueryScreen(key: ClinicalQueryScreen.queryKey),
          isSideBarRouted: true,
          isAppBar: true,
          actions: [
            IconButton(
              tooltip: 'Advanced Filter',
              icon: Icon(
                Icons.tune_rounded,
                color: provider.currentPaletteConfig.getPrimary(provider.isDarkMode),
              ),
              onPressed: () {
                ClinicalQueryScreen.queryKey.currentState
                    ?.openAdvancedSearchDialog();
              },
            ),
            IconButton(
              tooltip: 'Refresh Cases',
              icon: Icon(
                Icons.refresh_rounded,
                color: provider.currentPaletteConfig.getPrimary(provider.isDarkMode),
              ),
              onPressed: () {
                ClinicalQueryScreen.queryKey.currentState?.refreshCases();
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Export & Options',
              onSelected: (val) {
                if (val == 'export_excel') {
                  ClinicalQueryScreen.queryKey.currentState
                      ?.exportPatientsToExcel();
                } else if (val == 'export_csv') {
                  ClinicalQueryScreen.queryKey.currentState
                      ?.exportPatientsToCsv();
                } else if (val == 'refresh') {
                  ClinicalQueryScreen.queryKey.currentState?.refreshCases();
                } else if (val == 'advanced_filter') {
                  ClinicalQueryScreen.queryKey.currentState
                      ?.openAdvancedSearchDialog();
                } else if (val == 'upcoming_action') {
                  ClinicalQueryScreen.queryKey.currentState
                      ?.handleUpcomingAction();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem<String>(
                  value: 'export_excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_view_rounded, color: Colors.green, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Export to Excel (.xlsx)', softWrap: false),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'export_csv',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Export to CSV (.csv)', softWrap: false),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'advanced_filter',
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Advanced Filter', softWrap: false),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Refresh', softWrap: false),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'upcoming_action',
                  child: Row(
                    children: [
                      Icon(Icons.more_horiz_rounded, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Upcoming Feature', softWrap: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),

        // RouteItem(
        //   id: 'surgical_registry',
        //   path: '/surgical_registry',
        //   label: 'Surgical Registry Hub',
        //   icon: Icons.dashboard_customize_rounded,
        //   content: const MainScreen(),
        //   isSideBarRouted: true,
        //   isAppBar: false,
        // ),
        RouteItem(
          id: 'surgical_hub',
          path: '/surgical_hub',
          label: 'Case Management',
          icon: Icons.folder_shared_rounded,
          content: ClinicalCaseManagementScreen(
            key: ClinicalCaseManagementScreen.caseManagementKey,
          ),
          isSideBarRouted: true,
          isAppBar: true,
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                tooltip: 'Return to Home / Research Query',
                icon: Icon(
                  Icons.home_rounded,
                  color: provider.currentPaletteConfig.getPrimary(provider.isDarkMode),
                ),
                onPressed: () => ClinicalCaseManagementScreen.navigateToHome(ctx),
              ),
            ),
            IconButton(
              tooltip: 'Search Patients',
              icon: Icon(
                Icons.person_search_rounded,
                color: provider.currentPaletteConfig.getPrimary(provider.isDarkMode),
              ),
              onPressed: () {
                ClinicalCaseManagementScreen.caseManagementKey.currentState
                    ?.openPatientSearchDialog();
              },
            ),
            IconButton(
              tooltip: 'Register New Patient',
              icon: Icon(
                Icons.person_add_alt,
                color: provider.currentPaletteConfig.getPrimary(provider.isDarkMode),
              ),
              onPressed: () {
                ClinicalCaseManagementScreen.caseManagementKey.currentState
                    ?.openAddPatientDialog();
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More Options',
              onSelected: (val) {
                if (val == 'reset') {
                  ClinicalCaseManagementScreen.caseManagementKey.currentState
                      ?.confirmClearDatabase();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reset Database',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),

        RouteItem(
          id: 'clinical_settings',
          path: '/clinical_settings',
          label: 'Settings & Appearance',
          icon: Icons.tune_rounded,
          content: const ClinicalSettingsScreen(),
          isSideBarRouted: true,
          isAppBar: true,
          actions: [
            IconButton(
              tooltip: provider.isDarkMode
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
              icon: Icon(
                provider.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: provider.isDarkMode
                    ? Colors.amberAccent
                    : provider.currentPaletteConfig.getPrimary(false),
              ),
              onPressed: () => provider.toggleTheme(),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Settings Options',
              onSelected: (val) {
                if (val == 'inspect_db') {
                  DatabaseInspectorDialog.show(context);
                } else if (val == 'reload') {
                  provider.reloadAllData();
                } else if (val == 'toggle_theme') {
                  provider.toggleTheme();
                } else if (val == 'purge_db') {
                  ClinicalCaseManagementScreen.caseManagementKey.currentState
                      ?.confirmClearDatabase();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem<String>(
                  value: 'inspect_db',
                  child: Row(
                    children: [
                      Icon(
                        Icons.plagiarism_outlined,
                        color: Colors.teal,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text('Database Inspector'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'reload',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Reload System Stats'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'toggle_theme',
                  child: Row(
                    children: [
                      Icon(
                        provider.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        provider.isDarkMode
                            ? 'Switch to Light Mode'
                            : 'Switch to Dark Mode',
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'purge_db',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Purge All Records',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:JoDija_tamplites/JoDija_tamplites.dart';

import 'providers/research_provider.dart';
import 'screens/clinical_case_management_screen.dart';
import 'screens/clinical_query_screen.dart';
import 'screens/clinical_settings_screen.dart';
import 'theme/app_theme.dart'; // <-- السطر 8
/// متغير التحكم في إظهار أو إخفاء البيانات الوهمية (Mock Data) في شاشة الإعدادات:
/// عند تعيينه على true تظهر بطاقة توليد البيانات الوهمية، وعند false تختفي تماماً.
bool enabliMockData = true;

// Aliases للتحكم المريح
bool get isenable => enabliMockData;
set isenable(bool value) => enabliMockData = value;

bool get isEnable => enabliMockData;
set isEnable(bool value) => enabliMockData = value;

bool get enableMockData => enabliMockData;
set enableMockData(bool value) => enabliMockData = value;

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
      titleApp: 'Clinical & Surgical Research',
      initRouter: '/clinical_query',
      languageCode: 'en',
      isDarkMode: provider.isDarkMode,
      lightTheme: AppTheme.lightTheme, // <-- السطر 32
      darkTheme: AppTheme.darkTheme, // <-- السطر 33
      loclizationLangs: {
        'ar': AppLocalizationsInit(),
        'en': AppLocalizationsInit(),
      },
      sidebarBackgroundColor: const Color(0xFF0F172A),
      sidebarSelectedColor: const Color(0xFF0D9488),
      sidebarTextColor: Colors.white70,
      sidebarSelectedTextColor: Colors.white,
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Options',
              onSelected: (val) {
                if (val == 'refresh') {
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
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'advanced_filter',
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Advanced Filter', softWrap: true),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'upcoming_action',
                  child: Row(
                    children: [
                      Icon(Icons.more_horiz_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Upcoming Feature'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        RouteItem(
          id: 'surgical_hub',
          path: '/surgical_hub',
          label: 'Case Management',
          icon: Icons.health_and_safety_rounded,
          content: ClinicalCaseManagementScreen(
            key: ClinicalCaseManagementScreen.caseManagementKey,
          ),
          isSideBarRouted: true,
          isAppBar: true,
          actions: [
            IconButton(
              tooltip: 'Register New Patient',
              icon: const Icon(Icons.person_add_alt, color: Colors.tealAccent),
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
              tooltip: provider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              icon: Icon(
                provider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: provider.isDarkMode ? Colors.amberAccent : Colors.tealAccent,
              ),
              onPressed: () => provider.toggleTheme(),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Settings Options',
              onSelected: (val) {
                if (val == 'reload') {
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
                        provider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(provider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'purge_db',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 18),
                      SizedBox(width: 10),
                      Text('Purge All Records', style: TextStyle(color: Colors.red)),
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

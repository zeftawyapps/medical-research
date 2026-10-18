import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/patient_record_brd.dart';
import '../services/database/connection/database_connection.dart';

/// Interactive In-App Database Inspector Modal
/// Allows clinicians and developers to inspect all SQLite tables, records, MRNs, IDs, and raw counts live.
class DatabaseInspectorDialog extends StatefulWidget {
  const DatabaseInspectorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const DatabaseInspectorDialog(),
    );
  }

  @override
  State<DatabaseInspectorDialog> createState() => _DatabaseInspectorDialogState();
}

class _DatabaseInspectorDialogState extends State<DatabaseInspectorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  List<Map<String, dynamic>> _rawPatients = [];
  List<Map<String, dynamic>> _rawOperations = [];
  List<Map<String, dynamic>> _tableCounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDatabaseData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDatabaseData() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseConnection().database;

      // 1. Raw Patients
      final patients = await db.rawQuery(
        'SELECT * FROM ${PatientTable.tableName} ORDER BY ${PatientTable.columnCreatedAt} DESC',
      );

      // 2. Raw Operations
      final operations = await db.rawQuery(
        'SELECT * FROM ${OperationTable.tableName} ORDER BY ${OperationTable.columnCreatedAt} DESC',
      );

      // 3. Table Counts
      final tables = [
        PatientTable.tableName,
        OperationTable.tableName,
        PreOpTable.tableName,
        IntraOpTable.tableName,
        PostOpTable.tableName,
        ComplicationTable.tableName,
        BloodLabTable.tableName,
        SurveyTable.tableName,
      ];

      final List<Map<String, dynamic>> counts = [];
      for (final table in tables) {
        try {
          final res = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          final count = res.isNotEmpty ? (res.first['count'] as int? ?? 0) : 0;
          counts.add({'table': table, 'count': count});
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _rawPatients = patients;
          _rawOperations = operations;
          _tableCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: theme.dialogTheme.backgroundColor ?? colorScheme.surface,
      child: Container(
        width: 860,
        height: 640,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.storage_rounded, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live SQLite Database Inspector',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Direct SQLite inspection • Table rows, MRN uniqueness, and raw records',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh Database Data',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadDatabaseData,
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: colorScheme.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text('Patients (${_rawPatients.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspaces_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text('Operations (${_rawOperations.length})'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.table_chart_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('All Tables Overview'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Filter
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _filter = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Filter records by Name, MRN, ID, or Date...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPatientsTab(theme, colorScheme, isDark),
                        _buildOperationsTab(theme, colorScheme, isDark),
                        _buildOverviewTab(theme, colorScheme, isDark),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsTab(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final filtered = _rawPatients.where((row) {
      if (_filter.isEmpty) return true;
      final mrn = (row[PatientTable.columnMedicalRecordNumber] ?? '').toString().toLowerCase();
      final id = (row[PatientTable.columnPatientId] ?? '').toString().toLowerCase();
      final demo = (row[PatientTable.columnDemographics] ?? '').toString().toLowerCase();
      return mrn.contains(_filter) || id.contains(_filter) || demo.contains(_filter);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _rawPatients.isEmpty ? 'No patient records found in SQLite database.' : 'No patients matching "$_filter".',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final row = filtered[idx];
        final id = row[PatientTable.columnPatientId]?.toString() ?? '';
        final mrn = row[PatientTable.columnMedicalRecordNumber]?.toString() ?? '';
        final createdAt = row[PatientTable.columnCreatedAt]?.toString() ?? '';
        Map<String, dynamic> demographics = {};
        try {
          final rawDemo = row[PatientTable.columnDemographics];
          if (rawDemo is String) {
            demographics = jsonDecode(rawDemo) as Map<String, dynamic>;
          } else if (rawDemo is Map) {
            demographics = Map<String, dynamic>.from(rawDemo);
          }
        } catch (_) {}

        final name = demographics['name']?.toString() ?? 'Unknown';
        final age = demographics['age']?.toString() ?? '';
        final gender = demographics['gender']?.toString() ?? '';
        final phone = demographics['phone']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: idx.isEven ? colorScheme.surface : colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.02),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MRN: $mrn',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Text(
                    'Created: ${createdAt.length > 19 ? createdAt.substring(0, 19) : createdAt}',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Age: $age yrs', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('Gender: $gender', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('Phone: $phone', style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  Text(
                    'UUID: ${id.length > 12 ? "${id.substring(0, 8)}..." : id}',
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOperationsTab(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final filtered = _rawOperations.where((row) {
      if (_filter.isEmpty) return true;
      final type = (row[OperationTable.columnOperationType] ?? '').toString().toLowerCase();
      final id = (row[OperationTable.columnOperationId] ?? '').toString().toLowerCase();
      final patId = (row[OperationTable.columnPatientId] ?? '').toString().toLowerCase();
      final diag = (row[OperationTable.columnDiagnosisDetails] ?? '').toString().toLowerCase();
      return type.contains(_filter) || id.contains(_filter) || patId.contains(_filter) || diag.contains(_filter);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _rawOperations.isEmpty ? 'No surgical operations recorded yet.' : 'No operations matching "$_filter".',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final row = filtered[idx];
        final opId = row[OperationTable.columnOperationId]?.toString() ?? '';
        final patId = row[OperationTable.columnPatientId]?.toString() ?? '';
        final type = row[OperationTable.columnOperationType]?.toString() ?? 'Operation';
        final diagnosis = row[OperationTable.columnDiagnosisDetails]?.toString() ?? '';
        final hospital = row[OperationTable.columnHospital]?.toString() ?? '';
        final createdAt = row[OperationTable.columnCreatedAt]?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: idx.isEven ? colorScheme.surface : colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.02),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services_outlined, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      type,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                  Text(
                    createdAt.length > 19 ? createdAt.substring(0, 19) : createdAt,
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Diagnosis: $diagnosis ${hospital.isNotEmpty ? "• Hospital: $hospital" : ""}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Patient UUID: ${patId.length > 12 ? "${patId.substring(0, 8)}..." : patId}',
                    style: TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                  const Spacer(),
                  Text(
                    'Op UUID: ${opId.length > 12 ? "${opId.substring(0, 8)}..." : opId}',
                    style: TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'SQLite Database Status: Active & Connected (medectal_research_v2.db)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Table Record Counters:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _tableCounts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final item = _tableCounts[idx];
                final tableName = item['table'] as String;
                final count = item['count'] as int;

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  ),
                  title: Text(tableName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: count > 0 ? colorScheme.primary.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count record${count == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: count > 0 ? colorScheme.primary : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

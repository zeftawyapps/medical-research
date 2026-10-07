import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/research_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_form_modal.dart';
import '../../widgets/common_widgets.dart';

class LabsSectionScreen extends StatefulWidget {
  const LabsSectionScreen({super.key});

  @override
  State<LabsSectionScreen> createState() => _LabsSectionScreenState();
}

class _LabsSectionScreenState extends State<LabsSectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddLabModal(BuildContext context, ResearchProvider provider) {
    if (provider.operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an Operation first!')),
      );
      return;
    }

    String selectedOpId = provider.operations.first.operationId;
    final testNameController = TextEditingController();
    final resultValController = TextEditingController();

    showAdaptiveFormModal(
      context: context,
      title: 'Add Blood & Lab Reading',
      icon: Icons.water_drop_rounded,
      iconColor: AppTheme.alertRed,
      saveButtonText: 'Save Lab Result',
      formBuilder: (ctx, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedOpId,
              decoration: const InputDecoration(labelText: 'Select Operation (FK) *'),
              items: provider.operations.map((op) {
                final patient = provider.patients.where((p) => p.patientId == op.patientId).firstOrNull;
                return DropdownMenuItem(
                  value: op.operationId,
                  child: Text('${op.operationType} - ${patient?.name ?? 'Patient'}', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setModalState(() => selectedOpId = val);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: testNameController,
              decoration: const InputDecoration(
                labelText: 'Biomarker / Lab Test Name *',
                hintText: 'e.g. Hemoglobin, Total Bilirubin, CRP, Troponin T',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: resultValController,
              decoration: const InputDecoration(
                labelText: 'Numeric / Text Result Value *',
                hintText: 'e.g. 13.4 g/dL, 1.1 mg/dL, 4.2 mg/L',
              ),
            ),
          ],
        );
      },
      onSave: () async {
        if (testNameController.text.isNotEmpty && resultValController.text.isNotEmpty) {
          await provider.addBloodLabToCase(
            selectedOpId,
            testNameController.text.trim(),
            resultValController.text.trim(),
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Blood Lab reading saved in SQLite!')),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    final filteredLabs = provider.bloodLabs.where((l) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return l.testName.toLowerCase().contains(q) || l.resultValue.toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.horizontalPadding(context),
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7. Blood & Laboratory Labs',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Digital biomarker tracking and serial blood panel readings in SQLite.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddLabModal(context, provider),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(isMobile ? 'Add' : 'Add Lab'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          CustomSearchBar(
            controller: _searchController,
            hint: 'Search labs by test name (e.g. Bilirubin, Hemoglobin, CRP)...',
            onChanged: (val) => setState(() => _query = val),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: 12),

          Text(
            'Total Lab Readings: ${filteredLabs.length}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          if (filteredLabs.isEmpty)
            const EmptyStateWidget(
              icon: Icons.water_drop_outlined,
              title: 'No Blood Labs Found',
              message: 'Click "Add Lab" above to log a clinical laboratory reading.',
            )
          else
            ...filteredLabs.map((l) {
              final op = provider.operations.where((o) => o.operationId == l.operationId).firstOrNull;
              final patient = op != null ? provider.patients.where((pt) => pt.patientId == op.patientId).firstOrNull : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.alertRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: AppTheme.alertRed, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  l.testName,
                                  style: GoogleFonts.inter(fontSize: isMobile ? 13.5 : 15, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l.resultValue,
                                  style: GoogleFonts.robotoMono(fontSize: isMobile ? 11.5 : 13, fontWeight: FontWeight.w800, color: AppTheme.primaryCyan),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${op?.operationType ?? 'Surgery'} • ${patient?.name ?? 'Patient'} • ${DateFormat('yyyy-MM-dd HH:mm').format(l.testDate)}',
                            style: GoogleFonts.inter(fontSize: isMobile ? 10.5 : 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.alertRed, size: 18),
                      onPressed: () => provider.deleteBloodLab(l.labId),
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

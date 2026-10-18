import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/complication_catalog_model.dart';
import '../../providers/research_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_form_modal.dart';
import '../../widgets/common_widgets.dart';
import 'complication_catalog_dialog.dart';

class ComplicationsSectionScreen extends StatefulWidget {
  const ComplicationsSectionScreen({super.key});

  @override
  State<ComplicationsSectionScreen> createState() => _ComplicationsSectionScreenState();
}

class _ComplicationsSectionScreenState extends State<ComplicationsSectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _gradeFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddComplicationModal(BuildContext context, ResearchProvider provider) {
    if (provider.operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an Operation first!')),
      );
      return;
    }

    String selectedOpId = provider.operations.first.operationId;
    final descController = TextEditingController();
    final podController = TextEditingController(text: '1');
    String selectedGrade = 'Clavien-Dindo Grade II';
    final managementController = TextEditingController();

    showAdaptiveFormModal(
      context: context,
      title: 'Log Surgical Complication',
      icon: Icons.warning_amber_rounded,
      iconColor: AppTheme.alertAmber,
      saveButtonText: 'Save Complication',
      formBuilder: (ctx, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),

            // Known Complication Autocomplete with Auto-fill
            const Text(
              'Complication (Known or Custom) *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Autocomplete<ComplicationCatalogModel>(
              displayStringForOption: (option) => option.name,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return provider.complicationCatalog;
                }
                final query = textEditingValue.text.toLowerCase();
                return provider.complicationCatalog.where((c) =>
                    c.name.toLowerCase().contains(query) ||
                    c.treatment.toLowerCase().contains(query));
              },
              onSelected: (option) {
                setModalState(() {
                  descController.text = option.name;
                  managementController.text = option.treatment;
                  if (option.grade.contains('Grade I (')) {
                    selectedGrade = 'Clavien-Dindo Grade I';
                  } else if (option.grade.contains('Grade II (')) {
                    selectedGrade = 'Clavien-Dindo Grade II';
                  } else if (option.grade.contains('Grade III (')) {
                    selectedGrade = 'Clavien-Dindo Grade IIIb';
                  } else if (option.grade.contains('Grade IV (')) {
                    selectedGrade = 'Clavien-Dindo Grade IV';
                  }
                });
              },
              fieldViewBuilder: (
                context,
                fieldTextController,
                focusNode,
                onFieldSubmitted,
              ) {
                if (descController.text.isNotEmpty && fieldTextController.text.isEmpty) {
                  fieldTextController.text = descController.text;
                }
                return TextField(
                  controller: fieldTextController,
                  focusNode: focusNode,
                  onChanged: (val) => descController.text = val,
                  decoration: const InputDecoration(
                    labelText: 'Complication Description *',
                    hintText: 'Select known complication or type custom...',
                    prefixIcon: Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: podController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Post-Operative Day (POD) *',
                hintText: 'e.g. 1, 3, 7, 14',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: selectedGrade,
              decoration: const InputDecoration(labelText: 'Clavien-Dindo Severity Grade *'),
              items: const [
                DropdownMenuItem(value: 'Clavien-Dindo Grade I', child: Text('Grade I (Minor / Bedside)')),
                DropdownMenuItem(value: 'Clavien-Dindo Grade II', child: Text('Grade II (Pharmacological / POAF / ABX)')),
                DropdownMenuItem(value: 'Clavien-Dindo Grade IIIa', child: Text('Grade IIIa (Intervention no GA)')),
                DropdownMenuItem(value: 'Clavien-Dindo Grade IIIb', child: Text('Grade IIIb (Intervention with GA)')),
                DropdownMenuItem(value: 'Clavien-Dindo Grade IV', child: Text('Grade IV (ICU / Organ Failure)')),
                DropdownMenuItem(value: 'Clavien-Dindo Grade V', child: Text('Grade V (Mortality)')),
              ],
              onChanged: (val) {
                if (val != null) setModalState(() => selectedGrade = val);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: managementController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Clinical Management & Intervention *',
                hintText: 'Auto-filled or type customized treatment plan...',
              ),
            ),
          ],
        );
      },
      onSave: () async {
        if (managementController.text.isNotEmpty) {
          final desc = descController.text.trim().isNotEmpty
              ? descController.text.trim()
              : 'Surgical Complication';
          await provider.addComplicationToCase(
            selectedOpId,
            int.tryParse(podController.text.trim()) ?? 1,
            selectedGrade,
            managementController.text.trim(),
            description: desc,
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Complication recorded in SQLite!')),
            );
          }
        }
      },
    );
  }

  Color _getGradeColor(String grade, Color primaryColor, Color secondaryColor) {
    if (grade.contains('Grade I') && !grade.contains('Grade II') && !grade.contains('Grade IV') && !grade.contains('Grade V')) {
      return primaryColor;
    } else if (grade.contains('Grade II')) {
      return AppTheme.alertAmber;
    } else if (grade.contains('Grade III')) {
      return secondaryColor;
    } else {
      return AppTheme.alertRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);
    final cardBg = theme.cardTheme.color ?? colorScheme.surface;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurface.withValues(alpha: 0.65);

    final filteredComplications = provider.complications.where((c) {
      if (_gradeFilter != 'All' && !c.grade.contains(_gradeFilter)) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final op = provider.operations.where((o) => o.operationId == c.operationId).firstOrNull;
      return c.grade.toLowerCase().contains(q) ||
          c.management.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.podDay.toString().contains(q) ||
          (op != null && op.operationType.toLowerCase().contains(q));
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
                      '6. Complications Tracker',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Postoperative adverse events by POD day and Clavien-Dindo grades.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => showComplicationCatalogDialog(context, isDark),
                    icon: const Icon(Icons.menu_book_rounded, size: 15),
                    label: Text(isMobile ? 'Catalog' : 'Complications Catalog'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.alertAmber,
                      side: const BorderSide(color: AppTheme.alertAmber),
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddComplicationModal(context, provider),
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: Text(isMobile ? 'Log' : 'Log Complication'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.alertAmber,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          CustomSearchBar(
            controller: _searchController,
            hint: 'Search complications by grade, POD day, or management...',
            onChanged: (val) => setState(() => _query = val),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Grade I', 'Grade II', 'Grade III', 'Grade IV'].map((g) {
                final isSelected = _gradeFilter == g;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _gradeFilter = g);
                    },
                    selectedColor: primaryColor.withValues(alpha: 0.25),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? primaryColor : textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Total Logged Complications: ${filteredComplications.length}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          if (filteredComplications.isEmpty)
            const EmptyStateWidget(
              icon: Icons.verified_user_outlined,
              title: 'No Complications Found',
              message: 'Click "Log Complication" above to document a surgical complication.',
            )
          else
            ...filteredComplications.map((c) {
              final op = provider.operations.where((o) => o.operationId == c.operationId).firstOrNull;
              final patient = op != null ? provider.patients.where((pt) => pt.patientId == op.patientId).firstOrNull : null;
              final color = _getGradeColor(c.grade, primaryColor, colorScheme.secondary);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'POD',
                            style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
                          ),
                          Text(
                            '${c.podDay}',
                            style: GoogleFonts.inter(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.w800, color: color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  c.grade,
                                  style: GoogleFonts.inter(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.w700, color: color),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (patient != null)
                                Expanded(
                                  child: Text(
                                    patient.name,
                                    style: GoogleFonts.inter(fontSize: 11, color: textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Management: ${c.management}',
                            style: GoogleFonts.inter(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w500, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.alertRed, size: 18),
                      onPressed: () => provider.deleteComplication(c.complicationId),
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

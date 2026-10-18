import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/research_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_form_modal.dart';
import '../../widgets/common_widgets.dart';

class PreOpSectionScreen extends StatefulWidget {
  const PreOpSectionScreen({super.key});

  @override
  State<PreOpSectionScreen> createState() => _PreOpSectionScreenState();
}

class _PreOpSectionScreenState extends State<PreOpSectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddPreOpModal(BuildContext context, ResearchProvider provider) {
    if (provider.operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one Operation first!'),
        ),
      );
      return;
    }

    String selectedOpId = provider.operations.first.operationId;
    final caseDescController = TextEditingController();
    final radiologyController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    showAdaptiveFormModal(
      context: context,
      title: 'Add Pre-Op Assessment',
      icon: Icons.assignment_outlined,
      iconColor: primaryColor,
      saveButtonText: 'Save Pre-Op',
      formBuilder: (ctx, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedOpId,
              decoration: const InputDecoration(
                labelText: 'Select Operation (FK) *',
              ),
              items: provider.operations.map((op) {
                final patient = provider.patients
                    .where((p) => p.patientId == op.patientId)
                    .firstOrNull;
                return DropdownMenuItem(
                  value: op.operationId,
                  child: Text(
                    '${op.operationType} - ${patient?.name ?? 'Patient'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setModalState(() => selectedOpId = val);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: caseDescController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Clinical Case Presentation *',
                hintText:
                    'e.g. 58-year-old presenting with right upper quadrant abdominal pain...',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: radiologyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Radiology Report & Findings *',
                hintText:
                    'e.g. CT Abdomen demonstrates a 4.2 cm hypervascular lesion...',
              ),
            ),
          ],
        );
      },
      onSave: () async {
        if (caseDescController.text.isNotEmpty &&
            radiologyController.text.isNotEmpty) {
          await provider.addPreOp(
            operationId: selectedOpId,
            caseDescription: caseDescController.text.trim(),
            radiologyReports: radiologyController.text.trim(),
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Pre-Op Assessment saved into SQLite!'),
                backgroundColor: primaryColor,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final isMobile = ResponsiveLayout.isMobile(context);
    final cardBg = theme.cardTheme.color ?? colorScheme.surface;
    final borderColor = theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.25);
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurface.withValues(alpha: 0.65);

    final filteredPreOps = provider.preOps.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final op = provider.operations
          .where((o) => o.operationId == p.operationId)
          .firstOrNull;
      return p.caseDescription.toLowerCase().contains(q) ||
          p.radiologyReports.toLowerCase().contains(q) ||
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
                      '3. Pre-Op Assessments',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Baseline clinical presentations, radiology reports, and imaging.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPreOpModal(context, provider),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(isMobile ? 'Add' : 'Add Pre-Op'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          CustomSearchBar(
            controller: _searchController,
            hint: 'Search Pre-Op by notes, radiology findings, or surgery...',
            onChanged: (val) => setState(() => _query = val),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: 12),

          Text(
            'Total Pre-Op Assessments: ${filteredPreOps.length}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          if (filteredPreOps.isEmpty)
            const EmptyStateWidget(
              icon: Icons.assignment_outlined,
              title: 'No Pre-Op Assessments Found',
              message:
                  'Click "Add Pre-Op" above to record pre-operative findings.',
            )
          else
            ...filteredPreOps.map((p) {
              final op = provider.operations
                  .where((o) => o.operationId == p.operationId)
                  .firstOrNull;
              final patient = op != null
                  ? provider.patients
                        .where((pt) => pt.patientId == op.patientId)
                        .firstOrNull
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.assignment_rounded,
                              color: primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              op?.operationType ?? 'Linked Operation',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 14 : 15.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (patient != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  patient.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.alertRed,
                            size: 18,
                          ),
                          onPressed: () => provider.deletePreOp(p.preOpId),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clinical Presentation:',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.caseDescription,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Radiology Report:',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.radiologyReports,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: textSecondary,
                      ),
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

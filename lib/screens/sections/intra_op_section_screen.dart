import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/research_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_form_modal.dart';
import '../../widgets/common_widgets.dart';

class IntraOpSectionScreen extends StatefulWidget {
  const IntraOpSectionScreen({super.key});

  @override
  State<IntraOpSectionScreen> createState() => _IntraOpSectionScreenState();
}

class _IntraOpSectionScreenState extends State<IntraOpSectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddIntraOpModal(BuildContext context, ResearchProvider provider) {
    if (provider.operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an Operation first!')),
      );
      return;
    }

    String selectedOpId = provider.operations.first.operationId;
    final descController = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    showAdaptiveFormModal(
      context: context,
      title: 'Add Intra-Op Surgical Details',
      icon: Icons.precision_manufacturing_rounded,
      iconColor: primaryColor,
      saveButtonText: 'Save Intra-Op',
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
              controller: descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Intra-Operative Steps & Findings *',
                hintText: 'e.g. Four-arm robotic approach, intraoperative ultrasound localization, parenchymal transection...',
              ),
            ),
          ],
        );
      },
      onSave: () async {
        if (descController.text.isNotEmpty) {
          await provider.addIntraOp(
            operationId: selectedOpId,
            description: descController.text.trim(),
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Intra-Op Record saved into SQLite!'),
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

    final filteredIntraOps = provider.intraOps.where((i) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final op = provider.operations.where((o) => o.operationId == i.operationId).firstOrNull;
      return i.operationDescription.toLowerCase().contains(q) ||
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
                      '4. Intra-Op Details',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Operative techniques, field steps, and surgical notes.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddIntraOpModal(context, provider),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(isMobile ? 'Add' : 'Add Intra-Op'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          CustomSearchBar(
            controller: _searchController,
            hint: 'Search Intra-Op by technique, findings, or surgery...',
            onChanged: (val) => setState(() => _query = val),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: 12),

          Text(
            'Total Intra-Op Records: ${filteredIntraOps.length}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          if (filteredIntraOps.isEmpty)
            const EmptyStateWidget(
              icon: Icons.precision_manufacturing_outlined,
              title: 'No Intra-Op Records Found',
              message: 'Click "Add Intra-Op" above to record surgical notes.',
            )
          else
            ...filteredIntraOps.map((i) {
              final op = provider.operations.where((o) => o.operationId == i.operationId).firstOrNull;
              final patient = op != null ? provider.patients.where((pt) => pt.patientId == op.patientId).firstOrNull : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.precision_manufacturing_rounded, color: colorScheme.secondary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              op?.operationType ?? 'Linked Operation',
                              style: GoogleFonts.inter(fontSize: isMobile ? 14 : 15.5, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                            const SizedBox(width: 6),
                            if (patient != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  patient.name,
                                  style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: primaryColor),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.alertRed, size: 18),
                          onPressed: () => provider.deleteIntraOp(i.intraOpId),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Operative Description & Steps:',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      i.operationDescription,
                      style: GoogleFonts.inter(fontSize: isMobile ? 11.5 : 13, color: textSecondary),
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

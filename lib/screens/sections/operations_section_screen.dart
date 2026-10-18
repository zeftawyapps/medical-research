import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/research_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_form_modal.dart';
import '../../widgets/common_widgets.dart';

class OperationsSectionScreen extends StatefulWidget {
  const OperationsSectionScreen({super.key});

  @override
  State<OperationsSectionScreen> createState() =>
      _OperationsSectionScreenState();
}

class _OperationsSectionScreenState extends State<OperationsSectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOperationModal(BuildContext context, ResearchProvider provider) {
    if (provider.patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one patient in the Patients section first!',
          ),
        ),
      );
      return;
    }

    String selectedPatientId = provider.patients.first.patientId;
    final opTypeController = TextEditingController();
    final diagnosisController = TextEditingController();
    DateTime opDate = DateTime.now();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    showAdaptiveFormModal(
      context: context,
      title: 'Add Operation & Diagnosis',
      icon: Icons.medical_services_outlined,
      iconColor: primaryColor,
      saveButtonText: 'Save Operation',
      formBuilder: (ctx, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedPatientId,
              decoration: const InputDecoration(
                labelText: 'Select Patient (FK) *',
              ),
              items: provider.patients.map((p) {
                return DropdownMenuItem(
                  value: p.patientId,
                  child: Text(
                    '${p.name} (${p.medicalRecordNumber})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setModalState(() => selectedPatientId = val);
              },
            ),
            const SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (textVal) {
                final existingNames = provider.operations
                    .map((o) => o.operationType)
                    .toSet()
                    .toList();

                if (textVal.text.isEmpty) return existingNames;
                final q = textVal.text.toLowerCase();
                return existingNames.where(
                  (name) => name.toLowerCase().contains(q),
                );
              },
              onSelected: (selectedName) {
                setModalState(() {
                  opTypeController.text = selectedName;
                });
              },
              fieldViewBuilder: (ctx, fieldCtrl, fNode, _) {
                fieldCtrl.text = opTypeController.text;
                return TextField(
                  controller: fieldCtrl,
                  focusNode: fNode,
                  onChanged: (v) => opTypeController.text = v,
                  decoration: const InputDecoration(
                    labelText: 'Operation Name & Type *',
                    hintText:
                        'e.g. Laparoscopic Cholecystectomy, Appendectomy...',
                    prefixIcon: Icon(Icons.healing),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: diagnosisController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Diagnosis Details *',
                hintText: 'e.g. Colorectal Liver Metastasis',
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: opDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setModalState(() => opDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Operation Date'),
                child: Text(DateFormat('yyyy-MM-dd').format(opDate)),
              ),
            ),
          ],
        );
      },
      onSave: () async {
        if (opTypeController.text.isNotEmpty &&
            diagnosisController.text.isNotEmpty) {
          await provider.addOperation(
            patientId: selectedPatientId,
            operationType: opTypeController.text.trim(),
            diagnosis: diagnosisController.text.trim(),
            operationDate: opDate,
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Operation saved into SQLite database!'),
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

    final filteredOps = provider.operations.where((op) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final patient = provider.patients
          .where((p) => p.patientId == op.patientId)
          .firstOrNull;
      return op.operationType.toLowerCase().contains(q) ||
          op.diagnosisDetails.toLowerCase().contains(q) ||
          (patient != null &&
              (patient.name.toLowerCase().contains(q) ||
                  patient.medicalRecordNumber.toLowerCase().contains(q)));
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
                      '2. Operations & Diagnosis',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Link surgical procedures, dates, and primary diagnoses with patients.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddOperationModal(context, provider),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(isMobile ? 'Add' : 'Add Operation'),
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
            hint:
                'Search operations by procedure, diagnosis, or patient name...',
            onChanged: (val) => setState(() => _query = val),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: 12),

          Text(
            'Total Operations: ${filteredOps.length}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          if (filteredOps.isEmpty)
            const EmptyStateWidget(
              icon: Icons.medical_services_outlined,
              title: 'No Operations Found',
              message:
                  'Click "Add Operation" above to link a surgery with a patient.',
            )
          else
            ...filteredOps.map((op) {
              final patient = provider.patients
                  .where((p) => p.patientId == op.patientId)
                  .firstOrNull;

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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.medical_information_rounded,
                        color: colorScheme.secondary,
                        size: 20,
                      ),
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
                                  op.operationType,
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 14.5 : 16,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(op.createdAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Patient: ${patient?.name ?? 'Unknown'} (${patient?.medicalRecordNumber ?? 'N/A'})',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 11.5 : 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Diagnosis: ${op.diagnosisDetails}',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 11.5 : 12.5,
                              color: textSecondary,
                            ),
                          ),
                          if (op.hospital.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_hospital_rounded,
                                  size: 13,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  op.hospital,
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.alertRed,
                        size: 18,
                      ),
                      tooltip: 'Delete Operation',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Operation'),
                            content: const Text(
                              'Are you sure you want to delete this operation?',
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
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          provider.deleteOperation(op.operationId);
                        }
                      },
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

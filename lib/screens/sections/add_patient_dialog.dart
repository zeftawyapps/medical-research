import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/patient_record_brd.dart';
import '../../services/database/clinical_repository.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/country_picker_field.dart';

/// Opens the Add New Patient dialog in a modal window.
Future<PatientModel?> openAddPatientDialog({
  required BuildContext context,
  required ClinicalRepository repository,
  required List<PatientModel> existingPatients,
  Future<void> Function(PatientModel newPatient)? onPatientAdded,
}) {
  return showDialog<PatientModel>(
    context: context,
    builder: (ctx) => AddPatientDialog(
      repository: repository,
      existingPatients: existingPatients,
      onPatientAdded: onPatientAdded,
    ),
  );
}

/// Standalone Add Patient Dialog with auto MRN, DOB picker, calculated age, and Wrap layout.
class AddPatientDialog extends StatefulWidget {
  final ClinicalRepository repository;
  final List<PatientModel> existingPatients;
  final Future<void> Function(PatientModel newPatient)? onPatientAdded;

  const AddPatientDialog({
    super.key,
    required this.repository,
    required this.existingPatients,
    this.onPatientAdded,
  });

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _mrnController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  DateTime _dob = DateTime(1995, 5, 20);
  String _gender = 'Female';
  String? _country;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _mrnController = TextEditingController(text: _generateUniqueMRN());
    _phoneController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mrnController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Generate a guaranteed unique Medical Record Number (MRN)
  String _generateUniqueMRN() {
    final now = DateTime.now();
    final year = now.year;
    final index = widget.existingPatients.length + 1;
    String candidate = 'MRN-$year-${index.toString().padLeft(4, '0')}';

    int attempt = 1;
    while (widget.existingPatients.any(
      (p) =>
          p.medicalRecordNumber.trim().toUpperCase() == candidate.toUpperCase(),
    )) {
      final rand = Random().nextInt(9000) + 1000;
      candidate =
          'MRN-$year-${(index + attempt).toString().padLeft(4, '0')}-$rand';
      attempt++;
    }
    return candidate;
  }

  // Calculate patient age from birth date
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final mrn = _mrnController.text.trim();

    if (name.isEmpty || mrn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter full patient name')),
      );
      return;
    }

    if (widget.existingPatients.any(
      (p) => p.medicalRecordNumber.trim().toUpperCase() == mrn.toUpperCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medical Record Number already exists. Regenerating...',
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _mrnController.text = _generateUniqueMRN();
      });
      return;
    }

    setState(() => _isSaving = true);

    try {
      const uuid = Uuid();
      final calculatedAge = _calculateAge(_dob);
      final newPatient = PatientModel(
        patientId: uuid.v4(),
        medicalRecordNumber: mrn,
        demographics: {
          'name': name,
          'date_of_birth': DateFormat('yyyy-MM-dd').format(_dob),
          'dob': DateFormat('yyyy-MM-dd').format(_dob),
          'age': calculatedAge,
          'gender': _gender,
          'country': _country ?? '',
          'notes': _notesController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
        createdAt: DateTime.now(),
      );

      await widget.repository.insertPatient(newPatient);

      if (mounted) {
        Navigator.pop(context, newPatient);
        if (widget.onPatientAdded != null) {
          await widget.onPatientAdded!(newPatient);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isCompactHeight = mediaQuery.size.height < 550;
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final isUltraCompact = (isLandscape || isCompactHeight) && isKeyboardOpen;
    final isNarrow = mediaQuery.size.width < 420;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isUltraCompact ? 8 : (isNarrow ? 12 : 24),
        vertical: isUltraCompact ? 4 : (isLandscape ? 8 : 24),
      ),
      titlePadding: EdgeInsets.fromLTRB(
        18,
        isUltraCompact ? 8 : 16,
        18,
        isUltraCompact ? 6 : 10,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isUltraCompact ? 14 : 20,
        vertical: 8,
      ),
      title: Row(
        children: [
          Icon(
            Icons.person_add_alt_1_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Add New Patient',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (isUltraCompact) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text(
                'Save',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final isNarrow = maxWidth < 420;
              final halfWidth = isNarrow ? maxWidth : (maxWidth - 12) / 2;
              final dobWidth = isNarrow ? maxWidth : (maxWidth - 12) * 0.62;
              final ageWidth = isNarrow ? maxWidth : (maxWidth - 12) * 0.38;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Auto-generated unique medical record (Read-Only)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _mrnController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Patient ID (MRN) *',
                      prefixIcon: Icon(
                        Icons.pin_outlined,
                        color: colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Regenerate Unique Patient ID (MRN)',
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _mrnController.text = _generateUniqueMRN();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    scrollPadding: ResponsiveLayout.textFieldScrollPadding(
                      context,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Full Patient Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Birth Date (DOB) & Age under Wrap (NOT Row)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: dobWidth,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dob,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _dob = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Birth Date (DOB) *',
                              prefixIcon: Icon(Icons.cake_outlined, size: 18),
                              suffixIcon: Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                              ),
                            ),
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(_dob),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: ageWidth,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Age (Auto)',
                            prefixIcon: Icon(
                              Icons.access_time_rounded,
                              size: 18,
                            ),
                            suffixText: 'yrs',
                          ),
                          child: Text(
                            '${_calculateAge(_dob)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Gender & Phone under Wrap (NOT Row)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: halfWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(
                              Icons.transgender_rounded,
                              size: 18,
                            ),
                          ),
                          items: ['Male', 'Female']
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _gender = v);
                          },
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: TextField(
                          keyboardType: TextInputType.phone,
                          controller: _phoneController,
                          scrollPadding:
                              ResponsiveLayout.textFieldScrollPadding(context),
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Country Selector (Optional with flags)
                  CountryPickerField(
                    selectedCountry: _country,
                    onCountryChanged: (c) => setState(() => _country = c),
                    labelText: 'Country (Optional)',
                    hintText: 'Select Country (Optional)',
                  ),
                  const SizedBox(height: 12),
                  // Notes Field (Optional)
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    scrollPadding: ResponsiveLayout.textFieldScrollPadding(
                      context,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Any special notes, allergy alerts, history...',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  if (!isUltraCompact) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    // Cancel & Add Patient buttons under SingleChildScrollView
                    if (isNarrow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 1,
                            ),
                            onPressed: _isSaving ? null : _submit,
                            icon: _isSaving
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 18,
                                  ),
                            label: const Text(
                              'Add Patient',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Cancel'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Cancel'),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 1,
                              ),
                              onPressed: _isSaving ? null : _submit,
                              icon: _isSaving
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 18,
                                    ),
                              label: const Text(
                                'Add Patient',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

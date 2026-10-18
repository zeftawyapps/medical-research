import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/research_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_form_modal.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/country_picker_field.dart';
import '../../data/countries_data.dart';

class PatientsSectionScreen extends StatefulWidget {
  const PatientsSectionScreen({super.key});

  @override
  State<PatientsSectionScreen> createState() => _PatientsSectionScreenState();
}

class _PatientsSectionScreenState extends State<PatientsSectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddPatientModal(BuildContext context, ResearchProvider provider) {
    final year = DateTime.now().year;
    int maxNum = 0;
    final regex = RegExp(r'MRN-\d{4}-(\d+)', caseSensitive: false);
    for (final p in provider.patients) {
      final m = regex.firstMatch(p.medicalRecordNumber);
      if (m != null) {
        final n = int.tryParse(m.group(1) ?? '0') ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    int candidateIndex = maxNum + 1;
    if (candidateIndex <= provider.patients.length) candidateIndex = provider.patients.length + 1;
    String candidateMrn = 'MRN-$year-${candidateIndex.toString().padLeft(4, '0')}';
    while (provider.patients.any((p) => p.medicalRecordNumber.trim().toUpperCase() == candidateMrn.toUpperCase())) {
      candidateIndex++;
      candidateMrn = 'MRN-$year-${candidateIndex.toString().padLeft(4, '0')}';
    }
    final mrnController = TextEditingController(text: candidateMrn);
    final nameController = TextEditingController();
    int calculateAge(DateTime dob) {
      final now = DateTime.now();
      int calculatedAge = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        calculatedAge--;
      }
      return calculatedAge >= 0 ? calculatedAge : 0;
    }

    DateTime? selectedDob = DateTime(1995, 5, 20);
    final dobController = TextEditingController(text: '1995-05-20');
    final ageController = TextEditingController(
      text: '${calculateAge(selectedDob)}',
    );
    String gender = 'Male';
    String bloodGroup = 'O+';
    String? country;
    final phoneController = TextEditingController();
    final notesController = TextEditingController();
    final bmiController = TextEditingController(text: '24.5');
    String asaScore = 'ASA II';

    void updateDob(
      DateTime picked,
      void Function(void Function()) setModalState,
    ) {
      setModalState(() {
        selectedDob = picked;
        dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        ageController.text = calculateAge(picked).toString();
      });
    }

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    showAdaptiveFormModal(
      context: context,
      title: 'Add New Patient',
      icon: Icons.person_add_alt_1_rounded,
      iconColor: primaryColor,
      saveButtonText: 'Save Patient',
      formBuilder: (ctx, setModalState) {
        Widget buildDobField() {
          return InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: selectedDob ?? DateTime(1985, 1, 1),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                updateDob(picked, setModalState);
              }
            },
            child: IgnorePointer(
              child: TextField(
                controller: dobController,
                decoration: InputDecoration(
                  labelText: 'Birth Date (DOB) *',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.cake_outlined, color: primaryColor, size: 18),
                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                ),
              ),
            ),
          );
        }

        Widget buildAgeField() {
          return TextField(
            controller: ageController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Age (Calculated)',
              hintText: 'Auto',
              suffixText: 'yrs',
              prefixIcon: Icon(Icons.access_time_rounded, color: primaryColor, size: 18),
            ),
          );
        }

        Widget buildGenderField() {
          return DropdownButtonFormField<String>(
            initialValue: gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
            ],
            onChanged: (val) {
              if (val != null) setModalState(() => gender = val);
            },
          );
        }

        Widget buildBloodGroupField() {
          return DropdownButtonFormField<String>(
            initialValue: bloodGroup,
            decoration: const InputDecoration(labelText: 'Blood Group'),
            items: const [
              DropdownMenuItem(value: 'O+', child: Text('O+')),
              DropdownMenuItem(value: 'O-', child: Text('O-')),
              DropdownMenuItem(value: 'A+', child: Text('A+')),
              DropdownMenuItem(value: 'A-', child: Text('A-')),
              DropdownMenuItem(value: 'B+', child: Text('B+')),
              DropdownMenuItem(value: 'B-', child: Text('B-')),
              DropdownMenuItem(value: 'AB+', child: Text('AB+')),
              DropdownMenuItem(value: 'AB-', child: Text('AB-')),
            ],
            onChanged: (val) {
              if (val != null) setModalState(() => bloodGroup = val);
            },
          );
        }

        Widget buildPhoneField() {
          return TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g. +1 (555) 000-0000',
            ),
          );
        }

        Widget buildBmiField() {
          return TextField(
            controller: bmiController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
            decoration: const InputDecoration(
              labelText: 'BMI (Body Mass Index)',
            ),
          );
        }

        Widget buildAsaField() {
          return DropdownButtonFormField<String>(
            initialValue: asaScore,
            decoration: const InputDecoration(
              labelText: 'ASA Physical Status Score',
            ),
            items: const [
              DropdownMenuItem(
                value: 'ASA I',
                child: Text('ASA I (Normal Healthy)'),
              ),
              DropdownMenuItem(
                value: 'ASA II',
                child: Text('ASA II (Mild Systemic Disease)'),
              ),
              DropdownMenuItem(
                value: 'ASA III',
                child: Text('ASA III (Severe Systemic Disease)'),
              ),
              DropdownMenuItem(
                value: 'ASA IV',
                child: Text('ASA IV (Life-threatening Disease)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setModalState(() => asaScore = val);
            },
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isLandscapeKeyboard =
                MediaQuery.of(context).orientation == Orientation.landscape &&
                MediaQuery.of(context).viewInsets.bottom > 0;
            final isMultiColumn =
                constraints.maxWidth >= 480 && !isLandscapeKeyboard;

            if (isMultiColumn) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: mrnController,
                          decoration: const InputDecoration(
                            labelText: 'MRN (Auto Sequential) *',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: buildDobField()),
                      const SizedBox(width: 12),
                      Expanded(child: buildAgeField()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: buildGenderField()),
                      const SizedBox(width: 12),
                      Expanded(child: buildBloodGroupField()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CountryPickerField(
                          selectedCountry: country,
                          onCountryChanged: (val) {
                            setModalState(() => country = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: buildPhoneField()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: buildBmiField()),
                      const SizedBox(width: 12),
                      Expanded(child: buildAsaField()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    scrollPadding: ResponsiveLayout.textFieldScrollPadding(
                      context,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Clinical Baseline Notes',
                    ),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: mrnController,
                  decoration: const InputDecoration(
                    labelText: 'Medical Record Number (MRN) *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                ),
                const SizedBox(height: 10),
                buildDobField(),
                const SizedBox(height: 10),
                buildAgeField(),
                const SizedBox(height: 10),
                buildGenderField(),
                const SizedBox(height: 10),
                buildBloodGroupField(),
                const SizedBox(height: 10),
                CountryPickerField(
                  selectedCountry: country,
                  onCountryChanged: (val) {
                    setModalState(() => country = val);
                  },
                ),
                const SizedBox(height: 10),
                buildPhoneField(),
                const SizedBox(height: 10),
                buildBmiField(),
                const SizedBox(height: 10),
                buildAsaField(),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  scrollPadding: ResponsiveLayout.textFieldScrollPadding(
                    context,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Clinical Baseline Notes',
                  ),
                ),
              ],
            );
          },
        );
      },
      onSave: () async {
        if (mrnController.text.trim().isEmpty ||
            nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please provide both Patient Name and MRN.'),
            ),
          );
          return;
        }

        final parsedAge =
            int.tryParse(ageController.text) ??
            calculateAge(selectedDob ?? DateTime(1990, 1, 1));
        final finalDob =
            selectedDob != null
                ? DateFormat('yyyy-MM-dd').format(selectedDob!)
                : dobController.text.trim();

        await provider.addPatient(
          mrn: mrnController.text.trim(),
          name: nameController.text.trim(),
          age: parsedAge,
          gender: gender,
          bloodGroup: bloodGroup,
          country: country ?? '',
          phone: phoneController.text.trim(),
          notes: notesController.text.trim(),
          dateOfBirth: finalDob,
          bmi: bmiController.text.trim().isNotEmpty ? bmiController.text.trim() : '24.5',
          asaScore: asaScore,
        );

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Patient "${nameController.text.trim()}" successfully registered.',
              ),
              backgroundColor: primaryColor,
            ),
          );
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

    final filteredPatients = provider.patients.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.medicalRecordNumber.toLowerCase().contains(q) ||
          p.gender.toLowerCase().contains(q) ||
          p.phone.toLowerCase().contains(q) ||
          p.bloodGroup.toLowerCase().contains(q);
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
          // Section Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Patients Registry',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage patient demographics, unique MRN, and baseline profiles.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddPatientModal(context, provider),
                icon: const Icon(Icons.person_add_rounded, size: 15),
                label: Text(isMobile ? 'Add' : 'Add Patient'),
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

          // Search Bar
          CustomSearchBar(
            controller: _searchController,
            hint: 'Search patients by Name, MRN, Gender, Blood Group...',
            onChanged: (val) => setState(() => _query = val),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: 12),

          // Counter Badge
          Text(
            'Total Registered Patients: ${filteredPatients.length}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Patients List Cards
          if (filteredPatients.isEmpty)
            const EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: 'No Patients Found',
              message:
                  'Click "Add Patient" above to register a patient record.',
            )
          else
            ...filteredPatients.map((p) {
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
                  children: [
                    Container(
                      width: isMobile ? 38 : 44,
                      height: isMobile ? 38 : 44,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.name.isNotEmpty
                            ? p.name.substring(0, 1).toUpperCase()
                            : 'P',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 15 : 18,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: GoogleFonts.inter(
                                    fontSize: isMobile ? 14 : 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
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
                                  p.medicalRecordNumber,
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Builder(
                            builder: (context) {
                              final countryObj = findCountry(p.country);
                              final countryDisplay = countryObj != null
                                  ? ' • ${countryObj.flag} ${countryObj.nameEn}'
                                  : (p.country.isNotEmpty ? ' • 🌐 ${p.country}' : '');
                              return Text(
                                'Age: ${p.age}y • Gender: ${p.gender}$countryDisplay • Blood: ${p.bloodGroup} • Phone: ${p.phone} • Date: ${DateFormat('yyyy-MM-dd').format(p.createdAt)}',
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 11 : 12,
                                  color: textSecondary,
                                ),
                              );
                            },
                          ),
                          if (p.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '📝 Notes: ${p.notes}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: textSecondary,
                              ),
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
                      tooltip: 'Delete Patient',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Patient'),
                            content: Text(
                              'Are you sure you want to delete ${p.name} (${p.medicalRecordNumber})?',
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
                          provider.deletePatient(p.patientId);
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

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
    final mrnController = TextEditingController(
      text: 'MRN-2026-${1000 + DateTime.now().millisecond}',
    );
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

    showAdaptiveFormModal(
      context: context,
      title: 'Add New Patient',
      icon: Icons.person_add_alt_1_rounded,
      iconColor: AppTheme.primaryCyan,
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
                decoration: const InputDecoration(
                  labelText: 'Birth Date (DOB) *',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.primaryCyan, size: 18),
                  suffixIcon: Icon(Icons.calendar_today_rounded, size: 16),
                ),
              ),
            ),
          );
        }

        Widget buildAgeField() {
          return TextField(
            controller: ageController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Age (Calculated)',
              hintText: 'Auto',
              suffixText: 'yrs',
              prefixIcon: Icon(Icons.access_time_rounded, color: AppTheme.primaryCyan, size: 18),
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
                child: Text('ASA II (Mild Disease)'),
              ),
              DropdownMenuItem(
                value: 'ASA III',
                child: Text('ASA III (Severe Disease)'),
              ),
              DropdownMenuItem(
                value: 'ASA IV',
                child: Text('ASA IV (Life Threat)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setModalState(() => asaScore = val);
            },
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final isSmall = maxWidth < 480;
            final halfWidth = isSmall ? maxWidth : (maxWidth - 12) / 2;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: halfWidth,
                      child: TextField(
                        controller: mrnController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Patient ID (MRN) *',
                          helperText: 'Auto-generated unique record (Read-Only)',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: halfWidth,
                      child: TextField(
                        controller: nameController,
                        scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                        decoration: const InputDecoration(
                          labelText: 'Patient Full Name *',
                          hintText: 'e.g. Robert Henderson',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isSmall ? maxWidth : (maxWidth - 12) * 0.6,
                      child: buildDobField(),
                    ),
                    SizedBox(
                      width: isSmall ? maxWidth : (maxWidth - 12) * 0.4,
                      child: buildAgeField(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: halfWidth,
                      child: buildGenderField(),
                    ),
                    SizedBox(
                      width: halfWidth,
                      child: buildBloodGroupField(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: halfWidth,
                      child: buildPhoneField(),
                    ),
                    SizedBox(
                      width: halfWidth,
                      child: buildBmiField(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: maxWidth,
                      child: buildAsaField(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CountryPickerField(
                  selectedCountry: country,
                  onCountryChanged: (val) => setModalState(() => country = val),
                  labelText: 'Country (Optional)',
                  hintText: 'Select Country (Optional)',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Patient remarks, allergies, clinical notes...',
                    prefixIcon: Icon(
                      Icons.note_alt_outlined,
                      color: AppTheme.primaryCyan,
                      size: 18,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onSave: () async {
        if (mrnController.text.isNotEmpty && nameController.text.isNotEmpty) {
          await provider.addPatient(
            mrn: mrnController.text.trim(),
            name: nameController.text.trim(),
            dateOfBirth: selectedDob != null
                ? DateFormat('yyyy-MM-dd').format(selectedDob!)
                : dobController.text.trim(),
            age: int.tryParse(ageController.text.trim()) ?? 0,
            gender: gender,
            bloodGroup: bloodGroup,
            phone: phoneController.text.trim(),
            country: country,
            notes: notesController.text.trim(),
            bmi: bmiController.text.trim(),
            asaScore: asaScore,
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Patient ${nameController.text} saved ')),
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

    final filteredPatients = provider.patients.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.medicalRecordNumber.toLowerCase().contains(q) ||
          p.country.toLowerCase().contains(q) ||
          p.notes.toLowerCase().contains(q) ||
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
                        color: isDark
                            ? Colors.white
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage patient demographics, unique MRN, and baseline profiles.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
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
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.black,
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
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
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
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isMobile ? 38 : 44,
                      height: isMobile ? 38 : 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.15),
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
                          color: AppTheme.primaryCyan,
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
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.lightTextPrimary,
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
                                  color: AppTheme.primaryCyan.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.medicalRecordNumber,
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryCyan,
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
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
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
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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

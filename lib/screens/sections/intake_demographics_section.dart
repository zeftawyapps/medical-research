import 'package:flutter/material.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/country_picker_field.dart';
import 'intake_section_card.dart';

class IntakeDemographicsSection extends StatelessWidget {
  final TextEditingController mrnController;
  final TextEditingController nameController;
  final TextEditingController dobController;
  final TextEditingController ageController;
  final TextEditingController phoneController;
  final TextEditingController notesController;
  final String gender;
  final String? country;
  final DateTime? dob;
  final ValueChanged<DateTime> onDobSelected;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String?> onCountryChanged;
  final bool isDark;

  const IntakeDemographicsSection({
    super.key,
    required this.mrnController,
    required this.nameController,
    required this.dobController,
    required this.ageController,
    required this.phoneController,
    required this.notesController,
    required this.gender,
    required this.country,
    required this.dob,
    required this.onDobSelected,
    required this.onGenderChanged,
    required this.onCountryChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntakeSectionCard(
      title: '1. Patient Demographics & Identification',
      icon: Icons.person_outline_rounded,
      isDark: isDark,
      children: [
        // Row 1: MRN and Name
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: mrnController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Patient ID (MRN) *',
                  hintText: 'Auto-generated',
                  prefixIcon: Icon(Icons.badge_outlined, size: 18),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'MRN is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: nameController,
                scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                decoration: const InputDecoration(
                  labelText: 'Patient Full Name *',
                  prefixIcon: Icon(Icons.person_rounded, size: 18),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Patient Name is required'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 2: DOB, Age, Gender, Phone
        Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dob ?? DateTime(1985, 1, 1),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    onDobSelected(picked);
                  }
                },
                child: IgnorePointer(
                  child: TextFormField(
                    controller: dobController,
                    decoration: const InputDecoration(
                      labelText: 'Birth Date (DOB) *',
                      hintText: 'YYYY-MM-DD',
                      suffixIcon: Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: ageController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Age (Calculated)',
                  hintText: 'Auto',
                  suffixText: 'yrs',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) onGenderChanged(val);
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  prefixIcon: Icon(Icons.phone_rounded, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 3: Country (Optional with all countries & flags)
        CountryPickerField(
          selectedCountry: country,
          onCountryChanged: onCountryChanged,
          labelText: 'Country (Optional)',
          hintText: 'Select Country (Optional)',
          isDark: isDark,
        ),
        const SizedBox(height: 14),

        // Row 4: Notes
        TextFormField(
          controller: notesController,
          maxLines: 2,
          scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Allergies, chronic conditions, special remarks...',
            prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../data/countries_data.dart';

/// A streamlined Dropdown List of countries requested for the clinical research portal:
/// - Primary: Egypt, Saudi Arabia, UAE, Kuwait
/// - Additional frequent: Qatar, Bahrain, USA, Europe, Other
class CountryPickerField extends StatelessWidget {
  final String? selectedCountry;
  final ValueChanged<String?> onCountryChanged;
  final String labelText;
  final String hintText;
  final bool isDark;

  const CountryPickerField({
    super.key,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.labelText = 'Country (Optional)',
    this.hintText = 'Select Country (Optional)',
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final textSecondary = colorScheme.onSurface.withValues(alpha: 0.65);

    // Resolve matching country from English/Arabic name or code
    final matchedCountry = findCountry(selectedCountry);
    final selectedValue = matchedCountry?.nameEn;

    final dropdownItems = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text(
          'None (Optional)',
          style: TextStyle(
            color: textSecondary,
            fontStyle: FontStyle.italic,
            fontSize: 13.5,
          ),
        ),
      ),
      ...worldCountries.map((country) {
        return DropdownMenuItem<String?>(
          value: country.nameEn,
          child: Row(
            children: [
              Text(
                country.flag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        country.nameEn,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: country.isPrimary ? FontWeight.w600 : FontWeight.normal,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (country.nameAr.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '(${country.nameAr})',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (country.isPrimary)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Main',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    ];

    // Fallback: If existing data contains a country outside the streamlined list, include it
    if (selectedValue != null && !worldCountries.any((c) => c.nameEn == selectedValue)) {
      dropdownItems.add(
        DropdownMenuItem<String?>(
          value: selectedValue,
          child: Row(
            children: [
              Text(matchedCountry?.flag ?? '🌐', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  matchedCountry?.label ?? selectedValue,
                  style: TextStyle(fontSize: 13.5, color: colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: selectedValue,
      isExpanded: true,
      menuMaxHeight: 380,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(
          Icons.public_rounded,
          size: 20,
          color: primaryColor,
        ),
      ),
      items: dropdownItems,
      onChanged: (val) {
        onCountryChanged(val);
      },
    );
  }
}

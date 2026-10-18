import 'package:flutter/material.dart';
import '../../models/patient_model.dart';
import '../../data/countries_data.dart';

/// Patient Profile Header & Quick Switcher widget for Clinical Case Management
class PatientProfileHeader extends StatelessWidget {
  final PatientModel? selectedPatient;
  final bool hasPatients;
  final bool isDark;
  final VoidCallback onFindPatient;
  final VoidCallback onNewPatient;
  final VoidCallback onChangePatient;
  final VoidCallback? onEditPatient;
  final VoidCallback onAddOperation;

  const PatientProfileHeader({
    super.key,
    required this.selectedPatient,
    required this.hasPatients,
    required this.isDark,
    required this.onFindPatient,
    required this.onNewPatient,
    required this.onChangePatient,
    this.onEditPatient,
    required this.onAddOperation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (selectedPatient == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.dividerTheme.color ??
                colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line 1: Heading
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person_search_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No Patient Selected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Line 2: Details
            Text(
              'Search for a patient or register a new one to manage surgical cases.',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            // Line 3: Action Buttons
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (hasPatients)
                  OutlinedButton.icon(
                    onPressed: onFindPatient,
                    icon: const Icon(Icons.search, size: 15),
                    label: const Text(
                      'Find Patient',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: onNewPatient,
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text(
                    'New Patient +',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final p = selectedPatient!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerTheme.color ??
              colorScheme.outline.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line 1: Patient Name alone (Completely separated from MRN and other metadata)
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  p.name.isNotEmpty
                      ? p.name.substring(0, 1).toUpperCase()
                      : 'P',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Line 2: Details alone (Demographic Badges including MRN)
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildDemographicBadge(
                context: context,
                icon: Icons.tag_rounded,
                label: 'MRN',
                value: p.medicalRecordNumber,
              ),
              _buildDemographicBadge(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'DOB',
                value: p.dateOfBirth ?? 'Not set',
              ),
              _buildDemographicBadge(
                context: context,
                icon: Icons.cake_outlined,
                label: 'Age',
                value: '${p.age} yrs',
              ),
              _buildDemographicBadge(
                context: context,
                icon: Icons.transgender_rounded,
                label: 'Gender',
                value: p.gender,
              ),
              _buildDemographicBadge(
                context: context,
                icon: Icons.bloodtype_outlined,
                label: 'Blood',
                value: p.bloodGroup,
              ),
              _buildDemographicBadge(
                context: context,
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: p.phone.isNotEmpty ? p.phone : 'Not set',
              ),
              if (p.country.isNotEmpty)
                _buildDemographicBadge(
                  context: context,
                  icon: Icons.public_rounded,
                  label: 'Country',
                  value: () {
                    final c = findCountry(p.country);
                    return c != null ? '${c.flag} ${c.nameEn}' : p.country;
                  }(),
                ),
            ],
          ),
          if (p.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.dividerTheme.color ??
                      colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.note_alt_outlined, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Notes: ${p.notes}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: theme.dividerTheme.color ?? theme.dividerColor,
          ),
          const SizedBox(height: 10),

          // Line 3: Action Buttons alone
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (onEditPatient != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onEditPatient,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text(
                    'Edit Patient',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onChangePatient,
                icon: const Icon(Icons.person_search, size: 15),
                label: const Text(
                  'Change Patient',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onAddOperation,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  '+ Add Operation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicBadge({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

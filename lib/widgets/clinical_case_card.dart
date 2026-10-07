import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/patient_record_brd.dart';
import '../data/countries_data.dart';

class ClinicalCaseCard extends StatelessWidget {
  final CompleteClinicalCase clinicalCase;
  final VoidCallback onTap;
  final bool isSelected;
  final List<String> matchedFields;

  const ClinicalCaseCard({
    super.key,
    required this.clinicalCase,
    required this.onTap,
    this.isSelected = false,
    this.matchedFields = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final patient = clinicalCase.patient;
    final operation = clinicalCase.operation;
    final formattedDate = DateFormat(
      'MMM dd, yyyy',
    ).format(operation.createdAt);

    final cardBg = theme.cardTheme.color ?? colorScheme.surface;
    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.2 : 0.04,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: MRN, Date, and Complication Tag
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            patient.medicalRecordNumber,
                            softWrap: true,
                            style: GoogleFonts.robotoMono(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Text(
                          formattedDate,
                          softWrap: true,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (clinicalCase.hasComplications)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: colorScheme.onErrorContainer,
                            ),
                            Text(
                              'POD ${clinicalCase.complications.first.podDay} (${clinicalCase.highestComplicationGrade})',
                              softWrap: true,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'No Complications',
                          softWrap: true,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Patient Name - STRICTLY with softWrap and no truncation
                Text(
                  patient.name,
                  softWrap: true,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),

                // Demographics on a separate line
                Builder(
                  builder: (context) {
                    final countryObj = findCountry(patient.country);
                    final countryDisplay = countryObj != null
                        ? ' ${countryObj.flag}'
                        : '';
                    final bloodDisplay =
                        (patient.bloodGroup.isNotEmpty &&
                            patient.bloodGroup != 'N/A')
                        ? ' (${patient.bloodGroup})'
                        : '';
                    return Text(
                      '${patient.age} yrs • ${patient.gender}$countryDisplay$bloodDisplay',
                      softWrap: true,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
                if (patient.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📝 ${patient.notes}',
                    softWrap: true,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Operation Type - Wrapped & non-truncated
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.medical_information_outlined,
                        size: 15,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        operation.operationType,
                        softWrap: true,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Diagnosis snippet - Full display with softWrap
                if (operation.diagnosisDetails.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    operation.diagnosisDetails,
                    softWrap: true,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                if (operation.hospital.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.local_hospital_rounded,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          operation.hospital,
                          softWrap: true,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Matched Fields Search Highlights
                if (matchedFields.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: matchedFields.map((match) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Found in $match',
                          softWrap: true,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),
                // Footer Badges: Pre-op, Intra-op, Post-op, Labs, Surveys
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPill(
                      context,
                      Icons.folder_shared_outlined,
                      clinicalCase.preOp != null ? 'Pre-Op ✓' : 'No Pre-Op',
                      colorScheme.primary,
                    ),
                    _buildPill(
                      context,
                      Icons.healing_outlined,
                      clinicalCase.intraOp != null ? 'Intra-Op ✓' : 'No Intra',
                      colorScheme.secondary,
                    ),
                    _buildPill(
                      context,
                      Icons.biotech_outlined,
                      '${clinicalCase.bloodLabs.length} Labs',
                      colorScheme.tertiary,
                    ),
                    _buildPill(
                      context,
                      Icons.assignment_outlined,
                      '${clinicalCase.surveys.length} Surveys',
                      colorScheme.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Icon(icon, size: 12, color: color),
          Text(
            text,
            softWrap: true,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

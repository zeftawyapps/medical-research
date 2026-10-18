import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/complete_clinical_case.dart';
import '../services/search_engine/research_search_engine.dart';
import '../utils/bmi_calculator.dart';

/// Clinical & Research Data Table for Conference Presentations, Cohort Studies, and Papers
class ClinicalResearchTableWidget extends StatefulWidget {
  final List<SearchMatchResult> results;
  final void Function(CompleteClinicalCase clinicalCase) onCaseSelected;
  final bool isDark;

  const ClinicalResearchTableWidget({
    super.key,
    required this.results,
    required this.onCaseSelected,
    required this.isDark,
  });

  @override
  State<ClinicalResearchTableWidget> createState() =>
      _ClinicalResearchTableWidgetState();
}

class _ClinicalResearchTableWidgetState
    extends State<ClinicalResearchTableWidget> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 48,
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No research cases match current filters',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort items
    final sortedList = List<SearchMatchResult>.from(widget.results);
    sortedList.sort((a, b) {
      final caseA = a.clinicalCase;
      final caseB = b.clinicalCase;
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0: // MRN
          cmp = caseA.patient.medicalRecordNumber
              .compareTo(caseB.patient.medicalRecordNumber);
          break;
        case 1: // Age
          cmp = caseA.patient.age.compareTo(caseB.patient.age);
          break;
        case 2: // Procedure
          cmp = caseA.operation.operationType
              .compareTo(caseB.operation.operationType);
          break;
        case 3: // BMI
          final bmiA = caseA.preOp?.bmi ?? 0.0;
          final bmiB = caseB.preOp?.bmi ?? 0.0;
          cmp = bmiA.compareTo(bmiB);
          break;
        case 4: // Fat
          final fatA = caseA.intraOp?.amountOfFatLiters ?? 0.0;
          final fatB = caseB.intraOp?.amountOfFatLiters ?? 0.0;
          cmp = fatA.compareTo(fatB);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingRowColor: WidgetStatePropertyAll(
                colorScheme.primaryContainer.withValues(alpha: widget.isDark ? 0.25 : 0.4),
              ),
              headingTextStyle: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 68,
              columnSpacing: 18,
              horizontalMargin: 16,
              columns: [
                DataColumn(
                  label: const Text('MRN / Patient'),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _sortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Age'),
                  numeric: true,
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _sortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Procedure Type'),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _sortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('BMI (kg/m²)'),
                  numeric: true,
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _sortAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Fat Aspirated'),
                  numeric: true,
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _sortAscending = ascending;
                    });
                  },
                ),
                const DataColumn(
                  label: Text('Past Medical History'),
                ),
                const DataColumn(
                  label: Text('Complications'),
                ),
                const DataColumn(
                  label: Text('Action'),
                ),
              ],
              rows: sortedList.map((match) {
                final c = match.clinicalCase;
                final bmi = c.preOp?.bmi;
                final bmiCat = bmi != null ? BmiCalculator.getShortCategory(bmi) : 'N/A';
                final bmiColor = bmi != null ? BmiCalculator.getCategoryColor(bmi) : Colors.grey;
                final fatLiters = c.intraOp?.amountOfFatLiters;
                final pmh = c.preOp?.pastMedicalHistory.trim();
                final pmhText = (pmh != null && pmh.isNotEmpty) ? pmh : 'None recorded';

                return DataRow(
                  cells: [
                    // MRN & Name
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.patient.medicalRecordNumber,
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            c.patient.name,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Age
                    DataCell(
                      Text(
                        '${c.patient.age} yrs',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Procedure Type
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.operation.operationType.isNotEmpty
                              ? c.operation.operationType
                              : 'Unspecified',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),

                    // BMI + Category Badge
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bmi != null ? bmi.toStringAsFixed(1) : '--',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: bmiColor,
                            ),
                          ),
                          if (bmi != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: bmiColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: bmiColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                bmiCat,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: bmiColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Fat Aspirated
                    DataCell(
                      Text(
                        fatLiters != null ? '${fatLiters.toStringAsFixed(1)} L' : '--',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Past Medical History
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          pmhText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    // Complications
                    DataCell(
                      c.hasComplications
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '${c.complications.length} (${c.complications.first.grade})',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.error,
                                ),
                              ),
                            )
                          : Text(
                              'None',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    // Action: Open Case
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        tooltip: 'Open Full Clinical Case',
                        color: colorScheme.primary,
                        onPressed: () => widget.onCaseSelected(c),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

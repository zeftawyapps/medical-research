import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/patient_record_brd.dart';

/// Modal dialog for selecting two cases and filtering data between their operation dates.
class ClinicalQueryBetweenCasesDialog extends StatefulWidget {
  final List<CompleteClinicalCase> allCases;
  final void Function(
    CompleteClinicalCase startCase,
    CompleteClinicalCase endCase,
    DateTime minOpDate,
    DateTime maxOpDate,
  ) onApply;

  const ClinicalQueryBetweenCasesDialog({
    super.key,
    required this.allCases,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CompleteClinicalCase> allCases,
    required void Function(
      CompleteClinicalCase startCase,
      CompleteClinicalCase endCase,
      DateTime minOpDate,
      DateTime maxOpDate,
    ) onApply,
  }) {
    if (allCases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No cases available to select between.'),
          duration: Duration(seconds: 2),
        ),
      );
      return Future.value();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ClinicalQueryBetweenCasesDialog(
        allCases: allCases,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ClinicalQueryBetweenCasesDialog> createState() =>
      _ClinicalQueryBetweenCasesDialogState();
}

class _ClinicalQueryBetweenCasesDialogState
    extends State<ClinicalQueryBetweenCasesDialog> {
  late List<CompleteClinicalCase> _sortedCases;
  late CompleteClinicalCase _startCase;
  late CompleteClinicalCase _endCase;

  @override
  void initState() {
    super.initState();
    _sortedCases = List<CompleteClinicalCase>.from(widget.allCases)
      ..sort(
        (a, b) => a.operation.operationDate.compareTo(b.operation.operationDate),
      );
    _startCase = _sortedCases.first;
    _endCase = _sortedCases.last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateF = DateFormat('yyyy-MM-dd');

    final minOpDate =
        _startCase.operation.operationDate.isBefore(_endCase.operation.operationDate)
            ? _startCase.operation.operationDate
            : _endCase.operation.operationDate;
    final maxOpDate =
        _startCase.operation.operationDate.isBefore(_endCase.operation.operationDate)
            ? _endCase.operation.operationDate
            : _startCase.operation.operationDate;

    final sDay = DateTime(minOpDate.year, minOpDate.month, minOpDate.day, 0, 0, 0);
    final eDay = DateTime(maxOpDate.year, maxOpDate.month, maxOpDate.day, 23, 59, 59);

    final casesBetweenCount = _sortedCases.where((c) {
      final d = c.operation.operationDate;
      return !d.isBefore(sDay) && !d.isAfter(eDay);
    }).length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.compare_arrows_rounded, color: colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filter Data Between Cases',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              softWrap: true,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select two clinical cases to analyze all surgical data and complications between their operation dates.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 16),

              // Start Case Dropdown
              Text(
                'First Case (Boundary A):',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<CompleteClinicalCase>(
                initialValue: _startCase,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _sortedCases.map((c) {
                  final mrn = c.patient.medicalRecordNumber;
                  final name = c.patient.name;
                  final proc = c.operation.operationType;
                  final opDateStr = dateF.format(c.operation.operationDate);
                  return DropdownMenuItem(
                    value: c,
                    child: Text(
                      '$mrn • $name • $proc • Op: $opDateStr',
                      style: const TextStyle(fontSize: 11.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _startCase = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              // End Case Dropdown
              Text(
                'Second Case (Boundary B):',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<CompleteClinicalCase>(
                initialValue: _endCase,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _sortedCases.map((c) {
                  final mrn = c.patient.medicalRecordNumber;
                  final name = c.patient.name;
                  final proc = c.operation.operationType;
                  final opDateStr = dateF.format(c.operation.operationDate);
                  return DropdownMenuItem(
                    value: c,
                    child: Text(
                      '$mrn • $name • $proc • Op: $opDateStr',
                      style: const TextStyle(fontSize: 11.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _endCase = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Live Preview Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Operation Window Preview',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Operation Dates: ${dateF.format(minOpDate)} ➔ ${dateF.format(maxOpDate)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$casesBetweenCount operations included in analysis',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.secondary,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_rounded, size: 16),
          onPressed: () {
            widget.onApply(_startCase, _endCase, minOpDate, maxOpDate);
            Navigator.of(context).pop();
          },
          label: const Text('Apply Between Cases'),
        ),
      ],
    );
  }
}

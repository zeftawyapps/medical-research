import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/patient_record_brd.dart';
import '../models/clinical_query_models.dart';

/// Interactive modal dialog for deep clinical cohort filtering.
/// Supports filtering by:
/// - Procedure Type
/// - Gender
/// - Age Range
/// - Complication Grade
/// - Garment Adherence
/// - BMI (Body Mass Index) Range
/// - Past Medical / Surgical History (SQL WHERE LIKE search)
/// - Amount of Fat Removed (Liters) Range
class ClinicalQueryAdvancedSearchDialog extends StatefulWidget {
  final AdvancedFilterCriteria currentCriteria;
  final List<CompleteClinicalCase> allCases;
  final ValueChanged<AdvancedFilterCriteria> onApply;

  const ClinicalQueryAdvancedSearchDialog({
    super.key,
    required this.currentCriteria,
    required this.allCases,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required AdvancedFilterCriteria currentCriteria,
    required List<CompleteClinicalCase> allCases,
    required ValueChanged<AdvancedFilterCriteria> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClinicalQueryAdvancedSearchDialog(
        currentCriteria: currentCriteria,
        allCases: allCases,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ClinicalQueryAdvancedSearchDialog> createState() =>
      _ClinicalQueryAdvancedSearchDialogState();
}

class _ClinicalQueryAdvancedSearchDialogState
    extends State<ClinicalQueryAdvancedSearchDialog> {
  late String? _tempProcedure;
  late String? _tempGender;
  late RangeValues? _tempAgeRange;
  late String? _tempComplicationGrade;
  late bool? _tempGarmentRequired;
  late RangeValues? _tempBmiRange;
  late TextEditingController _historyController;
  late RangeValues? _tempFatVolumeRange;

  @override
  void initState() {
    super.initState();
    _tempProcedure = widget.currentCriteria.procedure;
    _tempGender = widget.currentCriteria.gender;
    _tempAgeRange = widget.currentCriteria.ageRange;
    _tempComplicationGrade = widget.currentCriteria.complicationGrade;
    _tempGarmentRequired = widget.currentCriteria.garmentRequired;
    _tempBmiRange = widget.currentCriteria.bmiRange;
    _historyController = TextEditingController(
      text: widget.currentCriteria.medicalHistoryQuery ?? '',
    );
    _tempFatVolumeRange = widget.currentCriteria.fatVolumeRange;
  }

  @override
  void dispose() {
    _historyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    final screenwidth = MediaQuery.of(context).size.width - 10;
    // Distinct procedure names from existing cohort
    final distinctProcedures =
        widget.allCases
            .map((c) => c.operation.operationType)
            .where((p) => p.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // Distinct complication names from existing cohort
    final distinctComplications =
        widget.allCases
            .expand((c) => c.complications)
            .map((comp) => comp.description.trim())
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.90,
          maxWidth: screenwidth,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Advanced Search & Filter',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        softWrap: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable Filters Body
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Surgical Procedure Filter
                      _buildSectionHeader(
                        context,
                        title: 'Surgical Procedure',
                        icon: Icons.medical_services_outlined,
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        initialValue: _tempProcedure,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          context,
                          hint: 'All Procedures',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Procedures (Any)', softWrap: true),
                          ),
                          ...distinctProcedures.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p,
                              child: Text(p, softWrap: true),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _tempProcedure = val),
                      ),
                      const SizedBox(height: 16),

                      // 2. Gender Filter (Own Row)
                      _buildSectionHeader(
                        context,
                        title: 'Gender',
                        icon: Icons.wc_rounded,
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        initialValue: _tempGender,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          context,
                          hint: 'All',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All', softWrap: true),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female', softWrap: true),
                          ),
                          DropdownMenuItem(
                            value: 'Male',
                            child: Text('Male', softWrap: true),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _tempGender = val),
                      ),
                      const SizedBox(height: 16),

                      // 3. Age Range Slider (Own Row)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(
                            context,
                            title: 'Age Range',
                            icon: Icons.cake_outlined,
                          ),
                          Text(
                            _tempAgeRange != null
                                ? '${_tempAgeRange!.start.round()} - ${_tempAgeRange!.end.round()} yrs'
                                : 'Any',
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      RangeSlider(
                        values:
                            _tempAgeRange ??
                            const RangeValues(18, 75),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        labels: RangeLabels(
                          '${(_tempAgeRange ?? const RangeValues(18, 75)).start.round()}',
                          '${(_tempAgeRange ?? const RangeValues(18, 75)).end.round()}',
                        ),
                        onChanged: (vals) {
                          setState(() => _tempAgeRange = vals);
                        },
                      ),
                      const SizedBox(height: 16),

                      // 4. BMI (Body Mass Index) Range Filter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(
                            context,
                            title: 'BMI Range (kg/m²)',
                            icon: Icons.monitor_weight_outlined,
                          ),
                          if (_tempBmiRange != null)
                            InkWell(
                              onTap: () => setState(() => _tempBmiRange = null),
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.error,
                                ),
                                softWrap: true,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: RangeSlider(
                              values:
                                  _tempBmiRange ??
                                  const RangeValues(18.5, 35.0),
                              min: 15.0,
                              max: 55.0,
                              divisions: 80,
                              labels: RangeLabels(
                                (_tempBmiRange ?? const RangeValues(18.5, 35.0))
                                    .start
                                    .toStringAsFixed(1),
                                (_tempBmiRange ?? const RangeValues(18.5, 35.0))
                                    .end
                                    .toStringAsFixed(1),
                              ),
                              onChanged: (vals) {
                                setState(() => _tempBmiRange = vals);
                              },
                            ),
                          ),
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
                              _tempBmiRange != null
                                  ? '${_tempBmiRange!.start.toStringAsFixed(1)} - ${_tempBmiRange!.end.toStringAsFixed(1)}'
                                  : 'Any BMI',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. Past Medical & Surgical History (SQL WHERE LIKE search)
                      _buildSectionHeader(
                        context,
                        title: 'Medical & Surgical History (LIKE search)',
                        icon: Icons.history_edu_rounded,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _historyController,
                        decoration:
                            _inputDecoration(
                              context,
                              hint:
                                  'e.g. Diabetes, Hypertension, Previous C-section...',
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              suffixIcon: _historyController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          _historyController.clear();
                                        });
                                      },
                                    )
                                  : null,
                            ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // 5. Amount of Fat Removed (Liters)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(
                            context,
                            title: 'Amount of Fat Removed (Liters)',
                            icon: Icons.opacity_rounded,
                          ),
                          if (_tempFatVolumeRange != null)
                            InkWell(
                              onTap: () =>
                                  setState(() => _tempFatVolumeRange = null),
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.error,
                                ),
                                softWrap: true,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: RangeSlider(
                              values:
                                  _tempFatVolumeRange ??
                                  const RangeValues(0.5, 6.0),
                              min: 0.0,
                              max: 15.0,
                              divisions: 60,
                              labels: RangeLabels(
                                '${(_tempFatVolumeRange ?? const RangeValues(0.5, 6.0)).start.toStringAsFixed(1)} L',
                                '${(_tempFatVolumeRange ?? const RangeValues(0.5, 6.0)).end.toStringAsFixed(1)} L',
                              ),
                              onChanged: (vals) {
                                setState(() => _tempFatVolumeRange = vals);
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _tempFatVolumeRange != null
                                  ? '${_tempFatVolumeRange!.start.toStringAsFixed(1)} - ${_tempFatVolumeRange!.end.toStringAsFixed(1)} L'
                                  : 'Any Amount',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 7. Complication Filter (Actual Recorded Complications) - Own Row
                      _buildSectionHeader(
                        context,
                        title: 'Complication',
                        icon: Icons.healing_rounded,
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        initialValue: _tempComplicationGrade,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          context,
                          hint: 'All Complications',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All Complications (Any)',
                              softWrap: true,
                            ),
                          ),
                          ...distinctComplications.map(
                            (c) => DropdownMenuItem<String?>(
                              value: c,
                              child: Text(c, softWrap: true),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _tempComplicationGrade = val),
                      ),
                      const SizedBox(height: 16),

                      // 8. Garment Requirement - Separate Row
                      _buildSectionHeader(
                        context,
                        title: 'Garment Required',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<bool?>(
                        initialValue: _tempGarmentRequired,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          context,
                          hint: 'Any Status',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Any Garment Status', softWrap: true),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Required (Yes)', softWrap: true),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Not Required (No)', softWrap: true),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _tempGarmentRequired = val),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              // Bottom Action Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Apply Filters Button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded, size: 18),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              final criteria = AdvancedFilterCriteria(
                                procedure: _tempProcedure,
                                gender: _tempGender,
                                ageRange: _tempAgeRange,
                                complicationGrade: _tempComplicationGrade,
                                garmentRequired: _tempGarmentRequired,
                                bmiRange: _tempBmiRange,
                                medicalHistoryQuery:
                                    _historyController.text.trim().isNotEmpty
                                    ? _historyController.text.trim()
                                    : null,
                                fatVolumeRange: _tempFatVolumeRange,
                              );
                              widget.onApply(criteria);
                              Navigator.of(context).pop();
                            },
                            label: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Reset Filters Button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(
                                color: colorScheme.error.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _tempProcedure = null;
                                _tempGender = null;
                                _tempAgeRange = null;
                                _tempComplicationGrade = null;
                                _tempGarmentRequired = null;
                                _tempBmiRange = null;
                                _historyController.clear();
                                _tempFatVolumeRange = null;
                              });
                              widget.onApply(const AdvancedFilterCriteria());
                              Navigator.of(context).pop();
                            },
                            label: Text(
                              'Reset Filters',
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      children: [
        Icon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: 5),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          softWrap: true,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}

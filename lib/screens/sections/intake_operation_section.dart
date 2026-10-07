import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/procedure_catalog_model.dart';
import '../../services/database/clinical_repository.dart';
import '../../theme/responsive_layout.dart';
import 'intake_section_card.dart';

class IntakeOperationSection extends StatefulWidget {
  final TextEditingController operationTypeController;
  final TextEditingController diagnosisController;
  final TextEditingController? hospitalController;
  final DateTime operationDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool isDark;

  const IntakeOperationSection({
    super.key,
    required this.operationTypeController,
    required this.diagnosisController,
    this.hospitalController,
    required this.operationDate,
    required this.onDateSelected,
    required this.isDark,
  });

  @override
  State<IntakeOperationSection> createState() => _IntakeOperationSectionState();
}

class _IntakeOperationSectionState extends State<IntakeOperationSection> {
  final ClinicalRepository _repository = ClinicalRepository();
  List<ProcedureCatalogModel> _catalog = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final list = await _repository.getProcedureCatalog();
      if (mounted) {
        setState(() => _catalog = list);
      }
    } catch (_) {}
  }

  bool _isOptionSelected = false;
  FocusNode? _procFocusNode;

  void _applyProcedure(ProcedureCatalogModel proc) {
    setState(() {
      _isOptionSelected = true;
      widget.operationTypeController.text = proc.name;
      if (widget.diagnosisController.text.trim().isEmpty &&
          proc.description.isNotEmpty) {
        widget.diagnosisController.text = proc.description;
      }
    });
    _procFocusNode?.unfocus();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return IntakeSectionCard(
      title: '2. Operation & Primary Diagnosis',
      icon: Icons.medical_services_outlined,
      isDark: widget.isDark,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Autocomplete<ProcedureCatalogModel>(
                displayStringForOption: (option) => option.name,
                optionsBuilder: (textEditingValue) {
                  if (_isOptionSelected) {
                    return const [];
                  }
                  final text = textEditingValue.text.trim();
                  if (text.isEmpty) {
                    return _catalog;
                  }
                  final query = text.toLowerCase();
                  return _catalog.where(
                    (p) =>
                        p.name.toLowerCase().contains(query) ||
                        p.description.toLowerCase().contains(query),
                  );
                },
                onSelected: _applyProcedure,
                fieldViewBuilder:
                    (
                      context,
                      fieldTextEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      _procFocusNode = focusNode;
                      if (!focusNode.hasFocus &&
                          widget.operationTypeController.text.isNotEmpty &&
                          fieldTextEditingController.text !=
                              widget.operationTypeController.text) {
                        fieldTextEditingController.text =
                            widget.operationTypeController.text;
                      }
                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: focusNode,
                        scrollPadding: ResponsiveLayout.textFieldScrollPadding(
                          context,
                        ),
                        onTap: () {
                          if (_isOptionSelected) {
                            setState(() => _isOptionSelected = false);
                          }
                        },
                        onChanged: (val) {
                          if (_isOptionSelected) {
                            setState(() => _isOptionSelected = false);
                          }
                          widget.operationTypeController.text = val;
                        },
                        decoration: const InputDecoration(
                          labelText:
                              'Operation Name & Type (e.g. Laparoscopic Colectomy) *',
                          hintText: 'Select or type procedure name...',
                          prefixIcon: Icon(Icons.healing_rounded, size: 18),
                        ),
                        validator: (val) =>
                            widget.operationTypeController.text.isEmpty
                            ? 'Operation Type required'
                            : null,
                      );
                    },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.operationDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    widget.onDateSelected(picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Surgery Date',
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(widget.operationDate),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.diagnosisController,
          maxLines: 2,
          scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
          decoration: const InputDecoration(
            labelText: 'Comprehensive Initial Diagnosis *',
            prefixIcon: Icon(Icons.description_outlined, size: 18),
          ),
          validator: (val) =>
              val == null || val.isEmpty ? 'Diagnosis is required' : null,
        ),
        if (widget.hospitalController != null) ...[
          const SizedBox(height: 14),
          TextFormField(
            controller: widget.hospitalController,
            scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
            decoration: const InputDecoration(
              labelText: 'Hospital / Facility (المستشفى) (Optional)',
              hintText: 'e.g. Royal Surgery Center, King Faisal Hospital...',
              prefixIcon: Icon(Icons.local_hospital_outlined, size: 18),
            ),
          ),
        ],
      ],
    );
  }
}

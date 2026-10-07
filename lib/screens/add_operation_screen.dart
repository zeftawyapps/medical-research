import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/patient_record_brd.dart';
import '../services/database/clinical_repository.dart';
import '../theme/app_theme.dart';

/// Dedicated screen for adding a new surgical operation to a patient
/// Allows selecting from previously recorded procedures or typing a new procedure
/// Auto-fills Diagnosis from the procedure catalog
class AddOperationScreen extends StatefulWidget {
  final PatientModel patient;

  const AddOperationScreen({super.key, required this.patient});

  @override
  State<AddOperationScreen> createState() => _AddOperationScreenState();
}

class _AddOperationScreenState extends State<AddOperationScreen> {
  final ClinicalRepository _repository = ClinicalRepository();

  TextEditingController? _typeController;
  FocusNode? _typeFocusNode;
  bool _isOptionSelected = false;
  final TextEditingController _reasonController = TextEditingController();

  List<ProcedureCatalogModel> _catalog = [];
  bool _isLoadingCatalog = true;

  bool _isSaving = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await _repository.getProcedureCatalog();
      if (mounted) {
        setState(() {
          _catalog = catalog;
          _isLoadingCatalog = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCatalog = false);
      }
    }
  }

  void _applyProcedureFromCatalog(ProcedureCatalogModel proc) {
    setState(() {
      _isOptionSelected = true;
      if (proc.description.isNotEmpty) {
        _reasonController.text = proc.description;
      }
      _validationError = null;
    });
    _typeFocusNode?.unfocus();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final typeText = _typeController?.text.trim() ?? '';
    if (typeText.isEmpty) {
      setState(() {
        _validationError = 'Please select or type a procedure name';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _validationError = null;
    });

    try {
      const uuid = Uuid();
      final opId = uuid.v4();

      // 1. Create Operation Record
      final newOp = OperationModel(
        operationId: opId,
        patientId: widget.patient.patientId,
        operationType: typeText,
        diagnosisDetails: _reasonController.text.trim().isEmpty
            ? 'Procedure: $typeText'
            : _reasonController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _repository.insertOperation(newOp);

      // 2. Create Initial Pre-Op Record
      final initialPreOp = PreOpModel(
        preOpId: uuid.v4(),
        operationId: opId,
        pastMedicalHistory: '',
        occupation: '',
      );

      await _repository.insertPreOp(initialPreOp);

      // 3. Save / Update Procedure in Catalog so it's ready for future operations
      await _repository.addProcedureToCatalog(
        typeText,
        description: _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, newOp);
      }
    } catch (e) {
      debugPrint('Error creating operation: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _validationError = 'Failed to save operation: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patient = widget.patient;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Add New Surgical Operation',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Patient Mini Summary Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : Colors.teal.shade100,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.teal.withValues(
                                alpha: 0.15,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.teal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                patient.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'MRN: ${patient.medicalRecordNumber} • Age: ${patient.age} yrs • Gender: ${patient.gender}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Procedure & Clinical Fields Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.healing_outlined,
                              color: Colors.teal,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Procedure Details & Auto-Fill',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Select a previously recorded procedure or type a new one',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Procedure Name Autocomplete
                        _isLoadingCatalog
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Autocomplete<ProcedureCatalogModel>(
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
                                        p.description.toLowerCase().contains(
                                          query,
                                        ),
                                  );
                                },
                                onSelected: _applyProcedureFromCatalog,
                                fieldViewBuilder:
                                    (
                                      context,
                                      fieldTextEditingController,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      _typeController = fieldTextEditingController;
                                      _typeFocusNode = focusNode;
                                      return TextField(
                                        controller: fieldTextEditingController,
                                        focusNode: focusNode,
                                        onTap: () {
                                          if (_isOptionSelected) {
                                            setState(() => _isOptionSelected = false);
                                          }
                                        },
                                        onChanged: (val) {
                                          if (_isOptionSelected) {
                                            setState(() => _isOptionSelected = false);
                                          }
                                          if (_validationError != null) {
                                            setState(
                                              () => _validationError = null,
                                            );
                                          }
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Procedure Name *',
                                          hintText:
                                              'Select from history or type procedure name...',
                                          prefixIcon: const Icon(
                                            Icons.healing_outlined,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.arrow_drop_down),
                                            onPressed: () {
                                              setState(() => _isOptionSelected = false);
                                              focusNode.requestFocus();
                                            },
                                          ),
                                          errorText: _validationError,
                                        ),
                                      );
                                    },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 6,
                                      borderRadius: BorderRadius.circular(12),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 250,
                                          maxWidth: 680,
                                        ),
                                        child: ListView.separated(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          separatorBuilder: (_, _) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final option = options.elementAt(
                                              index,
                                            );
                                            return ListTile(
                                              dense: true,
                                              leading: const Icon(
                                                Icons.medical_services_outlined,
                                                color: Colors.teal,
                                                size: 20,
                                              ),
                                              title: Text(
                                                option.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle:
                                                  option.description.isNotEmpty
                                                  ? Text(
                                                      'Diagnosis: ${option.description}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    )
                                                  : null,
                                              onTap: () {
                                                _isOptionSelected = true;
                                                onSelected(option);
                                                _typeFocusNode?.unfocus();
                                                FocusScope.of(context).unfocus();
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 16),

                        // Diagnosis Field
                        TextField(
                          controller: _reasonController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Diagnosis & Indication (Optional)',
                            hintText:
                                'e.g. Clinical diagnosis, primary indication...',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox.shrink()
                          : const Icon(Icons.check_circle_rounded),
                      label: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Operation & Continue to Clinical Form',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

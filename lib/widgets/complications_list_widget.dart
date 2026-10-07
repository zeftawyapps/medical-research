import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/complication_model.dart';
import '../models/complication_catalog_model.dart';
import '../services/database/clinical_repository.dart';
import '../screens/sections/complication_catalog_dialog.dart';
import 'pod_calculator_badge.dart';

/// Clinical complications list widget with automatic POD calculation,
/// master complications catalog lookup, and responsive Wrap layout.
class ComplicationsListWidget extends StatefulWidget {
  final DateTime operationDate;
  final List<ComplicationModel> complications;
  final Function(ComplicationModel) onAddComplication;
  final Function(String) onDeleteComplication;

  const ComplicationsListWidget({
    super.key,
    required this.operationDate,
    required this.complications,
    required this.onAddComplication,
    required this.onDeleteComplication,
  });

  @override
  State<ComplicationsListWidget> createState() =>
      _ComplicationsListWidgetState();
}

class _ComplicationsListWidgetState extends State<ComplicationsListWidget> {
  final ClinicalRepository _repository = ClinicalRepository();
  List<ComplicationCatalogModel> _catalog = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final list = await _repository.getComplicationCatalog();
      if (mounted) {
        setState(() => _catalog = list);
      }
    } catch (_) {}
  }

  void _openAddComplicationDialog() {
    final descController = TextEditingController();
    final treatmentController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedGrade =
        'Grade I (Minor complication, no specific treatment required)';
    bool saveToCatalog = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
            final currentPod = ComplicationModel.computePod(
              widget.operationDate,
              selectedDate,
            );

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const Text(
                    'Add Surgical Complication',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      // Alert banner with automatic POD calculation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber
                              .withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(
                              Icons.calculate_outlined,
                              color: Colors.amber,
                              size: 20,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Operation Date: ${DateFormat('yyyy-MM-dd').format(widget.operationDate)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    const Text(
                                      'Calculated POD: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'POD $currentPod (Day $currentPod Post-Op)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Description with Known Complications Autocomplete
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '1/ Complication (Known or Custom) *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Select from catalog or type new',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Autocomplete<ComplicationCatalogModel>(
                        displayStringForOption: (option) => option.name,
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _catalog;
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return _catalog.where((c) =>
                              c.name.toLowerCase().contains(query) ||
                              c.treatment.toLowerCase().contains(query));
                        },
                        onSelected: (option) {
                          setDialogState(() {
                            descController.text = option.name;
                            treatmentController.text = option.treatment;
                            selectedGrade = option.grade;
                          });
                        },
                        fieldViewBuilder: (
                          context,
                          fieldTextController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          // Sync initial or updated text
                          if (descController.text.isNotEmpty &&
                              fieldTextController.text.isEmpty) {
                            fieldTextController.text = descController.text;
                          }
                          return TextField(
                            controller: fieldTextController,
                            focusNode: focusNode,
                            onChanged: (val) => descController.text = val,
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Seroma, Hematoma, Surgical Site Infection...',
                              prefixIcon: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                              ),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(10),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 220,
                                  maxWidth: 480,
                                ),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(6),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1),
                                  itemBuilder: (ctx, idx) {
                                    final option = options.elementAt(idx);
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        option.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        option.treatment,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          option.category,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // 2. Date of complication
                      const Text(
                        '2/ Date of Complication *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogCtx,
                            initialDate: selectedDate,
                            firstDate: widget.operationDate.subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 18,
                                    color: Colors.teal,
                                  ),
                                  Text(
                                    DateFormat('yyyy-MM-dd').format(selectedDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Change Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Treatment Protocol & Action Plan
                      const Text(
                        '3/ Treatment Protocol & Action Plan *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: treatmentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Auto-filled from known complication or enter customized treatment plan...',
                          prefixIcon: const Icon(
                            Icons.medical_services_outlined,
                            color: Colors.teal,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. Severity Grade
                      const Text(
                        '4/ Severity Grade (Clavien-Dindo Classification)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedGrade,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value:
                                'Grade I (Minor complication, no specific treatment required)',
                            child: Text(
                              'Grade I (Minor, no intervention)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Grade II (Requires pharmacological treatment/antibiotics)',
                            child: Text(
                              'Grade II (Pharmacological / Antibiotics)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Grade III (Requires surgical, endoscopic, or radiological intervention)',
                            child: Text(
                              'Grade III (Surgical / Intervention)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Grade IV (Life-threatening complication)',
                            child: Text(
                              'Grade IV (Life-threatening / ICU)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedGrade = val);
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      // Save to catalog option
                      CheckboxListTile(
                        value: saveToCatalog,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'Save / update this complication in Master Catalog',
                          style: TextStyle(fontSize: 12),
                        ),
                        onChanged: (val) {
                          setDialogState(() => saveToCatalog = val ?? true);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final desc = descController.text.trim();
                        final treat = treatmentController.text.trim();

                        if (desc.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter or select complication description',
                              ),
                            ),
                          );
                          return;
                        }

                        const uuid = Uuid();
                        final newComp = ComplicationModel(
                          complicationId: uuid.v4(),
                          operationId: '',
                          description: desc,
                          dateOfComplication: selectedDate,
                          podDay: currentPod,
                          treatment: treat.isEmpty
                              ? 'Clinical observation without intervention'
                              : treat,
                          grade: selectedGrade,
                        );

                        if (saveToCatalog) {
                          try {
                            await _repository.addComplicationToCatalog(
                              desc,
                              treatment: treat,
                              grade: selectedGrade,
                            );
                            _loadCatalog();
                          } catch (_) {}
                        }

                        if (ctx.mounted) {
                          widget.onAddComplication(newComp);
                          Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          size: 18),
                      label: const Text('Add to Records'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Wrap layout
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Icon(
                  Icons.list_alt_rounded,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
                Text(
                  'Registered Complications (${widget.complications.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade900,
                    side: BorderSide(
                      color: isDark
                          ? Colors.amber.shade700
                          : Colors.amber.shade400,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    showComplicationCatalogDialog(context, isDark);
                    await _loadCatalog();
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text(
                    'Complications Catalog',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _openAddComplicationDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    '+ Add Complication',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (widget.complications.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade300,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: const [
                Icon(Icons.verified_user_outlined,
                    color: Colors.green, size: 24),
                Text(
                  'No complications recorded for this procedure (uneventful recovery)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.complications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final comp = widget.complications[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E242B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade700.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber.shade800,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    comp.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PodCalculatorBadge(
                                    operationDate: widget.operationDate,
                                    evaluationDate: comp.dateOfComplication,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Wrap(
                                    spacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 14, color: Colors.grey),
                                      Text(
                                        'Date: ${DateFormat('yyyy-MM-dd').format(comp.dateOfComplication)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      comp.grade,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          tooltip: 'Delete Complication',
                          onPressed: () =>
                              widget.onDeleteComplication(comp.complicationId),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: const [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 16,
                              color: Colors.teal,
                            ),
                            Text(
                              'Treatment Plan: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          comp.treatment.isNotEmpty
                              ? comp.treatment
                              : 'No treatment recorded',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

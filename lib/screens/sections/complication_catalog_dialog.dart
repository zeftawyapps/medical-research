import 'package:flutter/material.dart';
import '../../models/complication_catalog_model.dart';
import '../../services/database/clinical_repository.dart';

/// Dialog to view, search, manage, and add complications to the Master Complications Catalog
void showComplicationCatalogDialog(BuildContext context, bool isDark) {
  showDialog(
    context: context,
    builder: (ctx) => _ComplicationCatalogDialog(isDark: isDark),
  );
}

class _ComplicationCatalogDialog extends StatefulWidget {
  final bool isDark;

  const _ComplicationCatalogDialog({required this.isDark});

  @override
  State<_ComplicationCatalogDialog> createState() =>
      _ComplicationCatalogDialogState();
}

class _ComplicationCatalogDialogState
    extends State<_ComplicationCatalogDialog> {
  final ClinicalRepository _repository = ClinicalRepository();
  List<ComplicationCatalogModel> _complications = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadComplications();
  }

  Future<void> _loadComplications() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getComplicationCatalog();
      if (mounted) {
        setState(() {
          _complications = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddComplicationDialog() {
    final nameCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    String selectedGrade =
        'Grade I (Minor complication, no specific treatment required)';
    String category = 'Wound';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_alert_rounded, color: Colors.amber),
                SizedBox(width: 8),
                Text('Add to Complications Catalog',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Complication Name *',
                        hintText: 'e.g. Seroma, Hematoma, SSI, Dehiscence...',
                        prefixIcon: Icon(Icons.warning_amber_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: treatmentCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Standard Treatment Protocol *',
                        hintText:
                            'e.g. Aspiration + compressive dressing / antibiotics...',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGrade,
                      decoration: const InputDecoration(
                        labelText: 'Clavien-Dindo Severity Grade',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value:
                              'Grade I (Minor complication, no specific treatment required)',
                          child: Text(
                            'Grade I (Minor / Bedside care)',
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
                            'Grade III (Requires Intervention / Debridement)',
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        'Wound',
                        'Vascular',
                        'Infectious',
                        'Cardiorespiratory',
                        'Tissue',
                        'Dermatologic',
                        'Urologic',
                        'Neurologic',
                        'General',
                      ]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style: const TextStyle(fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => category = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final treatment = treatmentCtrl.text.trim();
                  if (name.isEmpty || treatment.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please fill Complication Name and Treatment Protocol'),
                      ),
                    );
                    return;
                  }
                  await _repository.addComplicationToCatalog(
                    name,
                    treatment: treatment,
                    grade: selectedGrade,
                    category: category,
                  );
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                  if (mounted) {
                    _loadComplications();
                  }
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Save to Catalog'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _complications.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.treatment.toLowerCase().contains(q) ||
          c.grade.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Colors.amber, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Master Complications Catalog',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Standard complications, treatments & Clavien-Dindo grades (${_complications.length})',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _openAddComplicationDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          '+ Add Complication',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search complications by name, treatment, or grade...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 14),

              // List of Complications
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No complications found in catalog',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final comp = filtered[index];
                                final theme = Theme.of(context);
                                final colorScheme = theme.colorScheme;
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: theme.cardTheme.color ?? colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                  ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.warning_amber_rounded,
                                            size: 18, color: Colors.amber),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comp.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber
                                                          .withValues(
                                                              alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      comp.category,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .amber.shade900,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey
                                                          .withValues(
                                                              alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      comp.grade,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.redAccent),
                                          tooltip: 'Delete from Catalog',
                                          onPressed: () async {
                                            await _repository
                                                .deleteComplicationFromCatalog(
                                                    comp.id);
                                            _loadComplications();
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: widget.isDark
                                            ? Colors.black26
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.grey.withValues(
                                                alpha: 0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                  Icons
                                                      .medical_services_outlined,
                                                  size: 14,
                                                  color: Colors.teal),
                                              SizedBox(width: 6),
                                              Text(
                                                'Recognized Treatment Plan:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comp.treatment,
                                            style: const TextStyle(
                                                fontSize: 12, height: 1.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

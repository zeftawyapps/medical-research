import 'package:flutter/material.dart';
import '../../models/procedure_catalog_model.dart';
import '../../services/database/clinical_repository.dart';

/// Dialog to view, manage, and add procedures to the Master Procedure Catalog
void showProcedureCatalogDialog(BuildContext context, bool isDark) {
  showDialog(
    context: context,
    builder: (ctx) => _ProcedureCatalogDialog(isDark: isDark),
  );
}

class _ProcedureCatalogDialog extends StatefulWidget {
  final bool isDark;

  const _ProcedureCatalogDialog({required this.isDark});

  @override
  State<_ProcedureCatalogDialog> createState() =>
      _ProcedureCatalogDialogState();
}

class _ProcedureCatalogDialogState extends State<_ProcedureCatalogDialog> {
  final ClinicalRepository _repository = ClinicalRepository();
  List<ProcedureCatalogModel> _procedures = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProcedures();
  }

  Future<void> _loadProcedures() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getProcedureCatalog();
      if (mounted) {
        setState(() {
          _procedures = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddProcedureDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Procedure to Catalog'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Procedure Name *',
                    hintText: 'e.g. Hemorrhoidectomy, Cholecystectomy...',
                    prefixIcon: Icon(Icons.healing),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Default Diagnosis / Indication',
                    hintText: 'e.g. Grade III internal hemorrhoids...',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              await _repository.addProcedureToCatalog(
                name,
                description: descCtrl.text.trim(),
              );

              if (ctx.mounted) Navigator.pop(ctx);
              _loadProcedures();
            },
            child: const Text('Add to Catalog'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _procedures.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.pastMedicalHistory.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.teal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master Procedures Catalog',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Registry of surgical procedures performed in the clinic',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _openAddProcedureDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ Add New Procedure',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search registered procedures...',
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

              // List of Procedures
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No procedures found in catalog',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final proc = filtered[index];
                                final theme = Theme.of(context);
                                final colorScheme = theme.colorScheme;
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.cardTheme.color ?? colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                  ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.healing,
                                            size: 16, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            proc.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.red),
                                          tooltip: 'Delete from Catalog',
                                          onPressed: () async {
                                            await _repository
                                                .deleteProcedureFromCatalog(
                                                    proc.id);
                                            _loadProcedures();
                                          },
                                        ),
                                      ],
                                    ),
                                    if (proc.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Diagnosis: ${proc.description}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDark
                                              ? Colors.white70
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                    if (proc.pastMedicalHistory.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        'Past History **: ${proc.pastMedicalHistory}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: widget.isDark
                                              ? Colors.tealAccent.shade100
                                              : Colors.teal.shade800,
                                        ),
                                      ),
                                    ],
                                    if (proc.occupation.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        'Occupation **: ${proc.occupation}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: widget.isDark
                                              ? Colors.amber.shade200
                                              : Colors.deepOrange.shade800,
                                        ),
                                      ),
                                    ],
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

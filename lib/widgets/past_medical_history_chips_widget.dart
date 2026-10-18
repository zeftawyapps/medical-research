import 'package:flutter/material.dart';

/// Predefined standard clinical past medical history conditions
class PastMedicalHistoryCondition {
  final String id;
  final String label;
  final String? subtitle;
  final IconData icon;

  const PastMedicalHistoryCondition({
    required this.id,
    required this.label,
    this.subtitle,
    this.icon = Icons.medical_services_outlined,
  });
}

/// Interactive chips selector with automatic bi-directional sync to a TextEditingController
class PastMedicalHistoryChipsWidget extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String>? onChanged;

  const PastMedicalHistoryChipsWidget({
    super.key,
    required this.controller,
    required this.isDark,
    this.onChanged,
  });

  static const List<PastMedicalHistoryCondition> standardConditions = [
    PastMedicalHistoryCondition(
      id: 'hypertension',
      label: 'Hypertension',
      subtitle: 'HTN',
      icon: Icons.favorite_outline_rounded,
    ),
    PastMedicalHistoryCondition(
      id: 'diabetes',
      label: 'Diabetes Mellitus',
      subtitle: 'DM',
      icon: Icons.bloodtype_outlined,
    ),
    PastMedicalHistoryCondition(
      id: 'thyroid',
      label: 'Thyroid Disorder',
      subtitle: 'Thyroid',
      icon: Icons.healing_outlined,
    ),
    PastMedicalHistoryCondition(
      id: 'autoimmune',
      label: 'Autoimmune Disease',
      subtitle: 'Autoimmune',
      icon: Icons.shield_outlined,
    ),
    PastMedicalHistoryCondition(
      id: 'asthma',
      label: 'Asthma / Respiratory',
      icon: Icons.air_rounded,
    ),
    PastMedicalHistoryCondition(
      id: 'cardiac',
      label: 'Cardiovascular Disease',
      icon: Icons.monitor_heart_outlined,
    ),
    PastMedicalHistoryCondition(
      id: 'renal',
      label: 'Renal Disease',
      icon: Icons.water_drop_outlined,
    ),
  ];

  @override
  State<PastMedicalHistoryChipsWidget> createState() =>
      _PastMedicalHistoryChipsWidgetState();
}

class _PastMedicalHistoryChipsWidgetState
    extends State<PastMedicalHistoryChipsWidget> {
  final TextEditingController _customConditionController =
      TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _customConditionController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Parses the comma-separated or semicolon-separated conditions from controller text
  List<String> _getSelectedConditions() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return [];
    return text
        .split(RegExp(r'[,;\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool _isConditionSelected(PastMedicalHistoryCondition condition) {
    final currentList = _getSelectedConditions();
    final target = condition.label.toLowerCase();
    return currentList.any((c) =>
        c.toLowerCase() == target ||
        c.toLowerCase().contains(condition.id.toLowerCase()));
  }

  void _toggleCondition(PastMedicalHistoryCondition condition) {
    final currentList = _getSelectedConditions();
    final target = condition.label;
    final isSelected = _isConditionSelected(condition);

    if (isSelected) {
      currentList.removeWhere((c) =>
          c.toLowerCase() == target.toLowerCase() ||
          c.toLowerCase().contains(condition.id.toLowerCase()));
    } else {
      if (!currentList.any((c) => c.toLowerCase() == target.toLowerCase())) {
        currentList.add(target);
      }
    }

    final newText = currentList.join(', ');
    widget.controller.text = newText;
    widget.onChanged?.call(newText);
  }

  void _addCustomCondition() {
    final customVal = _customConditionController.text.trim();
    if (customVal.isEmpty) return;

    final currentList = _getSelectedConditions();
    if (!currentList.any((c) => c.toLowerCase() == customVal.toLowerCase())) {
      currentList.add(customVal);
      final newText = currentList.join(', ');
      widget.controller.text = newText;
      widget.onChanged?.call(newText);
    }
    _customConditionController.clear();
    setState(() {
      _showCustomInput = false;
    });
  }

  void _clearAllConditions() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = widget.isDark;
    final currentList = _getSelectedConditions();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Active Count & Quick Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.history_edu_rounded, color: colorScheme.primary, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Past Medical & Surgical History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              if (currentList.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentList.length} Selected',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _clearAllConditions,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap buttons to quickly tag conditions, or type any custom illness into the text field.',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Quick FilterChips Wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...PastMedicalHistoryChipsWidget.standardConditions.map((cond) {
                final isSelected = _isConditionSelected(cond);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cond.icon,
                        size: 14,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(cond.label),
                      if (cond.subtitle != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${cond.subtitle})',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(alpha: 0.85)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => _toggleCondition(cond),
                  selectedColor: colorScheme.primary,
                  checkmarkColor: colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  backgroundColor: theme.cardTheme.color ?? colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                );
              }),

              // "+ Other / Custom Disease" button
              ActionChip(
                avatar: Icon(
                  _showCustomInput ? Icons.close : Icons.add_circle_outline,
                  size: 15,
                  color: colorScheme.primary,
                ),
                label: Text(_showCustomInput ? 'Close Input' : '+ Other Condition'),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                backgroundColor: theme.cardTheme.color ?? colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showCustomInput = !_showCustomInput;
                  });
                },
              ),
            ],
          ),

          // Optional Custom Condition Input Field
          if (_showCustomInput) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customConditionController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Type other disease (e.g. Hepatitis C, Osteoporosis)...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 12),
                      onSubmitted: (_) => _addCustomCondition(),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _addCustomCondition,
                    child: const Text('Add Tag', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Editable Live Text Field reflecting active tags + freeform notes
          TextField(
            controller: widget.controller,
            maxLines: 2,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Compiled Medical & Surgical History (Editable)',
              hintText: 'e.g. Hypertension, Diabetes, Thyroid Disorder, Penicillin Allergy...',
              prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 12.5),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/garment_preferences_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';

/// Interactive conditional garment section widget
/// Allows switching Garment (Yes / No) and expands dynamic Autocomplete fields on Yes.
class ConditionalGarmentSectionWidget extends StatelessWidget {
  final bool isRequired;
  final ValueChanged<bool> onRequiredChanged;
  final TextEditingController typeController;
  final TextEditingController brandModelController;
  final List<String> typeSuggestions;
  final List<String> brandSuggestions;
  final ValueChanged<String>? onTypeAdded;
  final ValueChanged<String>? onBrandAdded;
  final bool isDark;
  final bool showValidationErrors;

  const ConditionalGarmentSectionWidget({
    super.key,
    required this.isRequired,
    required this.onRequiredChanged,
    required this.typeController,
    required this.brandModelController,
    this.typeSuggestions = const [],
    this.brandSuggestions = const [],
    this.onTypeAdded,
    this.onBrandAdded,
    this.isDark = false,
    this.showValidationErrors = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTypeEmpty =
        showValidationErrors &&
        isRequired &&
        typeController.text.trim().isEmpty;
    final isBrandEmpty =
        showValidationErrors &&
        isRequired &&
        brandModelController.text.trim().isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isTypeEmpty || isBrandEmpty)
              ? Colors.red.shade400
              : (isDark ? AppTheme.darkBorder : Colors.grey.shade300),
          width: (isTypeEmpty || isBrandEmpty) ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Toggle Switch (Responsive to prevent text squeezing)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;

              final titleWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isRequired
                          ? Colors.teal.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.checkroom_rounded,
                      color: isRequired ? Colors.teal : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '4/ Compression Garment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              );

              final toggleWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRequired ? 'Yes' : 'No',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isRequired
                          ? Colors.teal
                          : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: isRequired,
                    activeThumbColor: Colors.teal,
                    onChanged: onRequiredChanged,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [toggleWidget],
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [titleWidget, toggleWidget],
              );
            },
          ),

          // Dynamic Subfields (Animated Expansion)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isRequired
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 560;
                          final itemWidth = isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 14) / 2;

                          return Wrap(
                            spacing: 14,
                            runSpacing: 12,
                            children: [
                              // Field 1: Garment Type / Area Autocomplete
                              SizedBox(
                                width: itemWidth,
                                child: Autocomplete<String>(
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return typeSuggestions;
                                    }
                                    final q = textEditingValue.text
                                        .toLowerCase();
                                    return typeSuggestions.where(
                                      (t) => t.toLowerCase().contains(q),
                                    );
                                  },
                                  onSelected: (selection) {
                                    typeController.text = selection;
                                  },
                                  fieldViewBuilder:
                                      (
                                        context,
                                        textController,
                                        focusNode,
                                        onFieldSubmitted,
                                      ) {
                                        // Sync initial text if needed
                                        if (textController.text !=
                                                typeController.text &&
                                            typeController.text.isNotEmpty) {
                                          textController.text =
                                              typeController.text;
                                        }
                                        return TextField(
                                          controller: textController,
                                          focusNode: focusNode,
                                          scrollPadding:
                                              ResponsiveLayout.textFieldScrollPadding(
                                                context,
                                              ),
                                          onChanged: (val) =>
                                              typeController.text = val,
                                          decoration: InputDecoration(
                                            labelText: 'Garment Type / Area *',
                                            hintText:
                                                'e.g. Abdomen, Chest, Arms...',
                                            prefixIcon: const Icon(
                                              Icons.accessibility_new_rounded,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                color: Colors.teal,
                                                size: 20,
                                              ),
                                              tooltip:
                                                  'Add new type to SharedPreferences',
                                              onPressed: () =>
                                                  _showAddTypeDialog(context),
                                            ),
                                            errorText: isTypeEmpty
                                                ? 'Please specify garment area / type'
                                                : null,
                                          ),
                                        );
                                      },
                                ),
                              ),

                              // Field 2: Brand / Manufacturer & Model Autocomplete
                              SizedBox(
                                width: itemWidth,
                                child: Autocomplete<String>(
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return brandSuggestions;
                                    }
                                    final q = textEditingValue.text
                                        .toLowerCase();
                                    return brandSuggestions.where(
                                      (b) => b.toLowerCase().contains(q),
                                    );
                                  },
                                  onSelected: (selection) {
                                    brandModelController.text = selection;
                                  },
                                  fieldViewBuilder:
                                      (
                                        context,
                                        textController,
                                        focusNode,
                                        onFieldSubmitted,
                                      ) {
                                        // Sync initial text if needed
                                        if (textController.text !=
                                                brandModelController.text &&
                                            brandModelController
                                                .text
                                                .isNotEmpty) {
                                          textController.text =
                                              brandModelController.text;
                                        }
                                        return TextField(
                                          controller: textController,
                                          focusNode: focusNode,
                                          scrollPadding:
                                              ResponsiveLayout.textFieldScrollPadding(
                                                context,
                                              ),
                                          onChanged: (val) =>
                                              brandModelController.text = val,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Brand / Manufacturer & Model *',
                                            hintText:
                                                'e.g. Marena, Lipoelastic, VOE...',
                                            prefixIcon: const Icon(
                                              Icons.verified_outlined,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                color: Colors.teal,
                                                size: 20,
                                              ),
                                              tooltip:
                                                  'Add new brand to SharedPreferences',
                                              onPressed: () =>
                                                  _showAddBrandDialog(context),
                                            ),
                                            errorText: isBrandEmpty
                                                ? 'Please specify manufacturer & model'
                                                : null,
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Dedicated Add Buttons (Persisted in SharedPreferences)
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showAddTypeDialog(context),
                            icon: const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: Colors.teal,
                            ),
                            label: const Text(
                              '+ Add New Type',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.teal.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showAddBrandDialog(context),
                            icon: const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: Colors.teal,
                            ),
                            label: const Text(
                              '+ Add New Brand / Model',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.teal.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '💡 Custom types and brands are saved permanently in SharedPreferences and suggested automatically.',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTypeDialog(BuildContext context) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.teal),
            SizedBox(width: 8),
            Text(
              'Add Garment Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a new compression garment type / area (English). It will be saved permanently to SharedPreferences.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Garment Type *',
                hintText: 'e.g. Upper Thigh, Compression Vest...',
                prefixIcon: Icon(Icons.accessibility_new_rounded),
              ),
            ),
          ],
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
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Save to Preferences'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await GarmentPreferencesService.saveCustomType(result);
      typeController.text = result;
      onTypeAdded?.call(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$result" to saved garment types!'),
            duration: const Duration(milliseconds: 1500),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showAddBrandDialog(BuildContext context) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.teal),
            SizedBox(width: 8),
            Text(
              'Add Garment Brand / Model',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a new manufacturer or model name (English). It will be saved permanently to SharedPreferences.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Brand / Model *',
                hintText: 'e.g. Design Veronique, Isavela...',
                prefixIcon: Icon(Icons.verified_outlined),
              ),
            ),
          ],
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
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Save to Preferences'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await GarmentPreferencesService.saveCustomBrand(result);
      brandModelController.text = result;
      onBrandAdded?.call(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$result" to saved brands!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

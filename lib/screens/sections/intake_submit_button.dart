import 'package:flutter/material.dart';

class IntakeSubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const IntakeSubmitButton({
    super.key,
    required this.onPressed,
    this.label = 'Save Complete Surgery Case into SQLite Database',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.save_rounded, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

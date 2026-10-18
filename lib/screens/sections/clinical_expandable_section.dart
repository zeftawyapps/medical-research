import 'package:flutter/material.dart';

class ClinicalExpandableSection extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final Widget child;

  const ClinicalExpandableSection({
    super.key,
    required this.isDark,
    required this.title,
    required this.icon,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBg = theme.cardTheme.color ?? colorScheme.surface;
    final borderColor = theme.dividerTheme.color ?? colorScheme.outline.withValues(alpha: 0.25);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: ExpansionTile(
        key: ValueKey('$title-$initiallyExpanded'),
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        children: [child],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/responsive_layout.dart';
import 'intake_section_card.dart';

class IntakeIntraOpSection extends StatelessWidget {
  final TextEditingController intraOpDescController;
  final bool isDark;

  const IntakeIntraOpSection({
    super.key,
    required this.intraOpDescController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntakeSectionCard(
      title: '4. Intra-Operative Details & Surgical Notes',
      icon: Icons.healing_outlined,
      isDark: isDark,
      children: [
        TextFormField(
          controller: intraOpDescController,
          maxLines: 3,
          scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
          decoration: const InputDecoration(
            labelText:
                'Operative Steps, Approach, Blood Loss, Surgical Field Notes',
            prefixIcon: Icon(Icons.edit_note_rounded, size: 18),
          ),
        ),
      ],
    );
  }
}

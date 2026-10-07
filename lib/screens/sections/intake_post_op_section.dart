import 'package:flutter/material.dart';
import '../../theme/responsive_layout.dart';
import 'intake_section_card.dart';

class IntakePostOpSection extends StatelessWidget {
  final TextEditingController postOpDescController;
  final bool isDark;

  const IntakePostOpSection({
    super.key,
    required this.postOpDescController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntakeSectionCard(
      title: '5. Post-Operative Follow-Up & Evolution',
      icon: Icons.bed_outlined,
      isDark: isDark,
      children: [
        TextFormField(
          controller: postOpDescController,
          maxLines: 2,
          scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
          decoration: const InputDecoration(
            labelText: 'Post-Operative Progress & Recovery Notes',
            prefixIcon: Icon(Icons.hotel_class_rounded, size: 18),
          ),
        ),
      ],
    );
  }
}

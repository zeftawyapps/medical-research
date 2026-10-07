import 'package:flutter/material.dart';
import 'intake_section_card.dart';

class IntakeLabsSurveysSection extends StatelessWidget {
  final TextEditingController labNameController;
  final TextEditingController labValueController;
  final TextEditingController surveyTypeController;
  final TextEditingController surveyAnsController;
  final bool isDark;

  const IntakeLabsSurveysSection({
    super.key,
    required this.labNameController,
    required this.labValueController,
    required this.surveyTypeController,
    required this.surveyAnsController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntakeSectionCard(
      title: '7. Digital Labs & Patient Survey Intake',
      icon: Icons.biotech_rounded,
      isDark: isDark,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: labNameController,
                decoration: const InputDecoration(
                  labelText: 'Initial Lab Test Name',
                  prefixIcon: Icon(Icons.science_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: labValueController,
                decoration: const InputDecoration(
                  labelText: 'Result Value',
                  prefixIcon: Icon(Icons.assessment_outlined, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: surveyTypeController,
                decoration: const InputDecoration(
                  labelText: 'Survey Name (e.g. VAS Pain)',
                  prefixIcon: Icon(Icons.poll_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: surveyAnsController,
                decoration: const InputDecoration(
                  labelText: 'Survey Score / Answers',
                  prefixIcon: Icon(Icons.format_list_bulleted_rounded, size: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/past_medical_history_chips_widget.dart';
import 'intake_section_card.dart';

class IntakePreOpSection extends StatelessWidget {
  final TextEditingController preOpDescController;
  final TextEditingController radiologyReportController;
  final TextEditingController? pastHistoryController;
  final bool isDark;

  const IntakePreOpSection({
    super.key,
    required this.preOpDescController,
    required this.radiologyReportController,
    this.pastHistoryController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntakeSectionCard(
      title: '3. Pre-Operative Assessment & Baseline',
      icon: Icons.assignment_outlined,
      isDark: isDark,
      children: [
        if (pastHistoryController != null) ...[
          PastMedicalHistoryChipsWidget(
            controller: pastHistoryController!,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
        ],

        TextFormField(
          controller: preOpDescController,
          maxLines: 2,
          scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
          decoration: const InputDecoration(
            labelText: 'Pre-Op Clinical Case Description',
            hintText:
                'Presenting symptoms, comorbidities, baseline clinical assessment...',
            prefixIcon: Icon(Icons.notes_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: radiologyReportController,
          maxLines: 2,
          scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
          decoration: const InputDecoration(
            labelText: 'Radiology Reports (CT, MRI, X-Ray findings)',
            prefixIcon: Icon(Icons.document_scanner_outlined, size: 18),
          ),
        ),
      ],
    );
  }
}

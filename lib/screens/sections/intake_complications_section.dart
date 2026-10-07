import 'package:flutter/material.dart';
import '../../theme/responsive_layout.dart';
import 'intake_section_card.dart';

class IntakeComplicationsSection extends StatelessWidget {
  final bool hasComplication;
  final ValueChanged<bool> onHasComplicationChanged;
  final TextEditingController podController;
  final String grade;
  final ValueChanged<String> onGradeChanged;
  final TextEditingController mgmtController;
  final bool isDark;

  const IntakeComplicationsSection({
    super.key,
    required this.hasComplication,
    required this.onHasComplicationChanged,
    required this.podController,
    required this.grade,
    required this.onGradeChanged,
    required this.mgmtController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntakeSectionCard(
      title: '6. Complications & Clavien-Dindo Grade (Optional)',
      icon: Icons.warning_amber_rounded,
      isDark: isDark,
      children: [
        SwitchListTile(
          title: const Text(
            'Did the patient experience any post-op complication?',
          ),
          value: hasComplication,
          onChanged: onHasComplicationChanged,
          contentPadding: EdgeInsets.zero,
        ),
        if (hasComplication) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: podController,
                  keyboardType: TextInputType.number,
                  scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                  decoration: const InputDecoration(
                    labelText: 'Post-Op Day (POD)',
                    prefixIcon: Icon(Icons.today_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: grade,
                  decoration: const InputDecoration(
                    labelText: 'Clavien-Dindo Grade',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Clavien-Dindo Grade I',
                      child: Text('Grade I (Minor/Conservative)'),
                    ),
                    DropdownMenuItem(
                      value: 'Clavien-Dindo Grade II',
                      child: Text('Grade II (Pharmacological/POAF/ABX)'),
                    ),
                    DropdownMenuItem(
                      value: 'Clavien-Dindo Grade IIIa',
                      child: Text('Grade IIIa (Intervention no GA)'),
                    ),
                    DropdownMenuItem(
                      value: 'Clavien-Dindo Grade IIIb',
                      child: Text('Grade IIIb (Intervention under GA)'),
                    ),
                    DropdownMenuItem(
                      value: 'Clavien-Dindo Grade IV',
                      child: Text('Grade IV (ICU/Organ Dysfunction)'),
                    ),
                    DropdownMenuItem(
                      value: 'Clavien-Dindo Grade V',
                      child: Text('Grade V (Mortality)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) onGradeChanged(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: mgmtController,
            scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
            decoration: const InputDecoration(
              labelText: 'Medical / Surgical Management Provided',
              prefixIcon: Icon(Icons.healing_outlined, size: 18),
            ),
          ),
        ],
      ],
    );
  }
}

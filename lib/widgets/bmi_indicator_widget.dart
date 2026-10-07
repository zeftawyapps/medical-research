import 'package:flutter/material.dart';

/// Clinical widget displaying Body Mass Index (BMI) and color-coded status
class BmiIndicatorWidget extends StatelessWidget {
  final double? weightKg;
  final double? heightM;

  const BmiIndicatorWidget({
    super.key,
    required this.weightKg,
    required this.heightM,
  });

  double? get bmi {
    if (weightKg == null || heightM == null || heightM! <= 0 || weightKg! <= 0) {
      return null;
    }
    final val = weightKg! / (heightM! * heightM!);
    return double.parse(val.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final val = bmi;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (val == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade300,
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.calculate_outlined, color: Colors.grey, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Enter weight (kg) and height (m) to calculate BMI automatically',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // Determine category and color
    String categoryName;
    Color categoryColor;
    IconData categoryIcon;

    if (val < 18.5) {
      categoryName = 'Underweight';
      categoryColor = Colors.blue;
      categoryIcon = Icons.arrow_downward_rounded;
    } else if (val < 25.0) {
      categoryName = 'Normal Weight';
      categoryColor = Colors.green.shade600;
      categoryIcon = Icons.check_circle_outline_rounded;
    } else if (val < 30.0) {
      categoryName = 'Overweight';
      categoryColor = Colors.orange.shade700;
      categoryIcon = Icons.trending_up_rounded;
    } else if (val < 35.0) {
      categoryName = 'Obesity Class I';
      categoryColor = Colors.deepOrange.shade600;
      categoryIcon = Icons.warning_amber_rounded;
    } else {
      categoryName = 'Severe Obesity (Class II / III)';
      categoryColor = Colors.red.shade700;
      categoryIcon = Icons.health_and_safety_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'BMI: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      val.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: categoryColor,
                      ),
                    ),
                    const Text(
                      ' kg/m²',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'AUTO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

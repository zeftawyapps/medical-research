import 'package:flutter/material.dart';
import '../utils/bmi_calculator.dart';

/// Clinical widget displaying Body Mass Index (BMI) with WHO categorization,
/// smart height normalization (handles cm e.g. 175 & m e.g. 1.75), and visual gauge.
class BmiIndicatorWidget extends StatelessWidget {
  final double? weightKg;
  final double? heightM;

  const BmiIndicatorWidget({
    super.key,
    required this.weightKg,
    required this.heightM,
  });

  double? get bmi => BmiCalculator.calculate(weightKg, heightM);

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
                'Enter weight (kg) and height (m or cm) to calculate BMI automatically',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    final categoryName = BmiCalculator.getCategory(val);
    final categoryColor = BmiCalculator.getCategoryColor(val);
    final categoryIcon = BmiCalculator.getCategoryIcon(val);
    final normHeight = BmiCalculator.normalizeHeightM(heightM);

    final bool enteredAsCm = (heightM != null && heightM! > 3.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: categoryColor,
                          ),
                        ),
                        const Text(
                          ' kg/m²',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 13.5,
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
                  'WHO AUTO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Subtitle breakdown info
          Row(
            children: [
              Text(
                'Weight: ${weightKg?.toStringAsFixed(1) ?? '--'} kg  •  Height: ${enteredAsCm ? '${heightM!.toStringAsFixed(0)} cm (${normHeight?.toStringAsFixed(2)} m)' : '${normHeight?.toStringAsFixed(2) ?? '--'} m'}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Visual WHO BMI Scale Bar
          _buildBmiScaleBar(val, isDark),
        ],
      ),
    );
  }

  Widget _buildBmiScaleBar(double bmi, bool isDark) {
    // Categories: Underweight (<18.5), Normal (18.5-24.9), Overweight (25-29.9), Obese I (30-34.9), Obese II/III (>=35)
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: 18,
                child: Container(
                  height: 6,
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 65,
                child: Container(
                  height: 6,
                  color: Colors.green.shade500,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 50,
                child: Container(
                  height: 6,
                  color: Colors.orange.shade500,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 50,
                child: Container(
                  height: 6,
                  color: Colors.deepOrange.shade500,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 60,
                child: Container(
                  height: 6,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('<18.5', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            Text('18.5-24.9', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            Text('25.0-29.9', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            Text('30.0-34.9', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            Text('≥35.0', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }
}

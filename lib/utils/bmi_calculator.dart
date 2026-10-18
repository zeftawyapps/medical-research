import 'package:flutter/material.dart';

/// WHO Standard Body Mass Index (BMI) Calculator & Clinical Categorization
class BmiCalculator {
  /// Normalizes height to meters (auto-converts centimeters e.g. 175cm -> 1.75m)
  static double? normalizeHeightM(double? height) {
    if (height == null || height <= 0) return null;
    double h = height;
    if (h > 3.0) {
      // Input is in centimeters (e.g. 175 -> 1.75)
      h = h / 100.0;
    }
    if (h < 0.4 || h > 2.8) {
      // Outside realistic human height bounds
      return null;
    }
    return h;
  }

  /// Calculates BMI using standard formula: weight (kg) / [height (m)]^2
  /// Automatically handles height in cm or meters.
  static double? calculate(double? weightKg, double? height) {
    if (weightKg == null || height == null || weightKg <= 0 || height <= 0) {
      return null;
    }
    final h = normalizeHeightM(height);
    if (h == null) return null;

    final val = weightKg / (h * h);
    if (val.isNaN || val.isInfinite || val < 5.0 || val > 150.0) {
      return null;
    }
    return double.parse(val.toStringAsFixed(2));
  }

  /// WHO BMI Classification
  static String getCategory(double? bmi) {
    switch (bmi) {
      case null:
        return 'N/A';
      case < 18.5:
        return 'Underweight';
      case < 25.0:
        return 'Normal Weight';
      case < 30.0:
        return 'Overweight';
      case < 35.0:
        return 'Obesity Class I';
      case < 40.0:
        return 'Obesity Class II';
      default:
        return 'Obesity Class III (Morbid)';
    }
  }

  /// Concise category label
  static String getShortCategory(double? bmi) {
    switch (bmi) {
      case null:
        return 'N/A';
      case < 18.5:
        return 'Underweight';
      case < 25.0:
        return 'Normal';
      case < 30.0:
        return 'Overweight';
      case < 35.0:
        return 'Obese I';
      case < 40.0:
        return 'Obese II';
      default:
        return 'Obese III';
    }
  }

  /// Theme-conscious category color
  static Color getCategoryColor(double? bmi) {
    switch (bmi) {
      case null:
        return Colors.grey;
      case < 18.5:
        return Colors.blue.shade600;
      case < 25.0:
        return Colors.green.shade600;
      case < 30.0:
        return Colors.orange.shade700;
      case < 35.0:
        return Colors.deepOrange.shade600;
      case < 40.0:
        return Colors.red.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  /// Visual icon for the BMI category
  static IconData getCategoryIcon(double? bmi) {
    switch (bmi) {
      case null:
        return Icons.calculate_outlined;
      case < 18.5:
        return Icons.arrow_downward_rounded;
      case < 25.0:
        return Icons.check_circle_outline_rounded;
      case < 30.0:
        return Icons.trending_up_rounded;
      case < 35.0:
        return Icons.warning_amber_rounded;
      case < 40.0:
        return Icons.health_and_safety_rounded;
      default:
        return Icons.warning_rounded;
    }
  }
}

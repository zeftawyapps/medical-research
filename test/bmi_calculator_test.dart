import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/utils/bmi_calculator.dart';
import 'package:medecat_research/widgets/bmi_indicator_widget.dart';
import 'package:medecat_research/models/pre_op_model.dart';

void main() {
  group('BmiCalculator Tests', () {
    test('Calculates BMI accurately with height in meters', () {
      // 70 kg, 1.75 m -> 70 / (1.75 * 1.75) = 22.86
      final bmi = BmiCalculator.calculate(70.0, 1.75);
      expect(bmi, 22.86);
      expect(BmiCalculator.getCategory(bmi), 'Normal Weight');
    });

    test('Calculates BMI accurately with height in centimeters (Smart Normalization)', () {
      // 70 kg, 175 cm -> should auto-convert to 1.75 m -> 22.86
      final bmi = BmiCalculator.calculate(70.0, 175.0);
      expect(bmi, 22.86);
      expect(BmiCalculator.getCategory(bmi), 'Normal Weight');
    });

    test('Categorizes WHO categories correctly', () {
      // Underweight < 18.5
      expect(BmiCalculator.getCategory(17.5), 'Underweight');
      
      // Normal Weight 18.5 - 24.9
      expect(BmiCalculator.getCategory(18.5), 'Normal Weight');
      expect(BmiCalculator.getCategory(24.9), 'Normal Weight');

      // Overweight 25.0 - 29.9
      expect(BmiCalculator.getCategory(25.0), 'Overweight');
      expect(BmiCalculator.getCategory(28.5), 'Overweight');

      // Obese Class I 30.0 - 34.9
      expect(BmiCalculator.getCategory(30.0), 'Obesity Class I');
      expect(BmiCalculator.getCategory(34.2), 'Obesity Class I');

      // Obese Class II 35.0 - 39.9
      expect(BmiCalculator.getCategory(35.0), 'Obesity Class II');
      expect(BmiCalculator.getCategory(38.0), 'Obesity Class II');

      // Obese Class III >= 40.0
      expect(BmiCalculator.getCategory(40.0), 'Obesity Class III (Morbid)');
      expect(BmiCalculator.getCategory(45.0), 'Obesity Class III (Morbid)');
    });

    test('Handles invalid and null inputs safely', () {
      expect(BmiCalculator.calculate(null, 1.75), isNull);
      expect(BmiCalculator.calculate(70.0, null), isNull);
      expect(BmiCalculator.calculate(0.0, 1.75), isNull);
      expect(BmiCalculator.calculate(70.0, 0.0), isNull);
      expect(BmiCalculator.calculate(-70.0, 1.75), isNull);
      expect(BmiCalculator.calculate(70.0, -1.75), isNull);
    });

    test('PreOpModel delegates correctly to BmiCalculator', () {
      final preOp1 = PreOpModel(
        preOpId: 'pre1',
        operationId: 'op1',
        weightKg: 85.0,
        heightM: 1.80,
      );
      expect(preOp1.bmi, 26.23);
      expect(preOp1.bmiCategory, 'Overweight');

      final preOp2 = PreOpModel(
        preOpId: 'pre2',
        operationId: 'op2',
        weightKg: 85.0,
        heightM: 180.0, // in cm
      );
      expect(preOp2.bmi, 26.23);
      expect(preOp2.bmiCategory, 'Overweight');
    });
  });

  group('BmiIndicatorWidget UI Tests', () {
    testWidgets('Renders empty state when weight/height not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BmiIndicatorWidget(weightKg: null, heightM: null),
          ),
        ),
      );

      expect(find.textContaining('Enter weight (kg) and height'), findsOneWidget);
    });

    testWidgets('Renders calculated BMI with category and details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BmiIndicatorWidget(weightKg: 75.0, heightM: 1.75),
          ),
        ),
      );

      expect(find.text('24.5'), findsOneWidget);
      expect(find.text('Normal Weight'), findsOneWidget);
      expect(find.textContaining('75.0 kg'), findsOneWidget);
      expect(find.textContaining('1.75 m'), findsOneWidget);
    });

    testWidgets('Renders properly when height is entered in cm', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BmiIndicatorWidget(weightKg: 75.0, heightM: 175.0),
          ),
        ),
      );

      expect(find.text('24.5'), findsOneWidget);
      expect(find.text('Normal Weight'), findsOneWidget);
      expect(find.textContaining('175 cm (1.75 m)'), findsOneWidget);
    });
  });
}

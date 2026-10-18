import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/widgets/bmi_indicator_widget.dart';
import 'package:medecat_research/widgets/age_at_operation_badge.dart';
import 'package:medecat_research/widgets/pod_calculator_badge.dart';

/// ============================================================================
/// 🧪 Core Clinical Medical Widgets Test Suite (اختبارات الودجات الطبية والحسابية الأساسية)
/// 
/// تغطي هذه المجموعة:
/// 1. مؤشر كتلة الجسم [BmiIndicatorWidget] وحساب التصنيف الطبي (Normal Weight, Overweight, Obese).
/// 2. شارة حساب عمر المريض الدقيق عند تاريخ إجراء الجراحة [AgeAtOperationBadge].
/// 3. شارة حساب يوم ما بعد الجراحة [PodCalculatorBadge] (Post-Operative Day - POD) تلقائياً من تاريخ العملية والتقييم.
/// ============================================================================

void main() {
  group('Core Clinical Badges & Calculator Widgets', () {
    /// --------------------------------------------------------------------------
    /// 📋 Test 1:
    /// التحقق من حساب مؤشر كتلة الجسم (BMI) بدقة وعرض التصنيف المناسب
    /// --------------------------------------------------------------------------
    testWidgets('BMI Indicator calculates correct BMI and displays category', (WidgetTester tester) async {
    // 75 kg, 1.75 m -> BMI = 75 / (1.75 * 1.75) = 24.49 -> 24.5 (Normal Weight)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BmiIndicatorWidget(weightKg: 75, heightM: 1.75),
        ),
      ),
    );

    expect(find.text('24.5'), findsOneWidget);
    expect(find.text('Normal Weight'), findsOneWidget);
  });

    /// --------------------------------------------------------------------------
    /// 📋 Test 2:
    /// التحقق من حساب عمر المريض بدقة عند تاريخ الجراحة
    /// --------------------------------------------------------------------------
    testWidgets('AgeAtOperationBadge calculates age at the date of surgery correctly', (WidgetTester tester) async {
      final dob = DateTime(1990, 5, 10);
      final opDate = DateTime(2025, 5, 10); // Exactly 35 years

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgeAtOperationBadge(
              dateOfBirth: dob,
              operationDate: opDate,
            ),
          ),
        ),
      );

      expect(find.text('35 yrs'), findsOneWidget);
    });

    /// --------------------------------------------------------------------------
    /// 📋 Test 3:
    /// التحقق من حساب يوم ما بعد الجراحة (POD) تلقائياً
    /// --------------------------------------------------------------------------
    testWidgets('PodCalculatorBadge calculates Post-Operative Day (POD) automatically', (WidgetTester tester) async {
      final opDate = DateTime(2025, 6, 1);
      final compDate = DateTime(2025, 6, 5); // POD 4

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PodCalculatorBadge(
              operationDate: opDate,
              evaluationDate: compDate,
            ),
          ),
        ),
      );

      expect(find.text('POD: 4'), findsOneWidget);
      expect(find.text('(Day 4 Post-Op)'), findsOneWidget);
    });
  });
}

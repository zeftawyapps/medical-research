import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/models/patient_record_brd.dart';
import 'package:medecat_research/widgets/clinical_case_card.dart';

/// ============================================================================
/// 🧪 ClinicalCaseCard Test Suite (مجموعة اختبارات بطاقة الحالة السريرية)
/// 
/// الهدف من الاختبارات:
/// 1. التحقق من قدرة عنصر [ClinicalCaseCard] على عرض النصوص الطويلة جداً
///    (مثل الاسم الممتد، تفاصيل التشخيص المعقد، اسم المستشفى والعملية)
/// 2. التأكد من عدم حدوث أي Overflow أو أخطاء في الـ Layout على الشاشات الصغيرة (Mobile View - 360px).
/// 3. التحقق من ظهور حقول البحث المطابقة (Matched Search Highlights) بشكل صحيح.
/// ============================================================================

void main() {
  group('ClinicalCaseCard - UI & Responsiveness Tests', () {
    /// --------------------------------------------------------------------------
    /// 📋 Test Case 1:
    /// التحقق من معالجة النصوص الطويلة جداً بدون حدوث تجاوز في أبعاد الشاشة (Zero Overflow)
    /// --------------------------------------------------------------------------
    testWidgets(
      'ClinicalCaseCard handles extremely long text without overflow or truncation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640); // Small mobile screen width
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final extremeCase = CompleteClinicalCase(
      patient: PatientModel(
        patientId: 'extreme-pt-1',
        medicalRecordNumber: 'MRN-EXTREME-SUPER-LONG-NUMBER-123456789',
        demographics: {
          'name': 'Alexander Christopher Montgomery-Wellington III Very Long Multi Part Name',
          'age': 54,
          'gender': 'Male',
          'country': 'United Kingdom',
          'blood_group': 'AB+',
          'notes': 'Extremely detailed patient clinical note stating that the patient underwent previous multiple revisions and has high aesthetic expectations with extensive follow-up requirements over 12 months.',
        },
        createdAt: now,
      ),
      operation: OperationModel(
        operationId: 'extreme-op-1',
        patientId: 'extreme-pt-1',
        diagnosisDetails: 'Extensive bilateral secondary post-traumatic contour irregularity with massive lipodystrophy requiring specialized multi-plane lipo-contouring and extensive soft tissue reconstruction.',
        operationType: 'Comprehensive 360 High-Definition Vaser Liposuction Combined with Anatomical Flap Reconstruction and Extended Rectus Diastasis Repair',
        hospital: 'The Royal Specialized Surgical Center for Advanced Aesthetic & Reconstructive Surgery at London Central',
        createdAt: now,
      ),
      intraOp: IntraOpModel(
        intraOpId: 'extreme-intra-1',
        operationId: 'extreme-op-1',
        corsetType: 'Full Body Custom Anatomical Compression Garment',
        isGarmentRequired: true,
        garmentType: 'Full Body Suit',
        garmentBrandModel: 'Lipoelastic Custom Stage 1',
      ),
      complications: [
        ComplicationModel(
          complicationId: 'extreme-comp-1',
          operationId: 'extreme-op-1',
          description: 'Delayed localized seroma formation requiring ultrasound-guided aspiration',
          dateOfComplication: now.add(const Duration(days: 14)),
          podDay: 14,
          grade: 'Grade IIIa (Requiring surgical/radiological intervention without GA)',
          treatment: 'Ultrasound-guided evacuation under local anesthesia',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClinicalCaseCard(
              clinicalCase: extremeCase,
              matchedFields: const ['Patient Name', 'Operation Type', 'Diagnosis Details', 'Surgical Hospital', 'Complications'],
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify no exception / overflow was thrown
    expect(tester.takeException(), isNull);

    // Verify all text widgets rendered without error
    expect(find.textContaining('Alexander Christopher Montgomery-Wellington III'), findsOneWidget);
    expect(find.textContaining('Comprehensive 360 High-Definition Vaser Liposuction'), findsOneWidget);
    expect(find.textContaining('Extensive bilateral secondary post-traumatic'), findsOneWidget);
    expect(find.textContaining('The Royal Specialized Surgical Center'), findsOneWidget);
    expect(find.textContaining('Extremely detailed patient clinical note'), findsOneWidget);
  });
  });
}

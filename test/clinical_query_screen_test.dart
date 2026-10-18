import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medecat_research/models/patient_record_brd.dart';
import 'package:medecat_research/providers/research_provider.dart';
import 'package:medecat_research/screens/clinical_query_screen.dart';
import 'package:medecat_research/screens/clinical_query/models/clinical_query_models.dart';
import 'package:medecat_research/services/search_engine/research_search_engine.dart';

/// ============================================================================
/// 🧪 ClinicalQueryScreen Test Suite (مجموعة اختبارات شاشة الاستعلام السريري والبحث)
/// 
/// تغطي هذه المجموعة:
/// 1. بناء واجهة شاشة الاستعلام وعرض التابات الثنائية (Analytics Dashboard & Cohort Search).
/// 2. فحص محرك النطاق الزمني والفلترة بين الحالات (Between Cases Date Selector).
/// 3. التحقق من عدم حدوث تجاوز في أبعاد الشاشة عند عرض درجات المضاعفات الطويلة (320px).
/// 4. اختبار الفلترة المتقدمة (BMI, Medical History LIKE, Fat Volume).
/// 5. اختبار حفظ رقم التاب الأخير في SharedPreferences واستعادته تلقائياً عند الدخول.
/// ============================================================================

void main() {
  /// --------------------------------------------------------------------------
  /// 📋 Test 1:
  /// التحقق من رسم التابات الثنائية ومؤشرات الـ KPIs وزر إضافة مريض جديد (FAB)
  /// وفحص التبديل بين Analytics Dashboard و Cohort Search
  /// --------------------------------------------------------------------------
  testWidgets(
    'ClinicalQueryScreen renders dual tabs, KPI cards, and FloatingActionButton',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final sampleCase = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-1',
          medicalRecordNumber: 'MRN-101',
          demographics: {'name': 'John Doe', 'age': 42, 'gender': 'Male'},
          createdAt: now,
        ),
        operation: OperationModel(
          operationId: 'op-1',
          patientId: 'p-1',
          diagnosisDetails: 'Abdominal Lipodystrophy',
          operationType: 'Abdominal Liposuction',
          hospital: 'Central Hospital',
          createdAt: now,
        ),
        intraOp: IntraOpModel(
          intraOpId: 'intra-1',
          operationId: 'op-1',
          corsetType: 'Abdominal Garment',
          isGarmentRequired: true,
          garmentType: 'Stage 1 Binder',
        ),
        complications: [
          ComplicationModel(
            complicationId: 'comp-1',
            operationId: 'op-1',
            description: 'Minor fluid collection',
            dateOfComplication: now.add(const Duration(days: 2)),
            podDay: 2,
            grade: 'Grade I',
            treatment: 'Observation',
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ResearchProvider(),
          child: MaterialApp(
            home: ClinicalQueryScreen(
              key: ClinicalQueryScreen.queryKey,
              initialCases: [sampleCase],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Tab navigation exists
      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.text('Cohort Search & Cases'), findsOneWidget);

      // 2. Verify Tab 1 (Dashboard) KPI cards
      expect(find.text('Total Cases'), findsOneWidget);
      expect(find.text('Complication Rate'), findsOneWidget);
      expect(find.text('Mean Patient Age'), findsOneWidget);
      expect(find.text('Garment Adherence'), findsOneWidget);

      // 3. Verify Tab 1 breakdown sections
      expect(find.text('Surgical Procedures Breakdown'), findsOneWidget);
      expect(find.text('Clavien-Dindo Complications'), findsOneWidget);

      // 4. Verify FloatingActionButton
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Register Patient'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);

      // 5. Switch to Tab 2 (Cohort Search & Cases)
      await tester.tap(find.text('Cohort Search & Cases'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify search bar and filter chips in Tab 2
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Complications Only'), findsOneWidget);
      expect(find.text('All POD'), findsOneWidget);
      expect(find.text('POD 0-3'), findsOneWidget);

      // Verify case card rendered with standalone patient name
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('MRN-101'), findsOneWidget);

      // 6. Test Advanced Search Dialog opening via queryKey
      ClinicalQueryScreen.queryKey.currentState?.openAdvancedSearchDialog();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Advanced Search & Filter'), findsOneWidget);
    },
  );

  test(
    'ResearchSearchEngine.filterBetweenCases filters strictly by operation date',
    () {
      final case1 = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-1',
          medicalRecordNumber: 'MRN-1',
          demographics: {'name': 'Alice'},
          createdAt: DateTime(2025, 1, 1),
        ),
        operation: OperationModel(
          operationId: 'op-1',
          patientId: 'p-1',
          diagnosisDetails: 'Diagnosis 1',
          operationType: 'Surgery A',
          createdAt: DateTime(2025, 2, 10), // Op Date
        ),
      );

      final case2 = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-2',
          medicalRecordNumber: 'MRN-2',
          demographics: {'name': 'Bob'},
          createdAt: DateTime(2025, 1, 1),
        ),
        operation: OperationModel(
          operationId: 'op-2',
          patientId: 'p-2',
          diagnosisDetails: 'Diagnosis 2',
          operationType: 'Surgery B',
          createdAt: DateTime(2025, 5, 20), // Op Date
        ),
      );

      final case3 = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-3',
          medicalRecordNumber: 'MRN-3',
          demographics: {'name': 'Charlie'},
          createdAt: DateTime(2025, 1, 1),
        ),
        operation: OperationModel(
          operationId: 'op-3',
          patientId: 'p-3',
          diagnosisDetails: 'Diagnosis 3',
          operationType: 'Surgery C',
          createdAt: DateTime(2025, 11, 15), // Op Date
        ),
      );

      final cases = [case1, case2, case3];

      // Filter between case 1 (Feb 10) and case 2 (May 20)
      final between1And2 = ResearchSearchEngine.filterBetweenCases(
        cases,
        startCase: case1,
        endCase: case2,
      );
      expect(between1And2.length, 2);
      expect(
        between1And2.map((c) => c.patient.name),
        containsAll(['Alice', 'Bob']),
      );
      expect(
        between1And2.map((c) => c.patient.name),
        isNot(contains('Charlie')),
      );

      // Filter between case 2 and case 3
      final between2And3 = ResearchSearchEngine.filterBetweenCases(
        cases,
        startCase: case2,
        endCase: case3,
      );
      expect(between2And3.length, 2);
      expect(
        between2And3.map((c) => c.patient.name),
        containsAll(['Bob', 'Charlie']),
      );
      expect(between2And3.map((c) => c.patient.name), isNot(contains('Alice')));
    },
  );

  testWidgets(
    'Tapping Between Cases opens the case selection dialog and shows operation window preview',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final caseA = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'pa',
          medicalRecordNumber: 'MRN-A',
          demographics: {'name': 'Patient Alpha'},
          createdAt: DateTime(2025, 1, 1),
        ),
        operation: OperationModel(
          operationId: 'opa',
          patientId: 'pa',
          diagnosisDetails: 'Diagnosis Alpha',
          operationType: 'Procedure Alpha',
          createdAt: DateTime(2025, 3, 10),
        ),
      );

      final caseB = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'pb',
          medicalRecordNumber: 'MRN-B',
          demographics: {'name': 'Patient Beta'},
          createdAt: DateTime(2025, 1, 1),
        ),
        operation: OperationModel(
          operationId: 'opb',
          patientId: 'pb',
          diagnosisDetails: 'Diagnosis Beta',
          operationType: 'Procedure Beta',
          createdAt: DateTime(2025, 8, 25),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: ClinicalQueryScreen(initialCases: [caseA, caseB])),
      );
      await tester.pumpAndSettle();

      // Find and tap "Between Cases" chip
      expect(find.text('Between Cases'), findsOneWidget);
      await tester.ensureVisible(find.text('Between Cases'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Between Cases'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Filter Data Between Cases'), findsOneWidget);
      expect(find.text('Operation Window Preview'), findsOneWidget);
      expect(find.text('Apply Between Cases'), findsOneWidget);

      // Tap Apply
      await tester.tap(find.text('Apply Between Cases'));
      await tester.pumpAndSettle();

      // Verify custom operation date range controls appear
      expect(find.textContaining('Between Cases:'), findsOneWidget);
      expect(find.textContaining('From: 2025-03-10'), findsOneWidget);
      expect(find.textContaining('To: 2025-08-25'), findsOneWidget);
    },
  );

  testWidgets(
    'Complications breakdown renders long text with softWrap and zero overflow on narrow screen (320px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      const longGrade =
          'Grade IIIa (Requiring surgical/radiological intervention without general anesthesia in outpatient setting)';

      final compCase = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-comp',
          medicalRecordNumber: 'MRN-COMP-999',
          demographics: {'name': 'Patient With Complication'},
          createdAt: now,
        ),
        operation: OperationModel(
          operationId: 'op-comp',
          patientId: 'p-comp',
          diagnosisDetails: 'Test Diagnosis',
          operationType: 'Test Surgery',
          createdAt: now,
        ),
        complications: [
          ComplicationModel(
            complicationId: 'c-1',
            operationId: 'op-comp',
            description: 'Subcutaneous Fluid Accumulation (Seroma)',
            podDay: 5,
            grade: longGrade,
            treatment: 'Drainage',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: ClinicalQueryScreen(initialCases: [compCase])),
      );
      await tester.pumpAndSettle();

      // Verify the Clavien-Dindo Complications card renders the long grade text
      expect(find.text(longGrade), findsOneWidget);
      // Verify case count rendered on both procedure and complication cards
      expect(find.text('1 cases (100%)'), findsNWidgets(2));
      // Verify no RenderFlex overflow was thrown
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Advanced Filter filters cases by BMI, Medical History (LIKE), and Fat Volume',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();

      final caseFatima = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-fatima',
          medicalRecordNumber: 'MRN-F-1',
          demographics: {
            'name': 'Fatima Al-Sayed',
            'gender': 'Female',
            'age': 32,
          },
          createdAt: now,
        ),
        operation: OperationModel(
          operationId: 'op-f',
          patientId: 'p-fatima',
          diagnosisDetails: 'Abdominal Wall Laxity',
          operationType: 'Abdominoplasty',
          hospital: 'City Clinic',
          createdAt: now,
        ),
        preOp: PreOpModel(
          preOpId: 'pre-f',
          operationId: 'op-f',
          weightKg: 65,
          heightM: 1.65, // BMI ~ 23.9
          pastMedicalHistory: 'Hypertension controlled on ACE inhibitor',
          caseDescription: 'Aesthetic body contouring',
        ),
        intraOp: IntraOpModel(
          intraOpId: 'intra-f',
          operationId: 'op-f',
          amountOfFatLiters: 1.5,
        ),
      );

      final caseOmar = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-omar',
          medicalRecordNumber: 'MRN-O-2',
          demographics: {'name': 'Omar Khaled', 'gender': 'Male', 'age': 45},
          createdAt: now,
        ),
        operation: OperationModel(
          operationId: 'op-o',
          patientId: 'p-omar',
          diagnosisDetails: 'Severe abdominal lipodystrophy',
          operationType: 'High-Volume Liposuction',
          hospital: 'City Clinic',
          createdAt: now,
        ),
        preOp: PreOpModel(
          preOpId: 'pre-o',
          operationId: 'op-o',
          weightKg: 110,
          heightM: 1.70, // BMI ~ 38.1
          pastMedicalHistory: 'Type 2 Diabetes Mellitus, Previous Appendectomy',
          caseDescription: 'High risk metabolic profile',
        ),
        intraOp: IntraOpModel(
          intraOpId: 'intra-o',
          operationId: 'op-o',
          amountOfFatLiters: 6.5,
        ),
      );

      final caseSara = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-sara',
          medicalRecordNumber: 'MRN-S-3',
          demographics: {'name': 'Sara Mostafa', 'gender': 'Female', 'age': 28},
          createdAt: now,
        ),
        operation: OperationModel(
          operationId: 'op-s',
          patientId: 'p-sara',
          diagnosisDetails: 'Flank and thigh lipodystrophy',
          operationType: 'Liposuction',
          hospital: 'City Clinic',
          createdAt: now,
        ),
        preOp: PreOpModel(
          preOpId: 'pre-s',
          operationId: 'op-s',
          weightKg: 78,
          heightM: 1.60, // BMI ~ 30.5
          pastMedicalHistory: 'Bronchial Asthma, No prior surgery',
          caseDescription: 'Localized fat deposit',
        ),
        intraOp: IntraOpModel(
          intraOpId: 'intra-s',
          operationId: 'op-s',
          amountOfFatLiters: 3.2,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ResearchProvider(),
          child: MaterialApp(
            home: ClinicalQueryScreen(
              key: ClinicalQueryScreen.queryKey,
              initialCases: [caseFatima, caseOmar, caseSara],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Tab 2 (Cohort Search & Cases)
      await tester.tap(find.text('Cohort Search & Cases'));
      await tester.pumpAndSettle();

      // Initially all 3 cases are visible
      expect(find.text('Fatima Al-Sayed'), findsOneWidget);
      expect(find.text('Omar Khaled'), findsOneWidget);
      expect(find.text('Sara Mostafa'), findsOneWidget);

      // Open Advanced Filter dialog via queryKey
      ClinicalQueryScreen.queryKey.currentState?.openAdvancedSearchDialog();
      await tester.pumpAndSettle();

      // Verify dialog header and new fields are present
      expect(find.text('Advanced Search & Filter'), findsOneWidget);
      expect(find.text('BMI Range (kg/m²)'), findsOneWidget);
      expect(
        find.text('Medical & Surgical History (LIKE search)'),
        findsOneWidget,
      );
      expect(find.text('Amount of Fat Removed (Liters)'), findsOneWidget);

      // 1. Apply Medical History LIKE filter: "Diabetes"
      final historyFinder = find.byType(TextField).last;
      await tester.enterText(historyFinder, 'Diabetes');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Only Omar has Diabetes
      expect(find.text('Omar Khaled'), findsOneWidget);
      expect(find.text('Fatima Al-Sayed'), findsNothing);
      expect(find.text('Sara Mostafa'), findsNothing);

      // Verify specific history chip appears
      expect(find.text('History: "Diabetes"'), findsOneWidget);

      // Clear the history filter chip
      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pumpAndSettle();

      // All 3 cases returned
      expect(find.text('Fatima Al-Sayed'), findsOneWidget);
      expect(find.text('Omar Khaled'), findsOneWidget);
      expect(find.text('Sara Mostafa'), findsOneWidget);

      // 2. Programmatically apply BMI Range filter (18.5 - 25.0) via queryKey
      ClinicalQueryScreen.queryKey.currentState?.applyAdvancedFilter(
        const AdvancedFilterCriteria(bmiRange: RangeValues(18.5, 25.0)),
      );
      await tester.pumpAndSettle();

      // Only Fatima (BMI 23.9) is in range; Omar (38.1) and Sara (30.5) excluded
      expect(find.text('Fatima Al-Sayed'), findsOneWidget);
      expect(find.text('Omar Khaled'), findsNothing);
      expect(find.text('Sara Mostafa'), findsNothing);
      expect(find.text('BMI: 18.5 - 25.0'), findsOneWidget);

      // 3. Programmatically apply Fat Volume filter (2.0 - 5.0 L)
      ClinicalQueryScreen.queryKey.currentState?.applyAdvancedFilter(
        const AdvancedFilterCriteria(fatVolumeRange: RangeValues(2.0, 5.0)),
      );
      await tester.pumpAndSettle();

      // Only Sara (3.2 L) is in range; Fatima (1.5 L) and Omar (6.5 L) excluded
      expect(find.text('Sara Mostafa'), findsOneWidget);
      expect(find.text('Fatima Al-Sayed'), findsNothing);
      expect(find.text('Omar Khaled'), findsNothing);
      expect(find.text('Fat: 2.0 - 5.0 L'), findsOneWidget);
    },
  );

  testWidgets(
    'ClinicalQueryScreen switching from tab 1 to tab 2 records index 1 to SharedPreferences',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'clinical_query_last_tab_index': 0});
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final sampleCase = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-tab-1',
          medicalRecordNumber: 'MRN-TAB-1',
          demographics: {'name': 'Tab Test Patient', 'gender': 'Female', 'age': 28},
          createdAt: now,
        ),
        operation: OperationModel(
          operationId: 'op-tab-1',
          patientId: 'p-tab-1',
          diagnosisDetails: 'Test Details',
          operationType: 'Test Procedure',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ResearchProvider(),
          child: MaterialApp(
            home: ClinicalQueryScreen(initialCases: [sampleCase]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Tab 1 (Analytics Dashboard)
      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.text('Total Cases'), findsOneWidget);

      // Switch to Tab 2 (Cohort Search & Cases)
      await tester.tap(find.text('Cohort Search & Cases'));
      await tester.pumpAndSettle();

      // Verify that SharedPreferences received tab index = 1
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('clinical_query_last_tab_index'), equals(1));
    },
  );

  testWidgets(
    'ClinicalQueryScreen automatically opens on the last opened tab saved in SharedPreferences',
    (WidgetTester tester) async {
      // Pre-set saved tab index to 1 (Cohort Search & Cases)
      SharedPreferences.setMockInitialValues({'clinical_query_last_tab_index': 1});
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final sampleCase = CompleteClinicalCase(
        patient: PatientModel(
          patientId: 'p-tab-2',
          medicalRecordNumber: 'MRN-TAB-2',
          demographics: {'name': 'Auto Restored Patient', 'gender': 'Male', 'age': 35},
          createdAt: now,
        ),
        operation: OperationModel(
          operationId: 'op-tab-2',
          patientId: 'p-tab-2',
          diagnosisDetails: 'Auto Restore Details',
          operationType: 'Auto Restore Surgery',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ResearchProvider(),
          child: MaterialApp(
            home: ClinicalQueryScreen(initialCases: [sampleCase]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should automatically navigate to Tab 2 (Cohort Search & Cases)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Complications Only'), findsOneWidget);
      expect(find.text('Auto Restored Patient'), findsOneWidget);
    },
  );
}

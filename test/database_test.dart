import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/models/patient_record_brd.dart';
import 'package:medecat_research/services/database/clinical_repository.dart';
import 'package:medecat_research/services/database/repositories/patient_repository.dart';
import 'package:medecat_research/services/search_engine/research_search_engine.dart';

/// ============================================================================
/// 🧪 Database & Repository Integration Test Suite (اختبارات قاعدة البيانات والمستودعات)
/// 
/// تغطي هذه المجموعة:
/// 1. عمليات CRUD الأساسية لجدول المرضى (Insert, GetById, GetByMRN, Update, Delete) عبر [PatientRepository].
/// 2. عمليات الإدراج والاسترجاع الشاملة للحالة السريرية التجميعية [CompleteClinicalCase] عبر [ClinicalRepository].
/// 3. فحص محرك البحث الزمني [ResearchSearchEngine.filterByTimeFrame] (Last 7 Days, Last 30 Days, Last Year).
/// 4. فحص محرك البحث الشامل متعدد الحقول [ResearchSearchEngine.searchAllFields].
/// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// --------------------------------------------------------------------------
  /// 📋 Test 1:
  /// اختبار عمليات CRUD لجدول المرضى (إضافة، استرجاع، تعديل، حذف)
  /// --------------------------------------------------------------------------
  test('Database - Generic CRUD operations via PatientRepository', () async {
    final patientRepo = PatientRepository();
    final now = DateTime.now();

    final p = PatientModel(
      patientId: 'test-p-1',
      medicalRecordNumber: 'MRN-TEST-100',
      demographics: {'name': 'Test Patient', 'age': 45, 'gender': 'Male'},
      createdAt: now,
    );

    // 1. Insert
    final insertResult = await patientRepo.insert(p);
    expect(insertResult, greaterThan(0));

    // 2. Get by ID
    final fetched = await patientRepo.getById('test-p-1');
    expect(fetched, isNotNull);
    expect(fetched!.medicalRecordNumber, 'MRN-TEST-100');
    expect(fetched.name, 'Test Patient');

    // 3. Get by MRN
    final fetchedByMrn = await patientRepo.getByMedicalRecordNumber('MRN-TEST-100');
    expect(fetchedByMrn, isNotNull);
    expect(fetchedByMrn!.patientId, 'test-p-1');

    // 4. Update
    final updatedPatient = PatientModel(
      patientId: 'test-p-1',
      medicalRecordNumber: 'MRN-TEST-100',
      demographics: {'name': 'Updated Patient', 'age': 46, 'gender': 'Male'},
      createdAt: now,
    );
    await patientRepo.update(updatedPatient);
    final reFetched = await patientRepo.getById('test-p-1');
    expect(reFetched!.name, 'Updated Patient');

    // 5. Delete
    await patientRepo.delete('test-p-1');
    final afterDelete = await patientRepo.getById('test-p-1');
    expect(afterDelete, isNull);
  });

  test('ClinicalRepository - Aggregate Case Insertion and Retrieval', () async {
    final clinicalRepo = ClinicalRepository();
    final now = DateTime.now();

    final c = CompleteClinicalCase(
      patient: PatientModel(
        patientId: 'case-p-1',
        medicalRecordNumber: 'MRN-AGG-001',
        demographics: {'name': 'Aggregate Patient', 'age': 50, 'gender': 'Female'},
        createdAt: now,
      ),
      operation: OperationModel(
        operationId: 'case-op-1',
        patientId: 'case-p-1',
        diagnosisDetails: 'Test Surgical Indication',
        operationType: 'Test Laparoscopy',
        createdAt: now,
      ),
      preOp: PreOpModel(
        preOpId: 'case-pre-1',
        operationId: 'case-op-1',
        pastMedicalHistory: 'Hypertension, Diabetes',
        occupation: 'Engineer',
        isSmoker: true,
        cigarettesPerDay: 15,
        smokingYears: 10,
        weightKg: 82.0,
        heightM: 1.75,
        hemoglobin: 14.2,
        t3: 1.5,
        t4: 8.0,
        caseDescription: 'Pre-op diagnostic assessment',
      ),
      complications: [
        ComplicationModel(
          complicationId: 'case-comp-1',
          operationId: 'case-op-1',
          description: 'Mild surgical site seroma',
          dateOfComplication: now.add(const Duration(days: 1)),
          podDay: 1,
          grade: 'Grade I',
          treatment: 'Conservative observation',
        ),
      ],
      bloodLabs: [
        BloodLabModel(
          labId: 'case-lab-1',
          operationId: 'case-op-1',
          testName: 'Hemoglobin',
          resultValue: '14.2 g/dL',
          testDate: now,
        ),
      ],
    );

    // Insert complete case
    await clinicalRepo.insertCompleteCase(c);

    // Retrieve all cases
    final allCases = await clinicalRepo.getAllClinicalCases();
    expect(allCases.length, 1);
    expect(allCases.first.patient.medicalRecordNumber, 'MRN-AGG-001');
    expect(allCases.first.operation.operationType, 'Test Laparoscopy');
    expect(allCases.first.preOp?.caseDescription, 'Pre-op diagnostic assessment');
    expect(allCases.first.complications.length, 1);
    expect(allCases.first.bloodLabs.length, 1);

    // Delete case
    await clinicalRepo.deleteCase('case-op-1', 'case-p-1');
    final afterDeleteCases = await clinicalRepo.getAllClinicalCases();
    expect(afterDeleteCases.isEmpty, true);
  });

  test('ResearchSearchEngine - Time Frame filtering', () {
    final now = DateTime.now();

    final caseRecent = CompleteClinicalCase(
      patient: PatientModel(
        patientId: 'p1',
        medicalRecordNumber: 'MRN-001',
        demographics: {'name': 'John Doe', 'age': 55, 'gender': 'Male'},
        createdAt: now,
      ),
      operation: OperationModel(
        operationId: 'op1',
        patientId: 'p1',
        diagnosisDetails: 'Sigmoid adenocarcinoma',
        operationType: 'Robotic Colectomy',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    );

    final caseOld = CompleteClinicalCase(
      patient: PatientModel(
        patientId: 'p2',
        medicalRecordNumber: 'MRN-002',
        demographics: {'name': 'Jane Smith', 'age': 62, 'gender': 'Female'},
        createdAt: now,
      ),
      operation: OperationModel(
        operationId: 'op2',
        patientId: 'p2',
        diagnosisDetails: 'Cholelithiasis',
        operationType: 'Laparoscopic Cholecystectomy',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    );

    final cases = [caseRecent, caseOld];

    // Test Last 7 Days
    final last7 = ResearchSearchEngine.filterByTimeFrame(cases, preset: TimeFramePreset.last7Days);
    expect(last7.length, 1);
    expect(last7.first.patient.medicalRecordNumber, 'MRN-001');

    // Test All Time
    final allTime = ResearchSearchEngine.filterByTimeFrame(cases, preset: TimeFramePreset.allTime);
    expect(allTime.length, 2);
  });

  test('ResearchSearchEngine - Universal multi-field search', () {
    final now = DateTime.now();

    final c = CompleteClinicalCase(
      patient: PatientModel(
        patientId: 'p1',
        medicalRecordNumber: 'MRN-999',
        demographics: {'name': 'Arthur Pendelton', 'age': 70, 'gender': 'Male'},
        createdAt: now,
      ),
      operation: OperationModel(
        operationId: 'op1',
        patientId: 'p1',
        diagnosisDetails: 'Triple Vessel Disease',
        operationType: 'Coronary Bypass',
        hospital: 'Al-Amal Specialized Hospital',
        createdAt: now,
      ),
      preOp: PreOpModel(
        preOpId: 'pre1',
        operationId: 'op1',
        pastMedicalHistory: 'Coronary Artery Disease',
        occupation: 'Accountant',
        isSmoker: false,
        weightKg: 78.0,
        heightM: 1.70,
        hemoglobin: 13.8,
        t3: 1.4,
        t4: 7.9,
        caseDescription: 'Angina on exertion, Echocardiogram LVEF 55%',
      ),
      complications: [
        ComplicationModel(
          complicationId: 'comp1',
          operationId: 'op1',
          description: 'Postoperative atrial fibrillation',
          dateOfComplication: now.add(const Duration(days: 2)),
          podDay: 2,
          grade: 'Clavien-Dindo Grade II',
          treatment: 'Amiodarone for POAF',
        ),
      ],
      bloodLabs: [
        BloodLabModel(
          labId: 'lab1',
          operationId: 'op1',
          testName: 'Troponin T',
          resultValue: '42 ng/L',
          testDate: now,
        ),
      ],
    );

    final list = [c];

    // Search by MRN
    final res1 = ResearchSearchEngine.searchAllFields(list, 'MRN-999');
    expect(res1.isNotEmpty, true);

    // Search by complication
    final res2 = ResearchSearchEngine.searchAllFields(list, 'POAF');
    expect(res2.isNotEmpty, true);

    // Search by lab test
    final res3 = ResearchSearchEngine.searchAllFields(list, 'Troponin');
    expect(res3.isNotEmpty, true);

    // Search by radiology report
    final res4 = ResearchSearchEngine.searchAllFields(list, 'Echocardiogram');
    expect(res4.isNotEmpty, true);

    // Search by hospital
    final res5 = ResearchSearchEngine.searchAllFields(list, 'Al-Amal');
    expect(res5.isNotEmpty, true);
    expect(res5.first.matchedFields, contains('Hospital: Al-Amal Specialized Hospital'));
  });
}

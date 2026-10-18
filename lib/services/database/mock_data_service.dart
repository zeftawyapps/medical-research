import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/patient_record_brd.dart';
import 'connection/database_connection.dart';

/// Result object for mock data operations
class MockDataResult {
  final bool success;
  final bool alreadySeeded;
  final int insertedCases;
  final String message;

  const MockDataResult({
    required this.success,
    required this.alreadySeeded,
    required this.insertedCases,
    required this.message,
  });
}

/// High-Performance Deterministic Mock Data Service for Clinical Research
/// Generates 500+ comprehensive, realistic clinical cases in English.
/// Strictly idempotent: Prevents duplicate insertions under all circumstances.
class MockDataService {
  static const String prefKeyMockDataSeeded = 'clinical_mock_data_seeded_v1';
  static const String mockPrefix = 'MCK-';
  static const int targetCaseCount = 520;

  final DatabaseConnection _connection = DatabaseConnection();

  Future<Database> get _db => _connection.database;

  /// Checks if mock data has already been seeded in the database or persistent storage
  Future<bool> isMockDataSeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool? isFlagged = prefs.getBool(prefKeyMockDataSeeded);
      if (isFlagged == true) return true;

      final database = await _db;
      final result = await database.rawQuery(
        "SELECT COUNT(*) as count FROM ${PatientTable.tableName} WHERE ${PatientTable.columnMedicalRecordNumber} LIKE 'MRN-$mockPrefix%'",
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      if (count >= 100) {
        // Automatically ensure the preference flag is updated if records already exist
        await prefs.setBool(prefKeyMockDataSeeded, true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking mock data seeded status: $e');
      return false;
    }
  }

  /// Returns the current count of seeded mock cases in the database
  Future<int> getSeededMockCount() async {
    try {
      final database = await _db;
      final result = await database.rawQuery(
        "SELECT COUNT(*) as count FROM ${PatientTable.tableName} WHERE ${PatientTable.columnMedicalRecordNumber} LIKE 'MRN-$mockPrefix%'",
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Seeds 520 complete clinical cases inside a single lightning-fast SQLite batch transaction.
  /// If already seeded, terminates immediately and returns an idempotent response without inserting duplicates.
  Future<MockDataResult> seedMockData({bool force = false}) async {
    final database = await _db;

    if (!force) {
      final alreadySeeded = await isMockDataSeeded();
      if (alreadySeeded) {
        final existingCount = await getSeededMockCount();
        return MockDataResult(
          success: true,
          alreadySeeded: true,
          insertedCases: existingCount,
          message: 'Mock dataset is already installed ($existingCount cases). No duplicates were created.',
        );
      }
    }

    try {
      final List<CompleteClinicalCase> mockCases = _generate520ClinicalCases();

      await database.transaction((txn) async {
        final batch = txn.batch();

        for (final item in mockCases) {
          batch.insert(
            PatientTable.tableName,
            item.patient.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          batch.insert(
            OperationTable.tableName,
            item.operation.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          if (item.preOp != null) {
            batch.insert(
              PreOpTable.tableName,
              item.preOp!.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          if (item.intraOp != null) {
            batch.insert(
              IntraOpTable.tableName,
              item.intraOp!.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          if (item.postOp != null) {
            batch.insert(
              PostOpTable.tableName,
              item.postOp!.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          for (final comp in item.complications) {
            batch.insert(
              ComplicationTable.tableName,
              comp.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          for (final lab in item.bloodLabs) {
            batch.insert(
              BloodLabTable.tableName,
              lab.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          for (final s in item.surveys) {
            batch.insert(
              SurveyTable.tableName,
              s.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true);
      });

      // Mark persistent flag in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyMockDataSeeded, true);

      return MockDataResult(
        success: true,
        alreadySeeded: false,
        insertedCases: mockCases.length,
        message: 'Successfully generated and seeded ${mockCases.length} clinical research cases.',
      );
    } catch (e) {
      debugPrint('Failed to seed mock data batch: $e');
      return MockDataResult(
        success: false,
        alreadySeeded: false,
        insertedCases: 0,
        message: 'Failed to seed mock data: $e',
      );
    }
  }

  /// Cleanly clears ONLY the mock dataset and resets the persistent flag
  Future<int> clearMockData() async {
    try {
      final database = await _db;
      int deletedCount = 0;

      await database.transaction((txn) async {
        // Query patient IDs of mock cases
        final mockPatients = await txn.rawQuery(
          "SELECT ${PatientTable.columnPatientId} FROM ${PatientTable.tableName} WHERE ${PatientTable.columnMedicalRecordNumber} LIKE 'MRN-$mockPrefix%'",
        );

        final patientIds = mockPatients.map((m) => m[PatientTable.columnPatientId] as String).toList();
        deletedCount = patientIds.length;

        if (patientIds.isNotEmpty) {
          // Delete from patients (foreign key CASCADE handles child tables, or we explicitly delete)
          for (final pid in patientIds) {
            await txn.delete(
              PatientTable.tableName,
              where: '${PatientTable.columnPatientId} = ?',
              whereArgs: [pid],
            );
          }
        }
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyMockDataSeeded, false);

      return deletedCount;
    } catch (e) {
      debugPrint('Error clearing mock data: $e');
      return 0;
    }
  }

  // ===========================================================================
  // CLINICAL DATA GENERATOR (520 Real-world English Aesthetic & Reconstructive Cases)
  // ===========================================================================

  static List<CompleteClinicalCase> _generate520ClinicalCases() {
    final List<CompleteClinicalCase> cases = [];

    // Reference pools
    final femaleFirstNames = [
      'Emma', 'Olivia', 'Sophia', 'Isabella', 'Mia', 'Charlotte', 'Amelia', 'Emily',
      'Harper', 'Evelyn', 'Abigail', 'Elizabeth', 'Avery', 'Ella', 'Madison', 'Scarlett',
      'Victoria', 'Aria', 'Grace', 'Chloe', 'Camila', 'Penelope', 'Riley', 'Layla',
      'Lillian', 'Nora', 'Zoey', 'Mila', 'Aubrey', 'Hannah', 'Lily', 'Addison',
      'Eleanor', 'Natalie', 'Luna', 'Savannah', 'Brooklyn', 'Leah', 'Zoe', 'Stella',
      'Hazel', 'Ellie', 'Paisley', 'Audrey', 'Skylar', 'Violet', 'Claire', 'Bella',
      'Aurora', 'Lucy', 'Anna', 'Samantha', 'Caroline', 'Genesis', 'Aaliyah', 'Kennedy',
    ];

    final maleFirstNames = [
      'Liam', 'Noah', 'Oliver', 'James', 'William', 'Benjamin', 'Lucas', 'Henry',
      'Theodore', 'Jack', 'Levi', 'Alexander', 'Jackson', 'Mateo', 'Daniel', 'Michael',
      'Mason', 'Sebastian', 'Ethan', 'Logan', 'Owen', 'Samuel', 'Jacob', 'Asher',
      'Aiden', 'John', 'Joseph', 'Wyatt', 'David', 'Leo', 'Luke', 'Julian',
      'Hudson', 'Grayson', 'Matthew', 'Ezra', 'Gabriel', 'Carter', 'Isaac', 'Jayden',
      'Anthony', 'Dylan', 'Lincoln', 'Thomas', 'Maverick', 'Elias', 'Josiah', 'Charles',
      'Caleb', 'Christopher', 'Ezekiel', 'Miles', 'Jaxon', 'Nathan', 'Ryan', 'Adrian',
    ];

    final lastNames = [
      'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
      'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
      'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson',
      'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson', 'Walker',
      'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill',
      'Flores', 'Green', 'Adams', 'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell',
      'Mitchell', 'Carter', 'Roberts', 'Gomez', 'Phillips', 'Evans', 'Turner', 'Diaz',
    ];

    final countries = [
      'United States', 'United Kingdom', 'Canada', 'Australia', 'Germany',
      'United Arab Emirates', 'Saudi Arabia', 'Egypt', 'Jordan', 'France',
      'Switzerland', 'Kuwait', 'Qatar', 'Oman', 'Ireland',
    ];

    final bloodGroups = ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-'];

    final hospitals = [
      'Harley Street Specialized Surgical Centre',
      'St. Jude Aesthetic & Reconstructive Pavilion',
      'Metropolitan Plastic Surgery Institute',
      'Cleveland Clinic Specialty Hospital',
      'Mayo Surgical Care Center',
      'Al-Safwa Advanced Day Surgery Center',
      'Toronto Cosmetic & Reconstructive Clinic',
      'King Faisal Specialist Surgical Wing',
      'Swiss Alps Aesthetic Clinic Zurich',
      'Emirates International Medical Center',
    ];

    final occupations = [
      'Software Engineer', 'University Professor', 'Registered Nurse', 'Architect',
      'Senior Accountant', 'Corporate Attorney', 'Graphic Designer', 'Marketing Director',
      'Fitness & Wellness Coach', 'Physician', 'Clinical Pharmacist', 'Executive Consultant',
      'Financial Analyst', 'Interior Designer', 'Dentist', 'School Principal',
      'Aviation Pilot', 'Data Scientist', 'Journalist', 'Real Estate Broker',
    ];

    final pastMedicalHistories = [
      'Nil. Otherwise completely healthy with no chronic illnesses.',
      'Controlled Primary Hypertension on Lisinopril 10mg daily.',
      'Well-controlled Type 2 Diabetes Mellitus (HbA1c 6.2%) on Metformin.',
      'Mild Intermittent Bronchial Asthma, well-controlled with Salbutamol PRN.',
      'History of massive weight loss (-38 kg) following lifestyle modification.',
      'Primary Hypothyroidism on Levothyroxine 75 mcg daily (Euthyroid).',
      'Previous uncomplicated Caesarean section (Pfannenstiel incision).',
      'Mild Dyslipidemia managed with dietary adjustments.',
      'Prior open appendectomy in childhood, no current complaints.',
      'No prior surgical history, non-allergic, no chronic medical conditions.',
    ];

    // Procedures specification
    final procedures = [
      {
        'type': '360 Liposuction & Fat Transfer',
        'garmentRequired': true,
        'garmentType': 'Full Body Suit (Abdomen + Thighs)',
        'garmentBrand': 'Lipoelastic Stage 1',
        'fatRange': [2.2, 4.8],
        'femaleRatio': 0.90,
      },
      {
        'type': 'High-Definition Abdominal Liposuction',
        'garmentRequired': true,
        'garmentType': 'Custom Anatomical Foam + Abdominal Vest',
        'garmentBrand': 'Curvee Medical Pro',
        'fatRange': [1.4, 3.2],
        'femaleRatio': 0.50,
      },
      {
        'type': 'Extended Abdominoplasty',
        'garmentRequired': true,
        'garmentType': 'Abdominal Binder / 3-Panel Girdle',
        'garmentBrand': 'Dale Medical Binder',
        'fatRange': [0.8, 2.5],
        'femaleRatio': 0.85,
      },
      {
        'type': 'Bilateral Gynecomastia Correction',
        'garmentRequired': true,
        'garmentType': 'Male Compression Vest (Chest Corset)',
        'garmentBrand': 'Macom Medical Vest',
        'fatRange': [0.4, 1.3],
        'femaleRatio': 0.00, // 100% Male
      },
      {
        'type': 'Primary Dual-Plane Breast Augmentation',
        'garmentRequired': true,
        'garmentType': 'Post-Surgical Sports Bra & Stabilizer Band',
        'garmentBrand': 'Anita Care Rebound',
        'fatRange': [0.0, 0.0],
        'femaleRatio': 1.00, // 100% Female
      },
      {
        'type': 'Mastopexy with Auto-Augmentation',
        'garmentRequired': true,
        'garmentType': 'Post-Surgical Support Bra',
        'garmentBrand': 'Anita Care Support',
        'fatRange': [0.0, 0.0],
        'femaleRatio': 1.00,
      },
      {
        'type': 'Open Preservation Rhinoplasty',
        'garmentRequired': false,
        'garmentType': '',
        'garmentBrand': '',
        'fatRange': [0.0, 0.0],
        'femaleRatio': 0.65,
      },
      {
        'type': 'Bilateral Brachioplasty',
        'garmentRequired': true,
        'garmentType': 'Arm Sleeves with Chest Closure',
        'garmentBrand': 'Design Veronique Sleeves',
        'fatRange': [0.3, 0.9],
        'femaleRatio': 0.85,
      },
      {
        'type': 'Medial Thigh Lift (Cruroplasty)',
        'garmentRequired': true,
        'garmentType': 'High-Waist Thigh Compression Garment',
        'garmentBrand': 'Lipoelastic Stage 2',
        'fatRange': [0.4, 1.4],
        'femaleRatio': 0.90,
      },
      {
        'type': 'Deep Plane Rhytidectomy (Facelift)',
        'garmentRequired': true,
        'garmentType': 'Facial & Neck Support Band',
        'garmentBrand': 'Macom Medical Face Strap',
        'fatRange': [0.0, 0.2],
        'femaleRatio': 0.80,
      },
      {
        'type': 'Blepharoplasty (Upper & Lower)',
        'garmentRequired': false,
        'garmentType': '',
        'garmentBrand': '',
        'fatRange': [0.0, 0.0],
        'femaleRatio': 0.70,
      },
      {
        'type': 'Post-Bariatric Body Contouring',
        'garmentRequired': true,
        'garmentType': 'Combined Torso & Lower Extremity Suit',
        'garmentBrand': 'Marena Recovery Bodysuit',
        'fatRange': [1.0, 3.0],
        'femaleRatio': 0.75,
      },
    ];

    // Complication catalog templates
    final complicationTemplates = [
      {
        'pod': 2,
        'name': 'Localized Hematoma',
        'grade': 'Grade IIIa (Requiring surgical/radiological intervention without GA)',
        'treatment': 'Bedside drainage of organized hematoma under local anesthesia with replacement of closed-suction drain for 48 hours.',
      },
      {
        'pod': 3,
        'name': 'Acute Vasovagal Hypotension',
        'grade': 'Grade I (Minor complication, no specific treatment required)',
        'treatment': 'Patient placed in Trendelenburg position, intravenous bolus of 500ml normal saline, full resolution within 2 hours.',
      },
      {
        'pod': 5,
        'name': 'Early Postoperative Seroma',
        'grade': 'Grade I (Minor complication, no specific treatment required)',
        'treatment': 'Ultrasound-guided percutaneous needle aspiration (35 ml sterile fluid evacuated) and increased garment compression pressure.',
      },
      {
        'pod': 6,
        'name': 'Mild Localized Wound Edge Erythema',
        'grade': 'Grade II (Requiring pharmacological treatment)',
        'treatment': 'Empirical oral antibiotic therapy with Amoxicillin-Clavulanate 1g BID for 7 days, complete clinical resolution.',
      },
      {
        'pod': 8,
        'name': 'Subcutaneous Fluid Accumulation (Seroma)',
        'grade': 'Grade I (Minor complication, no specific treatment required)',
        'treatment': 'Outpatient aspiration of 45cc serosanguinous fluid under aseptic technique. Pressure garment worn continuously for 14 days.',
      },
      {
        'pod': 12,
        'name': 'Superficial Incision Dehiscence (1 cm)',
        'grade': 'Grade I (Minor complication, no specific treatment required)',
        'treatment': 'Local wound cleansing with chlorhexidine, application of topical hydrogel and silver dressing, healed by secondary intention.',
      },
      {
        'pod': 15,
        'name': 'Suture Granuloma at T-Junction',
        'grade': 'Grade I (Minor complication, no specific treatment required)',
        'treatment': 'Removal of offending non-absorbable suture knot in outpatient clinic under topical anesthesia; healed promptly.',
      },
      {
        'pod': 22,
        'name': 'Mild Cellulitis at Inferior Flap Margin',
        'grade': 'Grade II (Requiring pharmacological treatment)',
        'treatment': 'Oral Ciprofloxacin 500mg BID and Clindamycin 300mg TID for 10 days; rapid resolution of warmth and erythema.',
      },
      {
        'pod': 35,
        'name': 'Hypertrophic Scar Formation',
        'grade': 'Grade I (Minor complication, no specific treatment required)',
        'treatment': 'Topical silicone gel sheeting applied twice daily combined with intralesional triamcinolone acetonide (10mg/ml) injection.',
      },
      {
        'pod': 45,
        'name': 'Delayed Mild Asymmetry',
        'grade': 'Grade I (Minor complication, no specific treatment required)',
        'treatment': 'Conservative observation and lymphatic drainage massage; planned for review at 6 months postoperatively.',
      },
    ];

    final now = DateTime.now();

    for (int i = 1; i <= targetCaseCount; i++) {
      final indexStr = i.toString().padLeft(4, '0');
      final patientId = 'mock-pt-$indexStr';
      final operationId = 'mock-op-$indexStr';
      final preOpId = 'mock-preop-$indexStr';
      final intraOpId = 'mock-intraop-$indexStr';
      final postOpId = 'mock-postop-$indexStr';

      // Pick procedure deterministically
      final proc = procedures[(i - 1) % procedures.length];
      final procType = proc['type'] as String;
      final femaleRatio = proc['femaleRatio'] as double;

      // Gender determination
      final isFemale = ((i * 13) % 100) / 100.0 < femaleRatio;
      final gender = isFemale ? 'Female' : 'Male';
      final firstName = isFemale
          ? femaleFirstNames[(i * 7) % femaleFirstNames.length]
          : maleFirstNames[(i * 11) % maleFirstNames.length];
      final lastName = lastNames[(i * 13) % lastNames.length];
      final fullName = '$firstName $lastName';

      // Age: 21 to 65
      final age = 21 + ((i * 17) % 45);
      final birthYear = now.year - age;
      final birthMonth = (i % 12) + 1;
      final birthDay = (i % 28) + 1;
      final dobStr = '$birthYear-${birthMonth.toString().padLeft(2, '0')}-${birthDay.toString().padLeft(2, '0')}';

      final country = countries[(i * 3) % countries.length];
      final bloodGroup = bloodGroups[(i * 5) % bloodGroups.length];
      final hospital = hospitals[(i * 2) % hospitals.length];
      final occupation = occupations[(i * 7) % occupations.length];
      final pmh = pastMedicalHistories[(i * 3) % pastMedicalHistories.length];

      // Surgery date: spread over the last 400 days
      final daysAgo = ((i * 31) % 395) + 2; // from 2 to 397 days ago
      final surgeryDate = now.subtract(Duration(days: daysAgo));

      // Smoker: ~23% smokers
      final isSmoker = (i % 100) < 23;
      final cigarettesPerDay = isSmoker ? (10 + (i % 20)) : null;
      final smokingYears = isSmoker ? (3 + (i % 15)) : null;

      // Height & Weight & BMI
      final heightM = double.parse((1.55 + ((i % 32) * 0.01)).toStringAsFixed(2));
      final weightKg = double.parse((52.0 + ((i * 7) % 42)).toStringAsFixed(1));

      // Labs
      final hb = double.parse((12.0 + ((i % 38) * 0.1)).toStringAsFixed(1));
      final tsh = double.parse((1.2 + ((i % 35) * 0.1)).toStringAsFixed(2));
      final hba1c = double.parse((5.2 + ((i % 25) * 0.1)).toStringAsFixed(1));

      // Intra-op details
      final isGarmentRequired = proc['garmentRequired'] as bool;
      final garmentType = proc['garmentType'] as String;
      final garmentBrand = proc['garmentBrand'] as String;
      final fatRange = proc['fatRange'] as List<double>;
      final minFat = fatRange[0];
      final maxFat = fatRange[1];
      double? amountOfFatLiters;
      if (maxFat > 0) {
        amountOfFatLiters = double.parse(
          (minFat + (((i * 9) % 100) / 100.0) * (maxFat - minFat)).toStringAsFixed(2),
        );
      }

      final operativeNotes = 'Standard sterile preparation and drape under general endotracheal anesthesia. '
          'Surgical procedure: $procType. Infiltration performed with tumescent Klein solution. '
          'Careful surgical dissection preserving cutaneous perforators and underlying neurovascular bundles. '
          'Adequate hemostasis achieved with bipolar electrocautery. Multilayer anatomical closure with Monocryl sutures. '
          '${isGarmentRequired ? 'Sterile dressings placed followed by application of fitted $garmentType.' : 'Protective surgical dressing applied.'} '
          'Patient transferred to PACU in stable condition with no immediate intraoperative complications.';

      // Patient Model
      final patient = PatientModel(
        patientId: patientId,
        medicalRecordNumber: 'MRN-$mockPrefix$indexStr',
        demographics: {
          'name': fullName,
          'gender': gender,
          'dob': dobStr,
          'age': age,
          'blood_group': bloodGroup,
          'country': country,
          'phone': '+1 (555) ${(100 + (i % 899))}-${(1000 + (i % 8999))}',
          'notes': 'Clinical research trial cohort patient #$i.',
        },
        createdAt: surgeryDate.subtract(const Duration(days: 7)),
      );

      // Operation Model
      final operation = OperationModel(
        operationId: operationId,
        patientId: patientId,
        diagnosisDetails: 'Primary surgical indication: $procType evaluation and anatomical correction.',
        operationType: procType,
        hospital: hospital,
        createdAt: surgeryDate,
      );

      // Pre-Op Model
      final preOp = PreOpModel(
        preOpId: preOpId,
        operationId: operationId,
        pastMedicalHistory: pmh,
        occupation: occupation,
        isSmoker: isSmoker,
        cigarettesPerDay: cigarettesPerDay,
        smokingYears: smokingYears,
        weightKg: weightKg,
        heightM: heightM,
        hemoglobin: hb,
        tsh: tsh,
        hba1c: hba1c,
        caseDescription: 'Patient presented for elective $procType. Comprehensive pre-operative clinical examination confirmed suitability for surgical intervention.',
      );

      // Intra-Op Model
      final intraOp = IntraOpModel(
        intraOpId: intraOpId,
        operationId: operationId,
        operativeNotes: operativeNotes,
        amountOfFatLiters: amountOfFatLiters,
        isGarmentRequired: isGarmentRequired,
        garmentType: garmentType,
        garmentBrandModel: garmentBrand,
      );

      // Post-Op Model
      final postOp = PostOpModel(
        postOpId: postOpId,
        operationId: operationId,
        postOpDescription: 'Follow-up evaluated at routine clinical milestone. Surgical scars maturing as anticipated with expected tissue softness and symmetrical contours.',
      );

      // Complications: ~15% incidence (every ~6-7 cases)
      final List<ComplicationModel> complications = [];
      final hasComplication = (i % 6) == 0;
      if (hasComplication) {
        final compTemplate = complicationTemplates[(i ~/ 6) % complicationTemplates.length];
        final pod = compTemplate['pod'] as int;
        final compDate = surgeryDate.add(Duration(days: pod));

        complications.add(
          ComplicationModel(
            complicationId: 'mock-comp-$indexStr-1',
            operationId: operationId,
            description: compTemplate['name'] as String,
            dateOfComplication: compDate,
            podDay: pod,
            treatment: compTemplate['treatment'] as String,
            grade: compTemplate['grade'] as String,
          ),
        );
      }

      // Blood Labs (for ~40% of cases)
      final List<BloodLabModel> labs = [];
      if (i % 2 == 0) {
        labs.add(
          BloodLabModel(
            labId: 'mock-lab-$indexStr-1',
            operationId: operationId,
            testName: 'Hemoglobin (Hb)',
            resultValue: '$hb g/dL',
            testDate: surgeryDate.subtract(const Duration(days: 3)),
          ),
        );
        labs.add(
          BloodLabModel(
            labId: 'mock-lab-$indexStr-2',
            operationId: operationId,
            testName: 'C-Reactive Protein (CRP)',
            resultValue: '${(1.5 + ((i % 15) * 0.4)).toStringAsFixed(1)} mg/L',
            testDate: surgeryDate.add(const Duration(days: 2)),
          ),
        );
      }

      // Surveys (for ~35% of cases)
      final List<SurveyModel> surveys = [];
      if (i % 3 == 0) {
        final painScore = 2 + (i % 6);
        final satisfactionScore = 8 + (i % 3);
        surveys.add(
          SurveyModel(
            surveyId: 'mock-srv-$indexStr-1',
            operationId: operationId,
            surveyType: 'Standardized Pain Visual Analog Scale (VAS)',
            evaluationQuestions: {
              'pod_day': 1,
              'pain_score_1_to_10': painScore,
              'analgesia_required': painScore >= 5 ? 'Oral Tramadol/Paracetamol' : 'Paracetamol only',
            },
          ),
        );
        surveys.add(
          SurveyModel(
            surveyId: 'mock-srv-$indexStr-2',
            operationId: operationId,
            surveyType: 'Postoperative Patient Satisfaction & Aesthetic Outcome',
            evaluationQuestions: {
              'satisfaction_score_1_to_10': satisfactionScore,
              'would_recommend_procedure': 'Yes',
              'contour_symmetry_satisfaction': 'Satisfied to Very Satisfied',
            },
          ),
        );
      }

      cases.add(
        CompleteClinicalCase(
          patient: patient,
          operation: operation,
          preOp: preOp,
          intraOp: intraOp,
          postOp: postOp,
          complications: complications,
          bloodLabs: labs,
          surveys: surveys,
        ),
      );
    }

    return cases;
  }
}

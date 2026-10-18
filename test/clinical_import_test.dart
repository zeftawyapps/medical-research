import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/services/database/clinical_repository.dart';
import 'package:medecat_research/services/import/clinical_import_service.dart';
import 'package:medecat_research/services/backup/clinical_backup_service.dart';
import 'package:medecat_research/models/patient_record_brd.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ClinicalRepository repository;
  late Directory tempDir;

  setUp(() async {
    repository = ClinicalRepository();
    await repository.clearAllData();
    tempDir = await Directory.systemTemp.createTemp('import_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ClinicalImportService Tests', () {
    test('Imports complete cases from JSON backup accurately', () async {
      // 1. Create a dummy patient & operation
      final patientId = 'p-import-001';
      final operationId = 'op-import-001';

      final patient = PatientModel(
        patientId: patientId,
        medicalRecordNumber: 'MRN-IMPORT-99',
        demographics: {
          'name': 'Sarah Jenkins',
          'age': 34,
          'gender': 'Female',
          'phone_number': '+96650000000',
          'blood_group': 'A+',
          'notes': 'Import test',
        },
        createdAt: DateTime.now(),
      );

      final operation = OperationModel(
        operationId: operationId,
        patientId: patientId,
        operationType: 'Breast Augmentation',
        diagnosisDetails: 'Hypoplasia',
        hospital: 'Riyadh Medical Center',
        createdAt: DateTime.now(),
      );

      final cCase = CompleteClinicalCase(
        patient: patient,
        operation: operation,
        complications: [],
        bloodLabs: [],
        surveys: [],
      );

      await repository.insertCompleteCase(cCase);

      // 2. Backup to JSON
      final backup = await ClinicalBackupService.createDatabaseBackup(
        repository: repository,
        customDirectoryPath: tempDir.path,
      );

      expect(backup.patientCount, 1);

      // 3. Clear DB
      await repository.clearAllData();
      final beforePatients = await repository.getAllPatients();
      expect(beforePatients.length, 0);

      // 4. Import from Backup JSON
      final result = await ClinicalImportService.importFromFile(
        backup.file,
        repository: repository,
      );

      expect(result.isSuccess, true);
      expect(result.patientsImported, 1);
      expect(result.operationsImported, 1);

      final afterPatients = await repository.getAllPatients();
      expect(afterPatients.length, 1);
      expect(afterPatients.first.medicalRecordNumber, 'MRN-IMPORT-99');
    });

    test('Imports patient data from CSV format safely with duplicate prevention', () async {
      final csvContent = '''MRN,Patient Name,Age,Gender,Operation Type / Procedure,Diagnosis Details,Hospital / Facility,Pre-Op Hb (g/dL),Pre-Op TSH (µIU/mL),Pre-Op HbA1c (%)
MRN-CSV-101,Emma Watson,29,Female,Rhinoplasty,Dorsal hump,Cosmetic Hospital,14.2,1.8,5.2
MRN-CSV-102,John Doe,45,Male,Liposuction,Flank fat,General Hospital,15.1,2.0,5.6''';

      final csvFile = File('${tempDir.path}/cases.csv');
      await csvFile.writeAsString(csvContent);

      final result = await ClinicalImportService.importFromFile(
        csvFile,
        repository: repository,
        skipDuplicateMrn: true,
      );

      expect(result.isSuccess, true);
      expect(result.patientsImported, 2);
      expect(result.operationsImported, 2);

      final patients = await repository.getAllPatients();
      expect(patients.length, 2);

      // Attempt second import with duplicate skip enabled
      final repeatResult = await ClinicalImportService.importFromFile(
        csvFile,
        repository: repository,
        skipDuplicateMrn: true,
      );

      expect(repeatResult.patientsImported, 0);
      expect(repeatResult.duplicatesSkipped, 2);
    });
  });
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medecat_research/models/patient_record_brd.dart';
import 'package:medecat_research/providers/research_provider.dart';
import 'package:medecat_research/screens/clinical_query_screen.dart';
import 'package:medecat_research/screens/clinical_settings_screen.dart';
import 'package:medecat_research/services/backup/clinical_backup_service.dart';
import 'package:medecat_research/services/export/clinical_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider_macos'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  final sampleCase = CompleteClinicalCase(
    patient: PatientModel(
      patientId: 'p-101',
      medicalRecordNumber: 'MRN-2026-001',
      demographics: {
        'name': 'Sarah Connor',
        'age': 35,
        'gender': 'Female',
        'date_of_birth': '1991-05-14',
        'blood_group': 'A+',
        'phone': '+1234567890',
        'country': 'Egypt',
        'notes': 'Allergic to penicillin',
      },
      createdAt: DateTime(2026, 3, 15, 10, 30),
    ),
    operation: OperationModel(
      operationId: 'op-101',
      patientId: 'p-101',
      diagnosisDetails: 'Abdominal Lipodystrophy & Flaccidity',
      operationType: 'High Definition Liposuction',
      hospital: 'Cairo Surgical Center',
      createdAt: DateTime(2026, 3, 16, 9, 0),
    ),
    preOp: PreOpModel(
      preOpId: 'pre-101',
      operationId: 'op-101',
      pastMedicalHistory: 'Hypertension controlled with ACE inhibitor',
      occupation: 'Architect',
      isSmoker: false,
      weightKg: 68.5,
      heightM: 1.68,
      hemoglobin: 13.8,
      t3: 1.4,
      t4: 8.2,
      caseDescription: 'Good candidate for Body Contouring',
      bloodGroup: 'A+',
    ),
    intraOp: IntraOpModel(
      intraOpId: 'intra-101',
      operationId: 'op-101',
      operativeNotes: 'Tumescent infiltration with VASER assisted lipo',
      amountOfFatLiters: 2.8,
      isGarmentRequired: true,
      garmentType: 'Full Abdominal & Flank Binder',
      garmentBrandModel: 'LipoElastic Stage 1',
    ),
    postOp: PostOpModel(
      postOpId: 'post-101',
      operationId: 'op-101',
      postOpDescription: 'Uneventful recovery. Swelling decreasing rapidly.',
      postOpPictures: ['path/to/pic1.jpg', 'path/to/pic2.jpg'],
    ),
    complications: [
      ComplicationModel(
        complicationId: 'comp-101',
        operationId: 'op-101',
        description: 'Mild seroma in lower abdomen',
        podDay: 5,
        grade: 'Grade I',
        treatment: 'Aspirated in clinic 15ml clear fluid',
        dateOfComplication: DateTime(2026, 3, 21),
      ),
    ],
    bloodLabs: [
      BloodLabModel(
        labId: 'lab-101',
        operationId: 'op-101',
        testName: 'Hemoglobin Post-Op',
        resultValue: '12.4 g/dL',
        testDate: DateTime(2026, 3, 17),
      ),
    ],
    surveys: [
      SurveyModel(
        surveyId: 'srv-101',
        operationId: 'op-101',
        surveyType: 'Satisfaction VAS',
        evaluationQuestions: {'satisfaction_score': 9, 'pain_score': 2},
      ),
    ],
  );

  group('ClinicalExportService Tests', () {
    test('exportToCsv generates valid CSV file with UTF-8 BOM and full patient data', () async {
      final file = await ClinicalExportService.exportToCsv([sampleCase]);

      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      final content = await file.readAsString();

      // Check UTF-8 BOM bytes (EF BB BF)
      expect(bytes.length >= 3, isTrue);
      expect(bytes[0], equals(0xEF));
      expect(bytes[1], equals(0xBB));
      expect(bytes[2], equals(0xBF));

      // Check Headers
      expect(content.contains('MRN,Patient ID,Patient Name,Age,Gender'), isTrue);
      expect(content.contains('Complications Details'), isTrue);

      // Check Data Values
      expect(content.contains('MRN-2026-001'), isTrue);
      expect(content.contains('Sarah Connor'), isTrue);
      expect(content.contains('High Definition Liposuction'), isTrue);
      expect(content.contains('Mild seroma in lower abdomen'), isTrue);
      expect(content.contains('LipoElastic Stage 1'), isTrue);

      // Clean up test file
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('exportToExcel generates valid XLSX file with multiple sheets', () async {
      final file = await ClinicalExportService.exportToExcel([sampleCase]);

      expect(await file.exists(), isTrue);
      final length = await file.length();
      expect(length, greaterThan(100));

      // Clean up test file
      if (await file.exists()) {
        await file.delete();
      }
    });
  });

  group('ClinicalQueryScreen AppBar and Export Actions Widget Tests', () {
    testWidgets('AppBar is rendered with Export options in PopupMenu', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ResearchProvider(),
            child: ClinicalQueryScreen(
              initialCases: [sampleCase],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AppBar is present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.textContaining('Clinical Query & Research Search'), findsOneWidget);

      // Verify AppBar actions
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Open the PopupMenu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verify Export options are present
      expect(find.text('Export to Excel (.xlsx)'), findsOneWidget);
      expect(find.text('Export to CSV (.csv)'), findsOneWidget);
      expect(find.text('Advanced Filter'), findsOneWidget);
      expect(find.text('Refresh Cases'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);

      // Tap Export to Excel (.xlsx)
      await tester.tap(find.text('Export to Excel (.xlsx)'));
      await tester.pumpAndSettle();

      // Allow real async Excel export and disk write to complete
      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 1));
      });
      await tester.pumpAndSettle();

      // Verify export complete dialog appears
      expect(find.text('Data Export Complete'), findsOneWidget);
      expect(find.textContaining('Successfully exported 1 complete patient case records to Excel (.xlsx)'), findsOneWidget);
      expect(find.text('Copy File Path'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Data Export Complete'), findsNothing);

      // Test CSV Export via PopupMenu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export to CSV (.csv)'));
      await tester.pumpAndSettle();

      // Allow real async CSV export and disk write to complete
      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 1));
      });
      await tester.pumpAndSettle();

      // Verify CSV export dialog appears
      expect(find.text('Data Export Complete'), findsOneWidget);
      expect(find.textContaining('Successfully exported 1 complete patient case records to CSV (.csv)'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });
  });

  group('ClinicalBackupService & Custom Directory Tests', () {
    test('createDatabaseBackup creates structured JSON file with all clinical entities', () async {
      final customTempDir = Directory('${Directory.systemTemp.path}/test_backup_${DateTime.now().millisecondsSinceEpoch}');
      await customTempDir.create(recursive: true);

      final result = await ClinicalBackupService.createDatabaseBackup(
        customDirectoryPath: customTempDir.path,
      );

      expect(await result.file.exists(), isTrue);
      expect(result.filePath.startsWith(customTempDir.path), isTrue);
      expect(result.fileSizeBytes, greaterThan(10));
      expect(result.formattedFileSize.isNotEmpty, isTrue);

      final fileContent = await result.file.readAsString();
      expect(fileContent.contains('backup_metadata'), isTrue);
      expect(fileContent.contains('Clinical Research & Surgical Registry'), isTrue);
      expect(fileContent.contains('entity_counts'), isTrue);

      // Clean up
      if (await customTempDir.exists()) {
        await customTempDir.delete(recursive: true);
      }
    });

    test('Custom export and backup directories in ClinicalExportService and ClinicalBackupService', () async {
      final customExportDir = Directory('${Directory.systemTemp.path}/test_custom_export_${DateTime.now().millisecondsSinceEpoch}');
      final customBackupDir = Directory('${Directory.systemTemp.path}/test_custom_backup_${DateTime.now().millisecondsSinceEpoch}');

      final resolvedExport = await ClinicalExportService.getExportDirectory(
        customDirectoryPath: customExportDir.path,
      );
      expect(resolvedExport.path, equals(customExportDir.path));
      expect(await resolvedExport.exists(), isTrue);

      final resolvedBackup = await ClinicalBackupService.getBackupDirectory(
        customDirectoryPath: customBackupDir.path,
      );
      expect(resolvedBackup.path, equals(customBackupDir.path));
      expect(await resolvedBackup.exists(), isTrue);

      // Clean up
      if (await customExportDir.exists()) await customExportDir.delete(recursive: true);
      if (await customBackupDir.exists()) await customBackupDir.delete(recursive: true);
    });

    test('ResearchProvider manages and persists custom export and backup directories', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ResearchProvider();

      expect(provider.customExportDirectory, isEmpty);
      expect(provider.customBackupDirectory, isEmpty);

      const testExportPath = '/Users/test/MedicalExports';
      const testBackupPath = '/Users/test/MedicalBackups';

      await provider.setCustomExportDirectory(testExportPath);
      expect(provider.customExportDirectory, equals(testExportPath));

      await provider.setCustomBackupDirectory(testBackupPath);
      expect(provider.customBackupDirectory, equals(testBackupPath));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ClinicalExportService.prefExportDirectoryKey), equals(testExportPath));
      expect(prefs.getString(ClinicalBackupService.prefBackupDirectoryKey), equals(testBackupPath));

      await provider.resetExportDirectory();
      expect(provider.customExportDirectory, isEmpty);
      expect(prefs.getString(ClinicalExportService.prefExportDirectoryKey), isNull);

      await provider.resetBackupDirectory();
      expect(provider.customBackupDirectory, isEmpty);
      expect(prefs.getString(ClinicalBackupService.prefBackupDirectoryKey), isNull);
    });

    testWidgets('ClinicalSettingsScreen renders Export & Backup Directory Paths section', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final provider = ResearchProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: const ClinicalSettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the Export & Backup Directory Paths section is rendered
      expect(find.text('Export & Backup Directory Paths'), findsOneWidget);
      expect(find.text('Data Export Destination Path'), findsOneWidget);
      expect(find.text('Database Backup Destination Path'), findsOneWidget);
      expect(find.text('Save Export Path'), findsOneWidget);
      expect(find.text('Save Backup Path'), findsOneWidget);
      expect(find.text('Create Backup Now'), findsOneWidget);

      // Verify typing custom export path and saving
      final exportTextField = find.widgetWithText(TextField, 'Export Directory Path');
      expect(exportTextField, findsOneWidget);
      await tester.ensureVisible(exportTextField);
      await tester.enterText(exportTextField, '/Custom/Export/Path');
      final saveExportBtn = find.text('Save Export Path');
      await tester.ensureVisible(saveExportBtn);
      await tester.tap(saveExportBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(provider.customExportDirectory, equals('/Custom/Export/Path'));

      // Verify typing custom backup path and saving
      final backupTextField = find.widgetWithText(TextField, 'Backup Directory Path');
      expect(backupTextField, findsOneWidget);
      await tester.ensureVisible(backupTextField);
      await tester.enterText(backupTextField, '/Custom/Backup/Path');
      final saveBackupBtn = find.text('Save Backup Path');
      await tester.ensureVisible(saveBackupBtn);
      await tester.tap(saveBackupBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(provider.customBackupDirectory, equals('/Custom/Backup/Path'));

      // Tap Reset on Export Path
      final resetButtons = find.text('Reset to Default');
      expect(resetButtons, findsNWidgets(2));
      await tester.ensureVisible(resetButtons.first);
      await tester.tap(resetButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(provider.customExportDirectory, isEmpty);

      // Drain any sqflite deadlock warning timer
      await tester.pump(const Duration(seconds: 11));
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/patient_record_brd.dart';

/// Service for exporting comprehensive clinical and patient research data to Excel and CSV
class ClinicalExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _fileTimestampFormat = DateFormat('yyyyMMdd_HHmmss');
  static const String prefExportDirectoryKey = 'custom_export_directory';

  /// Generates a standardized, timestamped filename guaranteed to include the date (YYYYMMDD_HHmmss)
  static String generateDatedFileName(String? baseName, String extension, [DateTime? date]) {
    final now = date ?? DateTime.now();
    final timestamp = _fileTimestampFormat.format(now);
    final cleanExt = extension.startsWith('.') ? extension.substring(1) : extension;

    if (baseName == null || baseName.trim().isEmpty) {
      return 'clinical_cases_full_export_$timestamp.$cleanExt';
    }

    var name = baseName.trim();
    if (name.toLowerCase().endsWith('.$cleanExt')) {
      name = name.substring(0, name.length - (cleanExt.length + 1));
    }
    // If the name already contains an 8-digit date sequence (YYYYMMDD), don't duplicate
    if (!RegExp(r'\d{8}').hasMatch(name)) {
      return '${name}_$timestamp.$cleanExt';
    }
    return '$name.$cleanExt';
  }

  /// Helper to request necessary storage and all-files permissions on Android
  static Future<void> ensureStoragePermissions() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          await Permission.manageExternalStorage.request();
        }
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
      } catch (_) {}
    }
  }

  /// Helper to convert dynamic cell value to CellValue for Excel 4.x
  static CellValue _toCellValue(dynamic value) {
    if (value == null) return TextCellValue('');
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return TextCellValue(value ? 'Yes' : 'No');
    if (value is DateTime) return TextCellValue(_dateFormat.format(value));
    return TextCellValue(value.toString());
  }

  /// Exports full clinical case list to an Excel (.xlsx) file with multi-sheet breakdown
  static Future<File> exportToExcel(
    List<CompleteClinicalCase> cases, {
    String? customFileName,
    String? customDirectoryPath,
  }) async {
    final excel = Excel.createExcel();

    // Default sheet name in package 'excel' is usually 'Sheet1'
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

    // 1. Sheet 1: Master All-In-One Cohort Export
    const masterSheetName = 'Complete Clinical Cases';
    final masterSheet = excel[masterSheetName];
    excel.setDefaultSheet(masterSheetName);
    if (defaultSheet != masterSheetName && excel.sheets.containsKey(defaultSheet)) {
      excel.delete(defaultSheet);
    }

    final masterHeaders = [
      'MRN',
      'Patient ID',
      'Patient Name',
      'Age',
      'Gender',
      'Date of Birth',
      'Blood Group',
      'Phone Number',
      'Country / Region',
      'Patient Notes',
      'Patient Reg Date',
      'Operation ID',
      'Operation Date',
      'Operation Type / Procedure',
      'Diagnosis Details',
      'Hospital / Facility',
      'Past Medical History',
      'Occupation',
      'Smoking Status',
      'Cigarettes / Day',
      'Smoking Years',
      'Weight (kg)',
      'Height (m)',
      'Calculated BMI',
      'Pre-Op Hb (g/dL)',
      'Pre-Op TSH (µIU/mL)',
      'Pre-Op HbA1c (%)',
      'Pre-Op Case Description',
      'Intra-Op Notes',
      'Fat Aspirated (L)',
      'Garment Required',
      'Garment Type',
      'Garment Brand/Model',
      'Post-Op Description',
      'Post-Op Photos Count',
      'Complications Count',
      'Highest Complication Grade',
      'Complications Details',
      'Blood Lab Tests Count',
      'Blood Labs Summary',
      'Surveys Count',
      'Surveys Summary',
    ];

    masterSheet.appendRow(masterHeaders.map((h) => TextCellValue(h)).toList());

    for (final c in cases) {
      final p = c.patient;
      final op = c.operation;
      final pre = c.preOp;
      final intra = c.intraOp;
      final post = c.postOp;

      final complicationsSummary = c.complications.isEmpty
          ? 'None'
          : c.complications
              .map((comp) =>
                  '[POD ${comp.podDay} | ${comp.grade}] ${comp.description} (Treatment: ${comp.treatment})')
              .join('; ');

      final labsSummary = c.bloodLabs.isEmpty
          ? 'None'
          : c.bloodLabs
              .map((lab) =>
                  '${lab.testName}: ${lab.resultValue} (${_dateFormat.format(lab.testDate)})')
              .join('; ');

      final surveysSummary = c.surveys.isEmpty
          ? 'None'
          : c.surveys
              .map((s) => '${s.surveyType}: ${jsonEncode(s.evaluationQuestions)}')
              .join('; ');

      final row = [
        p.medicalRecordNumber,
        p.patientId,
        p.name,
        p.age,
        p.gender,
        p.dateOfBirth ?? '',
        pre?.bloodGroup ?? p.bloodGroup,
        p.phone,
        p.country,
        p.notes,
        _dateFormat.format(p.createdAt),
        op.operationId,
        _dateFormat.format(op.operationDate),
        op.operationType,
        op.diagnosisDetails,
        op.hospital,
        pre?.pastMedicalHistory ?? '',
        pre?.occupation ?? '',
        pre != null ? (pre.isSmoker ? 'Yes' : 'No') : 'N/A',
        pre?.cigarettesPerDay ?? 0,
        pre?.smokingYears ?? 0,
        pre?.weightKg ?? '',
        pre?.heightM ?? '',
        pre?.bmi?.toStringAsFixed(1) ?? p.bmi ?? '',
        pre?.hemoglobin ?? '',
        pre?.tsh ?? (pre?.t3 ?? ''),
        pre?.hba1c ?? (pre?.t4 ?? ''),
        pre?.caseDescription ?? '',
        intra?.operativeNotes ?? '',
        intra?.amountOfFatLiters ?? '',
        intra != null ? (intra.isGarmentRequired ? 'Yes' : 'No') : 'No',
        intra?.garmentType ?? '',
        intra?.garmentBrandModel ?? '',
        post?.postOpDescription ?? '',
        post?.postOpPictures.length ?? 0,
        c.complications.length,
        c.highestComplicationGrade,
        complicationsSummary,
        c.bloodLabs.length,
        labsSummary,
        c.surveys.length,
        surveysSummary,
      ];

      masterSheet.appendRow(row.map(_toCellValue).toList());
    }

    // 2. Sheet 2: Patients Demographics
    final patientSheet = excel['Patients Demographics'];
    patientSheet.appendRow([
      'Patient ID',
      'MRN',
      'Name',
      'Age',
      'Gender',
      'Date of Birth',
      'Blood Group',
      'Phone',
      'Country',
      'BMI',
      'ASA Score',
      'Notes',
      'Registration Date',
    ].map((h) => TextCellValue(h)).toList());

    final seenPatients = <String>{};
    for (final c in cases) {
      final p = c.patient;
      if (seenPatients.add(p.patientId)) {
        patientSheet.appendRow([
          p.patientId,
          p.medicalRecordNumber,
          p.name,
          p.age,
          p.gender,
          p.dateOfBirth ?? '',
          p.bloodGroup,
          p.phone,
          p.country,
          p.bmi ?? '',
          p.asaScore ?? '',
          p.notes,
          _dateFormat.format(p.createdAt),
        ].map(_toCellValue).toList());
      }
    }

    // 3. Sheet 3: Operations & Procedures
    final opSheet = excel['Operations & Procedures'];
    opSheet.appendRow([
      'Operation ID',
      'Patient ID',
      'MRN',
      'Patient Name',
      'Operation Date',
      'Operation Type / Procedure',
      'Diagnosis Details',
      'Hospital',
    ].map((h) => TextCellValue(h)).toList());

    for (final c in cases) {
      final op = c.operation;
      final p = c.patient;
      opSheet.appendRow([
        op.operationId,
        op.patientId,
        p.medicalRecordNumber,
        p.name,
        _dateFormat.format(op.operationDate),
        op.operationType,
        op.diagnosisDetails,
        op.hospital,
      ].map(_toCellValue).toList());
    }

    // 4. Sheet 4: Complications Registry
    final compSheet = excel['Complications Registry'];
    compSheet.appendRow([
      'Complication ID',
      'Operation ID',
      'MRN',
      'Patient Name',
      'Operation Date',
      'POD Day',
      'Grade',
      'Description',
      'Treatment',
      'Date of Complication',
    ].map((h) => TextCellValue(h)).toList());

    for (final c in cases) {
      for (final comp in c.complications) {
        compSheet.appendRow([
          comp.complicationId,
          comp.operationId,
          c.patient.medicalRecordNumber,
          c.patient.name,
          _dateFormat.format(c.operation.operationDate),
          comp.podDay,
          comp.grade,
          comp.description,
          comp.treatment,
          _dateFormat.format(comp.dateOfComplication),
        ].map(_toCellValue).toList());
      }
    }

    // 5. Sheet 5: Blood Labs
    final labSheet = excel['Blood Labs'];
    labSheet.appendRow([
      'Lab ID',
      'Operation ID',
      'MRN',
      'Patient Name',
      'Test Name',
      'Result Value',
      'Test Date',
    ].map((h) => TextCellValue(h)).toList());

    for (final c in cases) {
      for (final lab in c.bloodLabs) {
        labSheet.appendRow([
          lab.labId,
          lab.operationId,
          c.patient.medicalRecordNumber,
          c.patient.name,
          lab.testName,
          lab.resultValue,
          _dateFormat.format(lab.testDate),
        ].map(_toCellValue).toList());
      }
    }

    // 6. Sheet 6: Patient Surveys
    final surveySheet = excel['Surveys & Scores'];
    surveySheet.appendRow([
      'Survey ID',
      'Operation ID',
      'MRN',
      'Patient Name',
      'Survey Type',
      'Questions & Scores JSON',
    ].map((h) => TextCellValue(h)).toList());

    for (final c in cases) {
      for (final s in c.surveys) {
        surveySheet.appendRow([
          s.surveyId,
          s.operationId,
          c.patient.medicalRecordNumber,
          c.patient.name,
          s.surveyType,
          jsonEncode(s.evaluationQuestions),
        ].map(_toCellValue).toList());
      }
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file bytes.');
    }

    await ensureStoragePermissions();

    final outputDir = await getExportDirectory(customDirectoryPath: customDirectoryPath);
    final fileName = generateDatedFileName(customFileName, 'xlsx');
    File file = File('${outputDir.path}/$fileName');
    try {
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }
      file.writeAsBytesSync(bytes);
    } catch (_) {
      // Fallback to default application documents directory if custom path has OS permission restrictions
      final fallbackDir = await _getDefaultExportDirectory();
      file = File('${fallbackDir.path}/$fileName');
      file.writeAsBytesSync(bytes);
    }

    return file;
  }

  /// Exports full clinical case list to a single comprehensive CSV file (with UTF-8 BOM)
  static Future<File> exportToCsv(
    List<CompleteClinicalCase> cases, {
    String? customFileName,
    String? customDirectoryPath,
  }) async {
    final rows = <List<dynamic>>[];

    // CSV Headers
    rows.add([
      'MRN',
      'Patient ID',
      'Patient Name',
      'Age',
      'Gender',
      'Date of Birth',
      'Blood Group',
      'Phone Number',
      'Country / Region',
      'Patient Notes',
      'Patient Reg Date',
      'Operation ID',
      'Operation Date',
      'Operation Type / Procedure',
      'Diagnosis Details',
      'Hospital / Facility',
      'Past Medical History',
      'Occupation',
      'Smoking Status',
      'Cigarettes / Day',
      'Smoking Years',
      'Weight (kg)',
      'Height (m)',
      'Calculated BMI',
      'Pre-Op Hb (g/dL)',
      'Pre-Op TSH (µIU/mL)',
      'Pre-Op HbA1c (%)',
      'Pre-Op Case Description',
      'Intra-Op Notes',
      'Fat Aspirated (L)',
      'Garment Required',
      'Garment Type',
      'Garment Brand/Model',
      'Post-Op Description',
      'Post-Op Photos Count',
      'Complications Count',
      'Highest Complication Grade',
      'Complications Details',
      'Blood Lab Tests Count',
      'Blood Labs Summary',
      'Surveys Count',
      'Surveys Summary',
    ]);

    for (final c in cases) {
      final p = c.patient;
      final op = c.operation;
      final pre = c.preOp;
      final intra = c.intraOp;
      final post = c.postOp;

      final complicationsSummary = c.complications.isEmpty
          ? 'None'
          : c.complications
              .map((comp) =>
                  '[POD ${comp.podDay} | ${comp.grade}] ${comp.description} (Treatment: ${comp.treatment})')
              .join('; ');

      final labsSummary = c.bloodLabs.isEmpty
          ? 'None'
          : c.bloodLabs
              .map((lab) =>
                  '${lab.testName}: ${lab.resultValue} (${_dateFormat.format(lab.testDate)})')
              .join('; ');

      final surveysSummary = c.surveys.isEmpty
          ? 'None'
          : c.surveys
              .map((s) => '${s.surveyType}: ${jsonEncode(s.evaluationQuestions)}')
              .join('; ');

      rows.add([
        p.medicalRecordNumber,
        p.patientId,
        p.name,
        p.age,
        p.gender,
        p.dateOfBirth ?? '',
        pre?.bloodGroup ?? p.bloodGroup,
        p.phone,
        p.country,
        p.notes,
        _dateFormat.format(p.createdAt),
        op.operationId,
        _dateFormat.format(op.operationDate),
        op.operationType,
        op.diagnosisDetails,
        op.hospital,
        pre?.pastMedicalHistory ?? '',
        pre?.occupation ?? '',
        pre != null ? (pre.isSmoker ? 'Yes' : 'No') : 'N/A',
        pre?.cigarettesPerDay ?? 0,
        pre?.smokingYears ?? 0,
        pre?.weightKg ?? '',
        pre?.heightM ?? '',
        pre?.bmi?.toStringAsFixed(1) ?? p.bmi ?? '',
        pre?.hemoglobin ?? '',
        pre?.tsh ?? (pre?.t3 ?? ''),
        pre?.hba1c ?? (pre?.t4 ?? ''),
        pre?.caseDescription ?? '',
        intra?.operativeNotes ?? '',
        intra?.amountOfFatLiters ?? '',
        intra != null ? (intra.isGarmentRequired ? 'Yes' : 'No') : 'No',
        intra?.garmentType ?? '',
        intra?.garmentBrandModel ?? '',
        post?.postOpDescription ?? '',
        post?.postOpPictures.length ?? 0,
        c.complications.length,
        c.highestComplicationGrade,
        complicationsSummary,
        c.bloodLabs.length,
        labsSummary,
        c.surveys.length,
        surveysSummary,
      ]);
    }

    final csvString = _encodeToCsv(rows);

    // Add UTF-8 BOM (\uFEFF) for Excel & spreadsheet international character support
    final utf8BomString = '\uFEFF$csvString';

    await ensureStoragePermissions();

    final outputDir = await getExportDirectory(customDirectoryPath: customDirectoryPath);
    final fileName = generateDatedFileName(customFileName, 'csv');
    File file = File('${outputDir.path}/$fileName');
    try {
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }
      file.writeAsStringSync(utf8BomString, encoding: utf8);
    } catch (_) {
      // Fallback to default application documents directory if custom path has OS permission restrictions
      final fallbackDir = await _getDefaultExportDirectory();
      file = File('${fallbackDir.path}/$fileName');
      file.writeAsStringSync(utf8BomString, encoding: utf8);
    }

    return file;
  }

  /// Encodes table rows into standard RFC 4180 CSV string
  static String _encodeToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((field) {
        if (field == null) return '';
        final str = field.toString();
        if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\r\n');
  }

  /// Determines appropriate documents / exports directory across platforms
  static Future<Directory> getExportDirectory({String? customDirectoryPath}) async {
    if (customDirectoryPath != null && customDirectoryPath.trim().isNotEmpty) {
      final customDir = Directory(customDirectoryPath.trim());
      if (!await customDir.exists()) {
        await customDir.create(recursive: true);
      }
      return customDir;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString(prefExportDirectoryKey);
      if (savedPath != null && savedPath.trim().isNotEmpty) {
        final customDir = Directory(savedPath.trim());
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }
        return customDir;
      }
    } catch (_) {}

    return await _getDefaultExportDirectory();
  }

  static Future<Directory> _getDefaultExportDirectory() async {
    Directory? dir;
    try {
      dir = await getApplicationDocumentsDirectory()
          .timeout(const Duration(milliseconds: 200));
    } catch (_) {
      try {
        dir = await getDownloadsDirectory()
            .timeout(const Duration(milliseconds: 200));
      } catch (_) {
        try {
          dir = await getTemporaryDirectory()
              .timeout(const Duration(milliseconds: 200));
        } catch (_) {
          dir = Directory.systemTemp;
        }
      }
    }
    dir ??= Directory.systemTemp;
    final exportSubdir = Directory('${dir.path}/clinical_exports');
    if (!await exportSubdir.exists()) {
      await exportSubdir.create(recursive: true);
    }
    return exportSubdir;
  }
}

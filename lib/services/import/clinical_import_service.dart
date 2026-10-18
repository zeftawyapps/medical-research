import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../../models/patient_record_brd.dart';
import '../database/clinical_repository.dart';

/// Result summary of external data import (Excel, CSV, JSON)
class ImportResult {
  final String fileName;
  final int totalRows;
  final int patientsImported;
  final int operationsImported;
  final int preOpsImported;
  final int complicationsImported;
  final int bloodLabsImported;
  final int totalRecordsImported;
  final int duplicatesSkipped;
  final List<String> errorMessages;
  final bool isSuccess;

  const ImportResult({
    required this.fileName,
    required this.totalRows,
    required this.patientsImported,
    required this.operationsImported,
    required this.preOpsImported,
    required this.complicationsImported,
    required this.bloodLabsImported,
    required this.totalRecordsImported,
    required this.duplicatesSkipped,
    required this.errorMessages,
    required this.isSuccess,
  });

  String get summaryMessage {
    if (!isSuccess) {
      return 'Import failed: ${errorMessages.isNotEmpty ? errorMessages.first : "Unknown error"}';
    }
    return 'Imported $patientsImported patients, $operationsImported operations, $complicationsImported complications ($duplicatesSkipped skipped).';
  }
}

/// Robust Service for importing clinical research cases from Excel (.xlsx), CSV (.csv), and JSON files
class ClinicalImportService {
  static const Uuid _uuid = Uuid();

  /// Automatically inspects file extension and routes to appropriate parser
  static Future<ImportResult> importFromFile(
    File file, {
    ClinicalRepository? repository,
    bool skipDuplicateMrn = true,
  }) async {
    final path = file.path.toLowerCase();
    if (path.endsWith('.json')) {
      return await importFromJson(file, repository: repository, skipDuplicates: skipDuplicateMrn);
    } else if (path.endsWith('.xlsx') || path.endsWith('.xls')) {
      return await importFromExcel(file, repository: repository, skipDuplicateMrn: skipDuplicateMrn);
    } else if (path.endsWith('.csv')) {
      return await importFromCsv(file, repository: repository, skipDuplicateMrn: skipDuplicateMrn);
    } else {
      return ImportResult(
        fileName: file.uri.pathSegments.last,
        totalRows: 0,
        patientsImported: 0,
        operationsImported: 0,
        preOpsImported: 0,
        complicationsImported: 0,
        bloodLabsImported: 0,
        totalRecordsImported: 0,
        duplicatesSkipped: 0,
        errorMessages: ['Unsupported file format. Please provide .xlsx, .csv, or .json file.'],
        isSuccess: false,
      );
    }
  }

  /// Imports complete database snapshot or cohort list from JSON
  static Future<ImportResult> importFromJson(
    File file, {
    ClinicalRepository? repository,
    bool skipDuplicates = false,
  }) async {
    final repo = repository ?? ClinicalRepository();
    final fileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'backup.json';
    final List<String> errors = [];

    try {
      final content = await file.readAsString();
      final dynamic decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        return ImportResult(
          fileName: fileName,
          totalRows: 0,
          patientsImported: 0,
          operationsImported: 0,
          preOpsImported: 0,
          complicationsImported: 0,
          bloodLabsImported: 0,
          totalRecordsImported: 0,
          duplicatesSkipped: 0,
          errorMessages: ['Invalid JSON structure: Expected a root JSON object.'],
          isSuccess: false,
        );
      }

      int patientsCount = 0;
      int opsCount = 0;
      int preOpsCount = 0;
      int intraOpsCount = 0;
      int postOpsCount = 0;
      int compCount = 0;
      int bloodCount = 0;
      int surveyCount = 0;
      int skipped = 0;

      final existingPatients = await repo.getAllPatients();
      final existingMrns = existingPatients.map((e) => e.medicalRecordNumber.trim().toLowerCase()).toSet();
      final existingPatientIds = existingPatients.map((e) => e.patientId).toSet();

      // 1. Patients
      if (decoded.containsKey('patients') && decoded['patients'] is List) {
        for (final item in decoded['patients']) {
          if (item is Map<String, dynamic>) {
            try {
              final patient = PatientModel.fromMap(item);
              if (skipDuplicates && (existingMrns.contains(patient.medicalRecordNumber.trim().toLowerCase()) || existingPatientIds.contains(patient.patientId))) {
                skipped++;
                continue;
              }
              await repo.insertPatient(patient);
              existingMrns.add(patient.medicalRecordNumber.trim().toLowerCase());
              existingPatientIds.add(patient.patientId);
              patientsCount++;
            } catch (e) {
              errors.add('Error reading patient record: $e');
            }
          }
        }
      }

      // 2. Operations
      if (decoded.containsKey('operations') && decoded['operations'] is List) {
        for (final item in decoded['operations']) {
          if (item is Map<String, dynamic>) {
            try {
              final op = OperationModel.fromMap(item);
              await repo.insertOperation(op);
              opsCount++;
            } catch (e) {
              errors.add('Error reading operation: $e');
            }
          }
        }
      }

      // 3. Pre-Ops
      if (decoded.containsKey('pre_ops') && decoded['pre_ops'] is List) {
        for (final item in decoded['pre_ops']) {
          if (item is Map<String, dynamic>) {
            try {
              final pre = PreOpModel.fromMap(item);
              await repo.insertPreOp(pre);
              preOpsCount++;
            } catch (e) {
              errors.add('Error reading pre-op assessment: $e');
            }
          }
        }
      }

      // 4. Intra-Ops
      if (decoded.containsKey('intra_ops') && decoded['intra_ops'] is List) {
        for (final item in decoded['intra_ops']) {
          if (item is Map<String, dynamic>) {
            try {
              final intra = IntraOpModel.fromMap(item);
              await repo.insertIntraOp(intra);
              intraOpsCount++;
            } catch (e) {
              errors.add('Error reading intra-op record: $e');
            }
          }
        }
      }

      // 5. Post-Ops
      if (decoded.containsKey('post_ops') && decoded['post_ops'] is List) {
        for (final item in decoded['post_ops']) {
          if (item is Map<String, dynamic>) {
            try {
              final post = PostOpModel.fromMap(item);
              await repo.insertPostOp(post);
              postOpsCount++;
            } catch (e) {
              errors.add('Error reading post-op record: $e');
            }
          }
        }
      }

      // 6. Complications
      if (decoded.containsKey('complications') && decoded['complications'] is List) {
        for (final item in decoded['complications']) {
          if (item is Map<String, dynamic>) {
            try {
              final comp = ComplicationModel.fromMap(item);
              await repo.addComplication(comp);
              compCount++;
            } catch (e) {
              errors.add('Error reading complication: $e');
            }
          }
        }
      }

      // 7. Blood Labs
      if (decoded.containsKey('blood_labs') && decoded['blood_labs'] is List) {
        for (final item in decoded['blood_labs']) {
          if (item is Map<String, dynamic>) {
            try {
              final lab = BloodLabModel.fromMap(item);
              await repo.addBloodLab(lab);
              bloodCount++;
            } catch (e) {
              errors.add('Error reading blood lab: $e');
            }
          }
        }
      }

      // 8. Surveys
      if (decoded.containsKey('surveys') && decoded['surveys'] is List) {
        for (final item in decoded['surveys']) {
          if (item is Map<String, dynamic>) {
            try {
              final survey = SurveyModel.fromMap(item);
              await repo.addSurvey(survey);
              surveyCount++;
            } catch (e) {
              errors.add('Error reading survey: $e');
            }
          }
        }
      }

      final totalImported = patientsCount + opsCount + preOpsCount + intraOpsCount + postOpsCount + compCount + bloodCount + surveyCount;

      return ImportResult(
        fileName: fileName,
        totalRows: totalImported + skipped,
        patientsImported: patientsCount,
        operationsImported: opsCount,
        preOpsImported: preOpsCount,
        complicationsImported: compCount,
        bloodLabsImported: bloodCount,
        totalRecordsImported: totalImported,
        duplicatesSkipped: skipped,
        errorMessages: errors,
        isSuccess: true,
      );
    } catch (e) {
      return ImportResult(
        fileName: fileName,
        totalRows: 0,
        patientsImported: 0,
        operationsImported: 0,
        preOpsImported: 0,
        complicationsImported: 0,
        bloodLabsImported: 0,
        totalRecordsImported: 0,
        duplicatesSkipped: 0,
        errorMessages: ['Failed to parse JSON file: $e'],
        isSuccess: false,
      );
    }
  }

  /// Imports patients and complete cases from Excel spreadsheet (.xlsx)
  static Future<ImportResult> importFromExcel(
    File file, {
    ClinicalRepository? repository,
    bool skipDuplicateMrn = true,
  }) async {
    final repo = repository ?? ClinicalRepository();
    final fileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'data.xlsx';
    final List<String> errors = [];

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return ImportResult(
          fileName: fileName,
          totalRows: 0,
          patientsImported: 0,
          operationsImported: 0,
          preOpsImported: 0,
          complicationsImported: 0,
          bloodLabsImported: 0,
          totalRecordsImported: 0,
          duplicatesSkipped: 0,
          errorMessages: ['Excel workbook contains no sheets.'],
          isSuccess: false,
        );
      }

      final sheetName = excel.tables.keys.firstWhere(
        (k) => k.toLowerCase().contains('case') || k.toLowerCase().contains('patient') || k.toLowerCase().contains('sheet'),
        orElse: () => excel.tables.keys.first,
      );

      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) {
        return ImportResult(
          fileName: fileName,
          totalRows: 0,
          patientsImported: 0,
          operationsImported: 0,
          preOpsImported: 0,
          complicationsImported: 0,
          bloodLabsImported: 0,
          totalRecordsImported: 0,
          duplicatesSkipped: 0,
          errorMessages: ['Selected Excel sheet is empty.'],
          isSuccess: false,
        );
      }

      final headerRow = sheet.rows.first;
      final Map<String, int> headerMap = {};
      for (int i = 0; i < headerRow.length; i++) {
        final cell = headerRow[i];
        if (cell != null && cell.value != null) {
          final title = cell.value.toString().trim().toLowerCase();
          headerMap[title] = i;
        }
      }

      final existingPatients = await repo.getAllPatients();
      final existingMrns = existingPatients.map((e) => e.medicalRecordNumber.trim().toLowerCase()).toSet();

      int patientsImported = 0;
      int opsImported = 0;
      int preOpsImported = 0;
      int compImported = 0;
      int skipped = 0;

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty || row.every((c) => c == null || c.value == null || c.value.toString().trim().isEmpty)) {
          continue;
        }

        try {
          String getVal(List<String> synonyms, [String fallback = '']) {
            for (final syn in synonyms) {
              final idx = headerMap[syn.toLowerCase()];
              if (idx != null && idx < row.length && row[idx] != null && row[idx]!.value != null) {
                final str = row[idx]!.value.toString().trim();
                if (str.isNotEmpty) return str;
              }
            }
            return fallback;
          }

          double getNum(List<String> synonyms, [double fallback = 0.0]) {
            final str = getVal(synonyms);
            if (str.isEmpty) return fallback;
            return double.tryParse(str.replaceAll(RegExp(r'[^0-9.]'), '')) ?? fallback;
          }

          int getInt(List<String> synonyms, [int fallback = 0]) {
            final str = getVal(synonyms);
            if (str.isEmpty) return fallback;
            return int.tryParse(str.replaceAll(RegExp(r'[^0-9]'), '')) ?? fallback;
          }

          final rawMrn = getVal(['mrn', 'medical record number', 'patient mrn', 'code', 'file no', 'id']);
          final mrn = rawMrn.isNotEmpty ? rawMrn : 'MRN-${DateTime.now().millisecondsSinceEpoch % 100000}';

          if (skipDuplicateMrn && existingMrns.contains(mrn.toLowerCase())) {
            skipped++;
            continue;
          }

          final name = getVal(['patient name', 'name', 'full name', 'patient'], 'Imported Patient');
          final age = getInt(['age', 'patient age'], 35);
          final gender = getVal(['gender', 'sex'], 'Female');
          final phone = getVal(['phone number', 'phone', 'mobile', 'contact'], '');
          final bloodGroup = getVal(['blood group', 'blood type', 'abo'], 'O+');
          final notes = getVal(['patient notes', 'notes', 'comments'], 'Imported via Excel');

          final patientId = _uuid.v4();
          final operationId = _uuid.v4();

          final patient = PatientModel(
            patientId: patientId,
            medicalRecordNumber: mrn,
            demographics: {
              'name': name,
              'age': age,
              'gender': gender,
              'phone_number': phone,
              'blood_group': bloodGroup,
              'notes': notes,
            },
            createdAt: DateTime.now(),
          );

          final proc = getVal(['operation type / procedure', 'procedure', 'operation type', 'surgery', 'operation'], 'Aesthetic Procedure');
          final diagnosis = getVal(['diagnosis details', 'diagnosis', 'indication'], 'Clinical Assessment');
          final hospital = getVal(['hospital / facility', 'hospital', 'center', 'facility'], 'Main Surgical Center');
          final pmh = getVal(['past medical history', 'medical history', 'pmh', 'history'], 'None');
          final occupation = getVal(['occupation', 'job'], '');
          final smoking = getVal(['smoking status', 'smoking', 'smoker'], 'Non-smoker');

          final op = OperationModel(
            operationId: operationId,
            patientId: patientId,
            operationType: proc,
            diagnosisDetails: diagnosis,
            hospital: hospital,
            createdAt: DateTime.now(),
          );

          final weight = getNum(['weight (kg)', 'weight', 'wt', 'kg'], 70.0);
          final height = getNum(['height (m)', 'height', 'ht', 'cm', 'm'], 1.68);
          final normHeight = height > 3.0 ? height / 100.0 : height;
          final hb = getNum(['pre-op hb (g/dl)', 'hb', 'hemoglobin'], 13.5);
          final tsh = getNum(['pre-op tsh (µiu/ml)', 'tsh'], 2.1);
          final hba1c = getNum(['pre-op hba1c (%)', 'hba1c'], 5.4);
          final isSmoker = smoking.toLowerCase().contains('yes') || (smoking.toLowerCase().contains('smok') && !smoking.toLowerCase().contains('non'));

          final preOp = PreOpModel(
            preOpId: _uuid.v4(),
            operationId: operationId,
            pastMedicalHistory: pmh,
            occupation: occupation,
            isSmoker: isSmoker,
            weightKg: weight,
            heightM: normHeight,
            hemoglobin: hb,
            tsh: tsh,
            hba1c: hba1c,
            caseDescription: getVal(['pre-op case description', 'pre-op notes'], 'Imported baseline evaluation'),
            bloodGroup: bloodGroup,
          );

          await repo.insertPatient(patient);
          existingMrns.add(mrn.toLowerCase());
          patientsImported++;

          await repo.insertOperation(op);
          opsImported++;

          await repo.insertPreOp(preOp);
          preOpsImported++;

          final compDesc = getVal(['complications details', 'complication', 'complications', 'adverse event']);
          if (compDesc.isNotEmpty && compDesc.toLowerCase() != 'none') {
            final comp = ComplicationModel(
              complicationId: _uuid.v4(),
              operationId: operationId,
              podDay: getInt(['pod day', 'pod'], 7),
              description: compDesc,
              grade: getVal(['highest complication grade', 'grade'], 'Grade I (Minor complication, no specific treatment required)'),
              treatment: getVal(['treatment', 'management'], 'Conservative observation'),
            );
            await repo.addComplication(comp);
            compImported++;
          }
        } catch (rowErr) {
          errors.add('Row $r parsing error: $rowErr');
        }
      }

      final totalImported = patientsImported + opsImported + preOpsImported + compImported;

      return ImportResult(
        fileName: fileName,
        totalRows: sheet.rows.length - 1,
        patientsImported: patientsImported,
        operationsImported: opsImported,
        preOpsImported: preOpsImported,
        complicationsImported: compImported,
        bloodLabsImported: 0,
        totalRecordsImported: totalImported,
        duplicatesSkipped: skipped,
        errorMessages: errors,
        isSuccess: true,
      );
    } catch (e) {
      return ImportResult(
        fileName: fileName,
        totalRows: 0,
        patientsImported: 0,
        operationsImported: 0,
        preOpsImported: 0,
        complicationsImported: 0,
        bloodLabsImported: 0,
        totalRecordsImported: 0,
        duplicatesSkipped: 0,
        errorMessages: ['Failed to read Excel workbook: $e'],
        isSuccess: false,
      );
    }
  }

  /// Imports patients and complete cases from CSV file (.csv)
  static Future<ImportResult> importFromCsv(
    File file, {
    ClinicalRepository? repository,
    bool skipDuplicateMrn = true,
  }) async {
    final repo = repository ?? ClinicalRepository();
    final fileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'data.csv';
    final List<String> errors = [];

    try {
      final content = await file.readAsString();
      final rows = const CsvDecoder().convert(content);

      if (rows.isEmpty) {
        return ImportResult(
          fileName: fileName,
          totalRows: 0,
          patientsImported: 0,
          operationsImported: 0,
          preOpsImported: 0,
          complicationsImported: 0,
          bloodLabsImported: 0,
          totalRecordsImported: 0,
          duplicatesSkipped: 0,
          errorMessages: ['CSV file is empty.'],
          isSuccess: false,
        );
      }

      final headerRow = rows.first;
      final Map<String, int> headerMap = {};
      for (int i = 0; i < headerRow.length; i++) {
        final title = headerRow[i].toString().trim().toLowerCase();
        headerMap[title] = i;
      }

      final existingPatients = await repo.getAllPatients();
      final existingMrns = existingPatients.map((e) => e.medicalRecordNumber.trim().toLowerCase()).toSet();

      int patientsImported = 0;
      int opsImported = 0;
      int preOpsImported = 0;
      int compImported = 0;
      int skipped = 0;

      for (int r = 1; r < rows.length; r++) {
        final row = rows[r];
        if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) continue;

        try {
          String getVal(List<String> synonyms, [String fallback = '']) {
            for (final syn in synonyms) {
              final idx = headerMap[syn.toLowerCase()];
              if (idx != null && idx < row.length) {
                final str = row[idx].toString().trim();
                if (str.isNotEmpty) return str;
              }
            }
            return fallback;
          }

          double getNum(List<String> synonyms, [double fallback = 0.0]) {
            final str = getVal(synonyms);
            if (str.isEmpty) return fallback;
            return double.tryParse(str.replaceAll(RegExp(r'[^0-9.]'), '')) ?? fallback;
          }

          int getInt(List<String> synonyms, [int fallback = 0]) {
            final str = getVal(synonyms);
            if (str.isEmpty) return fallback;
            return int.tryParse(str.replaceAll(RegExp(r'[^0-9]'), '')) ?? fallback;
          }

          final rawMrn = getVal(['mrn', 'medical record number', 'patient mrn', 'code', 'file no', 'id']);
          final mrn = rawMrn.isNotEmpty ? rawMrn : 'MRN-${DateTime.now().millisecondsSinceEpoch % 100000}';

          if (skipDuplicateMrn && existingMrns.contains(mrn.toLowerCase())) {
            skipped++;
            continue;
          }

          final name = getVal(['patient name', 'name', 'full name', 'patient'], 'Imported Patient');
          final age = getInt(['age', 'patient age'], 35);
          final gender = getVal(['gender', 'sex'], 'Female');
          final phone = getVal(['phone number', 'phone', 'mobile', 'contact'], '');
          final bloodGroup = getVal(['blood group', 'blood type', 'abo'], 'O+');
          final notes = getVal(['patient notes', 'notes', 'comments'], 'Imported via CSV');

          final patientId = _uuid.v4();
          final operationId = _uuid.v4();

          final patient = PatientModel(
            patientId: patientId,
            medicalRecordNumber: mrn,
            demographics: {
              'name': name,
              'age': age,
              'gender': gender,
              'phone_number': phone,
              'blood_group': bloodGroup,
              'notes': notes,
            },
            createdAt: DateTime.now(),
          );

          final proc = getVal(['operation type / procedure', 'procedure', 'operation type', 'surgery', 'operation'], 'Aesthetic Procedure');
          final diagnosis = getVal(['diagnosis details', 'diagnosis', 'indication'], 'Clinical Assessment');
          final hospital = getVal(['hospital / facility', 'hospital', 'center', 'facility'], 'Main Surgical Center');
          final pmh = getVal(['past medical history', 'medical history', 'pmh', 'history'], 'None');
          final occupation = getVal(['occupation', 'job'], '');
          final smoking = getVal(['smoking status', 'smoking', 'smoker'], 'Non-smoker');

          final op = OperationModel(
            operationId: operationId,
            patientId: patientId,
            operationType: proc,
            diagnosisDetails: diagnosis,
            hospital: hospital,
            createdAt: DateTime.now(),
          );

          final weight = getNum(['weight (kg)', 'weight', 'wt', 'kg'], 70.0);
          final height = getNum(['height (m)', 'height', 'ht', 'cm', 'm'], 1.68);
          final normHeight = height > 3.0 ? height / 100.0 : height;
          final hb = getNum(['pre-op hb (g/dl)', 'hb', 'hemoglobin'], 13.5);
          final tsh = getNum(['pre-op tsh (µiu/ml)', 'tsh'], 2.1);
          final hba1c = getNum(['pre-op hba1c (%)', 'hba1c'], 5.4);
          final isSmoker = smoking.toLowerCase().contains('yes') || (smoking.toLowerCase().contains('smok') && !smoking.toLowerCase().contains('non'));

          final preOp = PreOpModel(
            preOpId: _uuid.v4(),
            operationId: operationId,
            pastMedicalHistory: pmh,
            occupation: occupation,
            isSmoker: isSmoker,
            weightKg: weight,
            heightM: normHeight,
            hemoglobin: hb,
            tsh: tsh,
            hba1c: hba1c,
            caseDescription: getVal(['pre-op case description', 'pre-op notes'], 'Imported baseline evaluation'),
            bloodGroup: bloodGroup,
          );

          await repo.insertPatient(patient);
          existingMrns.add(mrn.toLowerCase());
          patientsImported++;

          await repo.insertOperation(op);
          opsImported++;

          await repo.insertPreOp(preOp);
          preOpsImported++;

          final compDesc = getVal(['complications details', 'complication', 'complications', 'adverse event']);
          if (compDesc.isNotEmpty && compDesc.toLowerCase() != 'none') {
            final comp = ComplicationModel(
              complicationId: _uuid.v4(),
              operationId: operationId,
              podDay: getInt(['pod day', 'pod'], 7),
              description: compDesc,
              grade: getVal(['highest complication grade', 'grade'], 'Grade I (Minor complication, no specific treatment required)'),
              treatment: getVal(['treatment', 'management'], 'Conservative observation'),
            );
            await repo.addComplication(comp);
            compImported++;
          }
        } catch (rowErr) {
          errors.add('Row $r parsing error: $rowErr');
        }
      }

      final totalImported = patientsImported + opsImported + preOpsImported + compImported;

      return ImportResult(
        fileName: fileName,
        totalRows: rows.length - 1,
        patientsImported: patientsImported,
        operationsImported: opsImported,
        preOpsImported: preOpsImported,
        complicationsImported: compImported,
        bloodLabsImported: 0,
        totalRecordsImported: totalImported,
        duplicatesSkipped: skipped,
        errorMessages: errors,
        isSuccess: true,
      );
    } catch (e) {
      return ImportResult(
        fileName: fileName,
        totalRows: 0,
        patientsImported: 0,
        operationsImported: 0,
        preOpsImported: 0,
        complicationsImported: 0,
        bloodLabsImported: 0,
        totalRecordsImported: 0,
        duplicatesSkipped: 0,
        errorMessages: ['Failed to read CSV file: $e'],
        isSuccess: false,
      );
    }
  }
}

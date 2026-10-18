import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/clinical_repository.dart';

/// Result summary metadata for clinical database backup operations
class BackupResult {
  final File file;
  final String filePath;
  final int fileSizeBytes;
  final DateTime timestamp;
  final int patientCount;
  final int operationCount;
  final int complicationCount;
  final int totalRecords;

  const BackupResult({
    required this.file,
    required this.filePath,
    required this.fileSizeBytes,
    required this.timestamp,
    required this.patientCount,
    required this.operationCount,
    required this.complicationCount,
    required this.totalRecords,
  });

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Service for creating full database snapshots and backups to local storage
class ClinicalBackupService {
  static final DateFormat _timestampFormat = DateFormat('yyyyMMdd_HHmmss');
  static const String prefBackupDirectoryKey = 'custom_backup_directory';

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

  /// Resolves the effective backup directory (custom preference or default documents subfolder)
  static Future<Directory> getBackupDirectory({String? customDirectoryPath}) async {
    if (customDirectoryPath != null && customDirectoryPath.trim().isNotEmpty) {
      final customDir = Directory(customDirectoryPath.trim());
      if (!await customDir.exists()) {
        await customDir.create(recursive: true);
      }
      return customDir;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString(prefBackupDirectoryKey);
      if (savedPath != null && savedPath.trim().isNotEmpty) {
        final customDir = Directory(savedPath.trim());
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }
        return customDir;
      }
    } catch (_) {}

    return await _getDefaultBackupDirectory();
  }

  /// Default cross-platform backup directory
  static Future<Directory> _getDefaultBackupDirectory() async {
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
    final backupSubdir = Directory('${dir.path}/clinical_backups');
    if (!await backupSubdir.exists()) {
      await backupSubdir.create(recursive: true);
    }
    return backupSubdir;
  }

  /// Creates a full structured JSON backup of all clinical entities
  static Future<BackupResult> createDatabaseBackup({
    ClinicalRepository? repository,
    String? customDirectoryPath,
    String? customFileName,
  }) async {
    final repo = repository ?? ClinicalRepository();

    final patients = await repo.getAllPatients();
    final operations = await repo.getAllOperations();
    final preOps = await repo.getAllPreOps();
    final intraOps = await repo.getAllIntraOps();
    final postOps = await repo.getAllPostOps();
    final complications = await repo.getAllComplications();
    final bloodLabs = await repo.getAllBloodLabs();
    final surveys = await repo.getAllSurveys();
    final catalog = await repo.getProcedureCatalog();
    final templates = await repo.getAllTemplates();
    final abstracts = await repo.getAllAbstracts();

    final now = DateTime.now();
    final backupData = {
      'backup_metadata': {
        'version': 2,
        'app_name': 'Clinical Research & Surgical Registry',
        'created_at': now.toIso8601String(),
        'entity_counts': {
          'patients': patients.length,
          'operations': operations.length,
          'pre_ops': preOps.length,
          'intra_ops': intraOps.length,
          'post_ops': postOps.length,
          'complications': complications.length,
          'blood_labs': bloodLabs.length,
          'surveys': surveys.length,
          'procedure_catalog': catalog.length,
          'templates': templates.length,
          'abstracts': abstracts.length,
        }
      },
      'patients': patients.map((e) => e.toMap()).toList(),
      'operations': operations.map((e) => e.toMap()).toList(),
      'pre_ops': preOps.map((e) => e.toMap()).toList(),
      'intra_ops': intraOps.map((e) => e.toMap()).toList(),
      'post_ops': postOps.map((e) => e.toMap()).toList(),
      'complications': complications.map((e) => e.toMap()).toList(),
      'blood_labs': bloodLabs.map((e) => e.toMap()).toList(),
      'surveys': surveys.map((e) => e.toMap()).toList(),
      'procedure_catalog': catalog.map((e) => e.toMap()).toList(),
      'templates': templates.map((e) => e.toMap()).toList(),
      'abstracts': abstracts.map((e) => e.toMap()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    await ensureStoragePermissions();
    final targetDir = await getBackupDirectory(customDirectoryPath: customDirectoryPath);
    final fileName = customFileName ?? 'clinical_backup_${_timestampFormat.format(now)}.json';
    File file = File('${targetDir.path}/$fileName');

    try {
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }
      file.writeAsStringSync(jsonString, encoding: utf8);
    } catch (_) {
      // Fallback to default application documents backup directory if custom path has OS restrictions
      final fallbackDir = await _getDefaultBackupDirectory();
      file = File('${fallbackDir.path}/$fileName');
      file.writeAsStringSync(jsonString, encoding: utf8);
    }
    final fileLength = file.lengthSync();

    final totalRecords = patients.length +
        operations.length +
        preOps.length +
        intraOps.length +
        postOps.length +
        complications.length +
        bloodLabs.length +
        surveys.length;

    return BackupResult(
      file: file,
      filePath: file.path,
      fileSizeBytes: fileLength,
      timestamp: now,
      patientCount: patients.length,
      operationCount: operations.length,
      complicationCount: complications.length,
      totalRecords: totalRecords,
    );
  }
}

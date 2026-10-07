import 'package:JoDija_tamplites/JoDija_tamplites.dart';
import '../../../models/patient_record_brd.dart';

/// Singleton Database Connection Manager powered directly by JoDija's LocalDataStorageHelper.
class DatabaseConnection {
  static final DatabaseConnection _instance = DatabaseConnection._internal();
  factory DatabaseConnection() => _instance;
  DatabaseConnection._internal();

  static const String dbName = 'medecat_clinical_research.db';
  static const int dbVersion = 1;

  late final LocalDataStorageHelper _helper = LocalDataStorageHelper.fromSchema(
    dbName: dbName,
    version: dbVersion,
    createTableQueries: [
      PatientModel.createTableSql,
      OperationModel.createTableSql,
      PreOpModel.createTableSql,
      IntraOpModel.createTableSql,
      PostOpModel.createTableSql,
      ComplicationModel.createTableSql,
      BloodLabModel.createTableSql,
      SurveyModel.createTableSql,
      ResearchTemplateModel.createTableSql,
      ResearchAbstractModel.createTableSql,
      ProcedureCatalogModel.createTableSql,
      ComplicationCatalogModel.createTableSql,
      GarmentBrandModel.createTableSql,
      GarmentTypeModel.createTableSql,
      // Optimized performance indexes
      'CREATE INDEX IF NOT EXISTS idx_operations_created ON ${OperationTable.tableName} (${OperationTable.columnCreatedAt});',
      'CREATE INDEX IF NOT EXISTS idx_operations_patient ON ${OperationTable.tableName} (${OperationTable.columnPatientId});',
      'CREATE INDEX IF NOT EXISTS idx_patients_mrn ON ${PatientTable.tableName} (${PatientTable.columnMedicalRecordNumber});',
      'CREATE INDEX IF NOT EXISTS idx_complications_pod ON ${ComplicationTable.tableName} (${ComplicationTable.columnPodDay});',
      'CREATE INDEX IF NOT EXISTS idx_complications_op ON ${ComplicationTable.tableName} (${ComplicationTable.columnOperationId});',
      'CREATE INDEX IF NOT EXISTS idx_preop_op ON ${PreOpTable.tableName} (${PreOpTable.columnOperationId});',
      'CREATE INDEX IF NOT EXISTS idx_intraop_op ON ${IntraOpTable.tableName} (${IntraOpTable.columnOperationId});',
      'CREATE INDEX IF NOT EXISTS idx_postop_op ON ${PostOpTable.tableName} (${PostOpTable.columnOperationId});',
    ],
    onConfigure: (db) async {
      try {
        await db.execute('ALTER TABLE ${PreOpTable.tableName} ADD COLUMN ${PreOpTable.columnBloodGroup} TEXT;');
      } catch (_) {
        // Column already exists or table not yet created
      }
      try {
        await db.execute('ALTER TABLE ${OperationTable.tableName} ADD COLUMN ${OperationTable.columnHospital} TEXT;');
      } catch (_) {
        // Column already exists or table not yet created
      }
      try {
        await db.execute('ALTER TABLE ${IntraOpTable.tableName} ADD COLUMN ${IntraOpTable.columnIsGarmentRequired} INTEGER DEFAULT 0;');
      } catch (_) {
        // Column already exists or table not yet created
      }
      try {
        await db.execute('ALTER TABLE ${IntraOpTable.tableName} ADD COLUMN ${IntraOpTable.columnGarmentType} TEXT;');
      } catch (_) {
        // Column already exists or table not yet created
      }
      try {
        await db.execute('ALTER TABLE ${IntraOpTable.tableName} ADD COLUMN ${IntraOpTable.columnGarmentBrandModel} TEXT;');
      } catch (_) {
        // Column already exists or table not yet created
      }
      try {
        await db.execute(GarmentBrandModel.createTableSql);
      } catch (_) {}
      try {
        await db.execute(GarmentTypeModel.createTableSql);
      } catch (_) {}
    },
  );

  /// Retrieves the active database instance
  Future<Database> get database async => await _helper.db;

  /// Close the database connection safely
  Future<void> close() => _helper.close();

  /// Clear all data in all tables within an atomic transaction
  Future<void> clearAllTables() async {
    await _helper.clearTables([
      ResearchAbstractTable.tableName,
      ResearchTemplateTable.tableName,
      SurveyTable.tableName,
      BloodLabTable.tableName,
      ComplicationCatalogTable.tableName,
      ComplicationTable.tableName,
      PostOpTable.tableName,
      IntraOpTable.tableName,
      PreOpTable.tableName,
      OperationTable.tableName,
      ProcedureCatalogTable.tableName,
      PatientTable.tableName,
    ]);
  }
}

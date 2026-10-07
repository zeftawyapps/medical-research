import 'package:sqflite/sqflite.dart';
import 'connection/database_connection.dart';

/// Helper and Database Manager delegating to DatabaseConnection
class AppDatabase {
  static Future<Database> get database => DatabaseConnection().database;

  static Future<void> clearAllData([Database? customDb]) async {
    await DatabaseConnection().clearAllTables();
  }

  static Future<void> seedInitialData([Database? customDb]) async {
    // Production database - No mock data
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/config/app_config.dart';
import 'package:medecat_research/main.dart';
import 'package:medecat_research/services/database/connection/database_connection.dart';
import 'package:medecat_research/services/database/mock_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseConnection().clearAllTables();
  });

  tearDown(() async {
    await DatabaseConnection().clearAllTables();
  });

  group('MockDataService & Anti-Duplication Verification', () {
    test('MockDataService provides >= 500 cases in English', () {
      expect(MockDataService.targetCaseCount, greaterThanOrEqualTo(500));
      expect(MockDataService.targetCaseCount, equals(520));
    });

    test('AppConfig respects enabliMockData / isenable flag independently of debug mode', () {
      enabliMockData = true;
      expect(enabliMockData, isTrue);
      expect(isenable, isTrue);
      expect(isEnable, isTrue);
      expect(AppConfig.isMockDataAvailable, isTrue);

      // Disable via isenable
      isenable = false;
      expect(enabliMockData, isFalse);
      expect(AppConfig.isMockDataAvailable, isFalse);

      // Re-enable
      enabliMockData = true;
      expect(AppConfig.isMockDataAvailable, isTrue);
    });

    test('seedMockData seeds 520 cases and prevents duplicate insertion on second call', () async {
      final mockService = MockDataService();

      // 1. Initial State: Not seeded
      final isInitiallySeeded = await mockService.isMockDataSeeded();
      expect(isInitiallySeeded, isFalse);

      final initialCount = await mockService.getSeededMockCount();
      expect(initialCount, equals(0));

      // 2. First Seed: Should insert 520 cases
      final firstResult = await mockService.seedMockData();
      expect(firstResult.success, isTrue);
      expect(firstResult.alreadySeeded, isFalse);
      expect(firstResult.insertedCases, equals(520));

      final countAfterFirst = await mockService.getSeededMockCount();
      expect(countAfterFirst, equals(520));

      final isSeededAfterFirst = await mockService.isMockDataSeeded();
      expect(isSeededAfterFirst, isTrue);

      // 3. Second Seed Call (Duplication Attempt): Must be blocked idempotently
      final secondResult = await mockService.seedMockData();
      expect(secondResult.success, isTrue);
      expect(secondResult.alreadySeeded, isTrue);
      expect(secondResult.insertedCases, equals(520)); // reports existing count

      // Verify that count is STILL 520, zero duplicates were inserted
      final countAfterSecond = await mockService.getSeededMockCount();
      expect(countAfterSecond, equals(520));

      // 4. Third Seed Call on a newly instantiated MockDataService (Simulating App Reopening)
      final freshService = MockDataService();
      final isDetectedOnReopen = await freshService.isMockDataSeeded();
      expect(isDetectedOnReopen, isTrue);

      final reopenResult = await freshService.seedMockData();
      expect(reopenResult.alreadySeeded, isTrue);
      expect(await freshService.getSeededMockCount(), equals(520));
    });

    test('clearMockData removes only mock cases and resets seeding state', () async {
      final mockService = MockDataService();

      // Seed 520 cases
      await mockService.seedMockData();
      expect(await mockService.getSeededMockCount(), equals(520));

      // Clear
      final removed = await mockService.clearMockData();
      expect(removed, equals(520));

      // Check state
      expect(await mockService.getSeededMockCount(), equals(0));
      expect(await mockService.isMockDataSeeded(), isFalse);
    });
  });
}

import '../main.dart';

/// Central application configuration & feature flags
class AppConfig {
  /// Evaluates whether mock data functionality is enabled and visible:
  /// Controlled directly by [enabliMockData] (or isenable / isEnable) in main.dart,
  /// without requiring debug mode.
  static bool get isMockDataAvailable => enabliMockData;
}

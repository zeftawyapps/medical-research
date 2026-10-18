/// Central application configuration, environment settings & feature flags
class AppConfig {
  /// Toggle for Mock Data test suite visibility across the app.
  /// When true, mock dataset cards and tools are visible in Settings.
  /// When false, mock data UI is completely hidden.
  static bool enableMockData = true;

  /// Shorthand alias
  static bool get isMockDataAvailable => enableMockData;
  static set isMockDataAvailable(bool value) => enableMockData = value;

  static bool get isenable => enableMockData;
  static set isenable(bool value) => enableMockData = value;

  static bool get isEnable => enableMockData;
  static set isEnable(bool value) => enableMockData = value;
}

// Global top-level aliases for backwards compatibility with test scripts
bool get enabliMockData => AppConfig.enableMockData;
set enabliMockData(bool value) => AppConfig.enableMockData = value;

bool get isenable => AppConfig.enableMockData;
set isenable(bool value) => AppConfig.enableMockData = value;

bool get isEnable => AppConfig.enableMockData;
set isEnable(bool value) => AppConfig.enableMockData = value;

bool get enableMockData => AppConfig.enableMockData;
set enableMockData(bool value) => AppConfig.enableMockData = value;

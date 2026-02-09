class AppConstants {
  AppConstants._();

  static const String appName = 'BUS - Roma';
  static const String appVersion = '0.0.16';
  static const int dbBatchSize = 5000;
  static const double defaultLatitude = 41.9028;
  static const double defaultLongitude = 12.4964;
  static const double nearbyRadiusMeters = 1000.0;
  static const double tripPlanNearbyRadiusMeters = 1000.0;
  static const double walkingTransferMaxMeters = 700.0;
  static const double walkingSpeedMps = 1.2;
  static const String prefsKeyLastSync = 'last_sync_date';
  static const String prefsKeyThemeMode = 'theme_mode';
}

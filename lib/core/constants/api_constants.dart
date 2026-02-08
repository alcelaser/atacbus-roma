class ApiConstants {
  ApiConstants._();

  static const String gtfsStaticUrl =
      'https://romamobilita.it/sites/default/files/rome_static_gtfs.zip';
  static const String gtfsRtTripUpdatesUrl =
      'https://romamobilita.it/sites/default/files/rome_rtgtfs_trip_updates_feed.pb';
  static const String gtfsRtVehiclePositionsUrl =
      'https://romamobilita.it/sites/default/files/rome_rtgtfs_vehicle_positions_feed.pb';
  static const String gtfsRtServiceAlertsUrl =
      'https://romamobilita.it/sites/default/files/rome_rtgtfs_service_alerts_feed.pb';

  static const Duration rtRefreshInterval = Duration(seconds: 30);
  static const Duration staticRefreshInterval = Duration(hours: 24);
}

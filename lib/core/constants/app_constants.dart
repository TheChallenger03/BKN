class AppConstants {
  //Database
  static const String databaseName = 'BKN.db';
  static const int databaseVersion = 1;
  static const String locationsTable = 'locations';

  //OpenRouteService API
  static const String openRouteServiceBaseUrl = 'https://api.openrouteservice.org';
  static const String openRouteServiceDirectionsPath = '/v2/directions/foot-walking';
  static const String openRouteServiceApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjljZTcwMDI5MWIwMTQ2NjA5MjFlYjRkYmU2ZWRkY2IwIiwiaCI6Im11cm11cjY0In0=';

  //Geolocation Settings
  static const int locationUpdateIntervalSeconds = 5;
  static const double routeRecalculationThresholdMeters = 10.0;
  static const int routeRecalculationCooldownSeconds = 30;

  //Map Settings
  static const double defaultZoom = 15.0;
  static const double navigationZoom = 17.0;
  static const String osmTileUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

  //UI
  static const double listItemHeight = 72.0;
  static const int maxLabelLength = 50;

  AppConstants._(); //Private constructor to prevent instantiation
}
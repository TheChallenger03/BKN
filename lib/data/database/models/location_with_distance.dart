import '../app_database.dart';

/// Modello che rappresenta una location con la sua distanza da un punto di riferimento
class LocationWithDistance {
  /// Location salvata
  final SavedLocation location;
  
  /// Distanza in chilometri dal punto di riferimento
  final double distanceKm;
  
  LocationWithDistance({
    required this.location,
    required this.distanceKm,
  });
  
  /// Distanza formattata in metri o chilometri
  String get formattedDistance => 
      distanceKm < 1 
          ? '${(distanceKm * 1000).toStringAsFixed(0)} m'
          : '${distanceKm.toStringAsFixed(2)} km';
  
  /// Distanza in metri
  double get distanceMeters => distanceKm * 1000;
  
  /// Verifica se la location è vicina (< 100m)
  bool get isNearby => distanceKm < 0.1;
  
  @override
  String toString() => 
      'LocationWithDistance(distance: $formattedDistance)';
}

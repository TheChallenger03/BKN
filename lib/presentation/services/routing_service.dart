import 'package:latlong2/latlong.dart';
import '../../domain/entities/route_info.dart';
import '../../core/constants/app_constants.dart';

/// Servizio per la gestione della logica di routing
/// 
/// Separa la responsabilità di calcolo e manipolazione dei percorsi
/// dal state management della mappa.
class RoutingService {
  final Distance _distance = const Distance();

  /// Determina se il percorso deve essere ricalcolato
  /// 
  /// Verifica se la posizione attuale è troppo distante dal percorso corrente
  bool shouldRecalculateRoute({
    required LatLng currentPosition,
    required RouteInfo currentRoute,
  }) {
    assert(currentRoute.coordinates.isNotEmpty, 'Route coordinates cannot be empty');
    
    if (currentRoute.coordinates.isEmpty) return true;

    final minDistance = findClosestPoint(
      position: currentPosition,
      points: currentRoute.coordinates,
    ).distance;

    return minDistance > AppConstants.routeRecalculationThresholdMeters;
  }

  /// Taglia il percorso fino alla posizione corrente
  /// 
  /// Rimuove i punti del percorso già attraversati per ottimizzare
  /// la visualizzazione e il calcolo delle distanze rimanenti.
  RouteInfo? trimRouteToPosition({
    required LatLng currentPosition,
    required RouteInfo route,
  }) {
    if (route.coordinates.length <= 2) return null;

    final closest = findClosestPoint(
      position: currentPosition,
      points: route.coordinates,
    );

    // Se il punto più vicino è molto vicino (< 15m) e non è il primo
    if (closest.distance < 15.0 && closest.index > 0) {
      final trimmedCoordinates = route.coordinates.sublist(closest.index);
      
      if (trimmedCoordinates.length >= 2) {
        return RouteInfo(
          coordinates: trimmedCoordinates,
          distance: route.distance,
          duration: route.duration,
        );
      }
    }

    return null;
  }

  /// Trova il punto più vicino alla posizione corrente
  /// 
  /// Usa la formula di Haversine per calcolare la distanza
  /// tra la posizione e ogni punto del percorso.
  ({int index, double distance}) findClosestPoint({
    required LatLng position,
    required List<LatLng> points,
  }) {
    assert(points.isNotEmpty, 'Points list cannot be empty');
    
    if (points.isEmpty) {
      return (index: 0, distance: double.infinity);
    }

    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < points.length; i++) {
      final dist = _distance.as(LengthUnit.Meter, position, points[i]);
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    return (index: closestIndex, distance: minDistance);
  }

  /// Crea un percorso sintetico diretto
  /// 
  /// Usato come fallback quando l'API di routing non è disponibile
  /// o restituisce dati invalidi. Crea una linea retta tra due punti.
  RouteInfo createFallbackRoute({
    required LatLng from,
    required LatLng to,
  }) {
    final dist = _distance.as(LengthUnit.Meter, from, to);
    
    return RouteInfo(
      coordinates: [from, to],
      distance: dist,
      duration: dist / 1.4, // Assume velocità media 1.4 m/s (5 km/h camminata)
    );
  }
}

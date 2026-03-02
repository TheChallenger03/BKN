import 'dart:math';
import '../../domain/entities/saved_location.dart';

/// Servizio per filtrare e ricercare location.
/// Rispetta Single Responsibility Principle: si occupa SOLO del filtro/ricerca.
class LocationFilterService {
  /// Filtra location per testo di ricerca (label).
  /// Ricerca case-insensitive e supporta match parziali.
  List<SavedLocation> filterByText(
    List<SavedLocation> locations,
    String searchText,
  ) {
    if (searchText.isEmpty) return locations;

    final lowercaseSearch = searchText.toLowerCase();

    return locations.where((location) {
      return location.label.toLowerCase().contains(lowercaseSearch);
    }).toList();
  }

  /// Filtra location per categoria.
  /// Se categoryId è null, ritorna solo location senza categoria.
  List<SavedLocation> filterByCategory(
    List<SavedLocation> locations,
    int? categoryId,
  ) {
    return locations.where((location) {
      if (categoryId == null) {
        return location.category == null;
      }
      return location.category?.id == categoryId;
    }).toList();
  }

  /// Filtra location con foto.
  List<SavedLocation> filterWithPhotos(List<SavedLocation> locations) {
    return locations.where((location) {
      return location.photoPath != null && location.photoPath!.isNotEmpty;
    }).toList();
  }

  /// Filtra location pinnate.
  List<SavedLocation> filterPinned(List<SavedLocation> locations) {
    return locations.where((location) => location.isPinned).toList();
  }

  /// Filtra location non pinnate.
  List<SavedLocation> filterUnpinned(List<SavedLocation> locations) {
    return locations.where((location) => !location.isPinned).toList();
  }

  /// Applica filtri multipli combinati.
  /// Tutti i filtri specificati devono essere soddisfatti (AND logic).
  List<SavedLocation> applyFilters(
    List<SavedLocation> locations, {
    String? searchText,
    int? categoryId,
    bool? onlyWithPhotos,
    bool? onlyPinned,
  }) {
    var filtered = locations;

    if (searchText != null && searchText.isNotEmpty) {
      filtered = filterByText(filtered, searchText);
    }

    if (categoryId != null) {
      filtered = filterByCategory(filtered, categoryId);
    }

    if (onlyWithPhotos == true) {
      filtered = filterWithPhotos(filtered);
    }

    if (onlyPinned == true) {
      filtered = filterPinned(filtered);
    } else if (onlyPinned == false) {
      filtered = filterUnpinned(filtered);
    }

    return filtered;
  }

  /// Ordina location per distanza da un punto (Haversine).
  /// Ritorna le location ordinate dalla più vicina alla più lontana.
  List<SavedLocation> sortByDistance(
    List<SavedLocation> locations, {
    required double fromLatitude,
    required double fromLongitude,
  }) {
    final locationsWithDistance = locations.map((location) {
      final distance = _calculateDistance(
        fromLatitude,
        fromLongitude,
        location.latitude,
        location.longitude,
      );
      return _LocationWithDistance(location, distance);
    }).toList();

    locationsWithDistance.sort((a, b) => a.distance.compareTo(b.distance));

    return locationsWithDistance.map((e) => e.location).toList();
  }

  /// Calcola distanza tra due punti usando formula di Haversine.
  /// Ritorna distanza in metri.
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadiusKm * c * 1000; // Converti in metri
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}

/// Helper class interna per sorting con distanza.
class _LocationWithDistance {
  final SavedLocation location;
  final double distance;

  _LocationWithDistance(this.location, this.distance);
}

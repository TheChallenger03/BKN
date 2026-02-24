import '../../domain/entities/saved_location.dart';

class LinkUtils {
  static const String scheme = 'bknapp';
  static const String host = 'location';

  ///Generate a shareable deep lonk for a saved location
  ///Format: bknapp://location?lat=44.494887&lng=11.342616&label=Casa
  static String generateLocationLink(SavedLocation location) {
    final uri = Uri(
      scheme: scheme,
      host: host,
      queryParameters: {
        'lat': location.latitude.toString(),
        'lng': location.longitude.toString(),
        'label': location.label,
      }
    );
    return uri.toString();
  }

  ///Parse a deep link and extract the saved location
  ///Returns null if the link is invalid
  static LocationLinkData? parseLocationLink(Uri uri) {
    if(uri.scheme != scheme || uri.host != host) {
      return null;
    }

    final latStr = uri.queryParameters['lat'];
    final lngStr = uri.queryParameters['lng'];
    final label = uri.queryParameters['label'] ?? 'Unknown';

    if(latStr == null || lngStr == null) {
      return null;
    }

    final latitude = double.tryParse(latStr);
    final longitude = double.tryParse(lngStr);

    if(latitude == null || longitude == null) {
      return null;
    }

    return LocationLinkData(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
  }

  ///Generate a shareable text message with the location link
  static String generateShareMessage(SavedLocation location) {
    final link = generateLocationLink(location);
    return '📍 Ti condivido questa posizione: "${location.label}"\n\n'
        'Coordinate: ${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)}\n\n'
        'Apri con Location Tracker:\n$link\n\n'
        'O visualizza su Google Maps:\n'
        '${generateGoogleMapsLink(location)}';
  }

  ///Generate a Google Maps link as a fallback
  static String generateGoogleMapsLink(SavedLocation location) {
    return 'https://www.google.com/maps/search/?api=1&query='
        '${location.latitude},${location.longitude}';
  }
}

class LocationLinkData {
  final double latitude;
  final double longitude;
  final String label;

  LocationLinkData({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  SavedLocation toSavedLocation() {
    return SavedLocation(
      label: label,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      isPinned: false,
    );
  }
}
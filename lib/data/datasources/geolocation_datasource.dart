import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

abstract class GeolocationDataSource {
  Future<LatLng> getCurrentPosition();
  Future<bool> checkLocationPermission();
  Stream<LatLng> getPositionStream();
}

class GeolocationDataSourceImpl implements GeolocationDataSource {
  @override
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled) {
      return false;
    }

    permission =permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied) {
        return false;
      }
    }

    if(permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  @override
  Future<LatLng> getCurrentPosition() async {
    final hasPermission = await checkLocationPermission();

    if(!hasPermission) {
      throw Exception('Location permission denied');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }

  @override
  Stream<LatLng> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      // Remove timeLimit to prevent timeout exceptions
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
      .map((Position position) => LatLng(position.latitude, position.longitude))
      .handleError((error) {
        print('Position stream error: $error');
        // Return last known position on error
        return Geolocator.getLastKnownPosition().then((pos) {
          if (pos != null) {
            return LatLng(pos.latitude, pos.longitude);
          }
          throw error;
        });
      });
  }
}
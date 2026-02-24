import 'package:geolocator/geolocator.dart';

class PermissionHandler {
  static Future<PermissionStatus> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled) {
      return PermissionStatus.serviceDisabled;
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied) {
        return PermissionStatus.denied;
      }
    }

    if(permission == LocationPermission.deniedForever) {
      return PermissionStatus.permanentlyDenied;
    }

    return PermissionStatus.granted;
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

enum PermissionStatus {
    granted,
    denied,
    permanentlyDenied,
    serviceDisabled,
  }
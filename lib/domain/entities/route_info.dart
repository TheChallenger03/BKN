import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class RouteInfo extends Equatable {
  final List<LatLng> coordinates;
  final double distance; // in meters
  final double duration; // in seconds

  const RouteInfo({
    required this.coordinates,
    required this.distance,
    required this.duration,
  });

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  String get formattedDuration {
    final duration = Duration(seconds: this.duration.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  List<Object> get props => [coordinates, 
  distance, 
  duration];
}
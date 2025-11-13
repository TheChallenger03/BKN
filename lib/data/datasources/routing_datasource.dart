import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/route_info.dart';

abstract class RoutingDataSource {
  Future<RouteInfo> getRoute({
    required LatLng from,
    required LatLng to,
  });
}

class RoutingDataSourceImpl implements RoutingDataSource {
  final http.Client client;

  RoutingDataSourceImpl({http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<RouteInfo> getRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    final url = Uri.parse(
      '${AppConstants.openRouteServiceBaseUrl}'
      '${AppConstants.openRouteServiceDirectionsPath}',
    );

    final body =  jsonEncode({
      'coordinates': [
        [from.longitude, from.latitude],
        [to.longitude, to.latitude],
      ],
    });

    final response = await client.post(
      url,
      headers: {
        'Authorization': AppConstants.openRouteServiceApiKey,
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if(response.statusCode != 200) {
      throw Exception('Failed to fetch route: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);

    // OpenRouteService returns 'routes' not 'features'
    if(data['routes'] == null || (data['routes'] as List).isEmpty) {
      throw Exception('No route found in the response. Response: ${response.body}');
    }

    final route = data['routes'][0];
    final segments = route['segments'] as List;
    
    if(segments.isEmpty) {
      throw Exception('No segments found in route');
    }

    // Decode the geometry (it's in encoded polyline format)
    final geometry = route['geometry'] as String;
    final coordinates = _decodePolyline(geometry);

    // Get summary from segments
    double totalDistance = 0.0;
    double totalDuration = 0.0;
    
    for (var segment in segments) {
      totalDistance += (segment['distance'] as num).toDouble();
      totalDuration += (segment['duration'] as num).toDouble();
    }

    return RouteInfo(
      coordinates: coordinates,
      distance: totalDistance,
      duration: totalDuration,
    );
  }

  // Decode polyline geometry
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
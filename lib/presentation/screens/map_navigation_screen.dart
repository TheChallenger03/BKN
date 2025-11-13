import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/saved_location.dart';
import '../providers/map_provider.dart';
import '../../core/constants/app_constants.dart';

class MapNavigationScreen extends ConsumerStatefulWidget {
  final SavedLocation destination;

  const MapNavigationScreen({
    super.key,
    required this.destination,
  });

  @override
  ConsumerState<MapNavigationScreen> createState() =>
      _MapNavigationScreenState();
}

class _MapNavigationScreenState extends ConsumerState<MapNavigationScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider(widget.destination));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.label),
      ),
      body: Stack(
        children: [
          _buildMap(mapState),
          if (mapState.isLoading) _buildLoadingOverlay(),
          if (mapState.currentRoute != null) _buildRouteInfo(mapState),
          if (mapState.errorMessage != null) _buildErrorBanner(mapState),
        ],
      ),
    );
  }

  Widget _buildMap(mapState) {
    final destinationLatLng = LatLng(
      widget.destination.latitude,
      widget.destination.longitude,
    );

    // Center map on current position or destination
    final center = mapState.currentPosition ?? destinationLatLng;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: AppConstants.navigationZoom,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.osmTileUrl,
          userAgentPackageName: 'com.example.location_tracker',
        ),
        // Route polyline
        if (mapState.currentRoute != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: mapState.currentRoute!.coordinates,
                strokeWidth: 4,
                color: Colors.blue,
              ),
            ],
          ),
        // Markers
        MarkerLayer(
          markers: [
            // Destination marker
            Marker(
              point: destinationLatLng,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
            // Current position marker
            if (mapState.currentPosition != null)
              Marker(
                point: mapState.currentPosition!,
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Calcolo percorso...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo(mapState) {
    final route = mapState.currentRoute!;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    route.formattedDistance,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    route.formattedDuration,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(mapState) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        color: Colors.red[100],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mapState.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
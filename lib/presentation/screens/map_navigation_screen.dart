import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/saved_location.dart';
import '../providers/map_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/link_utils.dart';
import '../../core/themes/app_theme.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Condividi posizione',
            onPressed: _shareLocation,
          ),
        ],
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
                color: AppTheme.primaryTeal,
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
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
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
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Calcolo percorso...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }  Widget _buildRouteInfo(mapState) {
    final route = mapState.currentRoute!;

    return Positioned(
      bottom: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRouteInfoItem(
            Icons.directions_walk,
            route.formattedDistance,
          ),
          const SizedBox(height: 12),
          _buildRouteInfoItem(
            Icons.access_time,
            route.formattedDuration,
          ),
        ],
      ),
    );
  }  Widget _buildRouteInfoItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryTeal),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(mapState) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mapState.errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }  Future<void> _shareLocation() async {
    final message = LinkUtils.generateShareMessage(widget.destination);
    await Share.share(
      message,
      subject: 'Posizione: ${widget.destination.label}',
    );
  }
}
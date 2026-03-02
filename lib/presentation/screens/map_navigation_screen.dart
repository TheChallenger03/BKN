import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/saved_location.dart';
import '../providers/map_provider.dart';
import '../widgets/download_tiles_dialog.dart';
import '../widgets/offline_map_storage_widget.dart';
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
  late final MapController _mapController;
  late final StateNotifierProvider<MapNotifier, MapState> _mapProvider;
  bool _hasFittedBounds = false;

  LatLng get _destinationLatLng => LatLng(widget.destination.latitude, widget.destination.longitude);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _mapProvider = createMapProvider(widget.destination);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(_mapProvider);

    if (mapState.currentRoute != null && !_hasFittedBounds && mounted) {
      _hasFittedBounds = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitMapBounds(mapState);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Scarica mappe offline',
            onPressed: _showDownloadDialog,
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: 'Gestisci storage',
            onPressed: _showStorageDialog,
          ),
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

  void _fitMapBounds(MapState mapState) {
    final route = mapState.currentRoute;
    if (route == null) return;

    final allPoints = [
      ...route.coordinates,
      _destinationLatLng,
      if (mapState.currentPosition != null) mapState.currentPosition!,
    ];

    if (allPoints.isEmpty) return;

    final bounds = _calculateBounds(allPoints);
    
    try {
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ));
    } catch (_) {
      // Ignore if map controller not ready
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  Widget _buildMap(MapState mapState) {
    final center = mapState.currentPosition ?? _destinationLatLng;
    final routePoints = mapState.currentRoute?.coordinates.length ?? 0;
    final lastRec = mapState.lastRecalculation?.millisecondsSinceEpoch ?? 0;
    final mapKey = 'map_${widget.destination.id}_$lastRec';

    return FlutterMap(
      key: ValueKey(mapKey),
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
          maxNativeZoom: 19,
          maxZoom: 19,
          tileProvider: _getCachedTileProvider(),
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        if (routePoints > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: mapState.currentRoute!.coordinates,
                strokeWidth: 4,
                color: AppTheme.primaryTeal,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            _buildDestinationMarker(),
            if (mapState.currentPosition != null)
              _buildCurrentPositionMarker(mapState.currentPosition!),
          ],
        ),
      ],
    );
  }

  Marker _buildDestinationMarker() {
    return Marker(
      point: _destinationLatLng,
      width: 40,
      height: 40,
      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
    );
  }

  Marker _buildCurrentPositionMarker(LatLng position) {
    return Marker(
      point: position,
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
    );
  }

  Widget _buildLoadingOverlay() {
    final mapState = ref.watch(_mapProvider);
    final hasPosition = mapState.currentPosition != null;
    
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
                hasPosition ? 'Calcolo percorso...' : 'Ottenendo posizione GPS...',
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
  }

  Widget _buildRouteInfo(MapState mapState) {
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
  }

  Widget _buildRouteInfoItem(IconData icon, String text) {
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

  Widget _buildErrorBanner(MapState mapState) {
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
  }

  Future<void> _shareLocation() async {
    final message = LinkUtils.generateShareMessage(widget.destination);
    await Share.share(
      message,
      subject: 'Posizione: ${widget.destination.label}',
    );
  }

  /// Ottiene il tile provider con caching offline
  dynamic _getCachedTileProvider() {
    try {
      final service = ref.read(offlineTileServiceProvider);
      return service.getTileProvider();
    } catch (e) {
      // Fallback to network provider se il caching non è disponibile
      return NetworkTileProvider();
    }
  }

  /// Mostra il dialog per scaricare i tile offline
  Future<void> _showDownloadDialog() async {
    final mapState = ref.read(_mapProvider);
    final center = mapState.currentPosition ?? _destinationLatLng;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadTilesDialog(center: center),
    );
  }

  /// Mostra il dialog per gestire lo storage offline
  Future<void> _showStorageDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const OfflineMapStorageWidget(),
    );
  }
}
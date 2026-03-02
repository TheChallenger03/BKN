import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/usecases/get_route.dart';
import '../../core/constants/app_constants.dart';
import 'location_provider.dart';

class MapState {
  final SavedLocation destination;
  final LatLng? currentPosition;
  final RouteInfo? currentRoute;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastRecalculation;

  MapState({
    required this.destination,
    this.currentPosition,
    this.currentRoute,
    this.isLoading = false,
    this.errorMessage,
    this.lastRecalculation,
  });

  MapState copyWith({
    LatLng? currentPosition,
    RouteInfo? currentRoute,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastRecalculation,
  }) {
    return MapState(
      destination: destination,
      currentPosition: currentPosition ?? this.currentPosition,
      currentRoute: currentRoute ?? this.currentRoute,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastRecalculation: lastRecalculation ?? this.lastRecalculation,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final GetRoute getRoute;
  final SavedLocation destination;
  StreamSubscription<LatLng>? _positionSubscription;
  Timer? _initialRouteTimer;
  bool _hasCalculatedInitialRoute = false;
  bool _isCalculatingRoute = false;

  LatLng get _destinationLatLng => LatLng(destination.latitude, destination.longitude);

  MapNotifier({
    required this.getRoute,
    required this.destination,
    required Stream<LatLng> positionStream,
    required Future<LatLng?> Function() getLastPosition,
  }) : super(MapState(destination: destination)) {
    _initializeRoute(getLastPosition);
    _startListening(positionStream);
  }

  Future<void> _initializeRoute(Future<LatLng?> Function() getLastPosition) async {
    _startFallbackTimer(getLastPosition);
    await _tryInitialCalculation(getLastPosition);
  }

  void _startFallbackTimer(Future<LatLng?> Function() getLastPosition) {
    _initialRouteTimer = Timer(const Duration(seconds: 3), () async {
      if (state.currentRoute == null && !state.isLoading) {
        _hasCalculatedInitialRoute = true;
        final position = await getLastPosition();
        if (position != null) {
          await _calculateRoute(position);
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Impossibile ottenere la posizione GPS',
          );
        }
      }
    });
  }

  Future<void> _tryInitialCalculation(Future<LatLng?> Function() getLastPosition) async {
    try {
      final lastPosition = await getLastPosition();
      if (lastPosition == null) return;

      _hasCalculatedInitialRoute = true;
      state = state.copyWith(isLoading: true, errorMessage: null);

      final result = await getRoute(from: lastPosition, to: _destinationLatLng);

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (route) {
          _initialRouteTimer?.cancel();
          state = state.copyWith(
            currentPosition: lastPosition,
            currentRoute: route,
            isLoading: false,
            lastRecalculation: DateTime.now(),
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _startListening(Stream<LatLng> positionStream) {
    Future.microtask(() {
      _positionSubscription = positionStream.listen(
        _updatePosition,
        onError: (error) => state = state.copyWith(errorMessage: error.toString()),
      );
    });
  }

  Future<void> _updatePosition(LatLng position) async {
    final oldPosition = state.currentPosition;
    state = state.copyWith(currentPosition: position);

    if (state.currentRoute != null) {
      _trimRouteToPosition(position);
    }

    if (state.currentRoute == null && !_hasCalculatedInitialRoute) {
      _initialRouteTimer?.cancel();
      _hasCalculatedInitialRoute = true;
      await _calculateRoute(position);
    } else if (oldPosition != null && _shouldRecalculateRoute(position)) {
      await _calculateRoute(position);
    }
  }

  void _trimRouteToPosition(LatLng currentPosition) {
    final route = state.currentRoute!;
    if (route.coordinates.length <= 2) return;

    final closestIndex = _findClosestPointIndex(currentPosition, route.coordinates);
    
    if (closestIndex.distance < 15.0 && closestIndex.index > 0) {
      final trimmedCoordinates = route.coordinates.sublist(closestIndex.index);
      if (trimmedCoordinates.length >= 2) {
        state = state.copyWith(
          currentRoute: RouteInfo(
            coordinates: trimmedCoordinates,
            distance: route.distance,
            duration: route.duration,
          ),
        );
      }
    }
  }

  ({int index, double distance}) _findClosestPointIndex(LatLng position, List<LatLng> points) {
    final distance = Distance();
    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < points.length; i++) {
      final dist = distance.as(LengthUnit.Meter, position, points[i]);
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    return (index: closestIndex, distance: minDistance);
  }

  bool _shouldRecalculateRoute(LatLng newPosition) {
    if (state.currentRoute == null) return true;
    if (state.isLoading) return false;

    final minDistance = _findClosestPointIndex(newPosition, state.currentRoute!.coordinates).distance;
    return minDistance > AppConstants.routeRecalculationThresholdMeters;
  }

  Future<void> _calculateRoute(LatLng from) async {
    if (state.isLoading || _isCalculatingRoute) return;

    _isCalculatingRoute = true;
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getRoute(from: from, to: _destinationLatLng);

    result.fold(
      (failure) {
        _isCalculatingRoute = false;
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (route) {
        _isCalculatingRoute = false;
        final finalRoute = route.coordinates.length <= 1
            ? _createSyntheticRoute(from)
            : route;
        
        state = state.copyWith(
          currentRoute: finalRoute,
          isLoading: false,
          lastRecalculation: DateTime.now(),
        );
      },
    );
  }

  RouteInfo _createSyntheticRoute(LatLng from) {
    final start = state.currentPosition ?? from;
    final distance = Distance();
    final dist = distance.as(LengthUnit.Meter, start, _destinationLatLng);
    
    return RouteInfo(
      coordinates: [start, _destinationLatLng],
      distance: dist,
      duration: dist / 1.4,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _initialRouteTimer?.cancel();
    super.dispose();
  }
}

// Position Stream Provider
final positionStreamProvider = StreamProvider<LatLng>((ref) {
  final repository = ref.read(locationRepositoryProvider);

  return repository.getCurrentPositionStream().asyncMap((either) {
    return either.fold(
      (failure) => throw Exception(failure.message),
      (position) => position,
    );
  });
});

// Map State Provider Factory - uses String key with destination data embedded
// Key format: "lat_lng_timestamp" to ensure uniqueness
final mapProvider = StateNotifierProvider.family<MapNotifier, MapState, String>((ref, key) {
  // Parse destination from key - this is a hack but necessary
  // The actual destination will be passed through the screen
  throw UnimplementedError('Use createMapProvider helper instead');
});

// Helper function to create provider with unique key
StateNotifierProvider<MapNotifier, MapState> createMapProvider(SavedLocation destination) {
  return StateNotifierProvider<MapNotifier, MapState>((ref) {
    final repository = ref.read(locationRepositoryProvider);
    final getRouteUseCase = GetRoute(repository);

    // Create position stream
    final positionStream = repository.getCurrentPositionStream().asyncMap((either) => either.fold(
      (failure) => throw Exception(failure.message),
      (position) => position,
    ));

    // Function to get last known position
    Future<LatLng?> getLastPosition() async {
      final result = await repository.getCurrentPosition();
      return result.fold(
        (failure) => null,
        (position) => position,
      );
    }
    
    return MapNotifier(
      getRoute: getRouteUseCase,
      destination: destination,
      positionStream: positionStream,
      getLastPosition: getLastPosition,
    );
  });
}
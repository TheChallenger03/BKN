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
  int _routeRetryCount = 0;
  static const int _maxRouteRetries = 3;
  bool _hasCalculatedInitialRoute = false;
  bool _isCalculatingRoute = false;

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
    // Set a timeout of 3 seconds to guarantee route calculation
    _initialRouteTimer = Timer(const Duration(seconds: 3), () async {
      // Force route calculation if still no route after 3 seconds
      if (state.currentRoute == null && !state.isLoading) {
        final position = await getLastPosition();
        if (position != null) {
          await _calculateRoute(position);
        } else {
          // If still no position, show error
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Impossibile ottenere la posizione GPS',
          );
        }
      }
    });

    // Try to get last known position immediately for faster route calculation
    try {
      final lastPosition = await getLastPosition();
      if (lastPosition != null) {
        // Calculate route immediately with last known position
        state = state.copyWith(isLoading: true, errorMessage: null);
        
        final destinationLatLng = LatLng(
          destination.latitude,
          destination.longitude,
        );

        final result = await getRoute(
          from: lastPosition,
          to: destinationLatLng,
        );

        result.fold(
          (failure) {
            
            // Don't cancel timer on failure - let it retry
            state = state.copyWith(
              isLoading: false,
              errorMessage: failure.message,
            );
          },
          (route) {
            // Success - cancel timer and update state with both route and position
            _initialRouteTimer?.cancel();
            state = state.copyWith(
              currentPosition: lastPosition,
              currentRoute: route,
              isLoading: false,
              lastRecalculation: DateTime.now(),
            );
          },
        );
      }
    } catch (e) {
      // If immediate calculation fails, timer will retry
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void _startListening(Stream<LatLng> positionStream) {
    // Ensure subscription happens on the event loop main task to avoid
    // potential platform-thread issues reported by some plugins.
    Future.microtask(() {
      _positionSubscription = positionStream.listen((position) {
        _updatePosition(position);
      }, onError: (error) {
        state = state.copyWith(errorMessage: error.toString());
      });
    });
  }

  Future<void> _updatePosition(LatLng position) async {
    final oldPosition = state.currentPosition;
    state = state.copyWith(currentPosition: position);

    // Trim route based on current position
    if (state.currentRoute != null) {
      _trimRouteToPosition(position);
    }

    // Calculate route if its the first position or enough time has passed
    if(state.currentRoute == null && !_hasCalculatedInitialRoute) {
      // Cancel timer since we got a real position
      _initialRouteTimer?.cancel();
      _hasCalculatedInitialRoute = true;
      await _calculateRoute(position);
    }
    else if(oldPosition != null && _shouldRecalculateRoute(position)) {
      await _calculateRoute(position);
    }
  }

  void _trimRouteToPosition(LatLng currentPosition) {
    final route = state.currentRoute!;
    if (route.coordinates.length <= 2) return;

    final distance = Distance();
    int closestIndex = 0;
    double minDistance = double.infinity;

    // Find closest point on route
    for (int i = 0; i < route.coordinates.length; i++) {
      final dist = distance.as(
        LengthUnit.Meter,
        currentPosition,
        route.coordinates[i],
      );
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    // Only trim if we're close enough to a point (within 15 meters) and not at the start
    if (minDistance < 15.0 && closestIndex > 0) {
      final trimmedCoordinates = route.coordinates.sublist(closestIndex);
      if (trimmedCoordinates.length >= 2) {
        final trimmedRoute = RouteInfo(
          coordinates: trimmedCoordinates,
          distance: route.distance,
          duration: route.duration,
        );
        state = state.copyWith(currentRoute: trimmedRoute);
      }
    }
  }

  bool _shouldRecalculateRoute(LatLng newPosition) {
    if(state.currentRoute == null) {
      return true;
    }
    if(state.isLoading) {
      return false;
    }

    // Check cooldown
    final route = state.currentRoute!;
    final distance = Distance();

    double minDistance = double.infinity;
    for(final point in route.coordinates) {
      final dist = distance.as(
        LengthUnit.Meter,
        newPosition,
        point,
      );
      if(dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance > AppConstants.routeRecalculationThresholdMeters;
  }

  Future<void> _calculateRoute(LatLng from) async {
    if(state.isLoading || _isCalculatingRoute) {
      return;
    }

    _isCalculatingRoute = true;
    state = state.copyWith(isLoading: true, errorMessage: null);

    final destinationLatLng = LatLng(
      destination.latitude,
      destination.longitude,
    );

    final result = await getRoute(
      from: from,
      to: destinationLatLng,
    );

    result.fold(
      (failure) {
        _isCalculatingRoute = false;
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (route) {
        

        // If route has 1 or 0 points, it may be a degenerate result (from==to)
        // Retry a few times before accepting it, to handle transient API or position issues.
        if (route.coordinates.length <= 1) {
          if (_routeRetryCount < _maxRouteRetries) {
            _routeRetryCount += 1;
            
            state = state.copyWith(isLoading: false);
            Future.delayed(const Duration(milliseconds: 400), () async {
              // Re-attempt using latest known position
              final fromPos = state.currentPosition ?? from;
              await _calculateRoute(fromPos);
            });
            return;
          } else {
            // Retries exhausted - create a synthetic short route between current position (or from)
            final start = state.currentPosition ?? from;
            final dest = destinationLatLng;
            final distanceCalc = Distance();
            final dist = distanceCalc.as(LengthUnit.Meter, start, dest);
            final duration = (dist / 1.4); // assume walking speed ~1.4 m/s
            final synthetic = RouteInfo(
              coordinates: [start, dest],
              distance: dist,
              duration: duration,
            );
            _routeRetryCount = 0;
            state = state.copyWith(
              currentRoute: synthetic,
              isLoading: false,
              lastRecalculation: DateTime.now(),
            );
            return;
          }
        }

        // Accept route
        _routeRetryCount = 0;
        state = state.copyWith(
          currentRoute: route,
          isLoading: false,
          lastRecalculation: DateTime.now(),
        );
      },
    );
    _isCalculatingRoute = false;
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
  final repository = ref.read(localRepositoryProvider);

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
    final repository = ref.read(localRepositoryProvider);
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
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/usecases/get_route.dart';
import '../../core/constants/app_constants.dart';
import 'location_provider.dart';

class MapState {
  final LatLng? currentPosition;
  final RouteInfo? currentRoute;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastRecalculation;

  MapState({
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

  MapNotifier({
    required this.getRoute,
    required this.destination,
    required Stream<LatLng> positionStream,
  }) : super(MapState()) {
    _startListening(positionStream);
  }

  void _startListening(Stream<LatLng> positionStream) {
    _positionSubscription = positionStream.listen((position) {
      _updatePosition(position);
    }, onError: (error) {
      state = state.copyWith(errorMessage: error.toString());
    },);
  }

  Future<void> _updatePosition(LatLng position) async {
    final oldPosition = state.currentPosition;
    state = state.copyWith(currentPosition: position);

    // Calculate route if its the first position or enough time has passed
    if(state.currentRoute == null) {
      await _calculateRoute(position);
    }
    else if(oldPosition != null && _shouldRecalculateRoute(position)) {
      await _calculateRoute(position);
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
    if(state.isLoading) {
      return;
    }

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
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (route) {
        state = state.copyWith(
          currentRoute: route,
          isLoading: false,
          lastRecalculation: DateTime.now(),
        );
      },
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
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

// Map State Provide Factory
final mapProvider = StateNotifierProvider.family<MapNotifier, MapState, SavedLocation>((ref, destination) {
  final repository = ref.read(localRepositoryProvider);
  final getRouteUseCase = GetRoute(repository);

  // Create position stream
  final positionStream = repository.getCurrentPositionStream().asyncMap((either) => either.fold(
    (failure) => throw Exception(failure.message),
    (position) => position,
  ));
  
  return MapNotifier(
    getRoute: getRouteUseCase,
    destination: destination,
    positionStream: positionStream,
  );
});
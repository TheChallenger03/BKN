import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/get_saved_locations.dart';
import '../../domain/usecases/save_current_location.dart';
import '../../domain/usecases/delete_location.dart';
import '../../domain/usecases/update_location_label.dart';
import '../../domain/usecases/toggle_location_pin.dart';
import '../../data/repositories/location_repository_drift_impl.dart';
import '../../data/datasources/location_drift_datasource.dart';
import '../../data/datasources/geolocation_datasource.dart';
import '../../data/datasources/routing_datasource.dart';
import '../../data/database/app_database.dart' hide SavedLocation;

// Provider del database Drift (singleton)
final driftDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Provider del DataSource
final locationDriftDataSourceProvider = Provider<LocationLocalDataSource>((ref) {
  final database = ref.watch(driftDatabaseProvider);
  return LocationDriftDataSource(database);
});

// Provider del Repository con Drift
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryDriftImpl(
    localDataSource: ref.read(locationDriftDataSourceProvider),
    geolocationDataSource: GeolocationDataSourceImpl(),
    routingDataSource: RoutingDataSourceImpl(),
  );
});

// ... resto dei provider rimane uguale

final getSavedLocationsProvider = Provider((ref) {
  return GetSavedLocations(ref.read(locationRepositoryProvider));
});

final saveCurrentLocationProvider = Provider((ref) {
  return SaveCurrentLocation(ref.read(locationRepositoryProvider));
});

final deleteLocationProvider = Provider((ref) {
  return DeleteLocation(ref.read(locationRepositoryProvider));
});

final updateLocationLabelProvider = Provider((ref) {
  return UpdateLocationLabel(ref.read(locationRepositoryProvider));
});

final toggleLocationPinProvider = Provider((ref) {
  return ToggleLocationPin(ref.read(locationRepositoryProvider));
});

// LocationNotifier rimane identico
class LocationNotifier extends StateNotifier<AsyncValue<List<SavedLocation>>> {
  final GetSavedLocations getSavedLocations;
  final SaveCurrentLocation saveCurrentLocation;
  final DeleteLocation deleteLocation;
  final UpdateLocationLabel updateLocationLabel;
  final ToggleLocationPin toggleLocationPin;

  LocationNotifier({
    required this.getSavedLocations,
    required this.saveCurrentLocation,
    required this.deleteLocation,
    required this.updateLocationLabel,
    required this.toggleLocationPin,
  }) : super(const AsyncValue.loading()) {
    loadLocations();
  }

  Future<void> loadLocations() async {
    state = const AsyncValue.loading();
    final result = await getSavedLocations();

    result.fold(
      (failure) => state = AsyncValue.error(
        failure.message,
        StackTrace.current,
      ),
      (locations) => state = AsyncValue.data(locations),
    );
  }

  Future<bool> saveLocation(String label) async {
    final result = await saveCurrentLocation(label);
    return result.fold(
      (failure) {
        state = AsyncValue.error(
          failure.message,
          StackTrace.current,
        );
        return false;
      },
      (location) {
        loadLocations();
        return true;
      },
    );
  }

  Future<bool> removeLocation(int id) async {
    final result = await deleteLocation(id);
    return result.fold(
      (failure) {
        state = AsyncValue.error(
          failure.message,
          StackTrace.current,
        );
        return false;
      },
      (_) {
        loadLocations();
        return true;
      },
    );
  }

  Future<bool> updateLabel(int id, String newLabel) async {
    final result = await updateLocationLabel(id: id, newLabel: newLabel);

    return result.fold(
      (failure) {
        state = AsyncValue.error(
          failure.message,
          StackTrace.current,
        );
        return false;
      },
      (_) {
        loadLocations();
        return true;
      },
    );
  }

  Future<bool> togglePin(int id) async {
    final result = await toggleLocationPin(id);

    return result.fold(
      (failure) {
        state = AsyncValue.error(
          failure.message,
          StackTrace.current,
        );
        return false;
      },
      (_) {
        loadLocations();
        return true;
      },
    );
  }
}

final locationsProvider = StateNotifierProvider<LocationNotifier, AsyncValue<List<SavedLocation>>>(
  (ref) => LocationNotifier(
    getSavedLocations: ref.read(getSavedLocationsProvider),
    saveCurrentLocation: ref.read(saveCurrentLocationProvider),
    deleteLocation: ref.read(deleteLocationProvider),
    updateLocationLabel: ref.read(updateLocationLabelProvider),
    toggleLocationPin: ref.read(toggleLocationPinProvider),
  ),
);
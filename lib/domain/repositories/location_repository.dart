import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';
import '../entities/route_info.dart';
import '../entities/saved_location.dart';
import '../../core/errors/failures.dart';

abstract class LocationRepository {
  /// Get all saved locations sorted (pinned first, then alphabetically)
  Future<Either<Failure, List<SavedLocation>>> getSavedLocations();

  /// Get a specific saved location by id
  Future<Either<Failure, SavedLocation>> getSavedLocationById(int id);

  /// Save a new location
  Future<Either<Failure, SavedLocation>> saveLocation(SavedLocation location);

  /// Update an existing location
  Future<Either<Failure, SavedLocation>> updateLocation(SavedLocation location);

  /// Delete a location
  Future<Either<Failure, void>> deleteLocation(int id);

  /// Toggle pin status of a location
  Future<Either<Failure, SavedLocation>> togglePin(int id);

  /// Get current device position
  Future<Either<Failure, LatLng>> getCurrentPosition();

  /// Get route from current position to destination
  Future<Either<Failure, RouteInfo>> getRoute({
    required LatLng from,
    required LatLng to,
  });

  /// Stream of current positions update
  Stream<Either<Failure, LatLng>> getCurrentPositionStream();  
}


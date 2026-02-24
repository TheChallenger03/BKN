import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/repositories/location_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/location_local_datasource.dart';
import '../datasources/geolocation_datasource.dart';
import '../datasources/routing_datasource.dart';
import '../models/saved_location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationLocalDataSource localDataSource;
  final GeolocationDataSource geolocationDataSource;
  final RoutingDataSource routingDataSource;

  LocationRepositoryImpl({
    required this.localDataSource,
    required this.geolocationDataSource,
    required this.routingDataSource,
  });

  @override
  Future<Either<Failure, List<SavedLocation>>> getSavedLocations() async {
    try {
      final locations = await localDataSource.getAllLocations();
      return Right(locations.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure('Failed to get locations: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SavedLocation>> getSavedLocationById(int id) async {
    try {
      final model = await localDataSource.getLocationById(id);
      if (model == null) {
        return Left(DatabaseFailure('Location not found'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('Failed to get location: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SavedLocation>> saveLocation(SavedLocation location) async {
    try {
      final model = SavedLocationModel.fromEntity(location);
      final savedModel = await localDataSource.insertLocation(model);
      return Right(savedModel.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('Failed to save location: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SavedLocation>> updateLocation(SavedLocation location) async {
    try {
      final model = SavedLocationModel.fromEntity(location);
      final updatedModel = await localDataSource.updateLocation(model);
      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('Failed to update location: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLocation(int id) async {
    try {
      await localDataSource.deleteLocation(id);
      return Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete location: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SavedLocation>> togglePin(int id) async {
    try {
      final updatedModel = await localDataSource.togglePin(id);
      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(DatabaseFailure('Failed to toggle pin: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, LatLng>> getCurrentPosition() async {
    try {
      final hasPermission = await geolocationDataSource.checkLocationPermission();
      if (!hasPermission) {
        return Left(LocationPermissionFailure('Location permission denied'));
      }
      final position = await geolocationDataSource.getCurrentPosition();
      return Right(position);
    } catch (e) {
      return Left(LocationServiceFailure('Failed to get current position: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, RouteInfo>> getRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    try {
      final routeInfo = await routingDataSource.getRoute(from: from, to: to);
      return Right(routeInfo);
    } catch (e) {
      return Left(ApiFailure('Failed to get route: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, LatLng>> getCurrentPositionStream() async*{
    try {
      final hasPermission = await geolocationDataSource.checkLocationPermission();
      if(!hasPermission) {
        yield const Left(LocationPermissionFailure('Location permission denied'));
        return;
      }
      await for (final position in geolocationDataSource.getPositionStream()) {
        yield Right(position);
      }
    }
    catch (e) {
      yield Left(LocationServiceFailure('Failed to get position stream: ${e.toString()}'));
    }
  }
}
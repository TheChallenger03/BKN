import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/location_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/location_drift_datasource.dart';
import '../datasources/geolocation_datasource.dart';
import '../datasources/routing_datasource.dart';
import '../database/app_database.dart' as drift_db;

class LocationRepositoryDriftImpl implements LocationRepository {
  final LocationLocalDataSource localDataSource;
  final GeolocationDataSource geolocationDataSource;
  final RoutingDataSource routingDataSource;

  LocationRepositoryDriftImpl({
    required this.localDataSource,
    required this.geolocationDataSource,
    required this.routingDataSource,
  });

  @override
  Future<Either<Failure, List<SavedLocation>>> getSavedLocations() async {
    try {
      final driftLocations = await localDataSource.getAllLocations();
      final categories = await localDataSource.getCategories();
      
      // Mappa categories per ID per lookup veloce
      final categoryMap = {for (var cat in categories) cat.id: cat};
      
      // Converti da Drift SavedLocation a domain SavedLocation
      final domainLocations = driftLocations.map((driftLoc) {
        Category? category;
        if (driftLoc.categoryId != null) {
          final driftCat = categoryMap[driftLoc.categoryId];
          if (driftCat != null) {
            category = Category(
              id: driftCat.id,
              name: driftCat.name,
              icon: driftCat.icon,
              colorHex: driftCat.color,
            );
          }
        }
        
        return SavedLocation(
          id: driftLoc.id,
          label: driftLoc.label,
          latitude: driftLoc.latitude,
          longitude: driftLoc.longitude,
          createdAt: driftLoc.createdAt,
          isPinned: driftLoc.isPinned,
          photoPath: driftLoc.photoPath,
          category: category,
        );
      }).toList();
      
      return Right(domainLocations);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get locations: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SavedLocation>> getSavedLocationById(int id) async {
    try {
      final driftLoc = await localDataSource.getLocationById(id);
      
      if (driftLoc == null) {
        return Left(LocationNotFoundFailure('Location $id not found'));
      }
      
      final domainLoc = SavedLocation(
        id: driftLoc.id,
        label: driftLoc.label,
        latitude: driftLoc.latitude,
        longitude: driftLoc.longitude,
        createdAt: driftLoc.createdAt,
        isPinned: driftLoc.isPinned,
      );
      
      return Right(domainLoc);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get location: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SavedLocation>> saveLocation(SavedLocation location) async {
    try {
      // Converti domain entity in Drift entity
      final driftLoc = drift_db.SavedLocation(
        id: location.id ?? 0, // temporaneo, sarà auto-incrementato
        label: location.label,
        latitude: location.latitude,
        longitude: location.longitude,
        createdAt: location.createdAt,
        isPinned: location.isPinned,
      );
      
      final savedDrift = await localDataSource.insertLocation(driftLoc);
      
      final savedDomain = SavedLocation(
        id: savedDrift.id,
        label: savedDrift.label,
        latitude: savedDrift.latitude,
        longitude: savedDrift.longitude,
        createdAt: savedDrift.createdAt,
        isPinned: savedDrift.isPinned,
      );
      
      return Right(savedDomain);
    } catch (e) {
      return Left(DatabaseFailure('Failed to save location: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SavedLocation>> updateLocation(SavedLocation location) async {
    try {
      if (location.id == null) {
        return Left(ValidationFailure('Cannot update location without ID'));
      }
      
      final driftLoc = drift_db.SavedLocation(
        id: location.id!,
        label: location.label,
        latitude: location.latitude,
        longitude: location.longitude,
        createdAt: location.createdAt,
        isPinned: location.isPinned,
      );
      
      final updatedDrift = await localDataSource.updateLocation(driftLoc);
      
      final updatedDomain = SavedLocation(
        id: updatedDrift.id,
        label: updatedDrift.label,
        latitude: updatedDrift.latitude,
        longitude: updatedDrift.longitude,
        createdAt: updatedDrift.createdAt,
        isPinned: updatedDrift.isPinned,
      );
      
      return Right(updatedDomain);
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
      final toggledDrift = await localDataSource.togglePin(id);
      
      final toggledDomain = SavedLocation(
        id: toggledDrift.id,
        label: toggledDrift.label,
        latitude: toggledDrift.latitude,
        longitude: toggledDrift.longitude,
        createdAt: toggledDrift.createdAt,
        isPinned: toggledDrift.isPinned,
      );
      
      return Right(toggledDomain);
    } catch (e) {
      return Left(DatabaseFailure('Failed to toggle pin: ${e.toString()}'));
    }
  }

  // ... altri metodi (getCurrentPosition, getRoute, ecc.) rimangono uguali
  
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
  Stream<Either<Failure, LatLng>> getCurrentPositionStream() async* {
    try {
      final hasPermission = await geolocationDataSource.checkLocationPermission();
      if (!hasPermission) {
        yield const Left(LocationPermissionFailure('Location permission denied'));
        return;
      }
      await for (final position in geolocationDataSource.getPositionStream()) {
        yield Right(position);
      }
    } catch (e) {
      yield Left(LocationServiceFailure('Failed to get position stream: ${e.toString()}'));
    }
  }

  // ============================================================
  // NEW FEATURES: Photo & Categories
  // ============================================================
  
  @override
  Future<Either<Failure, void>> updateLocationPhoto(int locationId, String? photoPath) async {
    try {
      await localDataSource.updateLocationPhoto(locationId, photoPath);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update location photo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> assignCategoryToLocation(int locationId, int? categoryId) async {
    try {
      await localDataSource.assignCategoryToLocation(locationId, categoryId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to assign category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final driftCategories = await localDataSource.getCategories();
      
      final domainCategories = driftCategories.map((driftCat) => Category(
        id: driftCat.id,
        name: driftCat.name,
        icon: driftCat.icon,
        colorHex: driftCat.color,
      )).toList();
      
      return Right(domainCategories);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get categories: ${e.toString()}'));
    }
  }
}
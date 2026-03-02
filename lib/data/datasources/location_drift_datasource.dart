import '../database/app_database.dart';
import '../database/models/location_statistics.dart';
import '../database/models/location_with_distance.dart';
import 'package:drift/drift.dart' as drift;

abstract class LocationLocalDataSource {
  Future<List<SavedLocation>> getAllLocations();
  Future<SavedLocation?> getLocationById(int id);
  Future<SavedLocation> insertLocation(SavedLocation location);
  Future<SavedLocation> updateLocation(SavedLocation location);
  Future<void> deleteLocation(int id);
  Future<SavedLocation> togglePin(int id);
  Future<SavedLocation> updateLabel(int id, String newLabel);
  Future<LocationStatistics> getStatistics();
  Future<List<LocationWithDistance>> getLocationsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
  Stream<List<SavedLocation>> watchLocations();
  
  // New features
  Future<void> updateLocationPhoto(int locationId, String? photoPath);
  Future<void> assignCategoryToLocation(int locationId, int? categoryId);
  Future<List<Category>> getCategories();
}

class LocationDriftDataSource implements LocationLocalDataSource {
  final AppDatabase _db;
  
  LocationDriftDataSource(this._db);
  
  @override
  Future<List<SavedLocation>> getAllLocations() {
    return _db.getAllLocationsSorted();
  }
  
  @override
  Future<SavedLocation?> getLocationById(int id) {
    return _db.getLocationById(id);
  }
  
  @override
  Future<SavedLocation> insertLocation(SavedLocation location) async {
    // Converti entity in Companion per insert
    final companion = SavedLocationsCompanion(
      label: drift.Value(location.label),
      latitude: drift.Value(location.latitude),
      longitude: drift.Value(location.longitude),
      createdAt: drift.Value(location.createdAt),
      isPinned: drift.Value(location.isPinned),
    );
    
    return await _db.insertLocation(companion);
  }
  
  @override
  Future<SavedLocation> updateLocation(SavedLocation location) async {
    final success = await _db.updateLocation(location);
    if (!success) {
      throw Exception('Update failed for location ${location.id}');
    }
    return location;
  }
  
  @override
  Future<void> deleteLocation(int id) async {
    final deleted = await _db.deleteLocation(id);
    if (deleted == 0) {
      throw Exception('Location $id not found');
    }
  }
  
  @override
  Future<SavedLocation> togglePin(int id) async {
    final success = await _db.togglePin(id);
    if (!success) {
      throw Exception('Toggle pin failed for location $id');
    }
    
    final updated = await _db.getLocationById(id);
    if (updated == null) {
      throw Exception('Location $id not found after toggle');
    }
    
    return updated;
  }
  
  @override
  Future<SavedLocation> updateLabel(int id, String newLabel) async {
    final success = await _db.updateLabel(id, newLabel);
    if (!success) {
      throw Exception('Update label failed for location $id');
    }
    
    final updated = await _db.getLocationById(id);
    if (updated == null) {
      throw Exception('Location $id not found after update');
    }
    
    return updated;
  }
  
  @override
  Future<LocationStatistics> getStatistics() {
    return _db.getStatistics();
  }
  
  @override
  Future<List<LocationWithDistance>> getLocationsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    return _db.getLocationsNearby(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
  
  @override
  Stream<List<SavedLocation>> watchLocations() {
    return _db.watchAllLocations();
  }
  
  // ============================================================
  // NEW FEATURES: Photo & Categories
  // ============================================================
  
  @override
  Future<void> updateLocationPhoto(int locationId, String? photoPath) async {
    await (_db.update(_db.savedLocations)
          ..where((tbl) => tbl.id.equals(locationId)))
        .write(SavedLocationsCompanion(
      photoPath: drift.Value(photoPath),
    ));
  }
  
  @override
  Future<void> assignCategoryToLocation(int locationId, int? categoryId) async {
    await (_db.update(_db.savedLocations)
          ..where((tbl) => tbl.id.equals(locationId)))
        .write(SavedLocationsCompanion(
      categoryId: drift.Value(categoryId),
    ));
  }
  
  @override
  Future<List<Category>> getCategories() async {
    final query = _db.select(_db.categories);
    return await query.get();
  }
}
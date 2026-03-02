import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/location_statistics.dart';
import '../models/location_with_distance.dart';

/// Data Access Object per le operazioni sulle location salvate
/// 
/// Questa classe gestisce tutte le operazioni CRUD e query complesse
/// relative alla tabella SavedLocations.
class LocationsDao {
  final AppDatabase _db;
  
  LocationsDao(this._db);
  
  // ============================================================
  // OPERAZIONI CRUD BASE
  // ============================================================
  
  /// Ottiene tutte le location ordinate per pin e label
  Future<List<SavedLocation>> getAllLocationsSorted() {
    return (_db.select(_db.savedLocations)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.label, mode: OrderingMode.asc),
      ])
    ).get();
  }
  
  /// Ottiene una location specifica tramite ID
  Future<SavedLocation?> getLocationById(int id) {
    return (_db.select(_db.savedLocations)
      ..where((t) => t.id.equals(id))
    ).getSingleOrNull();
  }
  
  /// Inserisce una nuova location e la ritorna con l'ID generato
  Future<SavedLocation> insertLocation(SavedLocationsCompanion location) {
    return _db.into(_db.savedLocations).insertReturning(location);
  }
  
  /// Aggiorna una location esistente
  Future<bool> updateLocation(SavedLocation location) {
    return _db.update(_db.savedLocations).replace(location);
  }
  
  /// Elimina una location tramite ID
  Future<int> deleteLocation(int id) {
    return (_db.delete(_db.savedLocations)
      ..where((t) => t.id.equals(id))
    ).go();
  }
  
  // ============================================================
  // OPERAZIONI SPECIFICHE
  // ============================================================
  
  /// Inverte lo stato di pin di una location
  Future<bool> togglePinLocation(int id) async {
    final location = await getLocationById(id);
    if (location != null) {
      return _db.update(_db.savedLocations).replace(
        location.copyWith(isPinned: !location.isPinned)
      );
    }
    return false;
  }
  
  /// Aggiorna l'etichetta di una location
  Future<bool> updateLabel(int id, String newLabel) async {
    final location = await getLocationById(id);
    if (location != null) {
      return _db.update(_db.savedLocations).replace(
        location.copyWith(label: newLabel)
      );
    }
    return false;
  }
  
  /// Ottiene solo le location con pin attivo
  Future<List<SavedLocation>> getPinnedLocations() {
    return (_db.select(_db.savedLocations)
      ..where((t) => t.isPinned.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.label)])
    ).get();
  }
  
  /// Scambia le etichette tra due location
  Future<void> swapLabels(int id1, int id2) async {
    await _db.transaction(() async {
      final loc1 = await getLocationById(id1);
      final loc2 = await getLocationById(id2);
      
      if (loc1 == null || loc2 == null) {
        throw Exception('Location not found');
      }
      
      await _db.update(_db.savedLocations).replace(
        loc1.copyWith(label: loc2.label)
      );
      await _db.update(_db.savedLocations).replace(
        loc2.copyWith(label: loc1.label)
      );
    });
  }
  
  // ============================================================
  // STATISTICHE E AGGREGAZIONI
  // ============================================================
  
  /// Ottiene le statistiche sulle location salvate
  Future<LocationStatistics> getStatistics() async {
    final countAll = _db.savedLocations.id.count();
    final countPinned = _db.savedLocations.id.count(
      filter: _db.savedLocations.isPinned.equals(true)
    );
    
    final query = _db.selectOnly(_db.savedLocations)
      ..addColumns([countAll, countPinned]);
    
    final result = await query.getSingle();
    
    return LocationStatistics(
      totalCount: result.read(countAll) ?? 0,
      pinnedCount: result.read(countPinned) ?? 0,
    );
  }
  
  // ============================================================
  // QUERY GEOGRAFICHE
  // ============================================================
  
  /// Ottiene location entro un certo raggio da coordinate specifiche
  /// 
  /// Utilizza la formula di Haversine per calcolare la distanza.
  /// [latitude] latitudine del punto di riferimento
  /// [longitude] longitudine del punto di riferimento
  /// [radiusKm] raggio di ricerca in chilometri
  Future<List<LocationWithDistance>> getLocationsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final query = _db.customSelect(
      '''
      SELECT 
        id,
        label,
        latitude,
        longitude,
        created_at,
        is_pinned,
        (6371 * acos(
          cos(radians(?)) * cos(radians(latitude)) * 
          cos(radians(longitude) - radians(?)) + 
          sin(radians(?)) * sin(radians(latitude))
        )) AS distance
      FROM saved_locations
      WHERE (6371 * acos(
          cos(radians(?)) * cos(radians(latitude)) * 
          cos(radians(longitude) - radians(?)) + 
          sin(radians(?)) * sin(radians(latitude))
        )) <= ?
      ORDER BY distance
      ''',
      variables: [
        Variable.withReal(latitude),
        Variable.withReal(longitude),
        Variable.withReal(latitude),
        Variable.withReal(latitude),
        Variable.withReal(longitude),
        Variable.withReal(latitude),
        Variable.withReal(radiusKm),
      ],
      readsFrom: {_db.savedLocations},
    );

    final results = await query.get();
    
    return results.map((row) {
      return LocationWithDistance(
        location: SavedLocation(
          id: row.read<int>('id'),
          label: row.read<String>('label'),
          latitude: row.read<double>('latitude'),
          longitude: row.read<double>('longitude'),
          createdAt: row.read<DateTime>('created_at'),
          isPinned: row.read<bool>('is_pinned'),
        ),
        distanceKm: row.read<double>('distance'),
      );
    }).toList();
  }
  
  // ============================================================
  // OPERAZIONI BATCH
  // ============================================================
  
  /// Inserisce multiple location in una singola transazione
  Future<void> insertLocationsBatch(List<SavedLocationsCompanion> locations) async {
    await _db.batch((batch) {
      batch.insertAll(_db.savedLocations, locations);
    });
  }
  
  /// Elimina tutte le location
  Future<int> deleteAllLocations() {
    return _db.delete(_db.savedLocations).go();
  }
  
  // ============================================================
  // STREAM REATTIVI
  // ============================================================
  
  /// Stream di tutte le location ordinate
  Stream<List<SavedLocation>> watchAllLocations() {
    return (_db.select(_db.savedLocations)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.label),
      ])
    ).watch();
  }
  
  /// Stream di una specifica location
  Stream<SavedLocation?> watchLocation(int id) {
    return (_db.select(_db.savedLocations)
      ..where((t) => t.id.equals(id))
    ).watchSingleOrNull();
  }
  
  /// Stream delle location pinnate
  Stream<List<SavedLocation>> watchPinnedLocations() {
    return (_db.select(_db.savedLocations)
      ..where((t) => t.isPinned.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.label)])
    ).watch();
  }
}

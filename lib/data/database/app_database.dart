import 'package:drift/drift.dart';
import 'tables.dart';
import 'database_connection.dart' as db_conn;
import 'daos/locations_dao.dart';
import 'models/location_statistics.dart';
import 'models/location_with_distance.dart';

part 'app_database.g.dart';

/// Database principale dell'applicazione
/// 
/// Questa classe gestisce la configurazione del database Drift,
/// le migrazioni dello schema e fornisce accesso ai DAOs.
@DriftDatabase(tables: [SavedLocations, Categories])
class AppDatabase extends _$AppDatabase {
  /// Istanza singleton del database (opzionale)
  static AppDatabase? _instance;
  
  /// Factory per ottenere l'istanza singleton
  factory AppDatabase.instance() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }
  
  /// Costruttore privato per il singleton
  AppDatabase._internal() : super(db_conn.DatabaseConnection.createConnection());
  
  /// Costruttore pubblico per testing o uso diretto
  AppDatabase() : super(db_conn.DatabaseConnection.createConnection());
  
  /// Costruttore per test con database in memoria
  AppDatabase.forTesting(super.executor);
  
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => _migrationStrategy;
  
  /// Strategia di migrazione del database
  MigrationStrategy get _migrationStrategy {
    return MigrationStrategy(
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  /// Chiamato alla creazione del database
  Future<void> _onCreate(Migrator m) async {
    await m.createAll();
    
    // Crea categorie predefinite
    await _insertDefaultCategories();
  }
  
  /// Chiamato durante l'aggiornamento dello schema
  Future<void> _onUpgrade(Migrator m, int from, int to) async {
    if (from < 2) {
      // Migration v1 -> v2: Aggiungi foto e categorie
      await m.createTable(categories);
      await m.addColumn(savedLocations, savedLocations.photoPath);
      await m.addColumn(savedLocations, savedLocations.categoryId);
      
      // Inserisci categorie predefinite
      await _insertDefaultCategories();
    }
  }
  
  /// Inserisce le categorie predefinite nel database
  Future<void> _insertDefaultCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(
        name: 'Casa',
        icon: const Value('🏠'),
        color: const Value('#4CAF50'),
      ),
      CategoriesCompanion.insert(
        name: 'Lavoro',
        icon: const Value('💼'),
        color: const Value('#2196F3'),
      ),
      CategoriesCompanion.insert(
        name: 'Ristoranti',
        icon: const Value('🍴'),
        color: const Value('#FF9800'),
      ),
      CategoriesCompanion.insert(
        name: 'Viaggi',
        icon: const Value('✈️'),
        color: const Value('#9C27B0'),
      ),
      CategoriesCompanion.insert(
        name: 'Sport',
        icon: const Value('⚽'),
        color: const Value('#F44336'),
      ),
      CategoriesCompanion.insert(
        name: 'Altro',
        icon: const Value('📍'),
        color: const Value('#607D8B'),
      ),
    ];
    
    for (final category in defaultCategories) {
      await into(categories).insert(
        category,
        mode: InsertMode.insertOrIgnore,
      );
    }
  }
  
  // ============================================================
  // DATA ACCESS OBJECTS
  // ============================================================
  
  /// DAO per le operazioni sulle location
  late final LocationsDao locationsDao = LocationsDao(this);
  
  // ============================================================
  // METODI DELEGATI PER ACCESSO SEMPLIFICATO
  // ============================================================
  
  /// Ottiene tutte le location ordinate
  Future<List<SavedLocation>> getAllLocationsSorted() => 
      locationsDao.getAllLocationsSorted();
  
  /// Ottiene una location tramite ID
  Future<SavedLocation?> getLocationById(int id) => 
      locationsDao.getLocationById(id);
  
  /// Inserisce una nuova location
  Future<SavedLocation> insertLocation(SavedLocationsCompanion location) => 
      locationsDao.insertLocation(location);
  
  /// Aggiorna una location
  Future<bool> updateLocation(SavedLocation location) => 
      locationsDao.updateLocation(location);
  
  /// Elimina una location
  Future<int> deleteLocation(int id) => 
      locationsDao.deleteLocation(id);
  
  /// Inverte lo stato pin di una location
  Future<bool> togglePin(int id) => 
      locationsDao.togglePinLocation(id);
  
  /// Aggiorna l'etichetta di una location
  Future<bool> updateLabel(int id, String newLabel) => 
      locationsDao.updateLabel(id, newLabel);
  
  /// Ottiene le statistiche
  Future<LocationStatistics> getStatistics() => 
      locationsDao.getStatistics();
  
  /// Ottiene location vicine
  Future<List<LocationWithDistance>> getLocationsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) => locationsDao.getLocationsNearby(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
  );
  
  /// Ottiene solo le location con pin attivo
  Future<List<SavedLocation>> getPinnedLocations() => 
      locationsDao.getPinnedLocations();
  
  /// Inserisce multiple location in batch
  Future<void> insertLocationsBatch(List<SavedLocationsCompanion> locations) => 
      locationsDao.insertLocationsBatch(locations);
  
  /// Scambia le etichette tra due location
  Future<void> swapLabels(int id1, int id2) => 
      locationsDao.swapLabels(id1, id2);
  
  /// Watch stream di tutte le location
  Stream<List<SavedLocation>> watchAllLocations() {
    return (select(savedLocations)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.label, mode: OrderingMode.asc),
      ])
    ).watch();
  }
}
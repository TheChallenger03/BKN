import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/saved_location_model.dart';
import '../../core/constants/app_constants.dart';

abstract class LocationLocalDataSource {
  Future<List<SavedLocationModel>> getAllLocations();
  Future<SavedLocationModel?> getLocationById(int id);
  Future<SavedLocationModel> insertLocation(SavedLocationModel location);
  Future<SavedLocationModel> updateLocation(SavedLocationModel location);
  Future<void> deleteLocation(int id);
  Future<SavedLocationModel> togglePin(int id);
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }


  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.locationsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        createdAt INTEGER NOT NULL,
        isPinned INTEGER DEFAULT 0
      )
    ''');
  }

  @override
  Future<List<SavedLocationModel>> getAllLocations() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.locationsTable,
      orderBy: 'isPinned DESC, label COLLATE NOCASE ASC',
      );
    return maps.map((map) => SavedLocationModel.fromMap(map)).toList();
  }

  @override
  Future<SavedLocationModel?> getLocationById(int id) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.locationsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if(maps.isEmpty) {
      throw Exception('Location not found');
    }
    return SavedLocationModel.fromMap(maps.first);
  }

  @override
  Future<SavedLocationModel> insertLocation(SavedLocationModel location) async {
    final db = await database;
    final id = await db.insert(
      AppConstants.locationsTable,
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return location.copyWith(id: id);
  }

  @override
  Future<SavedLocationModel> updateLocation(SavedLocationModel location) async {
    final db = await database;
    await db.update(
      AppConstants.locationsTable,
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
    return location;
  }

  @override
  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete(
      AppConstants.locationsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<SavedLocationModel> togglePin(int id) async {
    final location = await getLocationById(id);
    if (location == null) {
      throw Exception('Location not found');
    }
    final toggled = SavedLocationModel(
      id: location.id,
      label: location.label,
      latitude: location.latitude,
      longitude: location.longitude,
      createdAt: location.createdAt,
      isPinned: !location.isPinned,
    );
    return await updateLocation(toggled);
  }
}
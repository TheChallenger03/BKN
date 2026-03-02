import 'package:drift/drift.dart';

/// Tabella Categories per categorizzare le location
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text().withDefault(const Constant('📍'))();
  TextColumn get color => text().withDefault(const Constant('#1976D2'))(); // Hex color
}

/// Tabella SavedLocations
class SavedLocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  
  // New fields for enhanced features
  TextColumn get photoPath => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
}
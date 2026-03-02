import 'package:drift/drift.dart';

///Tabella SavedLocations
class SavedLocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
}
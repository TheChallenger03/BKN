import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:bkn/data/database/database.dart';

/// Test suite per LocationsDao
/// 
/// Testa tutte le funzionalità del DAO con un database in memoria
void main() {
  late AppDatabase database;
  late LocationsDao dao;

  setUp(() {
    // Crea un database in memoria per ogni test
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = database.locationsDao;
  });

  tearDown(() async {
    // Chiudi il database dopo ogni test
    await database.close();
  });

  group('CRUD Operations', () {
    test('insertLocation should insert and return location with ID', () async {
      // Arrange
      final companion = SavedLocationsCompanion.insert(
        label: 'Test Location',
        latitude: 45.4642,
        longitude: 9.1900,
        createdAt: DateTime.now(),
      );

      // Act
      final result = await dao.insertLocation(companion);

      // Assert
      expect(result.id, isNotNull);
      expect(result.label, 'Test Location');
      expect(result.latitude, 45.4642);
      expect(result.longitude, 9.1900);
    });

    test('getLocationById should return correct location', () async {
      // Arrange
      final inserted = await dao.insertLocation(
        SavedLocationsCompanion.insert(
          label: 'Test',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
        ),
      );

      // Act
      final result = await dao.getLocationById(inserted.id);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, inserted.id);
      expect(result.label, 'Test');
    });

    test('getLocationById should return null for non-existent ID', () async {
      // Act
      final result = await dao.getLocationById(999);

      // Assert
      expect(result, isNull);
    });

    test('updateLocation should update existing location', () async {
      // Arrange
      final inserted = await dao.insertLocation(
        SavedLocationsCompanion.insert(
          label: 'Old Label',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
        ),
      );

      // Act
      final updated = inserted.copyWith(label: 'New Label');
      final success = await dao.updateLocation(updated);

      // Assert
      expect(success, isTrue);
      final result = await dao.getLocationById(inserted.id);
      expect(result!.label, 'New Label');
    });

    test('deleteLocation should remove location', () async {
      // Arrange
      final inserted = await dao.insertLocation(
        SavedLocationsCompanion.insert(
          label: 'To Delete',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
        ),
      );

      // Act
      final deletedCount = await dao.deleteLocation(inserted.id);

      // Assert
      expect(deletedCount, 1);
      final result = await dao.getLocationById(inserted.id);
      expect(result, isNull);
    });

    test('getAllLocationsSorted should return locations sorted by pin and label', () async {
      // Arrange
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'B Location',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
        isPinned: Value(false),
      ));
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'A Location',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
        isPinned: Value(true),
      ));
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'C Location',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
        isPinned: Value(true),
      ));

      // Act
      final results = await dao.getAllLocationsSorted();

      // Assert
      expect(results.length, 3);
      expect(results[0].isPinned, isTrue);
      expect(results[0].label, 'A Location');
      expect(results[1].isPinned, isTrue);
      expect(results[1].label, 'C Location');
      expect(results[2].isPinned, isFalse);
      expect(results[2].label, 'B Location');
    });
  });

  group('Pin Operations', () {
    test('togglePinLocation should invert pin status', () async {
      // Arrange
      final inserted = await dao.insertLocation(
        SavedLocationsCompanion.insert(
          label: 'Test',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
          isPinned: Value(false),
        ),
      );

      // Act
      await dao.togglePinLocation(inserted.id);

      // Assert
      final result = await dao.getLocationById(inserted.id);
      expect(result!.isPinned, isTrue);

      // Act again
      await dao.togglePinLocation(inserted.id);

      // Assert
      final result2 = await dao.getLocationById(inserted.id);
      expect(result2!.isPinned, isFalse);
    });

    test('getPinnedLocations should return only pinned locations', () async {
      // Arrange
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'Pinned 1',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
        isPinned: Value(true),
      ));
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'Not Pinned',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
        isPinned: Value(false),
      ));
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'Pinned 2',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
        isPinned: Value(true),
      ));

      // Act
      final results = await dao.getPinnedLocations();

      // Assert
      expect(results.length, 2);
      expect(results.every((loc) => loc.isPinned), isTrue);
    });
  });

  group('Label Operations', () {
    test('updateLabel should update location label', () async {
      // Arrange
      final inserted = await dao.insertLocation(
        SavedLocationsCompanion.insert(
          label: 'Old',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
        ),
      );

      // Act
      await dao.updateLabel(inserted.id, 'New');

      // Assert
      final result = await dao.getLocationById(inserted.id);
      expect(result!.label, 'New');
    });

    test('swapLabels should exchange labels between two locations', () async {
      // Arrange
      final loc1 = await dao.insertLocation(
        SavedLocationsCompanion.insert(
          label: 'Label A',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
        ),
      );
      final loc2 = await dao.insertLocation(
        SavedLocationsCompanion.insert(
          label: 'Label B',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
        ),
      );

      // Act
      await dao.swapLabels(loc1.id, loc2.id);

      // Assert
      final result1 = await dao.getLocationById(loc1.id);
      final result2 = await dao.getLocationById(loc2.id);
      expect(result1!.label, 'Label B');
      expect(result2!.label, 'Label A');
    });
  });

  group('Statistics', () {
    test('getStatistics should return correct counts', () async {
      // Arrange
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'Pinned',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
        isPinned: Value(true),
      ));
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'Not Pinned',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
        isPinned: Value(false),
      ));

      // Act
      final stats = await dao.getStatistics();

      // Assert
      expect(stats.totalCount, 2);
      expect(stats.pinnedCount, 1);
      expect(stats.pinnedPercentage, 50.0);
    });
  });

  group('Batch Operations', () {
    test('insertLocationsBatch should insert multiple locations', () async {
      // Arrange
      final locations = List.generate(
        5,
        (i) => SavedLocationsCompanion.insert(
          label: 'Location $i',
          latitude: 45.0 + i,
          longitude: 9.0 + i,
          createdAt: DateTime.now(),
        ),
      );

      // Act
      await dao.insertLocationsBatch(locations);

      // Assert
      final all = await dao.getAllLocationsSorted();
      expect(all.length, 5);
    });

    test('deleteAllLocations should remove all locations', () async {
      // Arrange
      await dao.insertLocationsBatch([
        SavedLocationsCompanion.insert(
          label: 'Loc 1',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
        ),
        SavedLocationsCompanion.insert(
          label: 'Loc 2',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
        ),
      ]);

      // Act
      final deletedCount = await dao.deleteAllLocations();

      // Assert
      expect(deletedCount, 2);
      final all = await dao.getAllLocationsSorted();
      expect(all, isEmpty);
    });
  });

  group('Reactive Streams', () {
    test('watchAllLocations should emit updates', () async {
      // Arrange
      final stream = dao.watchAllLocations();
      final expectedCounts = [0, 1, 2];
      var index = 0;

      // Act & Assert
      stream.listen(expectAsync1((locations) {
        expect(locations.length, expectedCounts[index]);
        index++;
      }, count: 3));

      await Future.delayed(Duration(milliseconds: 100));
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'Test 1',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
      ));

      await Future.delayed(Duration(milliseconds: 100));
      await dao.insertLocation(SavedLocationsCompanion.insert(
        label: 'Test 2',
        latitude: 45.0,
        longitude: 9.0,
        createdAt: DateTime.now(),
      ));

      await Future.delayed(Duration(milliseconds: 100));
    });

    test('watchLocation should emit updates for specific location', () async {
      // Arrange
      final inserted = await dao.insertLocation(
        SavedLocationsCompanion.insert(
          label: 'Initial',
          latitude: 45.0,
          longitude: 9.0,
          createdAt: DateTime.now(),
        ),
      );

      final stream = dao.watchLocation(inserted.id);
      final expectedLabels = ['Initial', 'Updated'];
      var index = 0;

      // Act & Assert
      stream.listen(expectAsync1((location) {
        expect(location!.label, expectedLabels[index]);
        index++;
      }, count: 2));

      await Future.delayed(Duration(milliseconds: 100));
      await dao.updateLabel(inserted.id, 'Updated');

      await Future.delayed(Duration(milliseconds: 100));
    });
  });
}

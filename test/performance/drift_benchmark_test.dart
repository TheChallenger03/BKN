import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:bkn/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase database;

  setUp(() {
    // Database in-memory per test isolati
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Drift CRUD Operations', () {
    test('Insert and fetch location', () async {
      // Arrange
      final location = SavedLocationsCompanion(
        label: Value('Test'),
        latitude: Value(44.4949),
        longitude: Value(11.3426),
        createdAt: Value(DateTime.now()),
        isPinned: Value(false),
      );

      // Act
      final inserted = await database.insertLocation(location);
      final fetched = await database.getLocationById(inserted.id);

      // Assert
      expect(fetched, isNotNull);
      expect(fetched!.label, 'Test');
      expect(fetched.latitude, 44.4949);
    });

    test('Update location label', () async {
      // Arrange
      final location = await _createTestLocation(database, 'Original');

      // Act
      final success = await database.updateLabel(location.id, 'Updated');
      final updated = await database.getLocationById(location.id);

      // Assert
      expect(success, isTrue);
      expect(updated!.label, 'Updated');
    });

    test('Toggle pin status', () async {
      // Arrange
      final location = await _createTestLocation(database, 'Test', isPinned: false);

      // Act
      await database.togglePin(location.id);
      final toggled1 = await database.getLocationById(location.id);

      await database.togglePin(location.id);
      final toggled2 = await database.getLocationById(location.id);

      // Assert
      expect(toggled1!.isPinned, isTrue);
      expect(toggled2!.isPinned, isFalse);
    });

    test('Delete location', () async {
      // Arrange
      final location = await _createTestLocation(database, 'To Delete');

      // Act
      await database.deleteLocation(location.id);
      final deleted = await database.getLocationById(location.id);

      // Assert
      expect(deleted, isNull);
    });
  });

  group('Drift Query Operations', () {
    test('Sorted query - pinned first, then alphabetically', () async {
      // Arrange
      await _createTestLocation(database, 'C', isPinned: false);
      await _createTestLocation(database, 'A', isPinned: false);
      await _createTestLocation(database, 'B', isPinned: true);

      // Act
      final sorted = await database.getAllLocationsSorted();

      // Assert
      expect(sorted.length, 3);
      expect(sorted[0].label, 'B'); // Pinned first
      expect(sorted[1].label, 'A'); // Then alphabetically
      expect(sorted[2].label, 'C');
    });

    test('Statistics aggregation', () async {
      // Arrange
      await _createTestLocation(database, 'L1', isPinned: true);
      await _createTestLocation(database, 'L2', isPinned: false);
      await _createTestLocation(database, 'L3', isPinned: true);

      // Act
      final stats = await database.getStatistics();

      // Assert
      expect(stats.totalCount, 3);
      expect(stats.pinnedCount, 2);
      expect(stats.pinnedPercentage, closeTo(66.67, 0.1));
    });

    test('Nearby search - Haversine formula', () async {
      // Arrange - Bologna Centro
      await _createTestLocation(
        database,
        'Bologna Centro',
        lat: 44.4949,
        lng: 11.3426,
      );

      // Milano (circa 200km)
      await _createTestLocation(
        database,
        'Milano',
        lat: 45.4642,
        lng: 9.1900,
      );

      // Modena (circa 40km)
      await _createTestLocation(
        database,
        'Modena',
        lat: 44.6471,
        lng: 10.9252,
      );

      // Act - Cerca entro 50km da Bologna
      final nearby = await database.getLocationsNearby(
        latitude: 44.4949,
        longitude: 11.3426,
        radiusKm: 50,
      );

      // Assert
      expect(nearby.length, 2); // Bologna + Modena
      expect(nearby[0].location.label, 'Bologna Centro'); // Più vicina
      expect(nearby[1].location.label, 'Modena');
      expect(nearby[0].distanceKm, lessThan(1)); // Praticamente 0
      expect(nearby[1].distanceKm, greaterThan(35));
      expect(nearby[1].distanceKm, lessThan(45));
    });
  });

  group('Drift Advanced Operations', () {
    test('Batch insert performance', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      final locations = List.generate(
        1000,
        (i) => SavedLocationsCompanion(
          label: Value('Location $i'),
          latitude: Value(44.0 + i * 0.001),
          longitude: Value(11.0 + i * 0.001),
          createdAt: Value(DateTime.now()),
        ),
      );

      // Act
      await database.insertLocationsBatch(locations);

      stopwatch.stop();

      // Assert
      final count = await database.getStatistics();
      expect(count.totalCount, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // < 1 sec
      
      print('Batch insert 1000 records: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Transaction - swap labels', () async {
      // Arrange
      final loc1 = await _createTestLocation(database, 'Label 1');
      final loc2 = await _createTestLocation(database, 'Label 2');

      // Act
      await database.swapLabels(loc1.id, loc2.id);

      final swapped1 = await database.getLocationById(loc1.id);
      final swapped2 = await database.getLocationById(loc2.id);

      // Assert
      expect(swapped1!.label, 'Label 2');
      expect(swapped2!.label, 'Label 1');
    });

    test('Watch stream emits updates', () async {
      // Arrange
      final stream = database.watchAllLocations();
      final emissions = <List<SavedLocation>>[];

      // Listen
      final subscription = stream.listen((locations) {
        emissions.add(locations);
      });

      // Act
      await Future.delayed(Duration(milliseconds: 100));
      await _createTestLocation(database, 'Test 1');

      await Future.delayed(Duration(milliseconds: 100));
      await _createTestLocation(database, 'Test 2');

      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.length, 2);

      await subscription.cancel();
    });
  });
}

// Helper per creare location di test
Future<SavedLocation> _createTestLocation(
  AppDatabase db,
  String label, {
  double lat = 44.4949,
  double lng = 11.3426,
  bool isPinned = false,
}) async {
  return await db.insertLocation(SavedLocationsCompanion(
    label: Value(label),
    latitude: Value(lat),
    longitude: Value(lng),
    createdAt: Value(DateTime.now()),
    isPinned: Value(isPinned),
  ));
}


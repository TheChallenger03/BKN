import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:bkn/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'dart:io';
import 'dart:math';

/// Suite di benchmark completa per la tesi
/// Genera CSV con risultati per grafici
void main() {
  group('THESIS BENCHMARKS', () {
    
    test('DATASET 1: Query Performance vs Dataset Size', () async {
      final results = <BenchmarkResult>[];
      final sizes = [100, 500, 1000, 5000, 10000];
      
      for (final size in sizes) {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        
        // Popola database
        await _populateDatabase(db, size);
        
        // Test 1: Simple SELECT
        final selectTime = await _measureQuery(() => db.getAllLocationsSorted());
        
        // Test 2: Aggregation
        final aggTime = await _measureQuery(() => db.getStatistics());
        
        // Test 3: Geospatial (entro 50km da Bologna Centro)
        final geoTime = await _measureQuery(() => db.getLocationsNearby(
          latitude: 44.505832,
          longitude: 11.343207,
          radiusKm: 50,
        ));
        
        results.add(BenchmarkResult(
          datasetSize: size,
          simpleSelectMs: selectTime,
          aggregationMs: aggTime,
          geospatialMs: geoTime,
        ));
        
        await db.close();
        
        print('Dataset $size: SELECT=${selectTime}ms, AGG=${aggTime}ms, GEO=${geoTime}ms');
      }
      
      // Salva risultati in CSV per grafici
      await _saveResultsToCsv(results, 'benchmark_dataset_size.csv');
    });
    
    test('DATASET 2: Query Complexity Analysis', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final datasetSize = 10000;
      
      await _populateDatabase(db, datasetSize);
      
      final results = <QueryComplexityResult>[];
      
      // Query 1: Simple SELECT (tutte le locations)
      final q1Time = await _measureQuery(() => db.getAllLocationsSorted());
      results.add(QueryComplexityResult(
        queryType: 'Simple SELECT',
        complexity: 'O(n log n)', // sort
        executionTimeMs: q1Time,
        tupleCount: datasetSize,
      ));
      
      // Query 2: SELECT con filtro (solo pinned)
      final q2Time = await _measureQuery(() => db.getPinnedLocations());
      results.add(QueryComplexityResult(
        queryType: 'SELECT with WHERE',
        complexity: 'O(n)', // scan + filter
        executionTimeMs: q2Time,
        tupleCount: datasetSize,
      ));
      
      // Query 3: Aggregazione (COUNT)
      final q3Time = await _measureQuery(() => db.getStatistics());
      results.add(QueryComplexityResult(
        queryType: 'Aggregation (COUNT)',
        complexity: 'O(n)',
        executionTimeMs: q3Time,
        tupleCount: datasetSize,
      ));
      
      // Query 4: Geospatial (Haversine formula)
      final q4Time = await _measureQuery(() => db.getLocationsNearby(
        latitude: 44.505832,
        longitude: 11.343207,
        radiusKm: 50,
      ));
      results.add(QueryComplexityResult(
        queryType: 'Geospatial (Haversine)',
        complexity: 'O(n)', // scan + compute distance
        executionTimeMs: q4Time,
        tupleCount: datasetSize,
      ));
      
      // Query 5: Transaction (swap labels)
      final loc1 = await _createTestLocation(db, 'Test1');
      final loc2 = await _createTestLocation(db, 'Test2');
      final q5Time = await _measureQuery(() => db.swapLabels(loc1.id, loc2.id));
      results.add(QueryComplexityResult(
        queryType: 'Transaction (2 UPDATEs)',
        complexity: 'O(1)', // direct by ID
        executionTimeMs: q5Time,
        tupleCount: 2,
      ));
      
      await db.close();
      
      // Stampa tabella
      _printComplexityTable(results);
      
      // Salva CSV
      await _saveComplexityToCsv(results, 'benchmark_query_complexity.csv');
    });
    
    test('DATASET 3: Batch Insert Scalability', () async {
      final results = <BatchInsertResult>[];
      final sizes = [100, 500, 1000, 2000, 5000, 10000];
      
      for (final size in sizes) {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        
        final locations = _generateTestLocations(size);
        
        final stopwatch = Stopwatch()..start();
        await db.insertLocationsBatch(locations);
        stopwatch.stop();
        
        final timeMs = stopwatch.elapsedMilliseconds;
        final recordsPerSecond = (size / (timeMs / 1000)).round();
        
        results.add(BatchInsertResult(
          recordCount: size,
          totalTimeMs: timeMs,
          timePerRecordMs: timeMs / size,
          recordsPerSecond: recordsPerSecond,
        ));
        
        await db.close();
        
        print('Batch $size: ${timeMs}ms (${recordsPerSecond} records/sec)');
      }
      
      await _saveBatchInsertToCsv(results, 'benchmark_batch_insert.csv');
    });
    
    test('DATASET 4: Geospatial Query Accuracy', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      
      // Inserisci locations note in Italia
      await _insertKnownLocations(db);
      
      // Test ricerca da Bologna Centro (Stazione Centrale)
      final radiusTests = [10.0, 25.0, 50.0, 100.0, 200.0];
      final results = <GeospatialAccuracyResult>[];
      
      for (final radius in radiusTests) {
        final stopwatch = Stopwatch()..start();
        final found = await db.getLocationsNearby(
          latitude: 44.505832,
          longitude: 11.343207,
          radiusKm: radius,
        );
        stopwatch.stop();
        
        results.add(GeospatialAccuracyResult(
          radiusKm: radius,
          locationsFound: found.length,
          executionTimeMs: stopwatch.elapsedMilliseconds,
          locations: found.map((l) => 
            '${l.location.label} (${l.distanceKm.toStringAsFixed(1)}km)'
          ).toList(),
        ));
        
        print('Radius ${radius}km: ${found.length} locations in ${stopwatch.elapsedMilliseconds}ms');
        for (final loc in found) {
          print('  - ${loc.location.label}: ${loc.formattedDistance}');
        }
      }
      
      await db.close();
      
      await _saveGeospatialToCsv(results, 'benchmark_geospatial_accuracy.csv');
    });
  });
}

// ============= HELPER CLASSES =============

class BenchmarkResult {
  final int datasetSize;
  final int simpleSelectMs;
  final int aggregationMs;
  final int geospatialMs;

  BenchmarkResult({
    required this.datasetSize,
    required this.simpleSelectMs,
    required this.aggregationMs,
    required this.geospatialMs,
  });
}

class QueryComplexityResult {
  final String queryType;
  final String complexity;
  final int executionTimeMs;
  final int tupleCount;

  QueryComplexityResult({
    required this.queryType,
    required this.complexity,
    required this.executionTimeMs,
    required this.tupleCount,
  });
}

class BatchInsertResult {
  final int recordCount;
  final int totalTimeMs;
  final double timePerRecordMs;
  final int recordsPerSecond;

  BatchInsertResult({
    required this.recordCount,
    required this.totalTimeMs,
    required this.timePerRecordMs,
    required this.recordsPerSecond,
  });
}

class GeospatialAccuracyResult {
  final double radiusKm;
  final int locationsFound;
  final int executionTimeMs;
  final List<String> locations;

  GeospatialAccuracyResult({
    required this.radiusKm,
    required this.locationsFound,
    required this.executionTimeMs,
    required this.locations,
  });
}

// ============= HELPER FUNCTIONS =============

Future<int> _measureQuery(Future<dynamic> Function() query) async {
  final stopwatch = Stopwatch()..start();
  await query();
  stopwatch.stop();
  return stopwatch.elapsedMilliseconds;
}

Future<void> _populateDatabase(AppDatabase db, int count) async {
  final locations = _generateTestLocations(count);
  await db.insertLocationsBatch(locations);
}

List<SavedLocationsCompanion> _generateTestLocations(int count) {
  final random = Random();
  return List.generate(
    count,
    (i) => SavedLocationsCompanion.insert(
      label: 'Location $i',
      latitude: 38.0 + random.nextDouble() * 10, // Italia
      longitude: 7.0 + random.nextDouble() * 12,
      createdAt: DateTime.now().subtract(Duration(days: i)),
      isPinned: Value(i % 10 == 0),
    ),
  );
}

Future<SavedLocation> _createTestLocation(
  AppDatabase db,
  String label, {
  double lat = 44.505832,  // Bologna Centro - Stazione Centrale
  double lng = 11.343207,
}) async {
  return await db.insertLocation(SavedLocationsCompanion.insert(
    label: label,
    latitude: lat,
    longitude: lng,
    createdAt: DateTime.now(),
  ));
}

Future<void> _insertKnownLocations(AppDatabase db) async {
  // Città italiane con coordinate precise (stazioni principali/centri città)
  final locations = [
    ('Bologna Centro', 44.505832, 11.343207),  // 0km - Stazione Centrale
    ('Modena', 44.647128, 10.925256),          // ~40km - Stazione
    ('Ferrara', 44.835717, 11.619787),         // ~50km - Stazione
    ('Firenze SMN', 43.776322, 11.247955),     // ~90km - Santa Maria Novella
    ('Ravenna', 44.418354, 12.203451),         // ~80km - Stazione
    ('Milano Centrale', 45.486251, 9.204780),  // ~215km - Stazione Centrale
    ('Roma Termini', 41.900276, 12.502215),    // ~380km - Stazione Termini
    ('Venezia SL', 45.440847, 12.319653),      // ~155km - Santa Lucia
  ];
  
  final companions = locations.map((loc) => SavedLocationsCompanion.insert(
    label: loc.$1,
    latitude: loc.$2,
    longitude: loc.$3,
    createdAt: DateTime.now(),
  )).toList();
  
  await db.insertLocationsBatch(companions);
}

// ============= CSV EXPORT =============

Future<void> _saveResultsToCsv(List<BenchmarkResult> results, String filename) async {
  final file = File('test/performance/results/$filename');
  await file.parent.create(recursive: true);
  
  final lines = [
    'Dataset Size,Simple SELECT (ms),Aggregation (ms),Geospatial (ms)',
    ...results.map((r) => 
      '${r.datasetSize},${r.simpleSelectMs},${r.aggregationMs},${r.geospatialMs}'
    ),
  ];
  
  await file.writeAsString(lines.join('\n'));
  print('\n✅ Saved: ${file.path}');
}

Future<void> _saveComplexityToCsv(List<QueryComplexityResult> results, String filename) async {
  final file = File('test/performance/results/$filename');
  await file.parent.create(recursive: true);
  
  final lines = [
    'Query Type,Complexity,Execution Time (ms),Tuple Count',
    ...results.map((r) => 
      '${r.queryType},${r.complexity},${r.executionTimeMs},${r.tupleCount}'
    ),
  ];
  
  await file.writeAsString(lines.join('\n'));
  print('✅ Saved: ${file.path}');
}

Future<void> _saveBatchInsertToCsv(List<BatchInsertResult> results, String filename) async {
  final file = File('test/performance/results/$filename');
  await file.parent.create(recursive: true);
  
  final lines = [
    'Record Count,Total Time (ms),Time per Record (ms),Records per Second',
    ...results.map((r) => 
      '${r.recordCount},${r.totalTimeMs},${r.timePerRecordMs.toStringAsFixed(3)},${r.recordsPerSecond}'
    ),
  ];
  
  await file.writeAsString(lines.join('\n'));
  print('✅ Saved: ${file.path}');
}

Future<void> _saveGeospatialToCsv(List<GeospatialAccuracyResult> results, String filename) async {
  final file = File('test/performance/results/$filename');
  await file.parent.create(recursive: true);
  
  final lines = [
    'Radius (km),Locations Found,Execution Time (ms)',
    ...results.map((r) => 
      '${r.radiusKm},${r.locationsFound},${r.executionTimeMs}'
    ),
  ];
  
  await file.writeAsString(lines.join('\n'));
  print('✅ Saved: ${file.path}');
}

void _printComplexityTable(List<QueryComplexityResult> results) {
  print('\n╔════════════════════════════════════════════════════════════════╗');
  print('║           QUERY COMPLEXITY ANALYSIS (10K records)             ║');
  print('╠════════════════════════════════╦═══════════╦═══════════════════╣');
  print('║ Query Type                     ║ Time (ms) ║ Complexity        ║');
  print('╠════════════════════════════════╬═══════════╬═══════════════════╣');
  
  for (final r in results) {
    final queryPadded = r.queryType.padRight(30);
    final timePadded = r.executionTimeMs.toString().padLeft(9);
    final complexityPadded = r.complexity.padRight(17);
    print('║ $queryPadded ║ $timePadded ║ $complexityPadded ║');
  }
  
  print('╚════════════════════════════════╩═══════════╩═══════════════════╝\n');
}
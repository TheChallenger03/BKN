# Database Layer

Questo modulo gestisce la persistenza dei dati dell'applicazione utilizzando Drift (SQLite).

## Architettura

L'architettura del database segue il pattern **DAO (Data Access Object)** e i principi **SOLID** per garantire:
- 📦 **Separazione delle responsabilità**
- 🔧 **Manutenibilità**
- 🧪 **Testabilità**
- 📈 **Scalabilità**

## Struttura File

```
database/
├── app_database.dart              # Database principale e configurazione
├── database_connection.dart       # Gestione connessione al database
├── tables.dart                    # Definizione tabelle
├── database.dart                  # Barrel file per export
├── daos/                          # Data Access Objects
│   └── locations_dao.dart         # DAO per operazioni su SavedLocations
└── models/                        # DTOs e Value Objects
    ├── location_statistics.dart   # Statistiche sulle location
    └── location_with_distance.dart # Location con distanza calcolata
```

## Componenti Principali

### AppDatabase
**File:** `app_database.dart`

Classe principale che configura:
- Schema del database
- Versioning
- Strategie di migrazione
- Accesso ai DAOs

```dart
final db = AppDatabase.instance();
final locations = await db.locationsDao.getAllLocationsSorted();
```

### DatabaseConnection
**File:** `database_connection.dart`

Gestisce la connessione al database con:
- Configurazione lazy loading
- Path del database
- Utility per testing e debug

### LocationsDao
**File:** `daos/locations_dao.dart`

DAO che gestisce tutte le operazioni sulla tabella `SavedLocations`:

#### Operazioni CRUD Base
- `getAllLocationsSorted()` - Tutte le location ordinate
- `getLocationById(id)` - Location per ID
- `insertLocation(location)` - Inserimento
- `updateLocation(location)` - Aggiornamento
- `deleteLocation(id)` - Eliminazione

#### Operazioni Specifiche
- `togglePinLocation(id)` - Inverti stato pin
- `updateLabel(id, label)` - Aggiorna etichetta
- `getPinnedLocations()` - Solo location pinnate
- `swapLabels(id1, id2)` - Scambia etichette

#### Query Geografiche
- `getLocationsNearby()` - Location entro un raggio (formula Haversine)

#### Statistiche
- `getStatistics()` - Conta totali e aggregazioni

#### Operazioni Batch
- `insertLocationsBatch()` - Inserimenti multipli
- `deleteAllLocations()` - Eliminazione completa

#### Stream Reattivi
- `watchAllLocations()` - Stream di tutte le location
- `watchLocation(id)` - Stream di una location specifica
- `watchPinnedLocations()` - Stream location pinnate

## Modelli

### LocationStatistics
Statistiche sulle location salvate:
- `totalCount` - Totale location
- `pinnedCount` - Location pinnate
- `pinnedPercentage` - Percentuale calcolata

### LocationWithDistance
Location con distanza calcolata da un punto:
- `location` - Dati location
- `distanceKm` - Distanza in km
- `formattedDistance` - Distanza formattata (m/km)
- `isNearby` - Verifica vicinanza (< 100m)

## Utilizzo

### Inizializzazione

```dart
import 'package:bkn/data/database/database.dart';

// Con singleton
final db = AppDatabase.instance();

// Oppure istanza diretta
final db = AppDatabase();
```

### Operazioni CRUD

```dart
// Inserimento
final location = await db.locationsDao.insertLocation(
  SavedLocationsCompanion.insert(
    label: 'Casa',
    latitude: 45.4642,
    longitude: 9.1900,
    createdAt: DateTime.now(),
  ),
);

// Lettura
final allLocations = await db.locationsDao.getAllLocationsSorted();
final location = await db.locationsDao.getLocationById(1);

// Aggiornamento
await db.locationsDao.updateLabel(1, 'Nuova Casa');
await db.locationsDao.togglePinLocation(1);

// Eliminazione
await db.locationsDao.deleteLocation(1);
```

### Stream Reattivi

```dart
// Ascolta cambiamenti in tempo reale
db.locationsDao.watchAllLocations().listen((locations) {
  print('Aggiornamento: ${locations.length} location');
});

// Con StreamBuilder in Flutter
StreamBuilder<List<SavedLocation>>(
  stream: db.locationsDao.watchAllLocations(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    final locations = snapshot.data!;
    return ListView.builder(...);
  },
)
```

### Query Geografiche

```dart
// Trova location vicine
final nearby = await db.locationsDao.getLocationsNearby(
  latitude: 45.4642,
  longitude: 9.1900,
  radiusKm: 5.0,
);

for (final item in nearby) {
  print('${item.location.read<String>('label')}: ${item.formattedDistance}');
}
```

### Statistiche

```dart
final stats = await db.locationsDao.getStatistics();
print('Totale: ${stats.totalCount}');
print('Pinnate: ${stats.pinnedCount} (${stats.pinnedPercentage}%)');
```

## Migrazioni

Le migrazioni dello schema sono gestite in `app_database.dart`:

```dart
Future<void> _onUpgrade(Migrator m, int from, int to) async {
  if (from < 2) {
    // Esempio: aggiungere colonna in versione 2
    await m.addColumn(savedLocations, savedLocations.newColumn);
  }
  if (from < 3) {
    // Altre migrazioni per versione 3
  }
}
```

Per applicare una migrazione:
1. Incrementa `schemaVersion` in `AppDatabase`
2. Aggiungi logica in `_onUpgrade`
3. Rigenera codice: `flutter pub run build_runner build`

## Testing

Per test unitari, usa un database in memoria:

```dart
import 'package:drift/native.dart';

final testDb = AppDatabase.forTesting(
  NativeDatabase.memory(),
);

// Esegui test
final location = await testDb.locationsDao.insertLocation(...);
expect(location.id, isNotNull);
```

## Best Practices

1. **Usa sempre il DAO**: Non accedere direttamente alle tabelle
2. **Stream per UI reattive**: Usa `watch*` per aggiornamenti automatici
3. **Batch per performance**: Usa `insertLocationsBatch` per inserimenti multipli
4. **Transazioni per atomicità**: Operazioni multiple devono usare `transaction()`
5. **Testing**: Crea test per ogni metodo del DAO

## Rigenerazione Codice

Dopo modifiche a tabelle o DAOs:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Dipendenze

```yaml
dependencies:
  drift: ^2.20.3
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.5
  path: ^1.9.1

dev_dependencies:
  drift_dev: ^2.20.3
  build_runner: ^2.4.13
```

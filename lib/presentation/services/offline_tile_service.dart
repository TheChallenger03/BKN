import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Service per la gestione dei tile offline della mappa.
/// 
/// Rispetta Single Responsibility: gestisce SOLO il caching dei tile.
/// Non conosce la UI o la logica di business dell'app.
class OfflineTileService {
  static const String _storeName = 'bkn_offline_maps';
  static const String _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _userAgent = 'com.example.location_tracker';
  
  late final FMTCStore _store;
  bool _isInitialized = false;

  /// Inizializza il servizio e crea lo store per i tile
  Future<void> initialize() async {
    if (_isInitialized) return;

    await FMTCObjectBoxBackend().initialise();
    _store = FMTCStore(_storeName);
    await _store.manage.create();
    _isInitialized = true;
  }

  /// Scarica i tile per un'area rettangolare specificata
  /// 
  /// [southwest] - Angolo sud-ovest dell'area
  /// [northeast] - Angolo nord-est dell'area
  /// [minZoom] - Livello di zoom minimo (default: 5)
  /// [maxZoom] - Livello di zoom massimo (default: 18)
  /// [onProgress] - Callback per il progresso (tile scaricati / totali)
  Future<DownloadResult> downloadAreaTiles({
    required LatLng southwest,
    required LatLng northeast,
    int minZoom = 5,
    int maxZoom = 18,
    Function(int downloaded, int total)? onProgress,
  }) async {
    await _ensureInitialized();

    final region = RectangleRegion(
      LatLngBounds(southwest, northeast),
    );
    
    final downloadable = region.toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(
        urlTemplate: _tileUrl,
        userAgentPackageName: _userAgent,
      ),
    );

    return _downloadRegion(downloadable, onProgress);
  }

  /// Scarica i tile per un'area circolare centrata su un punto
  /// 
  /// [center] - Centro dell'area da scaricare
  /// [radiusKm] - Raggio in km (default: 5 km)
  /// [minZoom] - Livello di zoom minimo
  /// [maxZoom] - Livello di zoom massimo
  /// [onProgress] - Callback per il progresso
  Future<DownloadResult> downloadCircularArea({
    required LatLng center,
    double radiusKm = 5.0,
    int minZoom = 5,
    int maxZoom = 18,
    Function(int downloaded, int total)? onProgress,
  }) async {
    await _ensureInitialized();

    final region = CircleRegion(center, radiusKm * 1000); // metri

    final downloadable = region.toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(
        urlTemplate: _tileUrl,
        userAgentPackageName: _userAgent,
      ),
    );

    return _downloadRegion(downloadable, onProgress);
  }

  /// Ottiene le statistiche dello storage dei tile
  Future<TileStorageStats> getStorageStats() async {
    await _ensureInitialized();

    final stats = await _store.stats.length;
    final size = await _store.stats.size;

    return TileStorageStats(
      tileCount: stats,
      sizeInMB: size / (1024 * 1024),
    );
  }

  /// Cancella tutti i tile scaricati
  Future<void> clearAllTiles() async {
    await _ensureInitialized();
    await _store.manage.reset();
  }

  /// Ottiene il tile provider da usare nella mappa
  /// 
  /// Usa i tile offline se disponibili, altrimenti scarica da internet
  FMTCTileProvider getTileProvider() {
    if (!_isInitialized) {
      throw StateError('OfflineTileService non inizializzato. Chiama initialize() prima.');
    }
    return _store.getTileProvider();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Metodo privato per scaricare tile da una regione downloadable
  /// Elimina duplicazione di codice tra downloadAreaTiles e downloadCircularArea
  Future<DownloadResult> _downloadRegion(
    DownloadableRegion region,
    Function(int downloaded, int total)? onProgress,
  ) async {
    int downloadedTiles = 0;
    int totalTiles = 0;

    try {
      await for (final progress
          in _store.download.startForeground(region: region)) {
        downloadedTiles = progress.successfulTiles;
        totalTiles = progress.maxTiles;
        onProgress?.call(downloadedTiles, totalTiles);
      }
    } catch (e) {
      // Ignora errori di download singoli
    }

    return DownloadResult(
      downloaded: downloadedTiles,
      total: totalTiles,
      success: true,
    );
  }
}

/// Risultato di un'operazione di download
class DownloadResult {
  final int downloaded;
  final int total;
  final bool success;

  DownloadResult({
    required this.downloaded,
    required this.total,
    required this.success,
  });

  double get progress => total > 0 ? downloaded / total : 0.0;
  bool get isComplete => downloaded == total;
}

/// Statistiche dello storage dei tile
class TileStorageStats {
  final int tileCount;
  final double sizeInMB;

  TileStorageStats({
    required this.tileCount,
    required this.sizeInMB,
  });

  String get formattedSize {
    if (sizeInMB < 1) {
      return '${(sizeInMB * 1024).toStringAsFixed(1)} KB';
    } else if (sizeInMB < 1024) {
      return '${sizeInMB.toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInMB / 1024).toStringAsFixed(2)} GB';
    }
  }
}

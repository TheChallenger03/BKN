import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/themes/app_theme.dart';
import '../services/offline_tile_service.dart';

/// Provider per il servizio offline tile
final offlineTileServiceProvider = Provider<OfflineTileService>((ref) {
  final service = OfflineTileService();
  service.initialize();
  return service;
});

/// Dialog per scaricare i tile di un'area specifica
class DownloadTilesDialog extends ConsumerStatefulWidget {
  final LatLng center;

  const DownloadTilesDialog({
    super.key,
    required this.center,
  });

  @override
  ConsumerState<DownloadTilesDialog> createState() =>
      _DownloadTilesDialogState();
}

class _DownloadTilesDialogState extends ConsumerState<DownloadTilesDialog> {
  double _radiusKm = 5.0;
  int _maxZoom = 16;
  bool _isDownloading = false;
  int _downloadedTiles = 0;
  int _totalTiles = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.download,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Scarica Mappe Offline',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (!_isDownloading)
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_isDownloading) ...[
                    // Progress bar
                    _buildDownloadProgress(),
                  ] else ...[
                    // Configuration
                    _buildConfiguration(),
                    const SizedBox(height: 24),
                    _buildEstimation(),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.7),
                          ),
                          child: const Text('Annulla'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _startDownload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Scarica',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Raggio Area',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _radiusKm,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                label: '${_radiusKm.toStringAsFixed(1)} km',
                activeColor: AppTheme.primaryTeal,
                onChanged: (value) {
                  setState(() => _radiusKm = value);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_radiusKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Dettaglio Mappa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _maxZoom.toDouble(),
                min: 12.0,
                max: 18.0,
                divisions: 6,
                label: 'Zoom $_maxZoom',
                activeColor: AppTheme.primaryTeal,
                onChanged: (value) {
                  setState(() => _maxZoom = value.toInt());
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getZoomLabel(_maxZoom),
                style: const TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstimation() {
    final estimatedTiles = _estimateTileCount();
    final estimatedSizeMB = estimatedTiles * 0.05; // ~50KB per tile

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Stima Download',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.grid_on,
            'Tile stimati',
            '~$estimatedTiles',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.storage,
            'Dimensione',
            '~${estimatedSizeMB.toStringAsFixed(1)} MB',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    final progress = _totalTiles > 0 ? _downloadedTiles / _totalTiles : 0.0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
          minHeight: 8,
        ),
        const SizedBox(height: 16),
        Text(
          'Scaricamento in corso...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_downloadedTiles / $_totalTiles tile (${(progress * 100).toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  String _getZoomLabel(int zoom) {
    if (zoom <= 13) return 'Basso';
    if (zoom <= 15) return 'Medio';
    if (zoom <= 17) return 'Alto';
    return 'Massimo';
  }

  int _estimateTileCount() {
    // Stima approssimativa basata su raggio e zoom
    final area = 3.14159 * _radiusKm * _radiusKm;
    final factor = _maxZoom <= 13 ? 50 : _maxZoom <= 15 ? 200 : _maxZoom <= 17 ? 800 : 3200;
    return (area * factor).toInt();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadedTiles = 0;
      _totalTiles = 0;
    });

    try {
      final service = ref.read(offlineTileServiceProvider);
      
      await service.downloadCircularArea(
        center: widget.center,
        radiusKm: _radiusKm,
        minZoom: 5,
        maxZoom: _maxZoom,
        onProgress: (downloaded, total) {
          if (mounted) {
            setState(() {
              _downloadedTiles = downloaded;
              _totalTiles = total;
            });
          }
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scaricati $_downloadedTiles tile!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

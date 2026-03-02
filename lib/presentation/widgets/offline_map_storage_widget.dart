import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../services/offline_tile_service.dart';
import 'download_tiles_dialog.dart';

/// Widget per gestire lo storage dei tile offline
class OfflineMapStorageWidget extends ConsumerStatefulWidget {
  const OfflineMapStorageWidget({super.key});

  @override
  ConsumerState<OfflineMapStorageWidget> createState() =>
      _OfflineMapStorageWidgetState();
}

class _OfflineMapStorageWidgetState
    extends ConsumerState<OfflineMapStorageWidget> {
  TileStorageStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(offlineTileServiceProvider);
      final stats = await service.getStorageStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                          Icons.storage,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Mappe Offline',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryTeal,
                      ),
                    )
                  else ...[
                    // Stats
                    _buildStatsCard(),
                    const SizedBox(height: 24),

                  //   Actions
                    _buildActionButton(
                      icon: Icons.refresh,
                      label: 'Aggiorna Statistiche',
                      onPressed: _loadStats,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.delete_sweep,
                      label: 'Cancella Tutte le Mappe',
                      isDestructive: true,
                      onPressed: _confirmClearAll,
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

  Widget _buildStatsCard() {
    if (_stats == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Text(
            'Nessuna mappa offline',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

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
        children: [
          _buildStatRow(
            Icons.grid_on,
            'Tile Salvati',
            '${_stats!.tileCount}',
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          _buildStatRow(
            Icons.storage,
            'Spazio Utilizzato',
            _stats!.formattedSize,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryTeal,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive
              ? Colors.red.shade600
              : Colors.white.withValues(alpha: 0.1),
          foregroundColor: isDestructive ? Colors.white : AppTheme.primaryTeal,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancellare tutte le mappe?'),
        content: const Text(
          'Questa azione eliminerà tutti i tile scaricati. '
          'Dovrai scaricarli nuovamente per usare le mappe offline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final service = ref.read(offlineTileServiceProvider);
        await service.clearAllTiles();
        await _loadStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mappe offline cancellate'),
              backgroundColor: AppTheme.primaryTeal,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
}

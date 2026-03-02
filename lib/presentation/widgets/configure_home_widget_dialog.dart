import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/saved_location.dart';
import '../providers/location_provider.dart';
import '../services/home_widget_service.dart';

/// Dialog per configurare il widget Android della home screen
class ConfigureHomeWidgetDialog extends ConsumerStatefulWidget {
  const ConfigureHomeWidgetDialog({super.key});

  @override
  ConsumerState<ConfigureHomeWidgetDialog> createState() =>
      _ConfigureHomeWidgetDialogState();
}

class _ConfigureHomeWidgetDialogState
    extends ConsumerState<ConfigureHomeWidgetDialog> {
  int? _currentWidgetLocationId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentWidget();
  }

  Future<void> _loadCurrentWidget() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(homeWidgetServiceProvider);
      final id = await service.getWidgetLocationId();
      if (mounted) {
        setState(() {
          _currentWidgetLocationId = id;
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
    final locationsAsync = ref.watch(locationsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.widgets,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Widget Home Screen',
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
                ),

                // Info banner (solo Android)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Disponibile solo su Android. Aggiungi un widget alla home per accesso rapido alle location.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lista locations
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryTeal,
                          ),
                        )
                      : locationsAsync.when(
                          data: (locations) => _buildLocationsList(locations),
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          error: (error, _) => Center(
                            child: Text(
                              'Errore: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                ),

                // Clear button
                if (_currentWidgetLocationId != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _clearWidget,
                        icon: const Icon(Icons.clear, size: 20),
                        label: const Text('Rimuovi Widget'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationsList(List<SavedLocation> locations) {
    if (locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna location salvata',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        final isSelected = location.id == _currentWidgetLocationId;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryTeal.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryTeal
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: location.isPinned
                    ? AppTheme.primaryGradient
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSelected ? Icons.widgets : Icons.location_on,
                color: isSelected
                    ? Colors.black
                    : location.isPinned
                        ? Colors.black
                        : AppTheme.primaryTeal,
                size: 24,
              ),
            ),
            title: Text(
              location.label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            trailing: isSelected
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ATTIVO',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () => _setWidget(location),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.primaryTeal,
                  ),
            onTap: isSelected ? null : () => _setWidget(location),
          ),
        );
      },
    );
  }

  Future<void> _setWidget(SavedLocation location) async {
    try {
      final service = ref.read(homeWidgetServiceProvider);
      final success = await service.setWidgetLocation(location);

      if (success && mounted) {
        setState(() => _currentWidgetLocationId = location.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Widget aggiornato: ${location.label}'),
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

  Future<void> _clearWidget() async {
    try {
      final service = ref.read(homeWidgetServiceProvider);
      final success = await service.clearWidget();

      if (success && mounted) {
        setState(() => _currentWidgetLocationId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Widget rimosso'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/saved_location.dart';
import '../../core/utils/link_utils.dart';
import '../providers/location_provider.dart';
import '../providers/deep_link_provider.dart';
import '../widgets/save_location_dialog.dart';
import '../widgets/edit_location_dialog.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/import_location_dialog.dart';
import '../screens/map_navigation_screen.dart';
import '../../core/themes/app_theme.dart';

/// Controller che gestisce la logica business della schermata lista location
/// 
/// Separa la logica di orchestrazione dal rendering UI,
/// rispettando il Single Responsibility Principle.
class LocationScreenController {
  final WidgetRef ref;
  final BuildContext context;

  LocationScreenController({
    required this.ref,
    required this.context,
  });

  /// Verifica e gestisce eventuali location da importare via deep link
  void checkPendingDeepLink() {
    final pendingLocation = ref.read(pendingLocationProvider);
    if (pendingLocation != null) {
      showImportDialog(pendingLocation);
    }
  }

  /// Mostra il dialog per importare una location da deep link
  Future<void> showImportDialog(LocationLinkData locationData) async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => ImportLocationDialog(locationData: locationData),
    );

    if (shouldSave == true && context.mounted) {
      final notifier = ref.read(locationsProvider.notifier);
      await notifier.saveLocation(locationData.toSavedLocation().label);
    }

    ref.read(deepLinkProvider.notifier).clearLink();
  }

  /// Mostra il dialog per salvare una nuova location
  Future<void> saveNewLocation() async {
    final label = await showDialog<String>(
      context: context,
      builder: (context) => const SaveLocationDialog(),
    );

    if (label != null && context.mounted) {
      // Mostra dialog di caricamento
      _showLoadingDialog();

      final notifier = ref.read(locationsProvider.notifier);
      await notifier.saveLocation(label);

      // Chiudi il dialog di caricamento
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Mostra il dialog per modificare l'etichetta di una location
  Future<void> editLocationLabel(SavedLocation location) async {
    final newLabel = await showDialog<String>(
      context: context,
      builder: (context) => EditLocationDialog(location: location),
    );

    if (newLabel != null && newLabel != location.label && context.mounted) {
      await ref.read(locationsProvider.notifier).updateLabel(
        location.id!,
        newLabel,
      );
    }
  }

  /// Mostra il dialog di conferma per eliminare una location
  Future<void> deleteLocation(SavedLocation location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        locationLabel: location.label,
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(locationsProvider.notifier).removeLocation(location.id!);
    }
  }

  /// Inverte lo stato di pin di una location
  Future<void> togglePin(int id) async {
    assert(id > 0, 'Location ID must be positive');
    try {
      await ref.read(locationsProvider.notifier).togglePin(id);
    } catch (e) {
      // Errore gestito da Riverpod AsyncValue
    }
  }

  /// Naviga alla schermata mappa per la location specificata
  void navigateToMap(SavedLocation location) {
    assert(location.id != null, 'Location must have an ID');
    
    if (!context.mounted) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapNavigationScreen(
          key: ValueKey('map_${location.id}_${DateTime.now().millisecondsSinceEpoch}'),
          destination: location,
        ),
      ),
    );
  }

  /// Condivide una location tramite il sistema di condivisione
  Future<void> shareLocation(SavedLocation location) async {
    try {
      final message = LinkUtils.generateShareMessage(location);
      await Share.share(
        message,
        subject: 'Posizione: ${location.label}',
      );
    } catch (e) {
      // Errore nella condivisione (es. utente annulla) - ignora silenziosamente
    }
  }

  /// Mostra un dialog di caricamento generico
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Salvataggio posizione...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../domain/entities/saved_location.dart';

/// Service per gestire il widget Android della home screen.
/// 
/// Rispetta Single Responsibility: gestisce SOLO l'aggiornamento del widget.
class HomeWidgetService {
  static const String _widgetName = 'BKNLocationWidget';
  static const String _keyLocationLabel = 'location_label';
  static const String _keyLocationLat = 'location_lat';
  static const String _keyLocationLng = 'location_lng';
  static const String _keyLocationId = 'location_id';

  /// Inizializza il servizio home widget
  Future<void> initialize() async {
    // Registra l'app group per condivisione dati
    HomeWidget.setAppGroupId('com.example.location_tracker');
    
    // Note: Background callback gestito nativamente in Android/iOS
    // Il deep link handling è già implementato in deep_link_provider.dart
  }

  /// Imposta la location da mostrare nel widget
  Future<bool> setWidgetLocation(SavedLocation? location) async {
    final data = location == null
        ? <String, String?>{}
        : {
            _keyLocationLabel: location.label,
            _keyLocationLat: location.latitude.toString(),
            _keyLocationLng: location.longitude.toString(),
            _keyLocationId: location.id.toString(),
          };

    // Salva tutti i dati (null per rimuovere)
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData(entry.key, entry.value);
    }
    
    // Se location è null, rimuovi anche le chiavi rimaste
    if (location == null) {
      final keys = [_keyLocationLabel, _keyLocationLat, _keyLocationLng, _keyLocationId];
      for (final key in keys) {
        await HomeWidget.saveWidgetData(key, null);
      }
    }

    // Aggiorna il widget
    final result = await HomeWidget.updateWidget(
      name: _widgetName,
      androidName: _widgetName,
    );
    return result ?? false;
  }

  /// Ottiene l'ID della location attualmente nel widget
  Future<int?> getWidgetLocationId() async {
    final idString = await HomeWidget.getWidgetData(_keyLocationId);
    if (idString == null) return null;
    return int.tryParse(idString);
  }

  /// Rimuove la location dal widget
  Future<bool> clearWidget() async {
    return setWidgetLocation(null);
  }

  // Callback per tap sul widget gestito nativamente tramite PendingIntent
  // Vedi BKNLocationWidget.kt per implementazione Android

  /// Verifica se i widget sono supportati su questa piattaforma
  Future<bool> isWidgetSupported() async {
    try {
      await HomeWidget.getWidgetData(_keyLocationLabel);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider per il servizio home widget
final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  final service = HomeWidgetService();
  service.initialize();
  return service;
});

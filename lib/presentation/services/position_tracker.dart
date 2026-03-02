import 'dart:async';
import 'package:latlong2/latlong.dart';

/// Servizio per il tracking della posizione GPS
/// 
/// Gestisce lo stream della posizione e le logiche di inizializzazione
/// separando questa responsabilità dal state management della mappa.
class PositionTracker {
  StreamSubscription<LatLng>? _positionSubscription;
  final Stream<LatLng> _positionStream;
  final Future<LatLng?> Function() _getLastPosition;
  
  /// Callback chiamato quando la posizione viene aggiornata
  void Function(LatLng position)? onPositionUpdate;
  
  /// Callback chiamato in caso di errore nello stream
  void Function(Object error)? onError;

  PositionTracker({
    required Stream<LatLng> positionStream,
    required Future<LatLng?> Function() getLastPosition,
  })  : _positionStream = positionStream,
        _getLastPosition = getLastPosition;

  /// Avvia l'ascolto dello stream di posizione
  void startListening() {
    _positionSubscription?.cancel();
    
    _positionSubscription = _positionStream.listen(
      (position) {
        if (onPositionUpdate != null) {
          onPositionUpdate!(position);
        }
      },
      onError: (error) {
        if (onError != null) {
          onError!(error);
        }
      },
    );
  }

  /// Ottiene l'ultima posizione conosciuta
  /// 
  /// Utile per l'inizializzazione prima che lo stream emetta il primo valore
  Future<LatLng?> getLastKnownPosition() async {
    return await _getLastPosition();
  }

  /// Ferma l'ascolto e libera le risorse
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Indica se il tracker è attualmente in ascolto
  bool get isListening => _positionSubscription != null;
}

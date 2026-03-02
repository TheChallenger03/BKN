import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Configurazione e gestione della connessione al database Drift
class DatabaseConnection {
  /// Nome del file del database
  static const String _databaseName = 'bkn_drift.db';
  
  /// Flag per abilitare/disabilitare il logging delle query SQL
  static const bool _enableLogging = true;
  
  /// Crea una connessione lazy al database
  /// 
  /// La connessione viene inizializzata solo quando viene effettivamente utilizzata.
  /// Il database viene salvato nella directory dei documenti dell'applicazione.
  static LazyDatabase createConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, _databaseName));
      return NativeDatabase(file, logStatements: _enableLogging);
    });
  }
  
  /// Ottiene il percorso completo del file del database
  static Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, _databaseName);
  }
  
  /// Elimina il database (utile per testing o reset)
  static Future<void> deleteDatabase() async {
    final path = await getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// Verifica se il database esiste
  static Future<bool> databaseExists() async {
    final path = await getDatabasePath();
    return await File(path).exists();
  }
}

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Servizio per la gestione dello storage delle foto delle location.
/// Rispetta Single Responsibility Principle: gestisce SOLO il salvataggio/eliminazione foto.
class PhotoStorageService {
  final ImagePicker _picker = ImagePicker();

  /// Directory dove saranno salvate le foto
  Future<Directory> get _photoDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(path.join(appDir.path, 'location_photos'));

    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    return photoDir;
  }

  /// Apre la galleria per scegliere una foto
  /// Ritorna il path della foto salvata, o null se l'utente annulla
  Future<String?> pickPhotoFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return await _savePhoto(File(pickedFile.path));
    } catch (e) {
      return null;
    }
  }

  /// Apre la fotocamera per scattare una foto
  /// Ritorna il path della foto salvata, o null se l'utente annulla
  Future<String?> takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return await _savePhoto(File(pickedFile.path));
    } catch (e) {
      return null;
    }
  }

  /// Salva una foto nella directory dell'app con nome univoco
  Future<String> _savePhoto(File photoFile) async {
    final photoDir = await _photoDirectory;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = path.join(photoDir.path, fileName);

    await photoFile.copy(savedPath);

    return savedPath;
  }

  /// Elimina una foto dato il suo path
  /// Ritorna true se eliminata con successo, false se errore o file non esiste
  Future<bool> deletePhoto(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return false;

    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se una foto esiste
  Future<bool> photoExists(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return false;

    try {
      final file = File(photoPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il File di una foto
  File? getPhotoFile(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return null;
    return File(photoPath);
  }

  /// Pulisce tutte le foto orfane (non più referenziate da location)
  /// Utile per manutenzione storage
  Future<int> cleanOrphanedPhotos(Set<String> referencedPaths) async {
    try {
      final photoDir = await _photoDirectory;
      final files = photoDir.listSync();
      int deletedCount = 0;

      for (final file in files) {
        if (file is File) {
          final filePath = file.path;
          if (!referencedPaths.contains(filePath)) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      return 0;
    }
  }
}

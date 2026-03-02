import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/saved_location.dart';
import '../providers/category_provider.dart';
import '../providers/location_provider.dart';

/// Widget per mostrare la foto di una location con opzioni di gestione.
/// Rispetta Single Responsibility: SOLO display + azioni foto.
class LocationPhotoWidget extends ConsumerWidget {
  final SavedLocation location;
  final VoidCallback? onPhotoTap;
  final bool showActions;

  const LocationPhotoWidget({
    super.key,
    required this.location,
    this.onPhotoTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoPath = location.photoPath;

    if (photoPath == null || photoPath.isEmpty) {
      return _buildPlaceholder(context, ref);
    }

    return _buildPhotoDisplay(context, ref, photoPath);
  }

  Widget _buildPlaceholder(BuildContext context, WidgetRef ref) {
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Nessuna foto',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (showActions) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showPhotoPickerDialog(context, ref),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Aggiungi foto'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoDisplay(BuildContext context, WidgetRef ref, String photoPath) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onPhotoTap ?? () => _showFullScreenPhoto(context, photoPath),
          child: Hero(
            tag: 'photo_${location.id}',
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(photoPath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        if (showActions)
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  onPressed: () => _showPhotoPickerDialog(context, ref),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.delete,
                  onPressed: () => _confirmDeletePhoto(context, ref),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _showPhotoPickerDialog(BuildContext context, WidgetRef ref) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scegli foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Scatta foto'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Dalla galleria'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    final photoService = ref.read(photoStorageServiceProvider);
    String? newPhotoPath;

    if (choice == 'camera') {
      newPhotoPath = await photoService.takePhoto();
    } else if (choice == 'gallery') {
      newPhotoPath = await photoService.pickPhotoFromGallery();
    }

    if (newPhotoPath != null && context.mounted) {
      final updatePhoto = ref.read(updateLocationPhotoProvider);
      final result = await updatePhoto(location.id!, newPhotoPath);

      result.fold(
        (failure) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Errore: ${failure.message}')),
            );
          }
        },
        (_) {
          // Ricarica locations per mostrare la nuova foto
          ref.read(locationsProvider.notifier).loadLocations();
        },
      );
    }
  }

  Future<void> _confirmDeletePhoto(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina foto'),
        content: const Text('Vuoi eliminare questa foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final photoService = ref.read(photoStorageServiceProvider);
    await photoService.deletePhoto(location.photoPath);

    final updatePhoto = ref.read(updateLocationPhotoProvider);
    final result = await updatePhoto(location.id!, null);

    result.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: ${failure.message}')),
          );
        }
      },
      (_) {
        ref.read(locationsProvider.notifier).loadLocations();
      },
    );
  }

  void _showFullScreenPhoto(BuildContext context, String photoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: Hero(
              tag: 'photo_${location.id}',
              child: InteractiveViewer(
                child: Image.file(File(photoPath)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

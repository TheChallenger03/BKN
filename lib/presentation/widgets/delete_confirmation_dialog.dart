import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String locationLabel;

  const DeleteConfirmationDialog({
    super.key,
    required this.locationLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Elimina Posizione'),
      content: Text(
        'Sei sicuro di voler eliminare "$locationLabel"?\n'
        'Questa azione non può essere annullata.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Elimina'),
        ),
      ],
    );
  }
}
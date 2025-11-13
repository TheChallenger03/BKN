import 'package:flutter/material.dart';
import '../../core/utils/link_utils.dart';

class ImportLocationDialog extends StatelessWidget {
  final LocationLinkData locationData;
  
  const ImportLocationDialog({
    super.key,
    required this.locationData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Posizione Ricevuta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vuoi salvare questa posizione ricevuta?',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.label,
            'Etichetta',
            locationData.label,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            Icons.location_on,
            'Coordinate',
            '${locationData.latitude.toStringAsFixed(6)}, '
                '${locationData.longitude.toStringAsFixed(6)}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Ignora'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.save),
          label: const Text('Salva'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
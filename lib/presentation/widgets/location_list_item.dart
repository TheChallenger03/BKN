import 'package:flutter/material.dart';
import '../../domain/entities/saved_location.dart';

class LocationListItem extends StatelessWidget {
  final SavedLocation location;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onShare;

  const LocationListItem({
    super.key,
    required this.location,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: location.isPinned ? 2 : 1,
      color: location.isPinned
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: location.isPinned
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          child: Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Text(
          location.label,
          style: TextStyle(
            fontWeight: location.isPinned ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${location.latitude.toStringAsFixed(6)}, '
          '${location.longitude.toStringAsFixed(6)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                location.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: location.isPinned 
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              tooltip: location.isPinned ? 'Rimuovi pin' : 'Fissa in alto',
              onPressed: onTogglePin,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Condividi',
              onPressed: onShare,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifica etichetta',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Elimina',
              color: Colors.red,
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
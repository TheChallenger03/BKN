import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/location_provider.dart';
import '../providers/deep_link_provider.dart';
import '../widgets/location_list_item.dart';
import '../widgets/save_location_dialog.dart';
import '../widgets/edit_label_dialog.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/import_location_dialog.dart';
import '../widgets/glowing_fab.dart';
import '../../core/themes/app_theme.dart';
import '../../core/utils/link_utils.dart';
import 'map_navigation_screen.dart';

class LocationsListScreen extends ConsumerStatefulWidget {
  const LocationsListScreen({super.key});

  @override
  ConsumerState<LocationsListScreen> createState() => _LocationsListScreenState();
}

class _LocationsListScreenState extends ConsumerState<LocationsListScreen> {
  @override
  void initState() {
    super.initState();
    // Check for pending deep link after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingLocation();
    });
  }

  void _checkPendingLocation() {
    final pendingLocation = ref.read(pendingLocationProvider);
    if (pendingLocation != null) {
      _showImportDialog(pendingLocation);
    }
  }

  Future<void> _showImportDialog(LocationLinkData locationData) async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => ImportLocationDialog(locationData: locationData),
    );

    if (shouldSave == true && mounted) {
      final notifier = ref.read(locationsProvider.notifier);
      final location = locationData.toSavedLocation();
      
      // Save the location
      await notifier.saveLocation(location.label);
    }

    // Clear the pending link
    ref.read(deepLinkProvider.notifier).clearLink();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);

    // Listen for new deep links
    ref.listen(pendingLocationProvider, (previous, next) {
      if (next != null && previous != next) {
        _showImportDialog(next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('BKN'),
        centerTitle: true,
      ),
      body: locationsAsync.when(
        data: (locations) {
          if (locations.isEmpty) {
            return _buildEmptyState(context);
          }

          // Check if there are pinned and unpinned locations
          final hasPinned = locations.any((loc) => loc.isPinned);
          final hasUnpinned = locations.any((loc) => !loc.isPinned);
          final showDivider = hasPinned && hasUnpinned;

          // Find index where unpinned locations start
          int? dividerIndex;
          if (showDivider) {
            dividerIndex = locations.indexWhere((loc) => !loc.isPinned);
          }

          return ListView.builder(
            itemCount: locations.length + (showDivider ? 1 : 0),
            itemBuilder: (context, index) {
              // Insert divider between pinned and unpinned
              if (showDivider && index == dividerIndex) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(thickness: 2),
                );
              }

              // Adjust index if divider was inserted
              final locationIndex = showDivider && index > dividerIndex! 
                  ? index - 1 
                  : index;
              final location = locations[locationIndex];

              return LocationListItem(
                location: location,
                onTap: () => _navigateToMap(context, location),
                onTogglePin: () => _togglePin(ref, location.id!),
                onEdit: () => _editLabel(context, ref, location),
                onDelete: () => _deleteLocation(context, ref, location),
                onShare: () => _shareLocation(location),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Errore: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(locationsProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: GlowingFab(
        onPressed: () => _saveNewLocation(context, ref),
        icon: Icons.add_location,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryTeal.withValues(alpha: 0.1),
                  AppTheme.secondaryTeal.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.location_off,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Nessuna posizione salvata',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tocca il pulsante in basso per salvare\nla tua posizione attuale',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNewLocation(BuildContext context, WidgetRef ref) async {
    final label = await showDialog<String>(
      context: context,
      builder: (context) => const SaveLocationDialog(),
    );

    if (label != null && context.mounted) {
      final notifier = ref.read(locationsProvider.notifier);
      await notifier.saveLocation(label);
    }
  }

  Future<void> _editLabel(
    BuildContext context,
    WidgetRef ref,
    location,
  ) async {
    final newLabel = await showDialog<String>(
      context: context,
      builder: (context) => EditLabelDialog(currentLabel: location.label),
    );

    if (newLabel != null && newLabel != location.label && context.mounted) {
      final notifier = ref.read(locationsProvider.notifier);
      await notifier.updateLabel(location.id!, newLabel);
    }
  }

  Future<void> _deleteLocation(
    BuildContext context,
    WidgetRef ref,
    location,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        locationLabel: location.label,
      ),
    );

    if (confirm == true && context.mounted) {
      final notifier = ref.read(locationsProvider.notifier);
      await notifier.removeLocation(location.id!);
    }
  }

  Future<void> _togglePin(WidgetRef ref, int id) async {
    final notifier = ref.read(locationsProvider.notifier);
    await notifier.togglePin(id);
  }

  void _navigateToMap(BuildContext context, location) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapNavigationScreen(destination: location),
      ),
    );
  }

  Future<void> _shareLocation(location) async {
    final message = LinkUtils.generateShareMessage(location);
    await Share.share(
      message,
      subject: 'Posizione: ${location.label}',
    );
  }
}
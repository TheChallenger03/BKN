import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';
import '../providers/category_provider.dart';
import '../providers/deep_link_provider.dart';
import '../widgets/location_list_item.dart';
import '../widgets/location_search_bar.dart';
import '../widgets/glowing_fab.dart';
import '../widgets/configure_home_widget_dialog.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/saved_location.dart';
import '../controllers/location_screen_controller.dart';

class LocationsListScreen extends ConsumerStatefulWidget {
  const LocationsListScreen({super.key});

  @override
  ConsumerState<LocationsListScreen> createState() => _LocationsListScreenState();
}

class _LocationsListScreenState extends ConsumerState<LocationsListScreen> {
  /// Crea un controller quando necessario (lazy creation)
  LocationScreenController _createController() => 
    LocationScreenController(ref: ref, context: context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingLocation();
    });
  }

  void _checkPendingLocation() {
    _createController().checkPendingDeepLink();
  }

  @override
  Widget build(BuildContext context) {
    // Usa filteredLocationsProvider invece di locationsProvider
    final locationsAsync = ref.watch(filteredLocationsProvider);

    ref.listen(pendingLocationProvider, (previous, next) {
      if (next != null && previous != next) {
        _createController().showImportDialog(next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('BKN'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.widgets),
            tooltip: 'Configura Widget',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ConfigureHomeWidgetDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Aggiungi search bar con filtri
          const LocationSearchBar(),
          // Lista locations filtrate
          Expanded(
            child: locationsAsync.when(
              data: (locations) => _buildLocationsList(locations),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: _buildErrorState,
            ),
          ),
        ],
      ),
      floatingActionButton: GlowingFab(
        onPressed: () => _createController().saveNewLocation(),
        icon: Icons.add_location,
      ),
    );
  }

  Widget _buildLocationsList(List<SavedLocation> locations) {
    if (locations.isEmpty) return _buildEmptyState();

    final hasPinned = locations.any((loc) => loc.isPinned);
    final hasUnpinned = locations.any((loc) => !loc.isPinned);
    final showDivider = hasPinned && hasUnpinned;
    final dividerIndex = showDivider ? locations.indexWhere((loc) => !loc.isPinned) : null;

    return ListView.builder(
      itemCount: locations.length + (showDivider ? 1 : 0),
      itemBuilder: (context, index) => _buildListItem(locations, index, dividerIndex),
    );
  }

  Widget _buildListItem(List<SavedLocation> locations, int index, int? dividerIndex) {
    if (dividerIndex != null && index == dividerIndex) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(thickness: 2),
      );
    }

    final locationIndex = (dividerIndex != null && index > dividerIndex) ? index - 1 : index;  
    final location = locations[locationIndex];

    return LocationListItem(
      location: location,
      onTap: () => _createController().navigateToMap(location),
      onTogglePin: () => _createController().togglePin(location.id!),
      onEdit: () => _createController().editLocationLabel(location),
      onDelete: () => _createController().deleteLocation(location),
      onShare: () => _createController().shareLocation(location),
    );
  }

  Widget _buildErrorState(Object error, StackTrace stack) {
    return Center(
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
    );
  }

  Widget _buildEmptyState() {
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
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/assign_category_to_location.dart';
import '../../domain/usecases/update_location_photo.dart';
import '../services/photo_storage_service.dart';
import '../services/location_filter_service.dart';
import 'location_provider.dart';

// ============================================================
// PHOTO STORAGE SERVICE PROVIDER
// ============================================================

final photoStorageServiceProvider = Provider<PhotoStorageService>((ref) {
  return PhotoStorageService();
});

// ============================================================
// LOCATION FILTER SERVICE PROVIDER
// ============================================================

final locationFilterServiceProvider = Provider<LocationFilterService>((ref) {
  return LocationFilterService();
});

// ============================================================
// CATEGORIES USE CASES PROVIDERS
// ============================================================

final getCategoriesProvider = Provider<GetCategories>((ref) {
  return GetCategories(ref.read(locationRepositoryProvider));
});

final assignCategoryToLocationProvider = Provider<AssignCategoryToLocation>((ref) {
  return AssignCategoryToLocation(ref.read(locationRepositoryProvider));
});

final updateLocationPhotoProvider = Provider<UpdateLocationPhoto>((ref) {
  return UpdateLocationPhoto(ref.read(locationRepositoryProvider));
});

// ============================================================
// CATEGORIES STATE PROVIDER
// ============================================================

/// Provider per la lista di categorie disponibili
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final getCategories = ref.read(getCategoriesProvider);
  final result = await getCategories();
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});

// ============================================================
// FILTER STATE PROVIDERS
// ============================================================

/// Provider per il testo di ricerca/filtro
final searchTextProvider = StateProvider<String>((ref) => '');

/// Provider per la categoria selezionata nel filtro (null = tutte)
final selectedCategoryFilterProvider = StateProvider<int?>((ref) => null);

/// Provider per il filtro "solo con foto"
final onlyWithPhotosFilterProvider = StateProvider<bool>((ref) => false);

/// Provider per il filtro "solo pinnate"
final onlyPinnedFilterProvider = StateProvider<bool?>((ref) => null);

/// Provider che applica tutti i filtri alla lista di location
final filteredLocationsProvider = Provider((ref) {
  final locationsAsync = ref.watch(locationsProvider);
  final searchText = ref.watch(searchTextProvider);
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);
  final onlyWithPhotos = ref.watch(onlyWithPhotosFilterProvider);
  final onlyPinned = ref.watch(onlyPinnedFilterProvider);
  final filterService = ref.watch(locationFilterServiceProvider);

  return locationsAsync.when(
    data: (locations) {
      final filtered = filterService.applyFilters(
        locations,
        searchText: searchText.isEmpty ? null : searchText,
        categoryId: selectedCategory,
        onlyWithPhotos: onlyWithPhotos,
        onlyPinned: onlyPinned,
      );
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider per contare quanti filtri sono attivi
final activeFiltersCountProvider = Provider<int>((ref) {
  int count = 0;
  
  if (ref.watch(searchTextProvider).isNotEmpty) count++;
  if (ref.watch(selectedCategoryFilterProvider) != null) count++;
  if (ref.watch(onlyWithPhotosFilterProvider)) count++;
  if (ref.watch(onlyPinnedFilterProvider) != null) count++;
  
  return count;
});

/// Provider per resettare tutti i filtri
final resetFiltersProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(searchTextProvider.notifier).state = '';
    ref.read(selectedCategoryFilterProvider.notifier).state = null;
    ref.read(onlyWithPhotosFilterProvider.notifier).state = false;
    ref.read(onlyPinnedFilterProvider.notifier).state = null;
  };
});

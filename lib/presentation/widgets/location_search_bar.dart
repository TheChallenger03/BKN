import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';

/// Widget per la barra di ricerca con filtri.
/// Rispetta Single Responsibility: SOLO UI per search e filtri.
class LocationSearchBar extends ConsumerWidget {
  const LocationSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchText = ref.watch(searchTextProvider);
    final activeFiltersCount = ref.watch(activeFiltersCountProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      ref.read(searchTextProvider.notifier).state = value;
                    },
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cerca locations...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (searchText.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      ref.read(searchTextProvider.notifier).state = '';
                    },
                    icon: const Icon(Icons.clear),
                    color: Colors.white.withValues(alpha: 0.7),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () => _showFilterSheet(context, ref),
                      icon: const Icon(Icons.tune),
                      color: activeFiltersCount > 0
                          ? AppTheme.primaryTeal
                          : Colors.white.withValues(alpha: 0.7),
                      iconSize: 24,
                    ),
                    if (activeFiltersCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1A1A2E),
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '$activeFiltersCount',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const FilterBottomSheet(),
    );
  }
}

/// Bottom sheet per configurare i filtri avanzati.
class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final onlyWithPhotos = ref.watch(onlyWithPhotosFilterProvider);
    final onlyPinned = ref.watch(onlyPinnedFilterProvider);
    final activeFiltersCount = ref.watch(activeFiltersCountProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E).withValues(alpha: 0.95),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Filtri',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (activeFiltersCount > 0)
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Reset'),
                        onPressed: () {
                          ref.read(resetFiltersProvider)();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryTeal,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 20),

                // Filtro per categoria
                Text(
                  'Categoria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  data: (categories) =>
                      _buildCategoryFilter(ref, categories, selectedCategory),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(
                    'Errore: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 20),

                // Filtro per foto
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: SwitchListTile(
                    title: Row(
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Solo con foto',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    value: onlyWithPhotos,
                    onChanged: (value) {
                      ref.read(onlyWithPhotosFilterProvider.notifier).state = value;
                    },
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryTeal;
                      }
                      return null;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryTeal.withValues(alpha: 0.5);
                      }
                      return null;
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // Filtro per pinnate
                Text(
                  'Stato pin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment(
                      value: null,
                      label: Text('Tutte'),
                      icon: Icon(Icons.all_inclusive, size: 18),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Pinnate'),
                      icon: Icon(Icons.push_pin, size: 18),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Non'),
                      icon: Icon(Icons.push_pin_outlined, size: 18),
                    ),
                  ],
                  selected: {onlyPinned},
                  onSelectionChanged: (Set<bool?> newSelection) {
                    ref.read(onlyPinnedFilterProvider.notifier).state =
                        newSelection.first;
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryTeal;
                      }
                      return Colors.white.withValues(alpha: 0.05);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.black;
                      }
                      return Colors.white.withValues(alpha: 0.7);
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottone Applica
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Applica Filtri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(
    WidgetRef ref,
    List<Category> categories,
    int? selectedCategory,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "Tutte" chip
        FilterChip(
          label: const Text('Tutte'),
          selected: selectedCategory == null,
          onSelected: (selected) {
            if (selected) {
              ref.read(selectedCategoryFilterProvider.notifier).state = null;
            }
          },
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.3),
          checkmarkColor: AppTheme.primaryTeal,
          labelStyle: TextStyle(
            color: selectedCategory == null
                ? AppTheme.primaryTeal
                : Colors.white.withValues(alpha: 0.7),
            fontWeight:
                selectedCategory == null ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: selectedCategory == null
                ? AppTheme.primaryTeal
                : Colors.white.withValues(alpha: 0.2),
            width: selectedCategory == null ? 2 : 1,
          ),
        ),
        // Category chips
        ...categories.map((category) {
          final isSelected = selectedCategory == category.id;
          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              ref.read(selectedCategoryFilterProvider.notifier).state =
                  selected ? category.id : null;
            },
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            selectedColor: category.color,
            checkmarkColor: Colors.black,
            side: BorderSide(
              color: isSelected
                  ? category.color
                  : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          );
        }),
      ],
    );
  }
}

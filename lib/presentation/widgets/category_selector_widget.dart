import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';
import '../providers/location_provider.dart';

/// Widget per mostrare e selezionare la categoria di una location.
/// Rispetta Single Responsibility: SOLO gestione categoria.
class CategorySelectorWidget extends ConsumerWidget {
  final SavedLocation location;
  final bool readOnly;

  const CategorySelectorWidget({
    super.key,
    required this.location,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) => _buildCategoryDisplay(context, ref, categories),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Errore: $error'),
    );
  }

  Widget _buildCategoryDisplay(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    final currentCategory = location.category;

    if (currentCategory == null) {
      return readOnly
          ? const SizedBox.shrink()
          : _buildAddCategoryButton(context, ref, categories);
    }

    return Chip(
      avatar: Text(currentCategory.icon),
      label: Text(currentCategory.name),
      backgroundColor: currentCategory.color.withValues(alpha: 0.2),
      deleteIcon: readOnly ? null : const Icon(Icons.edit, size: 18),
      onDeleted: readOnly ? null : () => _showCategoryPicker(context, ref, categories),
    );
  }

  Widget _buildAddCategoryButton(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _showCategoryPicker(context, ref, categories),
      icon: const Icon(Icons.add),
      label: const Text('Aggiungi categoria'),
    );
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) async {
    final selectedCategory = await showDialog<Category?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona categoria'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (location.category != null)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: const Text('Rimuovi categoria'),
                  onTap: () => Navigator.of(context).pop(null),
                ),
              const Divider(),
              ...categories.map((category) {
                final isSelected = location.category?.id == category.id;
                return ListTile(
                  leading: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(category.name),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  tileColor: isSelected
                      ? category.color.withValues(alpha: 0.1)
                      : null,
                  onTap: () => Navigator.of(context).pop(category),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted) return;

    // Se l'utente ha confermato la selezione (anche null per rimuovere)
    if (selectedCategory != null || location.category != null) {
      final assignCategory = ref.read(assignCategoryToLocationProvider);
      final result = await assignCategory(
        location.id!,
        selectedCategory?.id,
      );

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
  }
}

/// Widget per mostrare solo l'icona della categoria (compatto)
class CategoryIconWidget extends StatelessWidget {
  final Category? category;
  final double size;

  const CategoryIconWidget({
    super.key,
    this.category,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (category == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: category!.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category!.icon,
        style: TextStyle(fontSize: size),
      ),
    );
  }
}

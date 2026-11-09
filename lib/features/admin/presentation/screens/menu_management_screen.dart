import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/app_sizes.dart';
import 'package:sistema_eve/features/admin/data/models/category_model.dart';
import 'package:sistema_eve/features/admin/providers/menu_providers.dart';
import 'package:sistema_eve/features/admin/providers/category_providers.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/menu_item_form_dialog.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/category_management_dialog.dart';
import 'package:sistema_eve/features/waiter/data/models/menu_item_model.dart';

/// Screen para gestionar items del menú
class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar categorías por defecto si no existen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryManagementProvider).initializeDefaultCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuItemsAsync = ref.watch(menuItemsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          // Barra de categorías
          _buildCategoryBar(context, categoriesAsync),

          // Lista de items
          Expanded(
            child: menuItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(context);
                }

                return categoriesAsync.when(
                  data: (categories) => _buildItemsList(items, categories),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    Text('Error: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuItemDialog(context, null),
        backgroundColor: AppColors.adminPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Item'),
      ),
    );
  }

  /// Barra de categorías con botón de gestión
  Widget _buildCategoryBar(
    BuildContext context,
    AsyncValue<List<CategoryModel>> categoriesAsync,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminPrimary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.adminPrimary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.category, color: AppColors.adminPrimary, size: 22),
          const SizedBox(width: 10),
          categoriesAsync.when(
            data: (categories) => Text(
              'Categorías: ${categories.length}',
              style: TextStyle(
                color: AppColors.adminPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            loading: () => const Text('Cargando...'),
            error: (_, _) => const Text('Error'),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showCategoryDialog(context),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Gestionar'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.adminPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(
    List<MenuItemModel> items,
    List<CategoryModel> categories,
  ) {
    // Crear mapa de categorías para lookup rápido
    final categoryMap = {for (var c in categories) c.slug: c};

    // Agrupar por categoría
    final itemsByCategory = <String, List<MenuItemModel>>{};
    for (final item in items) {
      itemsByCategory.putIfAbsent(item.category, () => []).add(item);
    }

    // Ordenar por el orden de las categorías
    final orderedCategories = categories
        .where((c) => itemsByCategory.containsKey(c.slug))
        .toList();

    // Agregar categorías sin definir
    for (final slug in itemsByCategory.keys) {
      if (!categoryMap.containsKey(slug)) {
        orderedCategories.add(
          CategoryModel(
            id: slug,
            name: slug.replaceAll('_', ' ').toUpperCase(),
            slug: slug,
            order: 999,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      itemCount: orderedCategories.length,
      itemBuilder: (context, index) {
        final category = orderedCategories[index];
        final categoryItems = itemsByCategory[category.slug] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
              child: Row(
                children: [
                  if (category.icon != null) ...[
                    Text(category.icon!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.adminPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categoryItems.length}',
                      style: TextStyle(
                        color: AppColors.adminPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...categoryItems.map((item) => _buildMenuItem(context, item)),
            const SizedBox(height: AppSizes.spacing16),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            'No hay items en el menú',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            'Agrega tu primer producto',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: AppSizes.spacing24),
          ElevatedButton.icon(
            onPressed: () => _showMenuItemDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primer Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing24,
                vertical: AppSizes.spacing16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showMenuItemDialog(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador de disponibilidad
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: item.available ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.available ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Precio y tiempo
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.adminPrimary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.adminPrimary,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${item.preparationTime} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (item.ingredients.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${item.ingredients.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Acciones
              Column(
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: item.available,
                      onChanged: (value) {
                        ref
                            .read(menuManagementProvider.notifier)
                            .toggleAvailability(item.id, value);
                      },
                      activeThumbColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showMenuItemDialog(context, item),
                        color: AppColors.info,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _confirmDelete(context, item),
                        color: AppColors.error,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenuItemDialog(BuildContext context, MenuItemModel? item) {
    showDialog(
      context: context,
      builder: (context) => MenuItemFormDialog(menuItem: item),
    );
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CategoryManagementDialog(),
    );
  }

  void _confirmDelete(BuildContext context, MenuItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar "${item.name}" del menú?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(menuManagementProvider.notifier).deleteMenuItem(item.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item eliminado del menú'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

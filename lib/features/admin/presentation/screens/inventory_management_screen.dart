import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/app_sizes.dart';
import 'package:sistema_eve/features/admin/providers/inventory_providers.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/inventory_form_dialog.dart';
import 'package:sistema_eve/features/admin/data/models/inventory_item_model.dart';

/// Screen completa de gestión de inventario
class InventoryManagementScreen extends ConsumerWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemsStreamProvider);

    return Scaffold(
      body: inventoryAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          // Separar por estado de stock
          final criticalItems = items
              .where((i) => i.stockStatus == 'critical')
              .toList();
          final lowItems = items.where((i) => i.stockStatus == 'low').toList();
          final sufficientItems = items
              .where((i) => i.stockStatus == 'sufficient')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            children: [
              // Alertas de stock bajo
              if (criticalItems.isNotEmpty || lowItems.isNotEmpty) ...[
                _buildAlertSection(context, criticalItems, lowItems),
                const SizedBox(height: AppSizes.spacing24),
              ],

              // Lista completa
              if (criticalItems.isNotEmpty) ...[
                _buildSectionHeader('Stock Crítico', AppColors.error),
                ...criticalItems.map(
                  (item) => _buildInventoryItem(context, ref, item),
                ),
                const SizedBox(height: AppSizes.spacing16),
              ],

              if (lowItems.isNotEmpty) ...[
                _buildSectionHeader('Stock Bajo', AppColors.warning),
                ...lowItems.map(
                  (item) => _buildInventoryItem(context, ref, item),
                ),
                const SizedBox(height: AppSizes.spacing16),
              ],

              if (sufficientItems.isNotEmpty) ...[
                _buildSectionHeader('Stock Suficiente', AppColors.success),
                ...sufficientItems.map(
                  (item) => _buildInventoryItem(context, ref, item),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSizes.spacing16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInventoryFormDialog(context, ref, null),
        backgroundColor: AppColors.adminPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Item'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            'No hay items en el inventario',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            'Agrega ingredientes y productos para comenzar',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: AppSizes.spacing24),
          ElevatedButton.icon(
            onPressed: () => _showInventoryFormDialog(context, ref, null),
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

  Widget _buildAlertSection(
    BuildContext context,
    List<InventoryItemModel> critical,
    List<InventoryItemModel> low,
  ) {
    return Card(
      color: critical.isNotEmpty
          ? AppColors.error.withValues(alpha: 0.1)
          : AppColors.warning.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: critical.isNotEmpty
                      ? AppColors.error
                      : AppColors.warning,
                  size: 28,
                ),
                const SizedBox(width: AppSizes.spacing8),
                Text(
                  'Alertas de Inventario',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
            if (critical.isNotEmpty)
              Text(
                '🔴 ${critical.length} item(s) con stock crítico',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (low.isNotEmpty)
              Text(
                '🟡 ${low.length} item(s) con stock bajo',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacing8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItem(
    BuildContext context,
    WidgetRef ref,
    InventoryItemModel item,
  ) {
    final statusColor = item.stockStatus == 'critical'
        ? AppColors.error
        : item.stockStatus == 'low'
        ? AppColors.warning
        : AppColors.success;

    final percentage = (item.currentStock / (item.minStock * 1.5) * 100).clamp(
      0,
      100,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
      child: InkWell(
        onTap: () => _showInventoryFormDialog(context, ref, item),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Indicador de estado
                  CircleAvatar(
                    backgroundColor: statusColor,
                    radius: 20,
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacing12),
                  // Info principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock: ${item.currentStock.toStringAsFixed(1)} ${item.unit} • Mínimo: ${item.minStock.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (item.supplier != null)
                          Text(
                            'Proveedor: ${item.supplier}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Costo y acciones
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${item.costPerUnit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'por unidad',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () =>
                                _showInventoryFormDialog(context, ref, item),
                            color: AppColors.info,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _confirmDelete(context, ref, item),
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
              const SizedBox(height: AppSizes.spacing8),
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInventoryFormDialog(
    BuildContext context,
    WidgetRef ref,
    InventoryItemModel? item,
  ) {
    showDialog(
      context: context,
      builder: (context) => InventoryFormDialog(item: item),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    InventoryItemModel item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar "${item.name}" del inventario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(inventoryManagementProvider.notifier)
                  .deleteItem(item.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item eliminado del inventario'),
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

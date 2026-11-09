import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/app_sizes.dart';
import 'package:pos_restaurante/core/constants/sections.dart';
import 'package:pos_restaurante/features/admin/providers/table_providers.dart';
import 'package:pos_restaurante/features/admin/presentation/widgets/table_form_dialog.dart';
import 'package:pos_restaurante/features/admin/data/models/table_model.dart';

/// Screen completa de gestión de mesas
class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesStreamProvider);

    return Scaffold(
      body: tablesAsync.when(
        data: (tables) {
          if (tables.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          // Agrupar por sección
          final tablesBySection = <Section, List<TableModel>>{};
          for (final table in tables) {
            tablesBySection.putIfAbsent(table.section, () => []).add(table);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            itemCount: tablesBySection.length,
            itemBuilder: (context, index) {
              final section = tablesBySection.keys.elementAt(index);
              final sectionTables = tablesBySection[section]!;
              sectionTables.sort(
                (a, b) => a.tableNumber.compareTo(b.tableNumber),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.spacing12,
                    ),
                    child: Text(
                      section.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Lista de cards (en lugar de grid)
                  ...sectionTables.map(
                    (table) => _buildTableCard(context, ref, table),
                  ),
                  const SizedBox(height: AppSizes.spacing24),
                ],
              );
            },
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
        onPressed: () => _showTableFormDialog(context, ref, null),
        backgroundColor: AppColors.adminPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Mesa'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.table_restaurant, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            'No hay mesas configuradas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            'Agrega mesas para comenzar a atender',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: AppSizes.spacing24),
          ElevatedButton.icon(
            onPressed: () => _showTableFormDialog(context, ref, null),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primera Mesa'),
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

  Widget _buildTableCard(
    BuildContext context,
    WidgetRef ref,
    TableModel table,
  ) {
    final statusColor = _getStatusColor(table.status);
    final statusIcon = _getStatusIcon(table.status);
    final statusText = _getStatusText(table.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      elevation: table.isActive ? 2 : 0,
      color: table.isActive ? null : Colors.grey.shade200,
      child: InkWell(
        onTap: () => _showTableFormDialog(context, ref, table),
        onLongPress: () => _confirmDelete(context, ref, table),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Indicador visual de estado
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '#${table.tableNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mesa ${table.tableNumber}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: table.isActive
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${table.capacity} pers.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          table.section.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!table.isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Mesa Inactiva',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Acciones
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showTableFormDialog(context, ref, table),
                    color: AppColors.info,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _confirmDelete(context, ref, table),
                    color: AppColors.error,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return AppColors.tableAvailable;
      case 'occupied':
        return AppColors.tableOccupied;
      case 'reserved':
        return AppColors.warning;
      case 'cleaning':
        return AppColors.tableNeedsCleaning;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle;
      case 'occupied':
        return Icons.people;
      case 'reserved':
        return Icons.schedule;
      case 'cleaning':
        return Icons.cleaning_services;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'occupied':
        return 'Ocupada';
      case 'reserved':
        return 'Reservada';
      case 'cleaning':
        return 'Limpiando';
      default:
        return status;
    }
  }

  void _showTableFormDialog(
    BuildContext context,
    WidgetRef ref,
    TableModel? table,
  ) {
    showDialog(
      context: context,
      builder: (context) => TableFormDialog(table: table),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TableModel table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la Mesa ${table.tableNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tableManagementProvider.notifier).deleteTable(table.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mesa eliminada'),
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

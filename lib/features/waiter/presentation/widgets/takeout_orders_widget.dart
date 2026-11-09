import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';
import 'package:pos_restaurante/features/waiter/providers/order_providers.dart';
import 'package:pos_restaurante/features/waiter/presentation/screens/create_order_screen.dart';

/// Widget que muestra las órdenes para llevar del mesero
class TakeoutOrdersWidget extends ConsumerWidget {
  const TakeoutOrdersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myTakeoutOrdersStreamProvider);

    return ordersAsync.when(
      data: (orders) {
        return Column(
          children: [
            // Header con botón de nueva orden
            _buildHeader(context, ref),

            // Lista de órdenes
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay órdenes para llevar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: _buildOrdersList(orders, context, ref),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_bag,
            color: AppColors.waiterPrimary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Para Llevar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _createTakeoutOrder(context, ref),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Nueva'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.waiterPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
    List<OrderModel> orders,
    BuildContext context,
    WidgetRef ref,
  ) {
    // Agrupar por estado
    final ready = orders.where((o) => o.status == OrderStatus.ready).toList();
    final preparing = orders
        .where((o) => o.status == OrderStatus.preparing)
        .toList();
    final pending = orders
        .where((o) => o.status == OrderStatus.pending)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Ready primero (listas para entregar)
        if (ready.isNotEmpty) ...[
          _buildSectionHeader('Listas', ready.length, AppColors.success),
          ...ready.map((order) => _buildTakeoutCard(context, ref, order)),
          const SizedBox(height: 24),
        ],

        // Preparing
        if (preparing.isNotEmpty) ...[
          _buildSectionHeader('En Cocina', preparing.length, AppColors.info),
          ...preparing.map((order) => _buildTakeoutCard(context, ref, order)),
          const SizedBox(height: 24),
        ],

        // Pending
        if (pending.isNotEmpty) ...[
          _buildSectionHeader('Pendientes', pending.length, AppColors.warning),
          ...pending.map((order) => _buildTakeoutCard(context, ref, order)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeoutCard(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    final statusColor = _getStatusColor(order.status);
    final timeSinceCreated = order.timestamps.timeSinceCreated;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.darkSurface,
      child: InkWell(
        onTap: () => _showOrderDetails(context, ref, order),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Número de orden + Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nombre del cliente
              if (order.customerName != null && order.customerName!.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 18,
                      color: AppColors.waiterPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.customerName!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.waiterPrimary,
                      ),
                    ),
                  ],
                ),
              if (order.customerName != null && order.customerName!.isNotEmpty)
                const SizedBox(height: 4),

              // Teléfono del cliente (si existe)
              if (order.customerPhone != null &&
                  order.customerPhone!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      order.customerPhone!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              if (order.customerPhone != null &&
                  order.customerPhone!.isNotEmpty)
                const SizedBox(height: 8),
              if ((order.customerName == null || order.customerName!.isEmpty) &&
                  (order.customerPhone == null || order.customerPhone!.isEmpty))
                const SizedBox.shrink()
              else if (order.customerName != null &&
                  order.customerName!.isNotEmpty &&
                  (order.customerPhone == null || order.customerPhone!.isEmpty))
                const SizedBox(height: 8),

              // Tiempo + Items
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: _getTimeColor(timeSinceCreated),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hace ${timeSinceCreated.inMinutes}min',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getTimeColor(timeSinceCreated),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.fastfood, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} items',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total + Acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  _buildActionButton(context, ref, order),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    if (order.status == OrderStatus.ready) {
      return ElevatedButton.icon(
        onPressed: () => _markAsDelivered(context, ref, order.id),
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Entregada'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
        ),
      );
    } else if (order.status == OrderStatus.pending) {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          OutlinedButton.icon(
            onPressed: () => _editOrder(context, order),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Editar', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.waiterPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _confirmCancel(context, ref, order.id),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancelar', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // Métodos auxiliares

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.preparing:
        return AppColors.info;
      case OrderStatus.ready:
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  Color _getTimeColor(Duration duration) {
    if (duration.inMinutes < 10) return AppColors.success;
    if (duration.inMinutes < 20) return AppColors.warning;
    return AppColors.error;
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.preparing:
        return 'En Cocina';
      case OrderStatus.ready:
        return 'Lista';
      case OrderStatus.delivered:
        return 'Entregada';
      default:
        return 'Desconocido';
    }
  }

  void _showOrderDetails(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Orden #${order.orderNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order.customerName != null && order.customerName!.isNotEmpty)
              Text('👤 ${order.customerName}'),
            if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
              Text('📞 ${order.customerPhone}'),
            if (order.customerName != null || order.customerPhone != null)
              const SizedBox(height: 8),
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ${item.quantity}x ${item.menuItemName}'),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          '📝 ${item.notes}',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Text(
              'Total: \$${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _editOrder(BuildContext context, OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          tableNumber: null, // takeout no tiene mesa
          orderToEdit: order,
        ),
      ),
    );
  }

  Future<void> _markAsDelivered(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) async {
    try {
      final repository = ref.read(orderRepositoryProvider);
      await repository.markAsDelivered(orderId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Orden marcada como entregada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Orden'),
        content: const Text(
          '¿Estás seguro de cancelar esta orden? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(orderRepositoryProvider);
        await repository.cancelOrder(orderId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orden cancelada'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _createTakeoutOrder(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateOrderScreen(tableNumber: null),
      ),
    );
  }
}

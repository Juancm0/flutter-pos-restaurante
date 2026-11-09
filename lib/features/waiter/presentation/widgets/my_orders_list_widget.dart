import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/app_sizes.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';
import 'package:sistema_eve/features/waiter/providers/order_providers.dart';
import 'package:sistema_eve/features/waiter/presentation/screens/create_order_screen.dart';
import 'package:sistema_eve/features/waiter/presentation/screens/add_items_screen.dart';
import 'package:sistema_eve/features/waiter/presentation/widgets/payment_dialog.dart';

/// Widget que muestra las órdenes activas del mesero
class MyOrdersListWidget extends ConsumerStatefulWidget {
  const MyOrdersListWidget({super.key});

  @override
  ConsumerState<MyOrdersListWidget> createState() => _MyOrdersListWidgetState();
}

class _MyOrdersListWidgetState extends ConsumerState<MyOrdersListWidget> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Actualizar cada 30 segundos para refrescar tiempos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myOrdersStreamProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No tienes órdenes activas',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Agrupar órdenes por estado
        final pending = orders
            .where((o) => o.status == OrderStatus.pending)
            .toList();
        final preparing = orders
            .where((o) => o.status == OrderStatus.preparing)
            .toList();
        final ready = orders
            .where((o) => o.status == OrderStatus.ready)
            .toList();
        final delivered = orders
            .where((o) => o.status == OrderStatus.delivered)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            children: [
              // Sección: Servidas (esperando pago)
              if (delivered.isNotEmpty) ...[
                _buildSectionHeader(
                  'Servidas',
                  delivered.length,
                  AppColors.waiterPrimary,
                  Icons.room_service,
                ),
                ...delivered.map(
                  (order) => _buildOrderCard(context, ref, order),
                ),
                const SizedBox(height: AppSizes.spacing24),
              ],

              // Sección: Listas para servir (prioridad alta)
              if (ready.isNotEmpty) ...[
                _buildSectionHeader(
                  'Listas para Servir',
                  ready.length,
                  AppColors.success,
                  Icons.done_all,
                ),
                ...ready.map((order) => _buildOrderCard(context, ref, order)),
                const SizedBox(height: AppSizes.spacing24),
              ],

              // Sección: En preparación
              if (preparing.isNotEmpty) ...[
                _buildSectionHeader(
                  'En Preparación',
                  preparing.length,
                  AppColors.info,
                  Icons.restaurant,
                ),
                ...preparing.map(
                  (order) => _buildOrderCard(context, ref, order),
                ),
                const SizedBox(height: AppSizes.spacing24),
              ],

              // Sección: Pendientes
              if (pending.isNotEmpty) ...[
                _buildSectionHeader(
                  'Pendientes',
                  pending.length,
                  AppColors.warning,
                  Icons.access_time,
                ),
                ...pending.map((order) => _buildOrderCard(context, ref, order)),
              ],
            ],
          ),
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

  Widget _buildSectionHeader(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
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

  Widget _buildOrderCard(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    final statusColor = _getStatusColor(order.status);
    final timeSinceCreated = order.timestamps.timeSinceCreated;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: InkWell(
        onTap: () => _showOrderDetails(context, ref, order),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Mesa + Tiempo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: order.orderType == OrderType.takeout
                                ? AppColors.waiterPrimary
                                : AppColors.adminPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                order.orderType == OrderType.takeout
                                    ? Icons.shopping_bag
                                    : Icons.table_restaurant,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.orderType == OrderType.takeout
                                    ? 'Llevar'
                                    : 'Mesa ${order.tableNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '#${order.orderNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTimeColor(timeSinceCreated).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: _getTimeColor(timeSinceCreated),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(timeSinceCreated),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getTimeColor(timeSinceCreated),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nombre del cliente (si existe)
              if (order.customerName != null && order.customerName!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.waiterPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.waiterPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.waiterPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerName!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.waiterPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Items
              Text(
                '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),

              // Total + Acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.adminPrimary,
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
        label: const Text('Servir'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
        ),
      );
    } else if (order.status == OrderStatus.pending) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _editOrder(context, ref, order),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Editar', style: TextStyle(fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.waiterPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(44, 44),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _confirmCancel(context, ref, order.id),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancelar', style: TextStyle(fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      );
    } else if (order.status == OrderStatus.delivered) {
      // Para órdenes servidas de mesa, mostrar botón de pago + añadir
      if (order.orderType == OrderType.dineIn) {
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Botón Añadir items
            OutlinedButton.icon(
              onPressed: () => _addItemsToOrder(context, order),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Añadir', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
            ),
            // Botón Procesar Pago
            ElevatedButton.icon(
              onPressed: () => _processPayment(context, ref, order),
              icon: const Icon(Icons.payment, size: 16),
              label: const Text('PAGAR', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
            ),
          ],
        );
      } else {
        // Para takeout, mostrar que está en caja
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.point_of_sale, size: 16, color: Colors.orange),
              SizedBox(width: 4),
              Text(
                'En caja',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ),
        );
      }
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.restaurant, size: 16, color: AppColors.info),
            SizedBox(width: 4),
            Text(
              'En cocina',
              style: TextStyle(fontSize: 12, color: AppColors.info),
            ),
          ],
        ),
      );
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
            // Tipo de orden
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: order.orderType == OrderType.takeout
                    ? AppColors.waiterPrimary.withValues(alpha: 0.2)
                    : AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.orderType == OrderType.takeout
                    ? '🛍️ Para Llevar'
                    : '🍽️ Mesa ${order.tableNumber}',
                style: TextStyle(
                  color: order.orderType == OrderType.takeout
                      ? AppColors.waiterPrimary
                      : AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                        padding: const EdgeInsets.only(left: 16, top: 2),
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

  void _editOrder(BuildContext context, WidgetRef ref, OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          tableNumber: order.tableNumber,
          orderToEdit: order,
        ),
      ),
    );
  }

  /// Navegar a pantalla para añadir items adicionales a orden servida
  void _addItemsToOrder(BuildContext context, OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddItemsScreen(existingOrder: order)),
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
            content: Text('✅ Orden marcada como servida'),
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

  Future<void> _processPayment(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => PaymentDialog(order: order),
    );
    // El diálogo ya maneja el snackbar de éxito
  }

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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 1) return 'Ahora';
    return '${minutes}min';
  }
}

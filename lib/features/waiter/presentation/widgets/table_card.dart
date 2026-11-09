import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/app_sizes.dart';
import 'package:sistema_eve/core/constants/firebase_constants.dart';
import 'package:sistema_eve/features/admin/data/models/table_model.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';
import 'package:sistema_eve/features/waiter/providers/order_providers.dart';
import 'package:sistema_eve/features/waiter/presentation/screens/create_order_screen.dart';
import 'package:sistema_eve/features/waiter/presentation/widgets/table_detail_dialog.dart';
import 'package:sistema_eve/features/waiter/presentation/widgets/table_status_helpers.dart';

/// Card individual de mesa con toda su información
class TableCard extends ConsumerWidget {
  final TableModel table;

  const TableCard({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = table.status == 'available';
    final statusColor = getTableStatusColor(table.status);

    // Si la mesa está ocupada, obtener la orden
    final orderAsync = table.currentOrderId != null
        ? ref.watch(orderByIdProvider(table.currentOrderId!))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleTableTap(context, ref, table),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor, width: 2),
              gradient: isAvailable
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor.withValues(alpha: 0.05),
                        statusColor.withValues(alpha: 0.02),
                      ],
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Número de mesa + Estado
                  Row(
                    children: [
                      // Icono de mesa
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.table_restaurant,
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Número y capacidad
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mesa ${table.tableNumber}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${table.capacity} personas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Badge de estado
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              getTableStatusIcon(table.status),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              getTableStatusText(table.status),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Si está ocupada, mostrar info de la orden
                  if (!isAvailable && orderAsync != null)
                    orderAsync.when(
                      data: (order) => _buildOrderInfo(context, order),
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfo(BuildContext context, OrderModel order) {
    final elapsedTime = DateTime.now().difference(order.timestamps.created);
    final minutesElapsed = elapsedTime.inMinutes;
    final timeColor = getOrderTimeColor(minutesElapsed);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del cliente
          if (order.customerName != null && order.customerName!.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
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
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          if (order.customerName != null && order.customerName!.isNotEmpty)
            const SizedBox(height: 8),

          // Número de orden
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                'Orden: ${order.orderNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tiempo transcurrido
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: timeColor),
              const SizedBox(width: 8),
              Text(
                formatElapsedTime(elapsedTime),
                style: TextStyle(
                  fontSize: 14,
                  color: timeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Estado de la orden
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getOrderStatusColor(order.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: getOrderStatusColor(order.status).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  getOrderStatusText(order.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: getOrderStatusColor(order.status),
                  ),
                ),
              ),
            ],
          ),

          // Total de la orden
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.attach_money,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${order.items.length} items)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleTableTap(
    BuildContext context,
    WidgetRef ref,
    TableModel table,
  ) async {
    if (table.status == 'available') {
      // Navegar a crear orden
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateOrderScreen(
            tableNumber: table.tableNumber,
            tableSection: table.section.name,
          ),
        ),
      );
    } else {
      // Mostrar diálogo con opciones para mesa ocupada
      await _showTableOptionsDialog(context, ref, table);
    }
  }

  Future<void> _showTableOptionsDialog(
    BuildContext context,
    WidgetRef ref,
    TableModel table,
  ) async {
    // Obtener información de la orden si existe
    OrderModel? order;
    if (table.currentOrderId != null) {
      try {
        final orderDoc = await FirebaseFirestore.instance
            .collection(FirebaseConstants.ordersCollection)
            .doc(table.currentOrderId)
            .get();
        if (orderDoc.exists) {
          order = OrderModel.fromFirestore(orderDoc);
        }
      } catch (e) {
        // Continuar sin orden
      }
    }

    if (!context.mounted) return;

    await showTableDetailDialog(
      context: context,
      table: table,
      order: order,
      onEditOrder: () {
        final currentOrder = order;
        if (currentOrder == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateOrderScreen(
              tableNumber: table.tableNumber,
              tableSection: table.section.name,
              orderToEdit: currentOrder,
            ),
          ),
        );
      },
      onAddItems: () {
        final currentOrder = order;
        if (currentOrder == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateOrderScreen(
              tableNumber: table.tableNumber,
              tableSection: table.section.name,
              orderToEdit: currentOrder,
            ),
          ),
        );
      },
      onMarkDelivered: () async {
        final currentOrder = order;
        if (currentOrder == null) return;
        await _markOrderAsDelivered(context, ref, currentOrder.id);
      },
      onProcessPayment: () async {
        final currentOrder = order;
        if (currentOrder == null) return;
        await _processPayment(context, ref, currentOrder);
      },
      onCleanTable: () => _cleanTable(context, ref, table),
    );
  }

  Future<void> _markOrderAsDelivered(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update({
            'status': 'delivered',
            'timestamps.delivered': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Orden marcada como servida'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processPayment(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TablePaymentDialog(order: order),
    );

    if (result != null && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection(FirebaseConstants.ordersCollection)
            .doc(order.id)
            .update({
              'status': 'pendingPayment',
              'paymentMethod': result['method'],
              'tip': result['tip'] ?? 0,
              'timestamps.pendingPayment': FieldValue.serverTimestamp(),
            });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Pago enviado a caja'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _cleanTable(
    BuildContext context,
    WidgetRef ref,
    TableModel table,
  ) async {
    try {
      // Liberar la mesa
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.tablesCollection)
          .doc(table.id)
          .update({'status': 'available', 'currentOrderId': null});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Mesa ${table.tableNumber} limpiada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al limpiar mesa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}


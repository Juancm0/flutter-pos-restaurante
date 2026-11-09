import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/utils/business_day.dart';
import 'package:sistema_eve/features/cashier/providers/cashier_providers.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';

/// Tab de órdenes pagadas del día (desde el último corte).
///
/// Extraída de CashierDashboard sin cambios de lógica ni de aspecto.
/// Tab de órdenes pagadas del día (desde el último corte)
class PaidOrdersTab extends ConsumerWidget {
  const PaidOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(filteredPaidOrdersTodayProvider);
    final selectedSection = ref.watch(cashierSectionFilterProvider);
    final lastCutTime = ref.watch(lastCashCutTimeProvider);

    return ordersAsync.when(
      data: (allOrders) {
        // Filtrar órdenes desde el último corte
        final shiftStartTime = lastCutTime ?? getBusinessDayStart();
        final orders = allOrders.where((o) {
          final paidTime = o.timestamps.paid ?? o.timestamps.created;
          return paidTime.isAfter(shiftStartTime);
        }).toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  selectedSection != null
                      ? 'Sin pagos de ${selectedSection.displayName} en este turno'
                      : 'Sin pagos en este turno',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lastCutTime != null
                      ? 'Desde último corte: ${DateFormat("HH:mm").format(lastCutTime)}'
                      : 'Desde inicio de turno',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final totalSales = orders.fold<double>(
          0,
          (sum, order) => sum + (order.total + (order.tip ?? 0)),
        );

        return Column(
          children: [
            // Resumen del día
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard(
                    icon: Icons.receipt,
                    label: 'Órdenes',
                    value: '${orders.length}',
                  ),
                  _StatCard(
                    icon: Icons.attach_money,
                    label: 'Total',
                    value: NumberFormat.currency(
                      symbol: '\$',
                      decimalDigits: 2,
                    ).format(totalSales),
                  ),
                ],
              ),
            ),
            // Lista de órdenes
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return PaidOrderCard(order: orders[index]);
                },
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }
}

/// Widget de estadística
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: const Color(0xFF4CAF50)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Card de orden pagada
class PaidOrderCard extends StatelessWidget {
  final OrderModel order;

  const PaidOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final grandTotal = order.total + (order.tip ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.darkSurface,
      child: ListTile(
        leading: Icon(
          order.orderType == OrderType.dineIn
              ? Icons.table_restaurant
              : Icons.shopping_bag,
          color: Colors.green,
        ),
        title: Text(
          order.displayReference,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${order.paymentMethod?.displayName ?? ''} - ${order.confirmedByUserName ?? ''}',
        ),
        trailing: Text(
          currencyFormat.format(grandTotal),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}

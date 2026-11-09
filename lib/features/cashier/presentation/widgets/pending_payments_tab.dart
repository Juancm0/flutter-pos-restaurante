import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/widgets/app_button.dart';
import 'package:pos_restaurante/features/auth/providers/auth_providers.dart';
import 'package:pos_restaurante/features/cashier/presentation/widgets/cashier_payment_dialog.dart';
import 'package:pos_restaurante/features/cashier/providers/cashier_providers.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';

/// Tab de pagos pendientes de confirmación.
///
/// Extraída de CashierDashboard sin cambiar su lógica: las órdenes las
/// sigue dando `filteredPendingPaymentsProvider` y la confirmación de
/// pago sigue llamando a `CashierActions.confirmPayment` /
/// `rejectPayment` (lógica del agente A, intacta).
/// Tab de pagos pendientes de confirmación
class PendingPaymentsTab extends ConsumerWidget {
  const PendingPaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(filteredPendingPaymentsProvider);
    final selectedSection = ref.watch(cashierSectionFilterProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin pagos pendientes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedSection != null
                      ? 'Sin pagos pendientes de ${selectedSection.displayName}'
                      : 'Todas las órdenes han sido confirmadas',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return PaymentConfirmationCard(order: orders[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar pagos',
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de confirmación de pago
class PaymentConfirmationCard extends ConsumerWidget {
  final OrderModel order;

  const PaymentConfirmationCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final grandTotal = order.total + (order.tip ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
        color: AppColors.darkSurface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Franja de estado (NUEVO, solo visual): qué falta por hacer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_actions, size: 18, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Pendiente de confirmación en caja',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Row(
              children: [
                Icon(
                  order.orderType == OrderType.dineIn
                      ? Icons.table_restaurant
                      : Icons.shopping_bag,
                  color: order.orderType == OrderType.dineIn
                      ? Colors.blue
                      : Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.displayReference,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '#${order.orderNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade800),
            const SizedBox(height: 12),

            // Info del mesero
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Mesero: ${order.paidByUserName ?? order.createdByName}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Desglose
            _AmountRow('Subtotal:', currencyFormat.format(order.total)),
            if (order.tip != null && order.tip! > 0)
              _AmountRow(
                'Propina:',
                currencyFormat.format(order.tip!),
                color: Colors.green,
              ),
            const SizedBox(height: 8),

            // TOTAL GRANDE Y PROMINENTE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    currencyFormat.format(grandTotal),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Método de pago
            Row(
              children: [
                Icon(
                  order.paymentMethod == PaymentMethod.cash
                      ? Icons.money
                      : Icons.credit_card,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  order.paymentMethod?.displayName ?? 'Sin método',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Si es efectivo, mostrar recibido y cambio
            if (order.paymentMethod == PaymentMethod.cash) ...[
              const SizedBox(height: 8),
              _AmountRow(
                'Recibido:',
                currencyFormat.format(order.cashReceived ?? 0),
              ),
              _AmountRow(
                'Cambio:',
                currencyFormat.format(order.cashChange ?? 0),
                color: Colors.blue,
              ),
            ],
            const SizedBox(height: 16),

            // Botones: confirmar a lo grande y rechazar como secundario.
            // (Antes eran dos botones iguales lado a lado; el orden de las
            // acciones y su lógica no cambian.)
            AppButton(
              text: order.paymentMethod == null ? 'PROCESAR PAGO' : 'CONFIRMAR',
              icon: Icons.check_circle,
              type: AppButtonType.success,
              size: AppButtonSize.large,
              isFullWidth: true,
              onPressed: () async {
                final userAsync = ref.read(currentUserProvider);
                final user = userAsync.value;
                if (user == null) return;

                // Si la orden no tiene método de pago, mostrar diálogo
                if (order.paymentMethod == null) {
                  await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => CashierPaymentDialog(order: order),
                  );
                  return; // El diálogo ya procesa el pago
                }

                // Si ya tiene datos de pago, solo confirmar
                try {
                  await ref
                      .read(cashierActionsProvider)
                      .confirmPayment(
                        orderId: order.id,
                        cashierId: user.id,
                        cashierName: user.name,
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Pago confirmado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(cashierActionsProvider)
                        .rejectPayment(
                          orderId: order.id,
                          reason: 'Rechazado por cajero',
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pago rechazado'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.cancel),
                label: const Text('RECHAZAR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper para mostrar fila de monto
class _AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color? color;

  const _AmountRow(this.label, this.amount, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: color ?? Colors.white70, fontSize: 14),
          ),
          Text(
            amount,
            style: TextStyle(color: color ?? Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

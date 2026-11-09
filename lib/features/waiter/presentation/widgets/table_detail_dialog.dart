import 'package:flutter/material.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/features/admin/data/models/table_model.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';
import 'package:pos_restaurante/features/waiter/presentation/widgets/table_status_helpers.dart';

/// Diálogo de detalle de una mesa ocupada.
///
/// Extraído de TableGridWidget sin cambiar su contenido ni sus acciones:
/// Editar Orden (pendiente), Servir (lista), Agregar / Pagar (servida) y
/// Limpiar Mesa (pagada). La tarjeta de mesa pasa los callbacks; este
/// archivo solo presenta y cierra el diálogo antes de invocarlos, como
/// hacía el código original. Una orden cancelada no muestra acciones,
/// solo la nota informativa (la orden se conserva para el historial).
Future<void> showTableDetailDialog({
  required BuildContext context,
  required TableModel table,
  required OrderModel? order,
  required VoidCallback onEditOrder,
  required VoidCallback onAddItems,
  required Future<void> Function() onMarkDelivered,
  required Future<void> Function() onProcessPayment,
  required Future<void> Function() onCleanTable,
}) async {
  if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.table_restaurant, color: getTableStatusColor(table.status)),
            const SizedBox(width: 8),
            Text('Mesa ${table.tableNumber}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nota para órdenes canceladas: solo se informa, sin acciones
            if (order?.status == OrderStatus.cancelled)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Orden cancelada: se conserva para el historial.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            // Estado de la mesa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: getTableStatusColor(table.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                getTableStatusText(table.status),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: getTableStatusColor(table.status),
                ),
              ),
            ),
            if (order != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              // Info de la orden
              Row(
                children: [
                  const Icon(Icons.receipt, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Orden #${order.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (order.customerName != null && order.customerName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Cliente: ${order.customerName}'),
                    ],
                  ),
                ),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Total: \$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    getOrderStatusIcon(order.status),
                    size: 18,
                    color: getOrderStatusColor(order.status),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getOrderStatusColor(
                        order.status,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      getOrderStatusText(order.status),
                      style: TextStyle(
                        color: getOrderStatusColor(order.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // Acciones según estado de la orden
          if (order != null) ...[
            // PENDIENTE: Editar o Cancelar
            if (order.status == OrderStatus.pending) ...[
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onEditOrder();
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar Orden'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.waiterPrimary,
                  minimumSize: const Size(130, 44),
                ),
              ),
            ],

            // LISTA: Marcar como servida
            if (order.status == OrderStatus.ready) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await onMarkDelivered();
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Servir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(130, 44),
                ),
              ),
            ],

            // SERVIDA: Agregar items o Procesar pago
            if (order.status == OrderStatus.delivered) ...[
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onAddItems();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  minimumSize: const Size(110, 44),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await onProcessPayment();
                },
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Pagar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(110, 44),
                ),
              ),
            ],

            // PAGADA: Limpiar mesa
            if (order.status == OrderStatus.paid) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await onCleanTable();
                },
                icon: const Icon(Icons.cleaning_services, size: 18),
                label: const Text('Limpiar Mesa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(140, 44),
                ),
              ),
            ],
          ],

          // Botón cerrar siempre visible
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
}

/// Diálogo para procesar el pago de una orden
class TablePaymentDialog extends StatefulWidget {
  final OrderModel order;

  const TablePaymentDialog({super.key, required this.order});

  @override
  State<TablePaymentDialog> createState() => _TablePaymentDialogState();
}

class _TablePaymentDialogState extends State<TablePaymentDialog> {
  String _selectedMethod = 'cash';
  final _tipController = TextEditingController();

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.payment, color: AppColors.success),
          SizedBox(width: 8),
          Text('Procesar Pago'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total de la orden
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Total a pagar'),
                const SizedBox(height: 4),
                Text(
                  '\$${widget.order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Método de pago',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Opciones de método de pago
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPaymentMethodChip('cash', 'Efectivo', Icons.money),
              _buildPaymentMethodChip('card', 'Tarjeta', Icons.credit_card),
              _buildPaymentMethodChip(
                'transfer',
                'Transferencia',
                Icons.account_balance,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Campo de propina
          TextField(
            controller: _tipController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Propina (opcional)',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final tip = double.tryParse(_tipController.text) ?? 0;
            Navigator.pop(context, {'method': _selectedMethod, 'tip': tip});
          },
          icon: const Icon(Icons.send),
          label: const Text('Enviar a Caja'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodChip(String value, String label, IconData icon) {
    final isSelected = _selectedMethod == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedMethod = value);
        }
      },
      selectedColor: AppColors.success,
      labelStyle: TextStyle(color: isSelected ? Colors.white : null),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/widgets/app_button.dart';
import 'package:pos_restaurante/core/widgets/app_text_field.dart';
import 'package:pos_restaurante/features/auth/providers/auth_providers.dart';
import 'package:pos_restaurante/features/cashier/providers/cashier_providers.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';
import 'package:intl/intl.dart';

/// Diálogo de procesamiento de pago para cajero
/// Para órdenes takeout que llegan sin datos de pago
class CashierPaymentDialog extends ConsumerStatefulWidget {
  final OrderModel order;

  const CashierPaymentDialog({super.key, required this.order});

  @override
  ConsumerState<CashierPaymentDialog> createState() =>
      _CashierPaymentDialogState();
}

class _CashierPaymentDialogState extends ConsumerState<CashierPaymentDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  double _tip = 0.0;
  double _cashReceived = 0.0;
  bool _isProcessing = false;

  final _cashReceivedController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void dispose() {
    _cashReceivedController.dispose();
    super.dispose();
  }

  double get _total => widget.order.total + _tip;
  double get _cashChange =>
      _selectedMethod == PaymentMethod.cash ? _cashReceived - _total : 0.0;

  void _setTipPercentage(double percentage) {
    setState(() {
      _tip = widget.order.total * percentage;
    });
  }

  Future<void> _processPayment() async {
    // Validaciones
    if (_selectedMethod == PaymentMethod.cash) {
      if (_cashReceived <= 0) {
        _showError('Ingrese el monto recibido');
        return;
      }
      if (_cashChange < 0) {
        _showError('El monto recibido es insuficiente');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await ref
          .read(cashierActionsProvider)
          .processTakeoutPayment(
            orderId: widget.order.id,
            paymentMethod: _selectedMethod,
            tip: _tip,
            cashReceived: _selectedMethod == PaymentMethod.cash
                ? _cashReceived
                : null,
            cashierId: user.id,
            cashierName: user.name,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pago procesado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.point_of_sale, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Procesar Pago',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '#${widget.order.orderNumber}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Resumen de orden
              _buildAmountRow('Subtotal:', widget.order.total),
              const SizedBox(height: 16),

              // Propina
              const Text(
                'Propina:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _tipButton('Sin', 0.0),
                  const SizedBox(width: 8),
                  _tipButton('10%', 0.10),
                  const SizedBox(width: 8),
                  _tipButton('15%', 0.15),
                  const SizedBox(width: 8),
                  _tipButton('20%', 0.20),
                ],
              ),
              const SizedBox(height: 8),
              _buildAmountRow('Propina:', _tip, color: Colors.purple),
              const Divider(height: 24),

              // Total
              _buildAmountRow(
                'TOTAL:',
                _total,
                isBold: true,
                fontSize: 28,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 24),

              // Método de pago
              const Text(
                'Método de pago:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _methodButton(
                      PaymentMethod.cash,
                      '💵 Efectivo',
                      Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _methodButton(
                      PaymentMethod.card,
                      '🏦 Transferencia',
                      Icons.account_balance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Si es efectivo, mostrar campos de cambio
              if (_selectedMethod == PaymentMethod.cash) ...[
                const Text(
                  'Monto recibido:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                AppNumberField(
                  controller: _cashReceivedController,
                  hint: '0.00',
                  prefix: '\$ ',
                  onChanged: (value) {
                    setState(() {
                      _cashReceived = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
                if (_cashReceived > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cashChange >= 0
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _cashChange >= 0 ? Colors.blue : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cambio:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(_cashChange),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: _cashChange >= 0 ? Colors.blue : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Botón de confirmar: inconfundible, ancho completo.
              AppButton(
                text: 'PROCESAR PAGO',
                icon: Icons.check_circle,
                type: AppButtonType.success,
                size: AppButtonSize.large,
                isFullWidth: true,
                isLoading: _isProcessing,
                onPressed: _processPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _tipButton(String label, double percentage) {
    // Para 0% (Sin propina), verificar si _tip es 0
    final bool isSelected;
    if (percentage == 0.0) {
      isSelected = _tip == 0.0;
    } else {
      isSelected = (_tip - widget.order.total * percentage).abs() < 0.01;
    }

    return Expanded(
      child: OutlinedButton(
        onPressed: () => _setTipPercentage(percentage),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.purple.withValues(alpha: 0.2) : null,
          side: BorderSide(
            color: isSelected ? Colors.purple : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _methodButton(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
              : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade600,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/widgets/app_button.dart';
import 'package:pos_restaurante/core/constants/firebase_constants.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';
import 'package:pos_restaurante/features/auth/providers/auth_providers.dart';
import 'package:intl/intl.dart';

/// Diálogo para procesar pago de orden (solo para dine-in)
/// El mesero captura: método de pago, propina, y monto recibido (si es efectivo)
class PaymentDialog extends ConsumerStatefulWidget {
  final OrderModel order;

  const PaymentDialog({super.key, required this.order});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _cashReceivedController = TextEditingController();
  double _tip = 0;
  double _tipPercentage = 0;
  bool _isProcessing = false;

  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void dispose() {
    _cashReceivedController.dispose();
    super.dispose();
  }

  double get _cashReceived {
    final text = _cashReceivedController.text
        .replaceAll('\$', '')
        .replaceAll(',', '');
    return double.tryParse(text) ?? 0;
  }

  // Comisión del 5% para pagos con tarjeta
  double get _cardCommission =>
      _selectedMethod == PaymentMethod.card ? widget.order.total * 0.05 : 0;

  double get _cashChange {
    if (_selectedMethod != PaymentMethod.cash) return 0;
    final total = widget.order.total + _tip + _cardCommission;
    return _cashReceived - total;
  }

  double get _grandTotal => widget.order.total + _tip + _cardCommission;

  void _selectTipPercentage(double percentage) {
    setState(() {
      // Si presiona el mismo porcentaje, desmarcar (propina = 0)
      if (_tipPercentage == percentage) {
        _tipPercentage = 0;
        _tip = 0;
      } else {
        _tipPercentage = percentage;
        _tip = widget.order.total * percentage;
      }
    });
  }

  void _setCustomTip(double amount) {
    setState(() {
      _tipPercentage = 0; // Reset percentage
      _tip = amount;
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

      // Actualizar orden a pendingPayment
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.ordersCollection)
          .doc(widget.order.id)
          .update({
            'status': OrderStatus.pendingPayment.name,
            'paymentMethod': _selectedMethod.name,
            'tip': _tip,
            'cashReceived': _selectedMethod == PaymentMethod.cash
                ? _cashReceived
                : null,
            'cashChange': _selectedMethod == PaymentMethod.cash
                ? _cashChange
                : null,
            'paidByUserId': user.id,
            'paidByUserName': user.name,
            'updatedAt': Timestamp.now(),
          });

      // Liberar mesa
      if (widget.order.tableNumber != null) {
        final tablesSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseConstants.tablesCollection)
            .where('tableNumber', isEqualTo: widget.order.tableNumber)
            .limit(1)
            .get();

        if (tablesSnapshot.docs.isNotEmpty) {
          await tablesSnapshot.docs.first.reference.update({
            'status': 'available',
            'currentOrderId': null,
          });
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Retornar true para indicar éxito

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Pago procesado - Enviado a caja\n${widget.order.tableNumber != null ? "Mesa ${widget.order.tableNumber} liberada" : ""}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error al procesar pago: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.payment, color: Colors.green, size: 32),
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
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.order.displayReference,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Total a pagar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a cobrar:',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _currencyFormat.format(widget.order.total),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Método de pago
              const Text(
                'Método de Pago:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PaymentMethodButton(
                      icon: Icons.money,
                      label: 'Efectivo',
                      isSelected: _selectedMethod == PaymentMethod.cash,
                      onTap: () =>
                          setState(() => _selectedMethod = PaymentMethod.cash),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PaymentMethodButton(
                      icon: Icons.credit_card,
                      label: 'Tarjeta',
                      isSelected: _selectedMethod == PaymentMethod.card,
                      onTap: () =>
                          setState(() => _selectedMethod = PaymentMethod.card),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Si es efectivo, mostrar input de monto recibido
              if (_selectedMethod == PaymentMethod.cash) ...[
                const Text(
                  'Monto Recibido:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cashReceivedController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Colors.green,
                    ),
                    hintText: '0.00',
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Mostrar cambio
                if (_cashReceived > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cashChange >= 0
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _cashChange >= 0
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cambio:',
                          style: TextStyle(
                            color: _cashChange >= 0 ? Colors.blue : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(_cashChange.abs()),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _cashChange >= 0 ? Colors.blue : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Propina
              const Text(
                '¿Dejó propina? (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TipButton(
                    percentage: 0.10,
                    isSelected: _tipPercentage == 0.10,
                    onTap: () => _selectTipPercentage(0.10),
                    amount: widget.order.total * 0.10,
                  ),
                  const SizedBox(width: 8),
                  _TipButton(
                    percentage: 0.15,
                    isSelected: _tipPercentage == 0.15,
                    onTap: () => _selectTipPercentage(0.15),
                    amount: widget.order.total * 0.15,
                  ),
                  const SizedBox(width: 8),
                  _TipButton(
                    percentage: 0.20,
                    isSelected: _tipPercentage == 0.20,
                    onTap: () => _selectTipPercentage(0.20),
                    amount: widget.order.total * 0.20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CustomTipButton(
                      onTipEntered: _setCustomTip,
                      isSelected: _tipPercentage == 0 && _tip > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_tip > 0)
                Text(
                  'Propina: ${_currencyFormat.format(_tip)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              // Mostrar comisión de tarjeta si aplica
              if (_cardCommission > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '💳 Comisión tarjeta (5%):',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(_cardCommission),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Total final
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL FINAL:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _currencyFormat.format(_grandTotal),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón confirmar: inconfundible, ancho completo.
              AppButton(
                text: 'CONFIRMAR PAGO',
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
}

/// Botón de método de pago
class _PaymentMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de propina
class _TipButton extends StatelessWidget {
  final double percentage;
  final bool isSelected;
  final VoidCallback onTap;
  final double amount;

  const _TipButton({
    required this.percentage,
    required this.isSelected,
    required this.onTap,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey.shade700,
            ),
          ),
          child: Column(
            children: [
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green : Colors.white,
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de propina personalizada
class _CustomTipButton extends StatelessWidget {
  final Function(double) onTipEntered;
  final bool isSelected;

  const _CustomTipButton({
    required this.onTipEntered,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final controller = TextEditingController();
        final result = await showDialog<double>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkSurface,
            title: const Text('Propina Personalizada'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                hintText: '0.00',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  final amount = double.tryParse(controller.text) ?? 0;
                  Navigator.pop(context, amount);
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );

        if (result != null && result > 0) {
          onTipEntered(result);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade700,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.edit, color: isSelected ? Colors.green : Colors.grey),
            Text(
              'Otra',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

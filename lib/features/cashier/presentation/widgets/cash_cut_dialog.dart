import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/features/auth/providers/auth_providers.dart';
import 'package:pos_restaurante/features/cashier/providers/cashier_providers.dart';
import 'package:pos_restaurante/features/cashier/services/cash_cut_pdf_generator.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';

/// Diálogo para realizar corte de caja
class CashCutDialog extends ConsumerStatefulWidget {
  final List<OrderModel> orders;
  final DateTime shiftStartTime;

  const CashCutDialog({
    super.key,
    required this.orders,
    required this.shiftStartTime,
  });

  @override
  ConsumerState<CashCutDialog> createState() => _CashCutDialogState();
}

class _CashCutDialogState extends ConsumerState<CashCutDialog> {
  bool _isProcessing = false;
  bool _pdfGenerated = false;

  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Calcular totales
  double get _totalCash => widget.orders
      .where((o) => o.paymentMethod == PaymentMethod.cash)
      .fold(0.0, (sum, o) => sum + o.total + (o.tip ?? 0));

  double get _totalCard => widget.orders
      .where((o) => o.paymentMethod == PaymentMethod.card)
      .fold(0.0, (sum, o) => sum + o.total + (o.tip ?? 0));

  double get _totalTips =>
      widget.orders.fold(0.0, (sum, o) => sum + (o.tip ?? 0));

  double get _grandTotal => _totalCash + _totalCard;

  Future<void> _generatePdf() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      await CashCutPdfGenerator.printOrShare(
        cashierName: user.name,
        cutStartTime: widget.shiftStartTime,
        cutEndTime: DateTime.now(),
        orders: widget.orders,
      );
      setState(() => _pdfGenerated = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmCashCut() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      await ref
          .read(cashierActionsProvider)
          .performCashCut(
            cashierId: user.id,
            cashierName: user.name,
            orders: widget.orders,
            branchId: user.branchId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Corte de caja realizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.green,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Corte de Caja',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Desde: ${_dateFormat.format(widget.shiftStartTime)}',
                          style: TextStyle(
                            fontSize: 12,
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

              // Resumen de órdenes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      icon: Icons.receipt,
                      label: 'Órdenes procesadas',
                      value: '${widget.orders.length}',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      icon: Icons.money,
                      label: 'Efectivo',
                      value: _currencyFormat.format(_totalCash),
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      icon: Icons.credit_card,
                      label: 'Tarjeta',
                      value: _currencyFormat.format(_totalCard),
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      icon: Icons.volunteer_activism,
                      label: 'Propinas',
                      value: _currencyFormat.format(_totalTips),
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Total grande
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
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
                      _currencyFormat.format(_grandTotal),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón Generar PDF
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _generatePdf,
                icon: _pdfGenerated
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_pdfGenerated ? 'PDF Generado ✓' : 'Generar PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _pdfGenerated ? Colors.green : Colors.blue,
                  side: BorderSide(
                    color: _pdfGenerated ? Colors.green : Colors.blue,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Botón Confirmar Corte
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _confirmCashCut,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isProcessing ? 'Procesando...' : 'CONFIRMAR CORTE',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 8),

              // Nota
              Text(
                'Al confirmar, las órdenes se limpiarán de tu vista',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de fila de estadística
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

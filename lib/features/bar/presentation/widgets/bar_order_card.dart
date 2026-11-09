import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/utils/prep_time_calculator.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';
import 'package:sistema_eve/features/kitchen/presentation/widgets/timer_badge.dart';
import 'package:sistema_eve/features/kitchen/presentation/widgets/section_status_chip.dart';
import 'package:sistema_eve/features/bar/providers/bar_providers.dart';

/// Card de orden para vista de BARRA
/// Solo muestra items de sección "bar"
/// Tema púrpura para distinguirla de cocina
class BarOrderCard extends ConsumerWidget {
  final OrderModel order;

  const BarOrderCard({super.key, required this.order});

  /// Obtiene solo los items de bar de la orden
  List<OrderItem> get barItems =>
      order.items.where((item) => item.section == 'bar').toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = DateTime.now().difference(
      order.status == OrderStatus.preparing
          ? (order.timestamps.preparing ?? order.timestamps.created)
          : order.timestamps.created,
    );

    final minutes = elapsed.inMinutes;
    final isUrgent = minutes > 15;

    // Usar sectionStatus específico de BAR en lugar de order.status global
    final barStatus = order.sectionStatus['bar'] ?? 'pending';
    final isPending = barStatus == 'pending';
    final isPreparing = barStatus == 'preparing';

    // Color púrpura para barra
    const primaryColor = Color(0xFF9C27B0);
    const urgentColor = Color(0xFFF44336);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? urgentColor : primaryColor,
          width: isUrgent ? 3 : 2,
        ),
        gradient: isUrgent
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  urgentColor.withValues(alpha: 0.1),
                  urgentColor.withValues(alpha: 0.05),
                ],
              )
            : null,
      ),
      child: Material(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tipo de orden + Número + Timer
              Row(
                children: [
                  // Icono según tipo
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getOrderTypeColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getOrderTypeIcon(),
                      color: _getOrderTypeColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Mesa/Takeout + Número de orden
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getOrderTitle(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${order.orderNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timer
                  UrgentTimerBadge(elapsed: elapsed),
                ],
              ),

              const SizedBox(height: 12),

              // Mesero
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mesero: ${order.createdByName}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Estado de la sección, legible de un vistazo (NUEVO)
              SectionStatusChip(status: barStatus, color: primaryColor),

              const SizedBox(height: 16),

              // Divider púrpura
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.5),
                      primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Items de bar SOLAMENTE
              _BarItemsList(items: barItems),

              const SizedBox(height: 16),

              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.1),
                      primaryColor.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tiempo estimado
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Tiempo estimado: ~${_getEstimatedTime()} min',
                    style: const TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Botones de acción
              if (isPending)
                _BarStartPreparingButton(orderId: order.id)
              else if (isPreparing)
                _BarMarkReadyButton(orderId: order.id),
            ],
          ),
        ),
      ),
    );
  }

  String _getOrderTitle() {
    if (order.orderType == OrderType.dineIn && order.tableNumber != null) {
      return '🍺 Mesa ${order.tableNumber}';
    } else {
      return '🍺 Para Llevar';
    }
  }

  IconData _getOrderTypeIcon() {
    return order.orderType == OrderType.dineIn
        ? Icons.table_restaurant
        : Icons.shopping_bag;
  }

  Color _getOrderTypeColor() {
    return order.orderType == OrderType.dineIn
        ? const Color(0xFF2196F3)
        : const Color(0xFF4CAF50);
  }

  int _getEstimatedTime() {
    return PrepTimeCalculator.calculateEstimatedTime(barItems);
  }
}

/// Lista de items de bar
class _BarItemsList extends StatelessWidget {
  final List<OrderItem> items;

  const _BarItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => _BarItemRow(item: item)).toList(),
    );
  }
}

/// Fila de item de bar
class _BarItemRow extends StatelessWidget {
  final OrderItem item;

  const _BarItemRow({required this.item});

  bool get hasNotes => item.notes != null && item.notes!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    const barColor = Color(0xFF9C27B0);
    const warningColor = Color(0xFFFFC107);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: hasNotes ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: hasNotes
          ? BoxDecoration(
              color: warningColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: warningColor.withValues(alpha: 0.3),
                width: 1,
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cantidad GRANDE y prominente
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: barColor, width: 2),
            ),
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre con icono de alerta si tiene notas
                Row(
                  children: [
                    const Icon(Icons.local_bar, size: 20, color: barColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.menuItemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Badge ADICIONAL si es item nuevo
                    if (item.isNewAddition)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'ADICIONAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hasNotes)
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: warningColor,
                      ),
                  ],
                ),

                // Notas destacadas
                if (hasNotes) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: warningColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: warningColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: warningColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '⚠️ ${item.notes!.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: warningColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón para iniciar preparación (Barra)
class _BarStartPreparingButton extends ConsumerWidget {
  final String orderId;

  const _BarStartPreparingButton({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            HapticFeedback.mediumImpact();
            await ref.read(barActionsProvider).startPreparing(orderId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Bebida en preparación'),
                    ],
                  ),
                  backgroundColor: Color(0xFF9C27B0),
                  duration: Duration(seconds: 2),
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
        },
        icon: const Icon(Icons.play_arrow, size: 24),
        label: const Text(
          'PREPARAR BEBIDA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

/// Botón para marcar como lista (Barra)
class _BarMarkReadyButton extends ConsumerWidget {
  final String orderId;

  const _BarMarkReadyButton({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            HapticFeedback.mediumImpact();
            await ref.read(barActionsProvider).markAsReady(orderId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('✅ Bebida lista - Mesero notificado'),
                    ],
                  ),
                  backgroundColor: Color(0xFF4CAF50),
                  duration: Duration(seconds: 3),
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
        },
        icon: const Icon(Icons.check_circle, size: 24),
        label: const Text(
          'MARCAR LISTA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

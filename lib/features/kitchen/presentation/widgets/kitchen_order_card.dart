import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/utils/prep_time_calculator.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';
import 'package:pos_restaurante/features/kitchen/presentation/widgets/timer_badge.dart';
import 'package:pos_restaurante/features/kitchen/presentation/widgets/section_status_chip.dart';
import 'package:pos_restaurante/features/kitchen/presentation/widgets/order_items_list.dart';
import 'package:pos_restaurante/features/kitchen/providers/kitchen_providers.dart';

/// Card de orden optimizada para vista de cocina
/// - Timer prominente
/// - Sin precios
/// - Modificadores destacados
/// - Botones de acción según estado
class KitchenOrderCard extends ConsumerWidget {
  final OrderModel order;

  const KitchenOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = DateTime.now().difference(
      order.status == OrderStatus.preparing
          ? (order.timestamps.preparing ?? order.timestamps.created)
          : order.timestamps.created,
    );

    final minutes = elapsed.inMinutes;
    final isUrgent = minutes > 15;

    // Usar sectionStatus específico de COMBI en lugar de order.status global
    final combiStatus = order.sectionStatus['combi'] ?? 'pending';
    final isPending = combiStatus == 'pending';
    final isPreparing = combiStatus == 'preparing';

    // Si no hay items de combi en esta orden, no mostrar el card
    final combiItems = order.items.where((i) => i.section == 'combi').toList();
    if (combiItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFF44336) // Rojo urgente
              : const Color(0xFFFF9800), // Naranja normal
          width: isUrgent ? 3 : 2,
        ),
        // Gradient sutil si es urgente
        gradient: isUrgent
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF44336).withValues(alpha: 0.1),
                  const Color(0xFFF44336).withValues(alpha: 0.05),
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
              // Header: Tipo de orden + Número + Timer + Indicador NUEVO
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
                        Row(
                          children: [
                            Text(
                              _getOrderTitle(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            // Indicador NUEVO si la orden tiene menos de 30 segundos
                            if (minutes < 1) ...[
                              const SizedBox(width: 8),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.8, end: 1.0),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '¡NUEVO!',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
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
              SectionStatusChip(
                status: combiStatus,
                color: isPending
                    ? const Color(0xFFFFC107)
                    : const Color(0xFFFF9800),
              ),

              const SizedBox(height: 16),

              // Divider
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9800).withValues(alpha: 0.5),
                      const Color(0xFFFF9800).withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Items de la orden (solo combi)
              OrderItemsList(
                items: order.items.where((i) => i.section == 'combi').toList(),
              ),

              const SizedBox(height: 16),

              // Divider
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9800).withValues(alpha: 0.1),
                      const Color(0xFFFF9800).withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tiempo estimado
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 18,
                    color: Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tiempo estimado: ~${_getEstimatedTime()} min',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Botones de acción
              if (isPending)
                _StartPreparingButton(orderId: order.id)
              else if (isPreparing)
                _MarkReadyButton(orderId: order.id),
            ],
          ),
        ),
      ),
    );
  }

  String _getOrderTitle() {
    if (order.orderType == OrderType.dineIn && order.tableNumber != null) {
      return '🍽️ Mesa ${order.tableNumber}';
    } else {
      return '🛍️ Para Llevar';
    }
  }

  IconData _getOrderTypeIcon() {
    return order.orderType == OrderType.dineIn
        ? Icons.table_restaurant
        : Icons.shopping_bag;
  }

  Color _getOrderTypeColor() {
    return order.orderType == OrderType.dineIn
        ? const Color(0xFF2196F3) // Azul
        : const Color(0xFF4CAF50); // Verde
  }

  int _getEstimatedTime() {
    // Usar calculadora dinámica que considera cantidades
    return PrepTimeCalculator.calculateEstimatedTime(order.items);
  }
}

/// Botón para iniciar preparación
class _StartPreparingButton extends ConsumerWidget {
  final String orderId;

  const _StartPreparingButton({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            // Vibración háptica
            HapticFeedback.mediumImpact();

            // Iniciar preparación
            await ref.read(kitchenActionsProvider).startPreparing(orderId);

            // Mostrar confirmación
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Orden en preparación'),
                    ],
                  ),
                  backgroundColor: Color(0xFF4CAF50),
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
          'INICIAR PREPARACIÓN',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9800),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

/// Botón para marcar como lista
class _MarkReadyButton extends ConsumerWidget {
  final String orderId;

  const _MarkReadyButton({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            // Vibración háptica
            HapticFeedback.mediumImpact();

            // Marcar como lista
            await ref.read(kitchenActionsProvider).markAsReady(orderId);

            // Mostrar confirmación
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('✅ Orden lista - Mesero notificado'),
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

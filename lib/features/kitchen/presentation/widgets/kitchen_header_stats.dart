import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/features/kitchen/providers/kitchen_providers.dart';

/// Header con estadísticas de cocina
/// Muestra contadores de órdenes pendientes y en preparación
class KitchenHeaderStats extends ConsumerWidget {
  const KitchenHeaderStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingOrdersCountProvider);
    final preparingCount = ref.watch(preparingOrdersCountProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Órdenes pendientes
          Expanded(
            child: _StatCard(
              icon: Icons.pending_actions,
              iconColor: const Color(0xFFFFC107), // Amarillo
              label: 'Pendientes',
              count: pendingCount,
              backgroundColor: const Color(0xFFFFC107).withValues(alpha: 0.1),
            ),
          ),

          const SizedBox(width: 12),

          // Órdenes en preparación
          Expanded(
            child: _StatCard(
              icon: Icons.soup_kitchen,
              iconColor: const Color(0xFFFF9800), // Naranja
              label: 'En Preparación',
              count: preparingCount,
              backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final Color backgroundColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: iconColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

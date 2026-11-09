import 'package:flutter/material.dart';

/// Chip de estado de una sección de orden (cocina / bar).
///
/// Muestra con icono + texto si la sección está pendiente, en preparación
/// o lista. Lo usan KitchenOrderCard y BarOrderCard para que el estado se
/// lea de un vistazo, junto al TimerBadge que ya mostraba el tiempo.
/// El color lo pasa el padre (naranja cocina, púrpura bar) para no cambiar
/// la identidad visual de cada rol.
class SectionStatusChip extends StatelessWidget {
  final String status; // 'pending' | 'preparing' | 'ready'
  final Color color;

  const SectionStatusChip({
    super.key,
    required this.status,
    required this.color,
  });

  String get _label {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'preparing':
        return 'En preparación';
      case 'ready':
        return 'Lista';
      default:
        return status;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top;
      case 'preparing':
        return Icons.soup_kitchen;
      case 'ready':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

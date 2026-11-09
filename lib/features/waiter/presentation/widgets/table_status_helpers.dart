import 'package:flutter/material.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';

/// Helpers de presentación para los estados de mesa y de orden.
///
/// Viven en un solo archivo para que la tarjeta de mesa, su diálogo de
/// detalle y la leyenda de estados usen siempre el mismo icono, color y
/// texto. La paleta no cambia: se reutilizan AppColors y los grises de
/// Material. No hay lógica de datos aquí.

/// Icono para el estado de una orden.
IconData getOrderStatusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.hourglass_empty;
    case OrderStatus.preparing:
      return Icons.restaurant;
    case OrderStatus.ready:
      return Icons.check_circle;
    case OrderStatus.delivered:
      return Icons.room_service;
    case OrderStatus.pendingPayment:
      return Icons.payment;
    case OrderStatus.paid:
      return Icons.done_all;
    case OrderStatus.cancelled:
      return Icons.cancel_outlined;
  }
}

/// Color para el estado de una orden.
/// Cancelada: gris apagado, para que no compita con los estados activos.
Color getOrderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return AppColors.warning;
    case OrderStatus.preparing:
      return AppColors.info;
    case OrderStatus.ready:
      return AppColors.success;
    case OrderStatus.delivered:
      return AppColors.waiterPrimary;
    case OrderStatus.pendingPayment:
      return Colors.orange.shade700;
    case OrderStatus.paid:
      return const Color(0xFF4CAF50); // Verde intenso para indicar éxito
    case OrderStatus.cancelled:
      return Colors.grey.shade500;
  }
}

/// Texto para el estado de una orden.
String getOrderStatusText(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pendiente';
    case OrderStatus.preparing:
      return 'En Cocina';
    case OrderStatus.ready:
      return 'Lista';
    case OrderStatus.delivered:
      return 'Servida';
    case OrderStatus.pendingPayment:
      return 'En Caja';
    case OrderStatus.paid:
      return 'Pagada';
    case OrderStatus.cancelled:
      return 'Cancelada';
  }
}

/// Color para el estado de una mesa ('available', 'occupied', ...).
Color getTableStatusColor(String status) {
  switch (status) {
    case 'available':
      return AppColors.success;
    case 'occupied':
      return AppColors.error;
    case 'reserved':
      return AppColors.warning;
    case 'cleaning':
      return AppColors.info;
    default:
      return Colors.grey;
  }
}

/// Icono para el estado de una mesa.
IconData getTableStatusIcon(String status) {
  switch (status) {
    case 'available':
      return Icons.check_circle;
    case 'occupied':
      return Icons.restaurant_menu;
    case 'reserved':
      return Icons.event_seat;
    case 'cleaning':
      return Icons.cleaning_services;
    default:
      return Icons.help;
  }
}

/// Texto para el estado de una mesa.
String getTableStatusText(String status) {
  switch (status) {
    case 'available':
      return 'Disponible';
    case 'occupied':
      return 'Ocupada';
    case 'reserved':
      return 'Reservada';
    case 'cleaning':
      return 'Limpieza';
    default:
      return status;
  }
}

/// Color del tiempo transcurrido de una orden (verde < 15 min,
/// ámbar < 30 min, rojo a partir de 30 min).
Color getOrderTimeColor(int minutes) {
  if (minutes < 15) return AppColors.success;
  if (minutes < 30) return AppColors.warning;
  return AppColors.error;
}

/// Texto corto del tiempo transcurrido ('Hace 5 min', 'Hace 1 h 20 min').
String formatElapsedTime(Duration elapsed) {
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes % 60;

  if (hours > 0) {
    return 'Hace $hours h $minutes min';
  } else {
    return 'Hace $minutes min';
  }
}

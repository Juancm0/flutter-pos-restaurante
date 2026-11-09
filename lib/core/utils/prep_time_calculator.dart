import 'package:sistema_eve/features/waiter/data/models/order_model.dart';

/// Calculadora de tiempo estimado de preparación
/// Considera cantidad de items usando multiplicador simple
class PrepTimeCalculator {
  /// Factor de tiempo adicional por item extra (30%)
  static const double _additionalItemFactor = 0.3;

  /// Calcular tiempo estimado de preparación para una orden
  ///
  /// Lógica:
  /// - Items se preparan en paralelo (toma el máximo)
  /// - Por cada item adicional del mismo tipo: +30% del tiempo base
  ///
  /// Ejemplo:
  /// - 1 papas (15 min) → 15 min
  /// - 3 papas (15 min) → 15 + (2 × 15 × 0.3) = 24 min
  /// - 5 papas (15 min) → 15 + (4 × 15 × 0.3) = 33 min
  static int calculateEstimatedTime(List<OrderItem> items) {
    if (items.isEmpty) return 10;

    int maxTime = 0;

    for (final item in items) {
      final int baseTime = item.prepTime;
      final int quantity = item.quantity;

      // Calcular tiempo considerando cantidad
      int itemTime = baseTime;

      if (quantity > 1) {
        // Por cada item adicional: +30% del tiempo base
        final int additionalTime =
            ((quantity - 1) * baseTime * _additionalItemFactor).round();
        itemTime = baseTime + additionalTime;
      }

      // Tomar el máximo (items diferentes se preparan en paralelo)
      if (itemTime > maxTime) {
        maxTime = itemTime;
      }
    }

    return maxTime;
  }

  /// Calcular tiempo para un item individual
  /// Útil para preview antes de agregar a orden
  static int calculateItemTime(int baseTime, int quantity) {
    if (quantity <= 1) return baseTime;

    final int additionalTime =
        ((quantity - 1) * baseTime * _additionalItemFactor).round();
    return baseTime + additionalTime;
  }
}

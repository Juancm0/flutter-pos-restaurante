import 'package:flutter/material.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';

/// Lista de items de una orden optimizada para vista de cocina
/// - Sin precios
/// - Modificadores destacados
/// - Notas especiales resaltadas
class OrderItemsList extends StatelessWidget {
  final List<OrderItem> items;
  final bool showCheckboxes;

  const OrderItemsList({
    super.key,
    required this.items,
    this.showCheckboxes = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _OrderItemCard(item: items[i], showCheckbox: showCheckboxes),
          if (i < items.length - 1) const Divider(height: 16),
        ],
      ],
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderItem item;
  final bool showCheckbox;

  const _OrderItemCard({required this.item, this.showCheckbox = false});

  bool get hasNotes => item.notes != null && item.notes!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: hasNotes ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: hasNotes
          ? BoxDecoration(
              color: const Color(0xFFFFC107).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                width: 1,
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox opcional (para marcar items completos)
          if (showCheckbox)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: Checkbox(
                value: false,
                onChanged: (value) {
                  // TODO: Implementar lógica de marcar item completo
                },
                activeColor: AppColors.success,
              ),
            ),

          // Cantidad GRANDE y prominente
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF9800), width: 2),
            ),
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
          ),

          // Contenido del item
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del item (con icono de alerta si tiene notas)
                Row(
                  children: [
                    // Emoji según categoría
                    Text(
                      _getCategoryEmoji(item.menuItemName),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),

                    // Nombre
                    Expanded(
                      child: Text(
                        item.menuItemName,
                        style: const TextStyle(
                          fontSize: 18,
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

                    // Icono de alerta si tiene notas
                    if (hasNotes)
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 22,
                        color: Color(0xFFFFC107),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Modificadores seleccionados
                if (item.selectedModifiers.isNotEmpty) ...[
                  for (final modifier in item.selectedModifiers)
                    Padding(
                      padding: const EdgeInsets.only(left: 0, bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bolt,
                            size: 16,
                            color: Color(0xFFFF9800), // Naranja
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${modifier.modifierName}: ${modifier.optionName}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // Notas especiales (DESTACADAS)
                if (hasNotes) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFC107),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '⚠️ ${item.notes!.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFC107),
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

  /// Obtener emoji según el nombre del item
  String _getCategoryEmoji(String itemName) {
    final name = itemName.toLowerCase();

    if (name.contains('hamburguesa') || name.contains('burger')) {
      return '🍔';
    } else if (name.contains('papas') || name.contains('fries')) {
      return '🍟';
    } else if (name.contains('refresco') ||
        name.contains('coca') ||
        name.contains('bebida')) {
      return '🥤';
    } else if (name.contains('ensalada') || name.contains('salad')) {
      return '🥗';
    } else if (name.contains('pollo') || name.contains('chicken')) {
      return '🍗';
    } else if (name.contains('pizza')) {
      return '🍕';
    } else if (name.contains('taco')) {
      return '🌮';
    } else if (name.contains('burrito')) {
      return '🌯';
    } else if (name.contains('postre') ||
        name.contains('pastel') ||
        name.contains('helado')) {
      return '🍰';
    } else if (name.contains('café') || name.contains('coffee')) {
      return '☕';
    } else if (name.contains('cerveza') || name.contains('beer')) {
      return '🍺';
    } else {
      return '🍽️';
    }
  }
}

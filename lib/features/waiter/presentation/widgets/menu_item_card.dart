import 'package:flutter/material.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/features/waiter/data/models/menu_item_model.dart';

/// Tarjeta de un producto del menú en la pantalla de crear orden.
///
/// Extraída de CreateOrderScreen sin cambiar su aspecto ni su
/// comportamiento: al tocarla se abre el bottom sheet para agregar el
/// item (lo decide el padre mediante [onTap]).
class MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onTap;

  const MenuItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.darkSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Info del item
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de sección + Nombre
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.section.name == 'bar'
                                ? Colors.purple.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.section.name == 'bar'
                                  ? Colors.purple.withValues(alpha: 0.5)
                                  : Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            item.section.name == 'bar'
                                ? Icons.local_bar
                                : Icons.restaurant,
                            size: 12,
                            color: item.section.name == 'bar'
                                ? Colors.purple
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Descripción
                    if (item.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Precio y tiempo
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.preparationTime}min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Icono agregar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.success,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

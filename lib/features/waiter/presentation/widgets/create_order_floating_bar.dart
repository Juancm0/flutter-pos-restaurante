import 'package:flutter/material.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';

/// Barra inferior flotante con el resumen de la orden en curso.
///
/// Extraída de CreateOrderScreen sin cambiar su aspecto: contador de
/// items, total y botón VER. Tocar cualquier parte abre el resumen
/// completo (lo decide el padre mediante [onTap]). El botón VER sigue
/// siendo un contenedor decorativo dentro del InkWell — convertirlo en
/// un botón real duplicaría la apertura del resumen —, por eso no usa
/// AppButton aquí.
class CreateOrderFloatingBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onTap;

  const CreateOrderFloatingBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.2),
                  AppColors.success.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Contador de items
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Total (expandible para evitar overflow)
                Expanded(
                  child: Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Botón Ver Orden (compacto)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'VER',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

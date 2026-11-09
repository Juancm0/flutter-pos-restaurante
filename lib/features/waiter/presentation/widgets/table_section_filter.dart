import 'package:flutter/material.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/app_sizes.dart';
import 'package:sistema_eve/core/constants/sections.dart';
import 'package:sistema_eve/features/waiter/presentation/widgets/table_status_helpers.dart';

/// Icono de una sección de mesas (Combi / Bar).
IconData getSectionIcon(Section section) {
  switch (section) {
    case Section.combi:
      return Icons.restaurant;
    case Section.bar:
      return Icons.local_bar;
  }
}

/// Filtro horizontal por sección de mesas (Todas / Bar / Combi).
///
/// Extraído de TableGridWidget sin cambiar su comportamiento: `null`
/// significa "todas las secciones". El estado seleccionado lo sigue
/// guardando el widget padre.
class TableSectionFilter extends StatelessWidget {
  final Section? selectedSection;
  final ValueChanged<Section?> onSectionSelected;

  const TableSectionFilter({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.darkBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Sección: ',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Todas',
              icon: Icons.apps,
              isSelected: selectedSection == null,
              color: Colors.grey,
              onTap: () => onSectionSelected(null),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Bar',
              icon: Icons.local_bar,
              isSelected: selectedSection == Section.bar,
              color: Colors.purple,
              onTap: () => onSectionSelected(Section.bar),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Combi',
              icon: Icons.restaurant,
              isSelected: selectedSection == Section.combi,
              color: Colors.orange,
              onTap: () => onSectionSelected(Section.combi),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade600,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Leyenda compacta de los estados de mesa (NUEVO, solo visual).
///
/// Va debajo del filtro para que el mesero lea de un vistazo qué significa
/// cada color de tarjeta. Usa los mismos colores y textos que la tarjeta.
class TableStatusLegend extends StatelessWidget {
  const TableStatusLegend({super.key});

  static const _statuses = ['available', 'occupied', 'reserved', 'cleaning'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing8,
      ),
      color: AppColors.darkBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < _statuses.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSizes.spacing16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: getTableStatusColor(_statuses[i]),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    getTableStatusText(_statuses[i]),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

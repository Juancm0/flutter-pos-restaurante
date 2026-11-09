import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/app_sizes.dart';
import 'package:pos_restaurante/core/constants/sections.dart';
import 'package:pos_restaurante/features/admin/data/models/table_model.dart';
import 'package:pos_restaurante/features/admin/providers/table_providers.dart';
import 'package:pos_restaurante/features/waiter/presentation/widgets/table_card.dart';
import 'package:pos_restaurante/features/waiter/presentation/widgets/table_section_filter.dart';

/// Widget que muestra todas las mesas en layout de cards
/// Con filtro por sección (Todos/Bar/Combi)
class TableGridWidget extends ConsumerStatefulWidget {
  const TableGridWidget({super.key});

  @override
  ConsumerState<TableGridWidget> createState() => _TableGridWidgetState();
}

class _TableGridWidgetState extends ConsumerState<TableGridWidget> {
  Section? _selectedSection; // null = todas

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesStreamProvider);

    return tablesAsync.when(
      data: (tables) {
        if (tables.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay mesas configuradas',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Filtrar mesas por sección activa
        final activeTables = tables.where((t) => t.isActive).toList();
        final filteredTables = _selectedSection == null
            ? activeTables
            : activeTables.where((t) => t.section == _selectedSection).toList();

        // Agrupar mesas por sección
        final mesasPorSection = <Section, List<TableModel>>{};
        for (final table in filteredTables) {
          mesasPorSection.putIfAbsent(table.section, () => []).add(table);
        }

        return Column(
          children: [
            // Filtro por sección + leyenda de estados de mesa
            TableSectionFilter(
              selectedSection: _selectedSection,
              onSectionSelected: (section) =>
                  setState(() => _selectedSection = section),
            ),
            const TableStatusLegend(),

            // Lista de mesas
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: mesasPorSection.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay mesas en ${_selectedSection?.displayName ?? "esta sección"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.spacing16),
                        itemCount: mesasPorSection.length,
                        itemBuilder: (context, index) {
                          final section = mesasPorSection.keys.elementAt(index);
                          final sectionTables = mesasPorSection[section]!;
                          sectionTables.sort(
                            (a, b) => a.tableNumber.compareTo(b.tableNumber),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título de zona
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSizes.spacing8,
                                  top: AppSizes.spacing8,
                                  bottom: AppSizes.spacing12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      getSectionIcon(section),
                                      color: AppColors.waiterPrimary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      section.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.waiterPrimary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${sectionTables.length} mesas',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.waiterPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Lista de mesas como cards
                              ...sectionTables.map(
                                (table) => TableCard(table: table),
                              ),
                              const SizedBox(height: AppSizes.spacing16),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error al cargar mesas: $error'),
          ],
        ),
      ),
    );
  }
}

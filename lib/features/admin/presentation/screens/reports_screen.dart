import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/sections.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/admin_drawer.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/period_selector.dart';
import 'package:sistema_eve/features/admin/providers/reports_providers.dart';
import 'package:sistema_eve/features/admin/utils/report_pdf_generator.dart';
import 'package:sistema_eve/features/admin/utils/report_csv_generator.dart';

/// Pantalla de reportes del administrador
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportPeriod _selectedPeriod = ReportPeriod.today;
  DateRange _dateRange = DateRange.today();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPeriodChanged(ReportPeriod period) {
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case ReportPeriod.today:
          _dateRange = DateRange.today();
          break;
        case ReportPeriod.week:
          _dateRange = DateRange.week();
          break;
        case ReportPeriod.month:
          _dateRange = DateRange.month();
          break;
        case ReportPeriod.custom:
          // Handled by onCustomRange
          break;
      }
    });
  }

  void _onCustomRange(DateRange range) {
    setState(() {
      _selectedPeriod = ReportPeriod.custom;
      _dateRange = range;
    });
  }

  Future<void> _exportToPDF() async {
    try {
      final currentTab = _tabController.index;

      switch (currentTab) {
        case 0: // Resumen
          final salesMetrics = ref.read(salesMetricsProvider(_dateRange));
          await salesMetrics.when(
            data: (metrics) async {
              await ReportPDFGenerator.generateSalesReport(
                dateRange: _dateRange,
                metrics: metrics,
              );
            },
            loading: () async {},
            error: (_, _) async {},
          );
          break;

        case 1: // Ingredientes
          final ingredientsData = ref.read(
            ingredientsUsageProvider(_dateRange),
          );
          await ingredientsData.when(
            data: (ingredients) async {
              if (ingredients.isNotEmpty) {
                await ReportPDFGenerator.generateIngredientsReport(
                  dateRange: _dateRange,
                  ingredients: ingredients,
                );
              }
            },
            loading: () async {},
            error: (_, _) async {},
          );
          break;

        case 2: // Items Menú
          final menuItemsData = ref.read(menuItemsSalesProvider(_dateRange));
          await menuItemsData.when(
            data: (items) async {
              if (items.isNotEmpty) {
                await ReportPDFGenerator.generateMenuItemsReport(
                  dateRange: _dateRange,
                  items: items,
                );
              }
            },
            loading: () async {},
            error: (_, _) async {},
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Exporta la pestaña actual a CSV (mismas columnas/datos que el PDF)
  /// y abre la hoja de compartir del sistema.
  Future<void> _exportToCSV() async {
    try {
      final currentTab = _tabController.index;

      switch (currentTab) {
        case 0: // Resumen
          final salesMetrics = ref.read(salesMetricsProvider(_dateRange));
          await salesMetrics.when(
            data: (metrics) async {
              await ReportCSVGenerator.shareSalesReport(
                dateRange: _dateRange,
                metrics: metrics,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV de ventas listo para compartir'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            loading: () async {},
            error: (_, _) async {},
          );
          break;

        case 1: // Ingredientes
          final ingredientsData = ref.read(
            ingredientsUsageProvider(_dateRange),
          );
          await ingredientsData.when(
            data: (ingredients) async {
              if (ingredients.isNotEmpty) {
                await ReportCSVGenerator.shareIngredientsReport(
                  dateRange: _dateRange,
                  ingredients: ingredients,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CSV de ingredientes listo para compartir'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            loading: () async {},
            error: (_, _) async {},
          );
          break;

        case 2: // Items Menú
          final menuItemsData = ref.read(menuItemsSalesProvider(_dateRange));
          await menuItemsData.when(
            data: (items) async {
              if (items.isNotEmpty) {
                await ReportCSVGenerator.shareMenuItemsReport(
                  dateRange: _dateRange,
                  items: items,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'CSV de items del menú listo para compartir',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            loading: () async {},
            error: (_, _) async {},
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(currentRoute: 'reports'),
      appBar: AppBar(
        title: const Text('📈 Reportes'),
        backgroundColor: AppColors.adminPrimary,
        actions: [
          // PDF Export button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportToPDF(),
            tooltip: 'Exportar a PDF',
          ),
          // CSV Export button
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () => _exportToCSV(),
            tooltip: 'Exportar a CSV',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Resumen'),
            Tab(icon: Icon(Icons.restaurant), text: 'Ingredientes'),
            Tab(icon: Icon(Icons.menu_book), text: 'Items Menú'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period Selector
          Container(
            color: AppColors.darkSurface,
            child: Column(
              children: [
                PeriodSelector(
                  selectedPeriod: _selectedPeriod,
                  onPeriodChanged: _onPeriodChanged,
                  onCustomRange: _onCustomRange,
                ),

                // Section Filter
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Sección:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        _buildSectionChip(
                          label: 'Todas',
                          icon: Icons.all_inclusive,
                          isSelected:
                              ref.watch(reportsSectionFilterProvider) == null,
                          color: Colors.grey,
                          onTap: () =>
                              ref
                                      .read(
                                        reportsSectionFilterProvider.notifier,
                                      )
                                      .state =
                                  null,
                        ),
                        const SizedBox(width: 8),
                        _buildSectionChip(
                          label: Section.combi.displayName,
                          icon: Icons.restaurant,
                          isSelected:
                              ref.watch(reportsSectionFilterProvider) ==
                              Section.combi,
                          color: Colors.orange,
                          onTap: () =>
                              ref
                                  .read(reportsSectionFilterProvider.notifier)
                                  .state = Section
                                  .combi,
                        ),
                        const SizedBox(width: 8),
                        _buildSectionChip(
                          label: Section.bar.displayName,
                          icon: Icons.local_bar,
                          isSelected:
                              ref.watch(reportsSectionFilterProvider) ==
                              Section.bar,
                          color: Colors.purple,
                          onTap: () =>
                              ref
                                  .read(reportsSectionFilterProvider.notifier)
                                  .state = Section
                                  .bar,
                        ),
                      ],
                    ),
                  ),
                ),

                // Display selected range
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _dateRange.displayText,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildIngredientsTab(),
                _buildMenuItemsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final salesMetrics = ref.watch(salesMetricsProvider(_dateRange));

    return salesMetrics.when(
      data: (metrics) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Métricas principales
              const Text(
                'Métricas Principales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Real data from provider
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Ventas',
                      value: '\$${metrics.totalSales.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Órdenes',
                      value: '${metrics.totalOrders}',
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Ticket Promedio',
                      value: '\$${metrics.averageTicket.toStringAsFixed(2)}',
                      icon: Icons.analytics,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Propinas',
                      value: '\$${metrics.totalTips.toStringAsFixed(2)}',
                      icon: Icons.volunteer_activism,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsTab() {
    final ingredientsData = ref.watch(ingredientsUsageProvider(_dateRange));

    return ingredientsData.when(
      data: (ingredients) {
        if (ingredients.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 64,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay datos de ingredientes para este período',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los ingredientes se calculan a partir de las recetas\nconfiguradas en los items del menú',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con resumen
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.2),
                      Colors.orange.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          color: Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ingredients.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Ingredientes',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          color: Colors.blue,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Usados',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'En el período',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Text(
                'Ingredientes Consumidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Lista de ingredientes como cards
              ...ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ing = entry.value;
                final isTop3 = index < 3;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: isTop3
                        ? Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ing.ingredientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isTop3)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '⭐ Top ${index + 1} más usado',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Cantidad
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ing.quantityUsed.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            ing.unit,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    final menuItemsData = ref.watch(menuItemsSalesProvider(_dateRange));

    return menuItemsData.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No hay datos de ventas para este período',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Calcular total de revenue para el badge superior
        final totalRevenue = items.fold<double>(
          0,
          (sum, item) => sum + item.revenue,
        );
        final totalQuantity = items.fold<int>(
          0,
          (sum, item) => sum + item.quantitySold,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con total
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.adminPrimary.withValues(alpha: 0.2),
                      AppColors.adminPrimary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.adminPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.menu_book,
                          color: AppColors.adminPrimary,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${items.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Productos',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalQuantity',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Vendidos',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          color: Colors.orange,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${totalRevenue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Ingresos',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Text(
                'Items Más Vendidos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Lista de items como cards
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final rankColor = index == 0
                    ? Colors.amber
                    : index == 1
                    ? Colors.grey.shade400
                    : index == 2
                    ? Colors.orange.shade700
                    : AppColors.adminPrimary;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: index < 3
                        ? Border.all(
                            color: rankColor.withValues(alpha: 0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Ranking badge
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rankColor, width: 2),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Item info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_bag,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.quantitySold} vendidos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Progress bar para porcentaje
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.percentage / 100,
                                backgroundColor: Colors.grey.shade800,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  rankColor,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.percentage.toStringAsFixed(1)}% del total',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Revenue
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${item.revenue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'ingreso',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_routes.dart';
import 'package:sistema_eve/core/constants/sections.dart';
import 'package:sistema_eve/core/utils/business_day.dart';
import 'package:sistema_eve/features/auth/providers/auth_providers.dart';
import 'package:sistema_eve/features/cashier/providers/cashier_providers.dart';
import 'package:sistema_eve/features/cashier/presentation/widgets/paid_orders_tab.dart';
import 'package:sistema_eve/features/cashier/presentation/widgets/pending_payments_tab.dart';
import 'package:sistema_eve/features/cashier/presentation/widgets/cash_cut_dialog.dart';

/// Dashboard de Caja
/// Funcionalidades:
/// - Ver órdenes pendientes de confirmación
/// - Ver órdenes pagadas del día
/// - Confirmar pagos
/// - Procesar pagos de takeout
class CashierDashboard extends ConsumerStatefulWidget {
  const CashierDashboard({super.key});

  @override
  ConsumerState<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends ConsumerState<CashierDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Cargar último corte del cajero actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastCashCut();
    });
  }

  Future<void> _loadLastCashCut() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      final lastCut = await ref.read(loadLastCashCutProvider(user.id).future);
      ref.read(lastCashCutTimeProvider.notifier).state = lastCut;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    await ref.read(loginProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(currentUserProvider);

    return userData.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF4CAF50),
            title: Row(
              children: [
                const Icon(Icons.point_of_sale, size: 24, color: Colors.white),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caja',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Badge de pagos pendientes
              Consumer(
                builder: (context, ref, child) {
                  final pendingCount = ref.watch(pendingPaymentsCountProvider);
                  if (pendingCount == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pending,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingCount',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _handleLogout,
                tooltip: 'Cerrar sesión',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.pending_actions), text: 'Pendientes'),
                Tab(icon: Icon(Icons.check_circle), text: 'Pagados Hoy'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Selector de sección
              _buildSectionSelector(context, ref),

              // Tabs content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [PendingPaymentsTab(), PaidOrdersTab()],
                ),
              ),
            ],
          ),
          floatingActionButton: Consumer(
            builder: (context, ref, child) {
              final paidOrders = ref.watch(paidOrdersTodayProvider);
              final lastCutTime = ref.watch(lastCashCutTimeProvider);

              return paidOrders.when(
                data: (orders) {
                  // Filtrar órdenes desde el último corte
                  final shiftStartTime = lastCutTime ?? getBusinessDayStart();
                  final ordersInShift = orders.where((o) {
                    final paidTime = o.timestamps.paid ?? o.timestamps.created;
                    return paidTime.isAfter(shiftStartTime);
                  }).toList();

                  if (ordersInShift.isEmpty) return const SizedBox.shrink();

                  return FloatingActionButton.extended(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => CashCutDialog(
                          orders: ordersInShift,
                          shiftStartTime: shiftStartTime,
                        ),
                      );

                      // Si se confirmó el corte, recargar
                      if (result == true) {
                        ref.invalidate(paidOrdersTodayProvider);
                      }
                    },
                    backgroundColor: Colors.green,
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: Text(
                      'Corte (${ordersInShift.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleLogout,
                child: const Text('Volver al login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para seleccionar sección (Combi/Bar/Todas)
  Widget _buildSectionSelector(BuildContext context, WidgetRef ref) {
    final selectedSection = ref.watch(cashierSectionFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2D2D2D),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.filter_list, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Filtrar:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(width: 12),
            // Botón Todas
            _buildFilterChip(
              label: 'Todas',
              icon: Icons.all_inclusive,
              isSelected: selectedSection == null,
              color: Colors.grey,
              onTap: () =>
                  ref.read(cashierSectionFilterProvider.notifier).state = null,
            ),
            const SizedBox(width: 8),
            // Botón Combi
            _buildFilterChip(
              label: Section.combi.displayName,
              icon: Icons.restaurant,
              isSelected: selectedSection == Section.combi,
              color: Colors.orange,
              onTap: () =>
                  ref.read(cashierSectionFilterProvider.notifier).state =
                      Section.combi,
            ),
            const SizedBox(width: 8),
            // Botón Bar
            _buildFilterChip(
              label: Section.bar.displayName,
              icon: Icons.local_bar,
              isSelected: selectedSection == Section.bar,
              color: Colors.purple,
              onTap: () =>
                  ref.read(cashierSectionFilterProvider.notifier).state =
                      Section.bar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/app_routes.dart';
import 'package:pos_restaurante/features/auth/providers/auth_providers.dart';
import 'package:pos_restaurante/features/bar/providers/bar_providers.dart';
import 'package:pos_restaurante/features/bar/presentation/widgets/bar_order_card.dart';

/// Dashboard de Barra
/// Solo muestra items de sección "bar"
/// Tema púrpura para distinguirla de cocina
class BarDashboard extends ConsumerStatefulWidget {
  const BarDashboard({super.key});

  @override
  ConsumerState<BarDashboard> createState() => _BarDashboardState();
}

class _BarDashboardState extends ConsumerState<BarDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Refresh UI cada minuto para actualizar timers
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
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
        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Barra',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.name ?? 'Usuario',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
            leading: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.local_bar, color: Colors.white, size: 28),
            ),
            backgroundColor: const Color(0xFF9C27B0), // Púrpura
            actions: [
              // Contador de pendientes
              Consumer(
                builder: (context, ref, child) {
                  final count = ref.watch(barPendingOrdersCountProvider);
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
              // Conteo en la pestaña (NUEVO, solo visual).
              tabs: [
                Tab(
                  icon: const Icon(Icons.hourglass_top),
                  text:
                      'Pendientes (${ref.watch(barPendingOrdersCountProvider)})',
                ),
                Tab(
                  icon: const Icon(Icons.local_drink),
                  text:
                      'En Preparación (${ref.watch(barPreparingOrdersCountProvider)})',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Header Stats
              _BarHeaderStats(),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [_BarPendingTab(), _BarPreparingTab()],
                ),
              ),
            ],
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
}

/// Stats de barra
class _BarHeaderStats extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(barPendingOrdersProvider);
    final preparingAsync = ref.watch(barPreparingOrdersProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.hourglass_top,
            label: 'Pendientes',
            value: pendingAsync.when(
              data: (orders) => orders.length,
              loading: () => 0,
              error: (_, _) => 0,
            ),
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.local_drink,
            label: 'En Preparación',
            value: preparingAsync.when(
              data: (orders) => orders.length,
              loading: () => 0,
              error: (_, _) => 0,
            ),
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab de órdenes pendientes de bar
class _BarPendingTab extends ConsumerWidget {
  const _BarPendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(barPendingOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin bebidas pendientes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Las nuevas órdenes de bar aparecerán aquí',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) => BarOrderCard(order: orders[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $error', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Tab de órdenes en preparación de bar
class _BarPreparingTab extends ConsumerWidget {
  const _BarPreparingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(barPreparingOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_drink_outlined,
                  size: 80,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin bebidas en preparación',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) => BarOrderCard(order: orders[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $error', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

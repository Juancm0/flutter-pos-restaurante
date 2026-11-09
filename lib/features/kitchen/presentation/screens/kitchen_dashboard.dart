import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/app_routes.dart';
import 'package:sistema_eve/features/auth/providers/auth_providers.dart';
import 'package:sistema_eve/features/kitchen/providers/kitchen_providers.dart';
import 'package:sistema_eve/features/kitchen/presentation/widgets/kitchen_header_stats.dart';
import 'package:sistema_eve/features/kitchen/presentation/widgets/kitchen_order_card.dart';
import 'package:sistema_eve/features/kitchen/services/kitchen_audio_service.dart';

/// Dashboard de Cocina
/// Funcionalidades:
/// - Ver órdenes pendientes (pending)
/// - Ver órdenes en preparación (preparing)
/// - Iniciar preparación
/// - Marcar como lista
class KitchenDashboard extends ConsumerStatefulWidget {
  const KitchenDashboard({super.key});

  @override
  ConsumerState<KitchenDashboard> createState() => _KitchenDashboardState();
}

class _KitchenDashboardState extends ConsumerState<KitchenDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _audioService = KitchenAudioService();
  Timer? _urgentAlertTimer;
  final Set<String> _notifiedNewOrders = {};
  final Set<String> _urgentOrders = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAudio();
    _setupOrderListeners();
    _startUrgentAlertTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urgentAlertTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  /// Inicializar servicio de audio
  Future<void> _initializeAudio() async {
    await _audioService.initialize();
  }

  /// Configurar listeners para nuevas órdenes y alertas urgentes
  void _setupOrderListeners() {
    // Listener para nuevas órdenes (pending)
    ref.listenManual(pendingOrdersProvider, (previous, next) {
      next.whenData((orders) {
        if (previous == null) return; // Primera carga, no notificar

        for (final order in orders) {
          if (!_notifiedNewOrders.contains(order.id)) {
            // Nueva orden detectada
            _audioService.playNewOrderSound();
            _notifiedNewOrders.add(order.id);
          }
        }
      });
    });
  }

  /// Timer para verificar órdenes urgentes cada 30 segundos
  void _startUrgentAlertTimer() {
    _urgentAlertTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkUrgentOrders(),
    );
  }

  /// Verificar y alertar sobre órdenes urgentes (>15 min)
  void _checkUrgentOrders() {
    final preparingOrdersAsync = ref.read(preparingOrdersProvider);

    preparingOrdersAsync.whenData((orders) {
      for (final order in orders) {
        final elapsed = DateTime.now().difference(
          order.timestamps.preparing ?? order.timestamps.created,
        );

        if (elapsed.inMinutes > 15) {
          // Orden urgente
          if (!_urgentOrders.contains(order.id)) {
            // Primera vez que se vuelve urgente
            _audioService.playUrgentAlertSound();
            _urgentOrders.add(order.id);
          } else {
            // Ya es urgente, solo vibrar (no sonido cada 30seg)
            _audioService.playUrgentAlertSound();
          }
        } else {
          // Si ya no es urgente, remover del set
          _urgentOrders.remove(order.id);
        }
      }
    });
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
            backgroundColor: const Color(0xFFFF9800),
            title: Row(
              children: [
                const Icon(Icons.soup_kitchen, size: 24, color: Colors.white),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cocina',
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
              // Badge de órdenes pendientes
              Consumer(
                builder: (context, ref, child) {
                  final pendingCount = ref.watch(pendingOrdersCountProvider);
                  if (pendingCount == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pending_actions,
                          size: 18,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingCount',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
              // Conteo en la pestaña (NUEVO, solo visual): cuántas órdenes
              // hay en cada estado sin entrar a la pestaña.
              tabs: [
                Tab(
                  icon: const Icon(Icons.pending_actions),
                  text: 'Pendientes (${ref.watch(pendingOrdersCountProvider)})',
                ),
                Tab(
                  icon: const Icon(Icons.soup_kitchen),
                  text:
                      'En Preparación (${ref.watch(preparingOrdersCountProvider)})',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Header con estadísticas
              const KitchenHeaderStats(),

              // Tabs content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    // Tab 1: Órdenes pendientes
                    _PendingOrdersTab(),

                    // Tab 2: Órdenes en preparación
                    _PreparingOrdersTab(),
                  ],
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

/// Tab de órdenes pendientes (solo combi)
class _PendingOrdersTab extends ConsumerWidget {
  const _PendingOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(filteredPendingOrdersProvider);

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
                  '¡Todo listo!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No hay platos pendientes de cocina',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // El stream se actualizará automáticamente
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return KitchenOrderCard(order: orders[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar órdenes',
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab de órdenes en preparación (solo combi)
class _PreparingOrdersTab extends ConsumerWidget {
  const _PreparingOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(filteredPreparingOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lunch_dining_outlined,
                  size: 80,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin platos en preparación',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia preparación desde la pestaña Pendientes',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // El stream se actualizará automáticamente
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return KitchenOrderCard(order: orders[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar órdenes',
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

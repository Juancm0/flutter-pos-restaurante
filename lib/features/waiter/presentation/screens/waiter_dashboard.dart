import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_routes.dart';
import 'package:pos_restaurante/features/auth/providers/auth_providers.dart';
import 'package:pos_restaurante/features/waiter/presentation/widgets/table_grid_widget.dart';
import 'package:pos_restaurante/features/waiter/presentation/widgets/my_orders_list_widget.dart';
import 'package:pos_restaurante/features/waiter/presentation/widgets/takeout_orders_widget.dart';
import 'package:pos_restaurante/features/waiter/services/notification_service.dart';
import 'package:pos_restaurante/features/waiter/providers/order_providers.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';

/// Dashboard del Mesero
class WaiterDashboard extends ConsumerStatefulWidget {
  const WaiterDashboard({super.key});

  @override
  ConsumerState<WaiterDashboard> createState() => _WaiterDashboardState();
}

class _WaiterDashboardState extends ConsumerState<WaiterDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _notificationService = NotificationService();
  final Set<String> _notifiedOrders = {}; // Track notified orders

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs ahora
    _initializeNotifications();
    _setupOrderListener();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  void _setupOrderListener() {
    // Listen to order changes
    ref.listenManual(myOrdersStreamProvider, (previous, next) {
      next.whenData((orders) {
        for (final order in orders) {
          // Notify only if order is ready and we haven't notified yet
          if (order.status == OrderStatus.ready &&
              !_notifiedOrders.contains(order.id)) {
            _notificationService.showOrderReadyNotification(order);
            _notifiedOrders.add(order.id);
          }
        }
      });
    });
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
            title: Row(
              children: [
                const Icon(Icons.restaurant_menu, size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mesero', style: TextStyle(fontSize: 18)),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _handleLogout,
                tooltip: 'Cerrar sesión',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.table_restaurant), text: 'Mesas'),
                Tab(icon: Icon(Icons.shopping_bag), text: 'Para Llevar'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Mis Órdenes'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              // Tab 1: Vista de mesas
              TableGridWidget(),
              // Tab 2: Órdenes para llevar
              TakeoutOrdersWidget(),
              // Tab 3: Mis órdenes activas (mesas)
              MyOrdersListWidget(),
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

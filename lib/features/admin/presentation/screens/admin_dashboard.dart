import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/app_routes.dart';
import 'package:sistema_eve/features/auth/providers/auth_providers.dart';
import 'package:sistema_eve/features/admin/presentation/screens/user_management_screen.dart';
import 'package:sistema_eve/features/admin/presentation/screens/menu_management_screen.dart';
import 'package:sistema_eve/features/admin/presentation/screens/inventory_management_screen.dart';
import 'package:sistema_eve/features/admin/presentation/screens/table_management_screen.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/admin_drawer.dart';

/// Dashboard del Administrador con tabs
class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          drawer: const AdminDrawer(currentRoute: 'dashboard'),
          appBar: AppBar(
            title: Text('Admin - ${user.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _handleLogout,
                tooltip: 'Cerrar Sesión',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.info,
              labelColor: AppColors.info,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.people), text: 'Usuarios'),
                Tab(icon: Icon(Icons.restaurant_menu), text: 'Menú'),
                Tab(icon: Icon(Icons.inventory_2), text: 'Inventario'),
                Tab(icon: Icon(Icons.table_restaurant), text: 'Mesas'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              UserManagementScreen(),
              MenuManagementScreen(),
              InventoryManagementScreen(),
              TableManagementScreen(),
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

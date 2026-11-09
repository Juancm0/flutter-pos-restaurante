import 'package:flutter/material.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/firebase_constants.dart';
import 'package:pos_restaurante/features/admin/presentation/widgets/data_cleanup_dialog.dart';

/// Drawer lateral para el dashboard del administrador
class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.darkSurface,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.adminPrimary,
                  AppColors.adminPrimary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Panel Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'POS Restaurante',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: 'dashboard',
                  isSelected: currentRoute == 'dashboard',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Reportes',
                  route: 'reports',
                  isSelected: currentRoute == 'reports',
                ),
                const Divider(color: Colors.grey, height: 32),
                _buildDrawerItem(
                  context,
                  icon: Icons.delete_sweep,
                  title: 'Limpieza de Datos',
                  route: 'cleanup',
                  isSelected: false,
                  isDestructive: true,
                ),
              ],
            ),
          ),

          // Footer
          const Divider(color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v${FirebaseConstants.appVersion}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? AppColors.error
        : (isSelected ? AppColors.adminPrimary : Colors.white);

    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.adminPrimary.withValues(alpha: 0.1),
      onTap: () {
        Navigator.pop(context); // Cerrar drawer

        if (isSelected) {
          // Ya estamos en esta ruta
          return;
        }

        if (route == 'dashboard') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (route == 'reports') {
          Navigator.pushReplacementNamed(context, '/admin/reports');
        } else if (route == 'cleanup') {
          _showCleanupDialog(context);
        }
      },
    );
  }

  void _showCleanupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DataCleanupDialog(),
    );
  }
}

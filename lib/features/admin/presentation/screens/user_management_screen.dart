import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/app_sizes.dart';
import 'package:sistema_eve/features/admin/providers/user_management_providers.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/user_form_dialog.dart';
import 'package:sistema_eve/features/auth/data/models/user_model.dart';

/// Screen para gestión de usuarios
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  /// Obtener color por rol
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.info;
      case UserRole.waiter:
        return AppColors.success;
      case UserRole.kitchen:
        return AppColors.warning;
      case UserRole.bar:
        return const Color(0xFF9C27B0); // Púrpura para bar
      case UserRole.cashier:
        return AppColors.success;
    }
  }

  /// Obtener texto del rol en español
  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.waiter:
        return 'Mesero';
      case UserRole.kitchen:
        return 'Cocina';
      case UserRole.bar:
        return 'Barra';
      case UserRole.cashier:
        return 'Cajero';
    }
  }

  void _showUserDialog(BuildContext context, {UserModel? user}) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  /// Mostrar diálogo de confirmación para eliminar usuario
  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    List<UserModel> allUsers,
  ) {
    // Verificar que no sea el último administrador
    final adminCount = allUsers.where((u) => u.role == UserRole.admin).length;
    if (user.role == UserRole.admin && adminCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No puedes eliminar el único administrador'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Eliminar Usuario',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que deseas eliminar este usuario?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 18, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(userManagementProvider.notifier)
                  .deleteUser(user.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '✅ Usuario "${user.name}" eliminado'
                          : '❌ Error al eliminar usuario',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.white24),
                  const SizedBox(height: AppSizes.spacing16),
                  const Text(
                    'No hay usuarios registrados',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final roleColor = _getRoleColor(user.role);

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing16,
                    vertical: AppSizes.spacing8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: roleColor.withValues(alpha: 0.2),
                    child: Icon(Icons.person, color: roleColor),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(user.email),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRoleText(user.role),
                          style: TextStyle(
                            fontSize: 12,
                            color: roleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Estado activo/inactivo
                      Switch(
                        value: user.active,
                        onChanged: (value) async {
                          await ref
                              .read(userManagementProvider.notifier)
                              .toggleUserActive(user.id, value);
                        },
                        activeThumbColor: AppColors.success,
                      ),
                      // Botón editar
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showUserDialog(context, user: user),
                      ),
                      // Botón eliminar
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () =>
                            _showDeleteConfirmation(context, ref, user, users),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSizes.spacing16),
              Text(
                'Error al cargar usuarios',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: AppSizes.spacing8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context),
        backgroundColor: AppColors.info,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Usuario'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/app_sizes.dart';
import 'package:pos_restaurante/core/widgets/app_button.dart';
import 'package:pos_restaurante/core/widgets/app_text_field.dart';
import 'package:pos_restaurante/core/utils/validators.dart';
import 'package:pos_restaurante/features/admin/providers/user_management_providers.dart';
import 'package:pos_restaurante/features/auth/data/models/user_model.dart';

/// Dialog para crear/editar usuarios
class UserFormDialog extends ConsumerStatefulWidget {
  final UserModel? user;

  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _branchIdController;

  UserRole _selectedRole = UserRole.waiter;
  bool _isActive = true;
  bool _obscurePassword = true;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _branchIdController = TextEditingController(
      text: widget.user?.branchId ?? 'main',
    );

    if (widget.user != null) {
      _selectedRole = widget.user!.role;
      _isActive = widget.user!.active;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _branchIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    bool success;

    if (_isEditing) {
      // Actualizar usuario existente
      final updatedUser = widget.user!.copyWith(
        name: _nameController.text.trim(),
        role: _selectedRole,
        branchId: _branchIdController.text.trim(),
        active: _isActive,
        updatedAt: DateTime.now(),
      );

      success = await ref
          .read(userManagementProvider.notifier)
          .updateUser(updatedUser);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Usuario actualizado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      // Crear nuevo usuario
      // Primero mostrar advertencia
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Importante'),
          content: const Text(
            'Al crear un nuevo usuario, tu sesión se cerrará temporalmente '
            'debido a una limitación de Firebase.\n\n'
            'El usuario se creará correctamente, pero deberás iniciar sesión '
            'nuevamente para continuar trabajando.\n\n'
            '💡 Tip: Crea todos los usuarios que necesites de una vez.\n\n'
            '¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Crear Usuario'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      if (!mounted) return;

      success = await ref
          .read(userManagementProvider.notifier)
          .createUser(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            role: _selectedRole,
            branchId: _branchIdController.text.trim(),
          );

      if (!mounted) return;

      if (success) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Usuario creado exitosamente en Firebase.\n'
              '⚠️ Tu sesión se cerró. Por favor, inicia sesión nuevamente.',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );

        // Cerrar dialog
        Navigator.of(context).pop();

        // NO redirigir - dejar que el usuario vea el mensaje
        // La app detectará automáticamente que no hay sesión
        return;
      }
    }

    // Mostrar error si falló
    if (!success) {
      final state = ref.read(userManagementProvider);
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar Usuario' : 'Nuevo Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre
              AppTextField(
                controller: _nameController,
                label: 'Nombre',
                hint: 'Juan Pérez',
                prefixIcon: const Icon(Icons.person),
                validator: Validators.required,
                enabled: !state.isLoading,
              ),
              const SizedBox(height: AppSizes.spacing16),

              // Email
              AppTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                hint: 'usuario@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email),
                validator: Validators.email,
                enabled: !state.isLoading && !_isEditing,
              ),
              const SizedBox(height: AppSizes.spacing16),

              // Contraseña (solo al crear)
              if (!_isEditing)
                AppTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: Validators.password,
                  enabled: !state.isLoading,
                ),
              if (!_isEditing) const SizedBox(height: AppSizes.spacing16),

              // Rol
              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(
                    value: UserRole.admin,
                    child: Text('Administrador'),
                  ),
                  DropdownMenuItem(
                    value: UserRole.waiter,
                    child: Text('Mesero'),
                  ),
                  DropdownMenuItem(
                    value: UserRole.kitchen,
                    child: Text('Cocina'),
                  ),
                  DropdownMenuItem(value: UserRole.bar, child: Text('Barra')),
                  DropdownMenuItem(
                    value: UserRole.cashier,
                    child: Text('Cajero'),
                  ),
                ],
                onChanged: state.isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: AppSizes.spacing16),

              // Branch ID
              AppTextField(
                controller: _branchIdController,
                label: 'Sucursal',
                hint: 'main',
                prefixIcon: const Icon(Icons.store),
                validator: Validators.required,
                enabled: !state.isLoading,
              ),

              // Activo (solo al editar)
              if (_isEditing) ...[
                const SizedBox(height: AppSizes.spacing16),
                SwitchListTile(
                  title: const Text('Usuario Activo'),
                  value: _isActive,
                  onChanged: state.isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                  activeThumbColor: AppColors.success,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton(
          text: _isEditing ? 'Actualizar' : 'Crear',
          onPressed: state.isLoading ? null : _handleSave,
          isLoading: state.isLoading,
          type: AppButtonType.primary,
        ),
      ],
    );
  }
}

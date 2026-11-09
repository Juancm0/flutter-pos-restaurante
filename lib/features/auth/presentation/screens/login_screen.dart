import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/app_sizes.dart';
import 'package:pos_restaurante/core/constants/app_routes.dart';
import 'package:pos_restaurante/core/constants/firebase_constants.dart';
import 'package:pos_restaurante/core/widgets/app_button.dart';
import 'package:pos_restaurante/core/widgets/app_text_field.dart';
import 'package:pos_restaurante/core/utils/validators.dart';
import 'package:pos_restaurante/features/auth/providers/auth_providers.dart';

/// Pantalla de Login
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Limpiar cualquier error previo cuando se carga la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Resetear estado completamente antes de intentar login
    ref.read(loginProvider.notifier).reset();

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Quitar focus del teclado
    FocusScope.of(context).unfocus();

    // Intentar login
    final user = await ref
        .read(loginProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    // Verificar resultado
    if (user != null) {
      // Login exitoso - limpiar campos y navegar
      _emailController.clear();
      _passwordController.clear();

      final route = AppRoutes.getInitialRouteForRole(user.role.name);

      // Usar pushNamedAndRemoveUntil para limpiar toda la pila
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    } else {
      // Hubo un error - mostrar mensaje
      final loginState = ref.read(loginProvider);
      if (loginState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginState.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.spacing24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing32),

                  // Título
                  const Text(
                    'POS Restaurante',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing8),

                  // Subtítulo
                  Text(
                    'Gestión de Comida Rápida',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing48),

                  // Campo Email
                  AppTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    hint: 'usuario@ejemplo.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.email,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  // Campo Contraseña
                  AppTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    hint: '••••••••',
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: Validators.required,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: AppSizes.spacing32),

                  // Botón Login
                  AppButton(
                    text: 'Iniciar Sesión',
                    onPressed: loginState.isLoading ? null : _handleLogin,
                    isLoading: loginState.isLoading,
                    isFullWidth: true,
                    size: AppButtonSize.large,
                    type: AppButtonType.primary,
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  // Versión
                  Text(
                    'v${FirebaseConstants.appVersion}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

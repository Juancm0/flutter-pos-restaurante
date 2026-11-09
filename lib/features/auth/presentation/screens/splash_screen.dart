import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/core/constants/app_routes.dart';
import 'package:sistema_eve/features/auth/providers/auth_providers.dart';

/// Splash Screen con verificación de autenticación
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    // Esperar 1.5 segundos para mostrar splash. Timer guardado para
    // cancelarlo en dispose: con Future.delayed el temporizador quedaba
    // pendiente al desmontar el widget (rompia el widget test).
    _splashTimer = Timer(const Duration(milliseconds: 1500), _checkAuth);
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;

    try {
      // Obtener el repositorio directamente
      final authRepo = ref.read(authRepositoryProvider);
      final currentUser = authRepo.currentUser;

      if (currentUser == null) {
        // No hay usuario autenticado, ir a login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      } else {
        // Hay usuario autenticado, obtener datos de Firestore
        final userData = await authRepo.getCurrentUserData();

        if (!mounted) return;

        if (userData == null) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        } else {
          final route = AppRoutes.getInitialRouteForRole(userData.role.name);
          Navigator.of(context).pushReplacementNamed(route);
        }
      }
    } catch (e) {
      debugPrint('Error en splash: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 32),

            // Título
            const Text(
              'Sistema EVE',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Subtítulo
            Text(
              'Gestión de Comida Rápida',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 64),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
            ),
          ],
        ),
      ),
    );
  }
}

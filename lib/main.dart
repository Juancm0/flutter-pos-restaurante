import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/widgets/error_display.dart';

// Screens
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard.dart';
import 'features/admin/presentation/screens/reports_screen.dart';
import 'features/waiter/presentation/screens/waiter_dashboard.dart';
import 'features/kitchen/presentation/screens/kitchen_dashboard.dart';
import 'features/bar/presentation/screens/bar_dashboard.dart';
import 'features/cashier/presentation/screens/cashier_dashboard.dart';

void main() async {
  // Asegurar inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase. Si falla, NO se arranca la app sin backend:
  // se muestra una pantalla de error con reintento, porque sin Firebase
  // todas las pantallas (login, órdenes, inventario) fallarían después
  // con errores confusos.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('❌ Error al inicializar Firebase: $e');
    runApp(
      ProviderScope(child: _FirebaseErrorApp(error: e)),
    );
    return;
  }

  // Ejecutar app
  runApp(
    // ProviderScope es necesario para Riverpod
    const ProviderScope(child: SistemaEveApp()),
  );
}

/// Pantalla de error cuando Firebase no se pudo inicializar.
/// Permite reintentar la conexión sin cerrar la app.
class _FirebaseErrorApp extends StatefulWidget {
  const _FirebaseErrorApp({required this.error});

  final Object error;

  @override
  State<_FirebaseErrorApp> createState() => _FirebaseErrorAppState();
}

class _FirebaseErrorAppState extends State<_FirebaseErrorApp> {
  late Object _error = widget.error;
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase inicializado correctamente');
      // Éxito: arrancar la app normal.
      runApp(
        const ProviderScope(child: SistemaEveApp()),
      );
    } catch (e) {
      debugPrint('❌ Error al inicializar Firebase: $e');
      if (!mounted) return;
      setState(() {
        _error = e;
        _retrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema EVE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SafeArea(
          child: _retrying
              ? const Center(child: CircularProgressIndicator())
              : ErrorDisplay(
                  message:
                      'No se pudo conectar con Firebase.\n\n'
                      'Revisa tu conexión a internet e inténtalo de nuevo.\n\n'
                      'Error: $_error',
                  onRetry: _retry,
                ),
        ),
      ),
    );
  }
}

class SistemaEveApp extends StatelessWidget {
  const SistemaEveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema EVE',
      debugShowCheckedModeBanner: false,

      // Tema oscuro (principal)
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Ruta inicial
      initialRoute: AppRoutes.splash,

      // Rutas
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboard(),
        AppRoutes.adminReports: (context) => const ReportsScreen(),
        AppRoutes.waiterDashboard: (context) => const WaiterDashboard(),
        AppRoutes.kitchenDashboard: (context) => const KitchenDashboard(),
        AppRoutes.barDashboard: (context) => const BarDashboard(),
        AppRoutes.cashierDashboard: (context) => const CashierDashboard(),
      },
    );
  }
}

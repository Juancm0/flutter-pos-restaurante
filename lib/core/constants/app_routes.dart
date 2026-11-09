/// Rutas de navegación del sistema EVE
class AppRoutes {
  // No se puede instanciar
  AppRoutes._();

  // ===== AUTH =====
  static const String login = '/login';
  static const String splash = '/';

  // ===== DASHBOARDS (por rol) =====
  static const String waiterDashboard = '/waiter';
  static const String kitchenDashboard = '/kitchen';
  static const String barDashboard = '/bar';
  static const String cashierDashboard = '/cashier';
  static const String adminDashboard = '/admin';

  // ===== ADMIN =====
  static const String adminReports = '/admin/reports';

  // ===== UTILIDADES =====

  /// Obtiene la ruta inicial según el rol del usuario
  static String getInitialRouteForRole(String role) {
    switch (role.toLowerCase()) {
      case 'waiter':
      case 'mesero':
        return waiterDashboard;
      case 'kitchen':
      case 'cocina':
        return kitchenDashboard;
      case 'bar':
      case 'barra':
        return barDashboard;
      case 'cashier':
      case 'caja':
        return cashierDashboard;
      case 'admin':
      case 'administrador':
        return adminDashboard;
      default:
        return login;
    }
  }
}

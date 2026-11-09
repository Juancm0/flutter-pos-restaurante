/// Constantes para Firebase
class FirebaseConstants {
  // No se puede instanciar
  FirebaseConstants._();

  // Nombres de colecciones
  static const String usersCollection = 'users';
  static const String menuItemsCollection = 'menu_items';
  static const String ordersCollection = 'orders';
  static const String inventoryCollection = 'inventory';
  static const String inventoryMovementsCollection = 'inventory_movements';
  static const String shiftsCollection = 'shifts';
  static const String tablesCollection = 'tables';
  static const String dailyReportsCollection = 'daily_reports';

  // Branch ID por defecto (para single-branch inicial)
  static const String defaultBranchId = 'main';

  // Configuración de la app
  static const String appName = 'Sistema EVE';
  static const String appVersion = '1.0.0';
}

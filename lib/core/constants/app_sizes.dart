/// Tamaños, espaciados y dimensiones del sistema EVE
class AppSizes {
  // No se puede instanciar
  AppSizes._();

  // ===== ESPACIADO (Padding y Margin) =====

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Espaciado estándar por defecto
  static const double defaultPadding = spacing16;
  static const double cardPadding = spacing16;
  static const double screenPadding = spacing20;

  // ===== BORDER RADIUS =====

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusRound = 999.0; // Para círculos perfectos

  // Radius por defecto para cards
  static const double cardRadius = radiusLarge;
  static const double buttonRadius = radiusMedium;
  static const double inputRadius = radiusMedium;

  // ===== TAMAÑOS DE BOTONES =====

  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
  static const double buttonHeightXLarge = 64.0;

  // Touch target mínimo (accesibilidad)
  static const double minTouchTarget = 48.0;

  // ===== TAMAÑOS DE ICONOS =====

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // ===== ELEVACIÓN (Shadow) =====

  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationXHigh = 16.0;

  // ===== ANCHOS Y ALTURAS ESPECÍFICAS =====

  // Cards de mesa (en grid)
  static const double tableCardSize = 100.0;

  // Cards de menú
  static const double menuCardHeight = 160.0;

  // Cards de orden
  static const double orderCardMinHeight = 120.0;

  // AppBar
  static const double appBarHeight = 56.0;

  // Bottom Navigation (si se usa)
  static const double bottomNavHeight = 64.0;

  // Floating Action Button
  static const double fabSize = 56.0;
  static const double fabSizeMini = 40.0;

  // ===== ANCHOS MÁXIMOS (Responsive) =====

  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 600.0;
  static const double maxCardWidth = 400.0;

  // ===== DIVISORES Y BORDES =====

  static const double dividerThickness = 1.0;
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;

  // ===== GRID =====

  // Spacing entre items en grid
  static const double gridSpacing = 12.0;

  // Columnas por defecto en diferentes breakpoints
  static const int gridColumnsPhone = 2;
  static const int gridColumnsTablet = 3;
  static const int gridColumnsDesktop = 4;

  // ===== LISTAS =====

  static const double listItemHeight = 72.0;
  static const double listItemHeightCompact = 56.0;

  // ===== INPUTS =====

  static const double inputHeight = 48.0;
  static const double inputHeightLarge = 56.0;

  // ===== DIÁLOGOS Y MODALS =====

  static const double dialogMaxWidth = 400.0;
  static const double dialogBorderRadius = radiusXLarge;

  // ===== ANIMACIONES (Duración en milisegundos) =====

  static const int animationFast = 150;
  static const int animationMedium = 300;
  static const int animationSlow = 500;

  // ===== BREAKPOINTS (Responsive) =====

  static const double breakpointPhone = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;
}

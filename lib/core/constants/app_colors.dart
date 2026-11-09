import 'package:flutter/material.dart';

/// Paleta de colores del sistema EVE
/// Basado en diseño dark-first con acentos vibrantes
class AppColors {
  // No se puede instanciar
  AppColors._();

  // ===== COLORES BASE =====

  // Fondos oscuros (tema dark)
  static const Color darkBackground = Color(0xFF0F1419); // Azul-negro profundo
  static const Color darkSurface = Color(0xFF1C2630); // Gris azulado para cards
  static const Color darkSurfaceVariant = Color(0xFF242F3D);

  // Fondos claros (tema light)
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE8ECF1);

  // ===== COLORES DE ACENTO =====

  // Verde (acciones positivas, success, disponible)
  static const Color success = Color(0xFF00D9A3);
  static const Color successDark = Color(0xFF00B386);
  static const Color successLight = Color(0xFF33E3B5);

  // Amarillo (alertas, warnings, pendiente)
  static const Color warning = Color(0xFFFFB800);
  static const Color warningDark = Color(0xFFE5A700);
  static const Color warningLight = Color(0xFFFFC733);

  // Rojo (errores, crítico, urgente)
  static const Color error = Color(0xFFFF4757);
  static const Color errorDark = Color(0xFFE63946);
  static const Color errorLight = Color(0xFFFF6B79);

  // Azul (información, estado neutral)
  static const Color info = Color(0xFF4A90E2);
  static const Color infoDark = Color(0xFF357ABD);
  static const Color infoLight = Color(0xFF6BA9EC);

  // ===== COLORES DE TEXTO =====

  // Dark theme
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B8C1);
  static const Color darkTextTertiary = Color(0xFF7A8694);
  static const Color darkTextDisabled = Color(0xFF4A5159);

  // Light theme
  static const Color lightTextPrimary = Color(0xFF1A1F26);
  static const Color lightTextSecondary = Color(0xFF5D6771);
  static const Color lightTextTertiary = Color(0xFF8A9199);
  static const Color lightTextDisabled = Color(0xFFB8BFC6);

  // ===== COLORES ESPECIALES POR ROL =====

  // Mesero (waiter)
  static const Color waiterPrimary = Color(0xFF4A90E2);

  // Cocina (kitchen)
  static const Color kitchenPrimary = Color(0xFFFF6B35); // Naranja cálido

  // Caja (cashier)
  static const Color cashierPrimary = Color(0xFF00D9A3);

  // Admin
  static const Color adminPrimary = Color(0xFF9B59B6); // Púrpura

  // ===== COLORES DE ESTADO DE ORDEN =====

  static const Color orderPending = Color(0xFFFFB800); // Amarillo
  static const Color orderPreparing = Color(0xFF4A90E2); // Azul
  static const Color orderReady = Color(0xFF00D9A3); // Verde
  static const Color orderDelivered = Color(0xFF7A8694); // Gris
  static const Color orderPaid = Color(0xFF00B386); // Verde oscuro

  // ===== COLORES DE ESTADO DE MESA =====

  static const Color tableAvailable = Color(0xFF00D9A3); // Verde
  static const Color tableOccupied = Color(0xFF4A90E2); // Azul
  static const Color tableReady = Color(0xFFFFB800); // Amarillo
  static const Color tableNeedsCleaning = Color(0xFFFF4757); // Rojo

  // ===== GRADIENTES =====

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient successGradient = LinearGradient(
    colors: [Color(0xFF00D9A3), Color(0xFF00B386)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFE5A700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== COLORES DE OVERLAY =====

  static const Color overlayDark = Color(0xB3000000); // 70% opacidad
  static const Color overlayLight = Color(0x80FFFFFF); // 50% opacidad

  // ===== BORDES Y DIVISORES =====

  static const Color darkDivider = Color(0xFF2D3843);
  static const Color lightDivider = Color(0xFFE0E4E8);

  static const Color darkBorder = Color(0xFF3A4653);
  static const Color lightBorder = Color(0xFFD1D7DE);
}

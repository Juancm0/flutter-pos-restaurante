import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estilos de texto del POS Restaurante
/// Usa Inter como fuente principal y Outfit para títulos grandes
class AppTextStyles {
  // No se puede instanciar
  AppTextStyles._();

  // ===== FUENTES BASE =====

  static String get primaryFont => 'Inter';
  static String get headingFont => 'Outfit';

  // ===== HEADINGS (Títulos grandes) =====

  // H1 - Para saludos principales (ej: "Buenas Tardes")
  static TextStyle h1({Color? color}) => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: color,
  );

  // H2 - Títulos de pantalla
  static TextStyle h2({Color? color}) => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
    color: color,
  );

  // H3 - Subtítulos importantes
  static TextStyle h3({Color? color}) => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color,
  );

  // H4 - Secciones
  static TextStyle h4({Color? color}) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color,
  );

  // ===== BODY TEXT =====

  // Body Large - Texto principal grande
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: color,
  );

  // Body Medium - Texto estándar
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: color,
  );

  // Body Small - Texto secundario
  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color,
  );

  // ===== LABELS (Para botones, chips, etc) =====

  static TextStyle labelLarge({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
    color: color,
  );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
    color: color,
  );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.2,
    color: color,
  );

  // ===== ESTILOS ESPECIALES =====

  // Para números grandes (ej: totales, precios importantes)
  static TextStyle displayLarge({Color? color}) => GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1,
    color: color,
  );

  // Para números medianos (ej: precios)
  static TextStyle displayMedium({Color? color}) => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
    color: color,
  );

  // Número de orden grande (para cocina)
  static TextStyle orderNumber({Color? color}) => GoogleFonts.outfit(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1,
    letterSpacing: -0.5,
    color: color,
  );

  // Caption - Texto muy pequeño
  static TextStyle caption({Color? color}) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: color,
  );

  // Overline - Texto uppercase pequeño
  static TextStyle overline({Color? color}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.5,
        color: color,
      ).copyWith(
        // Forzar mayúsculas
        fontFeatures: [const FontFeature.enable('smcp')],
      );

  // Monospace - Para números de teléfono, códigos, etc
  static TextStyle monospace({Color? color}) => GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color,
  );

  // ===== ESTILOS DE COCINA (texto extra grande) =====

  // Para pantalla de cocina - súper legible
  static TextStyle kitchenOrderNumber({Color? color}) => GoogleFonts.outfit(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    height: 1,
    letterSpacing: -1,
    color: color,
  );

  static TextStyle kitchenItemName({Color? color}) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: color,
  );

  static TextStyle kitchenModifier({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    fontStyle: FontStyle.italic,
    color: color,
  );

  static TextStyle kitchenTimer({Color? color}) => GoogleFonts.robotoMono(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1,
    color: color,
  );
}

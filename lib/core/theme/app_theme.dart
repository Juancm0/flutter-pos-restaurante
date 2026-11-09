import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

/// Tema principal de la aplicación POS Restaurante
/// Soporta dark y light mode, con dark como principal
class AppTheme {
  // No se puede instanciar
  AppTheme._();

  // ===== TEMA OSCURO (Principal) =====

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Colores base
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.info,
        onPrimary: Colors.white,
        secondary: AppColors.success,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.h3(color: AppColors.darkTextPrimary),
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: AppSizes.iconMedium,
        ),
      ),

      // Cards
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: AppSizes.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.cardRadius)),
        ),
        margin: EdgeInsets.all(AppSizes.spacing8),
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, AppSizes.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing24,
            vertical: AppSizes.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          elevation: AppSizes.elevationMedium,
          textStyle: AppTextStyles.labelLarge(),
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.info,
          minimumSize: const Size(0, AppSizes.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16,
            vertical: AppSizes.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          textStyle: AppTextStyles.labelMedium(),
        ),
      ),

      // Botones outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.info,
          minimumSize: const Size(0, AppSizes.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing24,
            vertical: AppSizes.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: AppSizes.borderWidth,
          ),
          textStyle: AppTextStyles.labelMedium(),
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        elevation: AppSizes.elevationHigh,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16,
          vertical: AppSizes.spacing12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
            width: AppSizes.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
            width: AppSizes.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.info,
            width: AppSizes.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppSizes.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppSizes.borderWidthThick,
          ),
        ),
        labelStyle: AppTextStyles.bodyMedium(
          color: AppColors.darkTextSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium(color: AppColors.darkTextTertiary),
        errorStyle: AppTextStyles.bodySmall(color: AppColors.error),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.info,
        labelStyle: AppTextStyles.labelSmall(color: AppColors.darkTextPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing12,
          vertical: AppSizes.spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
      ),

      // Divisores
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: AppSizes.dividerThickness,
        space: AppSizes.spacing16,
      ),

      // Iconos
      iconTheme: const IconThemeData(
        color: AppColors.darkTextPrimary,
        size: AppSizes.iconMedium,
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(
          color: AppColors.darkTextPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium(
          color: AppColors.darkTextPrimary,
        ),
        headlineLarge: AppTextStyles.h1(color: AppColors.darkTextPrimary),
        headlineMedium: AppTextStyles.h2(color: AppColors.darkTextPrimary),
        headlineSmall: AppTextStyles.h3(color: AppColors.darkTextPrimary),
        titleLarge: AppTextStyles.h4(color: AppColors.darkTextPrimary),
        bodyLarge: AppTextStyles.bodyLarge(color: AppColors.darkTextPrimary),
        bodyMedium: AppTextStyles.bodyMedium(color: AppColors.darkTextPrimary),
        bodySmall: AppTextStyles.bodySmall(color: AppColors.darkTextSecondary),
        labelLarge: AppTextStyles.labelLarge(color: AppColors.darkTextPrimary),
        labelMedium: AppTextStyles.labelMedium(
          color: AppColors.darkTextPrimary,
        ),
        labelSmall: AppTextStyles.labelSmall(
          color: AppColors.darkTextSecondary,
        ),
      ),

      // Dialogs
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: AppSizes.elevationHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppSizes.dialogBorderRadius),
          ),
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXLarge),
          ),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        contentTextStyle: AppTextStyles.bodyMedium(
          color: AppColors.darkTextPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      ),
    );
  }

  // ===== TEMA CLARO (Opcional) =====

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.info,
        onPrimary: Colors.white,
        secondary: AppColors.success,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h3(color: AppColors.lightTextPrimary),
        iconTheme: const IconThemeData(
          color: AppColors.lightTextPrimary,
          size: AppSizes.iconMedium,
        ),
      ),

      // Cards
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: AppSizes.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.cardRadius)),
        ),
        margin: EdgeInsets.all(AppSizes.spacing8),
      ),

      // Resto de estilos similares pero con colores light
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, AppSizes.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing24,
            vertical: AppSizes.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          elevation: AppSizes.elevationMedium,
          textStyle: AppTextStyles.labelLarge(),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(
          color: AppColors.lightTextPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium(
          color: AppColors.lightTextPrimary,
        ),
        headlineLarge: AppTextStyles.h1(color: AppColors.lightTextPrimary),
        headlineMedium: AppTextStyles.h2(color: AppColors.lightTextPrimary),
        headlineSmall: AppTextStyles.h3(color: AppColors.lightTextPrimary),
        titleLarge: AppTextStyles.h4(color: AppColors.lightTextPrimary),
        bodyLarge: AppTextStyles.bodyLarge(color: AppColors.lightTextPrimary),
        bodyMedium: AppTextStyles.bodyMedium(color: AppColors.lightTextPrimary),
        bodySmall: AppTextStyles.bodySmall(color: AppColors.lightTextSecondary),
        labelLarge: AppTextStyles.labelLarge(color: AppColors.lightTextPrimary),
        labelMedium: AppTextStyles.labelMedium(
          color: AppColors.lightTextPrimary,
        ),
        labelSmall: AppTextStyles.labelSmall(
          color: AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

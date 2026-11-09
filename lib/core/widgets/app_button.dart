import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

/// Tipos de botón custom
enum AppButtonType { primary, secondary, success, warning, error, ghost }

/// Tamaños de botón
enum AppButtonSize { small, medium, large, xlarge }

/// Botón personalizado del POS Restaurante
/// Optimizado para uso táctil con mínimo 48dp de touch target
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final IconData? suffixIcon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = _getHeight();
    final buttonPadding = _getPadding();
    final textStyle = _getTextStyle();
    final colors = _getColors();

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors['text']!),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _getIconSize(), color: colors['text']),
                const SizedBox(width: AppSizes.spacing8),
              ],
              Text(text, style: textStyle.copyWith(color: colors['text'])),
              if (suffixIcon != null) ...[
                const SizedBox(width: AppSizes.spacing8),
                Icon(suffixIcon, size: _getIconSize(), color: colors['text']),
              ],
            ],
          );

    // Botón ghost (sin fondo)
    if (type == AppButtonType.ghost) {
      return SizedBox(
        height: buttonHeight,
        width: isFullWidth ? double.infinity : null,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: buttonPadding,
            foregroundColor: colors['background'],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    // Botones con fondo
    return SizedBox(
      height: buttonHeight,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['background'],
          foregroundColor: colors['text'],
          disabledBackgroundColor: colors['background']!.withValues(alpha: 0.5),
          disabledForegroundColor: colors['text']!.withValues(alpha: 0.5),
          padding: buttonPadding,
          elevation: type == AppButtonType.primary
              ? AppSizes.elevationMedium
              : 0,
          shadowColor: colors['background']!.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            side: type == AppButtonType.secondary
                ? BorderSide(
                    color: colors['background']!,
                    width: AppSizes.borderWidth,
                  )
                : BorderSide.none,
          ),
        ),
        child: buttonChild,
      ),
    );
  }

  // Obtiene la altura según el tamaño
  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppSizes.buttonHeightSmall;
      case AppButtonSize.medium:
        return AppSizes.buttonHeightMedium;
      case AppButtonSize.large:
        return AppSizes.buttonHeightLarge;
      case AppButtonSize.xlarge:
        return AppSizes.buttonHeightXLarge;
    }
  }

  // Obtiene el padding según el tamaño
  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16,
          vertical: AppSizes.spacing8,
        );
      case AppButtonSize.medium:
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing24,
          vertical: AppSizes.spacing12,
        );
      case AppButtonSize.xlarge:
        return const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing32,
          vertical: AppSizes.spacing16,
        );
    }
  }

  // Obtiene el estilo de texto según el tamaño
  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.labelSmall();
      case AppButtonSize.medium:
        return AppTextStyles.labelMedium();
      case AppButtonSize.large:
      case AppButtonSize.xlarge:
        return AppTextStyles.labelLarge();
    }
  }

  // Obtiene el tamaño del icono
  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppSizes.iconSmall;
      case AppButtonSize.medium:
        return AppSizes.iconMedium;
      case AppButtonSize.large:
      case AppButtonSize.xlarge:
        return AppSizes.iconLarge;
    }
  }

  // Obtiene los colores según el tipo
  Map<String, Color> _getColors() {
    switch (type) {
      case AppButtonType.primary:
        return {'background': AppColors.info, 'text': Colors.white};
      case AppButtonType.secondary:
        return {
          'background': AppColors.darkSurfaceVariant,
          'text': AppColors.darkTextPrimary,
        };
      case AppButtonType.success:
        return {'background': AppColors.success, 'text': Colors.white};
      case AppButtonType.warning:
        return {'background': AppColors.warning, 'text': Colors.black87};
      case AppButtonType.error:
        return {'background': AppColors.error, 'text': Colors.white};
      case AppButtonType.ghost:
        return {'background': AppColors.info, 'text': AppColors.info};
    }
  }
}

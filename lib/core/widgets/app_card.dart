import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Card personalizada del POS Restaurante
/// Con bordes redondeados, padding consistente y soporte para gestos
class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Border? border;
  final Gradient? gradient;

  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
    this.onLongPress,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.darkSurface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: border,
      ),
      child: child,
    );

    // Si tiene gestos, envolver en Material con InkWell
    if (onTap != null || onLongPress != null) {
      return Container(
        margin: margin ?? const EdgeInsets.all(AppSizes.spacing8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          boxShadow: elevation != null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: elevation!,
                    offset: Offset(0, elevation! / 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: AppSizes.elevationLow,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            child: cardContent,
          ),
        ),
      );
    }

    // Card simple sin gestos
    return Container(
      margin: margin ?? const EdgeInsets.all(AppSizes.spacing8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: elevation!,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: AppSizes.elevationLow,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: cardContent,
    );
  }
}

/// Card con header, body y footer pre-estructurada
class AppCardWithSections extends StatelessWidget {
  final Widget? header;
  final Widget body;
  final Widget? footer;
  final Color? color;
  final VoidCallback? onTap;

  const AppCardWithSections({
    super.key,
    this.header,
    required this.body,
    this.footer,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      color: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.all(AppSizes.cardPadding),
              child: header,
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            child: body,
          ),
          if (footer != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSizes.cardPadding),
              child: footer,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

/// Campo de texto personalizado del POS Restaurante
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function()? onEditingComplete;
  final void Function(String)? onFieldSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.enabled = true,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        // Sobrescribir estilos del tema si es necesario
        filled: true,
        fillColor: enabled
            ? AppColors.darkSurfaceVariant
            : AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
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
      style: AppTextStyles.bodyMedium(color: AppColors.darkTextPrimary),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      enabled: enabled,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}

/// Campo de texto optimizado para números (precio, cantidad, etc)
class AppNumberField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool allowDecimals;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefix;
  final String? suffix;

  const AppNumberField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.allowDecimals = true,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimals),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimals ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      validator: validator,
      onChanged: onChanged,
      prefixIcon:
          prefixIcon ??
          (prefix != null
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: AppSizes.spacing16,
                    right: AppSizes.spacing8,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      prefix!,
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
                )
              : null),
      suffixIcon:
          suffixIcon ??
          (suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(
                    right: AppSizes.spacing16,
                    left: AppSizes.spacing8,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      suffix!,
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
                )
              : null),
    );
  }
}

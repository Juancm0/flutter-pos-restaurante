/// Validadores para formularios
class Validators {
  // No se puede instanciar
  Validators._();

  // ===== VALIDADOR DE EMAIL =====

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  // ===== VALIDADOR DE CONTRASEÑA =====

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }

    return null;
  }

  /// Validador de contraseña fuerte (opcional)
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    // Al menos una mayúscula
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }

    // Al menos una minúscula
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Debe contener al menos una minúscula';
    }

    // Al menos un número
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }

    return null;
  }

  // ===== VALIDADOR REQUERIDO =====

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName es requerido'
          : 'Este campo es requerido';
    }
    return null;
  }

  // ===== VALIDADOR DE NÚMEROS =====

  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName es requerido'
          : 'Este campo es requerido';
    }

    if (double.tryParse(value) == null) {
      return 'Ingresa un número válido';
    }

    return null;
  }

  static String? positiveNumber(String? value, {String? fieldName}) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;

    final numValue = double.parse(value!);
    if (numValue <= 0) {
      return 'El valor debe ser mayor que 0';
    }

    return null;
  }

  static String? integer(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName es requerido'
          : 'Este campo es requerido';
    }

    if (int.tryParse(value) == null) {
      return 'Ingresa un número entero válido';
    }

    return null;
  }

  // ===== VALIDADOR DE LONGITUD =====

  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName es requerido'
          : 'Este campo es requerido';
    }

    if (value.length < min) {
      return 'Debe tener al menos $min caracteres';
    }

    return null;
  }

  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value == null) return null;

    if (value.length > max) {
      return 'Debe tener máximo $max caracteres';
    }

    return null;
  }

  static String? lengthRange(
    String? value,
    int min,
    int max, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName es requerido'
          : 'Este campo es requerido';
    }

    if (value.length < min || value.length > max) {
      return 'Debe tener entre $min y $max caracteres';
    }

    return null;
  }

  // ===== VALIDADOR DE TELÉFONO =====

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }

    // Remover espacios, paréntesis, guiones
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    // Teléfono mexicano: 10 dígitos
    if (cleaned.length != 10) {
      return 'Ingresa un teléfono válido de 10 dígitos';
    }

    return null;
  }

  // ===== VALIDADOR DE PRECIO =====

  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'El precio es requerido';
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Ingresa un precio válido';
    }

    if (numValue < 0) {
      return 'El precio no puede ser negativo';
    }

    // Máximo 2 decimales
    final parts = value.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'El precio puede tener máximo 2 decimales';
    }

    return null;
  }

  // ===== VALIDADOR DE STOCK/CANTIDAD =====

  static String? stock(String? value) {
    if (value == null || value.isEmpty) {
      return 'La cantidad es requerida';
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Ingresa una cantidad válida';
    }

    if (numValue < 0) {
      return 'La cantidad no puede ser negativa';
    }

    return null;
  }

  // ===== VALIDADOR PERSONALIZADO =====

  /// Combina múltiples validadores
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  // ===== VALIDADOR DE NOMBRE =====

  static String? name(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName es requerido'
          : 'El nombre es requerido';
    }

    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    // Solo letras y espacios
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'El nombre solo debe contener letras';
    }

    return null;
  }
}

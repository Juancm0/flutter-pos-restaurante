import 'package:intl/intl.dart';

/// Utilidades para formateo de datos
class Formatters {
  // No se puede instanciar
  Formatters._();

  // ===== FORMATO DE MONEDA =====

  /// Formatea un número como moneda en pesos mexicanos
  /// Ejemplo: 1500.5 → "$1,500.50"
  static String formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
      locale: 'es_MX',
    );
    return formatter.format(amount);
  }

  /// Formatea moneda de forma compacta
  /// Ejemplo: 1500.5 → "$1.5K"
  static String formatCurrencyCompact(num amount) {
    final formatter = NumberFormat.compactCurrency(
      symbol: '\$',
      decimalDigits: 1,
      locale: 'es_MX',
    );
    return formatter.format(amount);
  }

  // ===== FORMATO DE FECHAS =====

  /// Formato completo: "Lunes, 29 de Diciembre de 2025"
  static String formatDateComplete(DateTime date) {
    final formatter = DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es_MX');
    return formatter.format(date);
  }

  /// Formato corto: "29 Dic 2025"
  static String formatDateShort(DateTime date) {
    final formatter = DateFormat('d MMM y', 'es_MX');
    return formatter.format(date);
  }

  /// Solo fecha: "29/12/2025"
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy', 'es_MX');
    return formatter.format(date);
  }

  /// Solo hora: "14:30"
  static String formatTime(DateTime date) {
    final formatter = DateFormat('HH:mm', 'es_MX');
    return formatter.format(date);
  }

  /// Fecha y hora: "29/12/2025 14:30"
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');
    return formatter.format(date);
  }

  /// Formato relativo: "Hace 5 minutos", "Hace 2 horas", etc.
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return formatDateShort(date);
    }
  }

  /// Duración en formato legible: "2h 30min"
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}min';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}min';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // ===== FORMATO DE NÚMEROS =====

  /// Formatea un número con separadores de miles
  /// Ejemplo: 1500 → "1,500"
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,##0', 'es_MX');
    return formatter.format(number);
  }

  /// Formatea un porcentaje
  /// Ejemplo: 0.75 → "75%"
  static String formatPercentage(num decimal, {int decimals = 0}) {
    final formatter = NumberFormat.percentPattern('es_MX');
    formatter.minimumFractionDigits = decimals;
    formatter.maximumFractionDigits = decimals;
    return formatter.format(decimal);
  }

  // ===== FORMATO DE TELÉFONO =====

  /// Formatea un número de teléfono mexicano
  /// Ejemplo: "5512345678" → "(55) 1234-5678"
  static String formatPhone(String phone) {
    // Limpiar el número
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 2)}) ${cleaned.substring(2, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 12 && cleaned.startsWith('52')) {
      // Con código de país
      return '+52 (${cleaned.substring(2, 4)}) ${cleaned.substring(4, 8)}-${cleaned.substring(8)}';
    }

    return phone; // Si no coincide con el formato, devolver original
  }

  // ===== FORMATO DE ORDEN =====

  /// Genera número de orden formateado
  /// Ejemplo: 42 → "ORD-042"
  static String formatOrderNumber(int orderNumber) {
    return 'ORD-${orderNumber.toString().padLeft(3, '0')}';
  }

  // ===== CAPITALIZACIÓN =====

  /// Capitaliza la primera letra de cada palabra
  /// Ejemplo: "juan pérez" → "Juan Pérez"
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Capitaliza solo la primera letra
  /// Ejemplo: "hola mundo" → "Hola mundo"
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

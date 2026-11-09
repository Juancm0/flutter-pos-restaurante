import 'package:flutter/material.dart';

/// Extensiones útiles para BuildContext
extension BuildContextExtensions on BuildContext {
  // Acceso rápido al tema
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // Navegación
  NavigatorState get navigator => Navigator.of(this);

  void pop<T>([T? result]) => navigator.pop(result);

  Future<T?> push<T>(Route<T> route) => navigator.push(route);

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      navigator.pushNamed<T>(routeName, arguments: arguments);

  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    Object? arguments,
  }) => navigator.pushReplacementNamed<T, TO>(routeName, arguments: arguments);

  void popUntil(RoutePredicate predicate) => navigator.popUntil(predicate);

  // Tamaño de pantalla
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // Padding del sistema (notch, barra de navegación, etc)
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInset => MediaQuery.of(this).viewInsets;

  // Responsive breakpoints
  bool get isPhone => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;

  // Snackbar
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration, action: action),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Focus
  void unfocus() => FocusScope.of(this).unfocus();
}

/// Extensiones para DateTime
extension DateTimeExtensions on DateTime {
  // Comparaciones de fecha (ignorando hora)
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isToday() {
    return isSameDay(DateTime.now());
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  // Inicio y fin del día
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  // Inicio y fin del mes
  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  // Inicio y fin de la semana
  DateTime get startOfWeek {
    final daysToSubtract = weekday - 1;
    return subtract(Duration(days: daysToSubtract)).startOfDay;
  }

  DateTime get endOfWeek {
    final daysToAdd = 7 - weekday;
    return add(Duration(days: daysToAdd)).endOfDay;
  }

  // Chequear si está en un rango
  bool isBetween(DateTime start, DateTime end) {
    return isAfter(start) && isBefore(end);
  }

  // Obtener nombre del mes en español
  String get monthNameES {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }

  // Obtener nombre del día en español
  String get dayNameES {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[weekday - 1];
  }
}

/// Extensiones para String
extension StringExtensions on String {
  // Capitalizar
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // Validaciones rápidas
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  // Truncar texto
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  // Quitar espacios
  String get removeSpaces => replaceAll(' ', '');
  String get removeExtraSpaces => replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Extensiones para List
extension ListExtensions<T> on List<T> {
  // Obtener elemento seguro (no lanza excepción si el índice no existe)
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  // Dividir lista en chunks
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

/// Extensiones para num (int, double)
extension NumExtensions on num {
  // Formatear como moneda
  String toCurrency() {
    return '\$${toStringAsFixed(2)}';
  }

  // Clamp con sintaxis más limpia
  num clampValue(num min, num max) {
    return clamp(min, max);
  }
}

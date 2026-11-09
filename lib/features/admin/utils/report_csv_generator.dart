import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/period_selector.dart';
import 'package:sistema_eve/features/admin/providers/reports_providers.dart';

/// Generador de reportes en CSV.
///
/// Usa el paquete `csv` (ya estaba en pubspec pero sin ningún import en
/// `lib/`) y comparte el archivo con `share_plus` + `path_provider`.
///
/// Las columnas y los datos son los mismos que los del PDF
/// (`report_pdf_generator.dart`): ventas (métricas), ingredientes
/// (ingrediente / cantidad / unidad) e items del menú (item / cantidad /
/// revenue / %). El PDF queda intacto; esto solo añade la exportación CSV.
class ReportCSVGenerator {
  static const _csvConverter = ListToCsvConverter();

  /// CSV del reporte de ventas (mismas métricas que el PDF).
  static String salesCsv({
    required DateRange dateRange,
    required SalesMetrics metrics,
  }) {
    return _csvConverter.convert([
      ['Reporte de Ventas'],
      ['Periodo', _explicitRange(dateRange)],
      [],
      ['Metrica', 'Valor'],
      ['Total de Ventas', metrics.totalSales.toStringAsFixed(2)],
      ['Numero de Ordenes', metrics.totalOrders],
      ['Ticket Promedio', metrics.averageTicket.toStringAsFixed(2)],
      ['Total Propinas', metrics.totalTips.toStringAsFixed(2)],
      ['Efectivo', metrics.cashSales.toStringAsFixed(2)],
      ['Tarjeta', metrics.cardSales.toStringAsFixed(2)],
    ]);
  }

  /// Rango con fechas explicitas (d/M/yyyy - d/M/yyyy), no la etiqueta
  /// amistosa (`Hoy` / `Este Mes`) que usa el PDF en pantalla: en un
  /// archivo exportado la etiqueta es ambigua semanas despues.
  static String _explicitRange(DateRange dateRange) {
    String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
    return '${fmt(dateRange.start)} - ${fmt(dateRange.end)}';
  }

  /// CSV del reporte de ingredientes (mismas columnas que el PDF).
  static String ingredientsCsv({
    required DateRange dateRange,
    required List<IngredientUsage> ingredients,
  }) {
    return _csvConverter.convert([
      ['Reporte de Ingredientes'],
      ['Periodo', _explicitRange(dateRange)],
      [],
      ['Ingrediente', 'Cantidad', 'Unidad'],
      ...ingredients.map(
        (ing) => [
          ing.ingredientName,
          ing.quantityUsed.toStringAsFixed(2),
          ing.unit,
        ],
      ),
    ]);
  }

  /// CSV del reporte de items del menú (mismas columnas que el PDF).
  static String menuItemsCsv({
    required DateRange dateRange,
    required List<MenuItemSales> items,
  }) {
    return _csvConverter.convert([
      ['Reporte de Items del Menu'],
      ['Periodo', _explicitRange(dateRange)],
      [],
      ['Item', 'Cant.', 'Revenue', '%'],
      ...items.map(
        (item) => [
          item.itemName,
          item.quantitySold,
          item.revenue.toStringAsFixed(2),
          '${item.percentage.toStringAsFixed(1)}%',
        ],
      ),
    ]);
  }

  /// Genera el CSV de ventas y lo comparte (hoja de compartir del sistema).
  static Future<void> shareSalesReport({
    required DateRange dateRange,
    required SalesMetrics metrics,
  }) async {
    await _shareCsv(
      salesCsv(dateRange: dateRange, metrics: metrics),
      'reporte_ventas_${_fileDateSuffix()}.csv',
    );
  }

  /// Genera el CSV de ingredientes y lo comparte.
  static Future<void> shareIngredientsReport({
    required DateRange dateRange,
    required List<IngredientUsage> ingredients,
  }) async {
    await _shareCsv(
      ingredientsCsv(dateRange: dateRange, ingredients: ingredients),
      'reporte_ingredientes_${_fileDateSuffix()}.csv',
    );
  }

  /// Genera el CSV de items del menú y lo comparte.
  static Future<void> shareMenuItemsReport({
    required DateRange dateRange,
    required List<MenuItemSales> items,
  }) async {
    await _shareCsv(
      menuItemsCsv(dateRange: dateRange, items: items),
      'reporte_items_menu_${_fileDateSuffix()}.csv',
    );
  }

  /// Escribe el CSV en el directorio temporal y abre la hoja de compartir.
  static Future<void> _shareCsv(String csvContent, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvContent);
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte Sistema EVE');
  }

  static String _fileDateSuffix() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$y$m${d}_$hh$mm';
  }
}

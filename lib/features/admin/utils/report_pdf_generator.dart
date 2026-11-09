import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sistema_eve/features/admin/providers/reports_providers.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/period_selector.dart';

/// Generador de reportes en PDF
class ReportPDFGenerator {
  /// Genera reporte de ventas
  static Future<void> generateSalesReport({
    required DateRange dateRange,
    required SalesMetrics metrics,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Text(
              'Reporte de Ventas',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Período: ${dateRange.displayText}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Divider(height: 32),

            // Métricas
            _buildMetric(
              'Total de Ventas',
              '\$${metrics.totalSales.toStringAsFixed(2)}',
            ),
            _buildMetric('Número de Órdenes', '${metrics.totalOrders}'),
            _buildMetric(
              'Ticket Promedio',
              '\$${metrics.averageTicket.toStringAsFixed(2)}',
            ),
            _buildMetric(
              'Total Propinas',
              '\$${metrics.totalTips.toStringAsFixed(2)}',
            ),

            pw.SizedBox(height: 24),
            pw.Text(
              'Métodos de Pago',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildMetric(
              'Efectivo',
              '\$${metrics.cashSales.toStringAsFixed(2)}',
            ),
            _buildMetric(
              'Tarjeta',
              '\$${metrics.cardSales.toStringAsFixed(2)}',
            ),

            pw.Spacer(),
            pw.Text(
              'Generado: ${DateTime.now().toString().substring(0, 19)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  /// Genera reporte de ingredientes
  static Future<void> generateIngredientsReport({
    required DateRange dateRange,
    required List<IngredientUsage> ingredients,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Text(
              'Reporte de Ingredientes',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Período: ${dateRange.displayText}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Divider(height: 32),

            // Tabla
            pw.TableHelper.fromTextArray(
              headers: ['Ingrediente', 'Cantidad', 'Unidad'],
              data: ingredients
                  .map(
                    (ing) => [
                      ing.ingredientName,
                      ing.quantityUsed.toStringAsFixed(2),
                      ing.unit,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.center,
              },
            ),

            pw.Spacer(),
            pw.Text(
              'Total ingredientes: ${ingredients.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generado: ${DateTime.now().toString().substring(0, 19)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  /// Genera reporte de items del menú
  static Future<void> generateMenuItemsReport({
    required DateRange dateRange,
    required List<MenuItemSales> items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Text(
              'Reporte de Items del Menú',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Período: ${dateRange.displayText}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Divider(height: 32),

            // Tabla
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Cant.', 'Revenue', '%'],
              data: items
                  .map(
                    (item) => [
                      item.itemName,
                      '${item.quantitySold}',
                      '\$${item.revenue.toStringAsFixed(2)}',
                      '${item.percentage.toStringAsFixed(1)}%',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),

            pw.Spacer(),
            pw.Text(
              'Total items: ${items.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generado: ${DateTime.now().toString().substring(0, 19)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  /// Helper para construir métrica
  static pw.Widget _buildMetric(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

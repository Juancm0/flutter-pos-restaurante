import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';

/// Servicio para generar PDF del corte de caja
class CashCutPdfGenerator {
  /// Genera el PDF del corte de caja
  static Future<Uint8List> generateCashCutPdf({
    required String cashierName,
    required DateTime cutStartTime,
    required DateTime cutEndTime,
    required List<OrderModel> orders,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Calcular totales
    double totalCash = 0;
    double totalCard = 0;
    double totalTips = 0;

    for (final order in orders) {
      final orderTotal = order.total + (order.tip ?? 0);
      if (order.paymentMethod == PaymentMethod.cash) {
        totalCash += orderTotal;
      } else {
        totalCard += orderTotal;
      }
      totalTips += order.tip ?? 0;
    }

    final grandTotal = totalCash + totalCard;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(cashierName, cutStartTime, cutEndTime, dateFormat),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Resumen
          _buildSummarySection(
            ordersCount: orders.length,
            totalCash: totalCash,
            totalCard: totalCard,
            totalTips: totalTips,
            grandTotal: grandTotal,
            currencyFormat: currencyFormat,
          ),
          pw.SizedBox(height: 20),

          // Tabla de órdenes
          _buildOrdersTable(orders, currencyFormat, dateFormat),
        ],
      ),
    );

    return pdf.save();
  }

  /// Header del PDF
  static pw.Widget _buildHeader(
    String cashierName,
    DateTime startTime,
    DateTime endTime,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'POS RESTAURANTE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.Text(
                  'Corte de Caja',
                  style: const pw.TextStyle(fontSize: 18),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Cajero: $cashierName'),
                pw.Text('Inicio: ${dateFormat.format(startTime)}'),
                pw.Text('Cierre: ${dateFormat.format(endTime)}'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2, color: PdfColors.green800),
        pw.SizedBox(height: 10),
      ],
    );
  }

  /// Footer del PDF
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  /// Sección de resumen
  static pw.Widget _buildSummarySection({
    required int ordersCount,
    required double totalCash,
    required double totalCard,
    required double totalTips,
    required double grandTotal,
    required NumberFormat currencyFormat,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.green800, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMEN DEL TURNO',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Órdenes', '$ordersCount'),
              _summaryItem('Efectivo', currencyFormat.format(totalCash)),
              _summaryItem('Tarjeta', currencyFormat.format(totalCard)),
              _summaryItem('Propinas', currencyFormat.format(totalTips)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL GENERAL:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                currencyFormat.format(grandTotal),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Item de resumen
  static pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// Tabla de órdenes
  static pw.Widget _buildOrdersTable(
    List<OrderModel> orders,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETALLE DE ÓRDENES',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(2), // Referencia
            1: const pw.FlexColumnWidth(2), // Hora
            2: const pw.FlexColumnWidth(1.5), // Tipo
            3: const pw.FlexColumnWidth(1.5), // Método
            4: const pw.FlexColumnWidth(1.5), // Total
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green100),
              children: [
                _tableHeader('Referencia'),
                _tableHeader('Hora'),
                _tableHeader('Tipo'),
                _tableHeader('Pago'),
                _tableHeader('Total'),
              ],
            ),
            // Rows
            ...orders.map(
              (order) => pw.TableRow(
                children: [
                  _tableCell(order.displayReference),
                  _tableCell(
                    dateFormat.format(
                      order.timestamps.paid ?? order.timestamps.created,
                    ),
                  ),
                  _tableCell(
                    order.orderType == OrderType.dineIn
                        ? 'Mesa'
                        : 'Para Llevar',
                  ),
                  _tableCell(
                    order.paymentMethod == PaymentMethod.cash
                        ? 'Efectivo'
                        : 'Tarjeta',
                  ),
                  _tableCell(
                    currencyFormat.format(order.total + (order.tip ?? 0)),
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Header de tabla
  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Celda de tabla
  static pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Mostrar diálogo para imprimir/compartir PDF
  static Future<void> printOrShare({
    required String cashierName,
    required DateTime cutStartTime,
    required DateTime cutEndTime,
    required List<OrderModel> orders,
  }) async {
    final pdfBytes = await generateCashCutPdf(
      cashierName: cashierName,
      cutStartTime: cutStartTime,
      cutEndTime: cutEndTime,
      orders: orders,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Corte_Caja_${DateFormat('yyyyMMdd_HHmm').format(cutEndTime)}',
    );
  }
}

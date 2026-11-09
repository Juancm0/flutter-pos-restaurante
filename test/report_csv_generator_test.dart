import 'package:flutter_test/flutter_test.dart';
import 'package:pos_restaurante/features/admin/presentation/widgets/period_selector.dart';
import 'package:pos_restaurante/features/admin/providers/reports_providers.dart';
import 'package:pos_restaurante/features/admin/utils/report_csv_generator.dart';

/// Tests de la exportación CSV: mismas columnas y datos que el PDF
/// (`report_pdf_generator.dart`). Solo cubren la generación del texto CSV;
/// el compartir el archivo (`share_plus` / `path_provider`) no se prueba
/// aquí porque necesita un dispositivo.
void main() {
  final range = DateRange(
    start: DateTime(2026, 11, 1),
    end: DateTime(2026, 11, 8),
  );

  group('salesCsv', () {
    test('incluye las mismas métricas que el PDF', () {
      final csv = ReportCSVGenerator.salesCsv(
        dateRange: range,
        metrics: SalesMetrics(
          totalSales: 150.0,
          totalOrders: 3,
          averageTicket: 50.0,
          totalTips: 20.0,
          cashSales: 100.0,
          cardSales: 50.0,
        ),
      );

      expect(csv, contains('Reporte de Ventas'));
      expect(csv, contains('Periodo,1/11/2026 - 8/11/2026'));
      expect(csv, contains('Metrica,Valor'));
      expect(csv, contains('Total de Ventas,150.00'));
      expect(csv, contains('Numero de Ordenes,3'));
      expect(csv, contains('Ticket Promedio,50.00'));
      expect(csv, contains('Total Propinas,20.00'));
      expect(csv, contains('Efectivo,100.00'));
      expect(csv, contains('Tarjeta,50.00'));
    });

    test('con métricas en cero genera filas válidas', () {
      final csv = ReportCSVGenerator.salesCsv(
        dateRange: range,
        metrics: SalesMetrics.empty(),
      );
      expect(csv, contains('Total de Ventas,0.00'));
      expect(csv, contains('Numero de Ordenes,0'));
    });
  });

  group('ingredientsCsv', () {
    test('usa las columnas del PDF: Ingrediente, Cantidad, Unidad', () {
      final csv = ReportCSVGenerator.ingredientsCsv(
        dateRange: range,
        ingredients: [
          IngredientUsage(
            ingredientId: 'queso',
            ingredientName: 'Queso',
            quantityUsed: 1.5,
            unit: 'kg',
            estimatedCost: 0,
          ),
          IngredientUsage(
            ingredientId: 'pan',
            ingredientName: 'Pan',
            quantityUsed: 10,
            unit: 'pz',
            estimatedCost: 0,
          ),
        ],
      );

      expect(csv, contains('Reporte de Ingredientes'));
      expect(csv, contains('Ingrediente,Cantidad,Unidad'));
      expect(csv, contains('Queso,1.50,kg'));
      expect(csv, contains('Pan,10.00,pz'));
    });

    test('sin ingredientes solo deja el encabezado', () {
      final csv = ReportCSVGenerator.ingredientsCsv(
        dateRange: range,
        ingredients: [],
      );
      expect(csv, contains('Ingrediente,Cantidad,Unidad'));
      expect(csv, isNot(contains('Queso')));
    });
  });

  group('menuItemsCsv', () {
    test('usa las columnas del PDF: Item, Cant., Revenue, %', () {
      final csv = ReportCSVGenerator.menuItemsCsv(
        dateRange: range,
        items: [
          MenuItemSales(
            itemId: 'burger',
            itemName: 'Hamburguesa',
            quantitySold: 2,
            revenue: 200.0,
            percentage: 66.7,
          ),
          MenuItemSales(
            itemId: 'papas',
            itemName: 'Papas',
            quantitySold: 1,
            revenue: 100.0,
            percentage: 33.3,
          ),
        ],
      );

      expect(csv, contains('Reporte de Items del Menu'));
      expect(csv, contains('Item,Cant.,Revenue,%'));
      expect(csv, contains('Hamburguesa,2,200.00,66.7%'));
      expect(csv, contains('Papas,1,100.00,33.3%'));
    });

    test('sin items solo deja el encabezado', () {
      final csv = ReportCSVGenerator.menuItemsCsv(
        dateRange: range,
        items: [],
      );
      expect(csv, contains('Item,Cant.,Revenue,%'));
      expect(csv, isNot(contains('Hamburguesa')));
    });
  });
}

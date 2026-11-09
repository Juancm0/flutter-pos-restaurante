import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/firebase_constants.dart';
import 'package:sistema_eve/core/constants/sections.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';
import 'package:sistema_eve/features/admin/presentation/widgets/period_selector.dart';

/// Filtro de sección para reportes
/// null = todas las secciones
final reportsSectionFilterProvider = StateProvider<Section?>((ref) => null);

/// Clase para combinar filtros de fecha y sección
class ReportFilters {
  final DateRange dateRange;
  final Section? section;

  ReportFilters({required this.dateRange, this.section});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportFilters &&
          runtimeType == other.runtimeType &&
          dateRange == other.dateRange &&
          section == other.section;

  @override
  int get hashCode => dateRange.hashCode ^ section.hashCode;
}

/// Métricas de ventas
class SalesMetrics {
  final double totalSales;
  final int totalOrders;
  final double averageTicket;
  final double totalTips;
  final double cashSales;
  final double cardSales;

  SalesMetrics({
    required this.totalSales,
    required this.totalOrders,
    required this.averageTicket,
    required this.totalTips,
    required this.cashSales,
    required this.cardSales,
  });

  factory SalesMetrics.empty() {
    return SalesMetrics(
      totalSales: 0,
      totalOrders: 0,
      averageTicket: 0,
      totalTips: 0,
      cashSales: 0,
      cardSales: 0,
    );
  }
}

/// Uso de ingrediente
class IngredientUsage {
  final String ingredientId;
  final String ingredientName;
  final double quantityUsed;
  final String unit;
  final double estimatedCost;

  IngredientUsage({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityUsed,
    required this.unit,
    required this.estimatedCost,
  });
}

/// Ventas por item del menú
class MenuItemSales {
  final String itemId;
  final String itemName;
  final int quantitySold;
  final double revenue;
  final double percentage;

  MenuItemSales({
    required this.itemId,
    required this.itemName,
    required this.quantitySold,
    required this.revenue,
    required this.percentage,
  });
}

/// Provider de métricas de ventas por rango de fechas
final salesMetricsProvider = FutureProvider.family<SalesMetrics, DateRange>((
  ref,
  dateRange,
) async {
  try {
    final selectedSection = ref.watch(reportsSectionFilterProvider);

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection(FirebaseConstants.ordersCollection)
        .where('status', isEqualTo: 'paid')
        .where(
          'timestamps.paid',
          isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
        )
        .where('timestamps.paid', isLessThan: Timestamp.fromDate(dateRange.end))
        .get();

    if (ordersSnapshot.docs.isEmpty) {
      return SalesMetrics.empty();
    }

    List<OrderModel> orders = ordersSnapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();

    // Filtrar por sección si se seleccionó una
    if (selectedSection != null) {
      orders = orders.where((order) {
        return order.activeSections.contains(selectedSection.name) ||
            order.items.any((item) => item.section == selectedSection.name);
      }).toList();
    }

    if (orders.isEmpty) {
      return SalesMetrics.empty();
    }

    // Calcular métricas (solo items de la sección si aplica)
    double totalSales = 0;
    double totalTips = 0;
    double cashSales = 0;
    double cardSales = 0;

    for (var order in orders) {
      double orderTotal = order.total;

      // Si hay filtro de sección, calcular solo los items de esa sección
      if (selectedSection != null) {
        final sectionItems = order.items
            .where((item) => item.section == selectedSection.name)
            .toList();
        orderTotal = sectionItems.fold(
          0.0,
          (total, item) => total + (item.price * item.quantity),
        );
      }

      totalSales += orderTotal;
      totalTips += order.tip ?? 0.0;

      if (order.paymentMethod == PaymentMethod.cash) {
        cashSales += orderTotal;
      } else if (order.paymentMethod == PaymentMethod.card) {
        cardSales += orderTotal;
      }
    }

    final averageTicket = orders.isNotEmpty ? totalSales / orders.length : 0.0;

    return SalesMetrics(
      totalSales: totalSales,
      totalOrders: orders.length,
      averageTicket: averageTicket,
      totalTips: totalTips,
      cashSales: cashSales,
      cardSales: cardSales,
    );
  } catch (e) {
    throw Exception('Error al obtener métricas de ventas: $e');
  }
});

/// Provider de uso de ingredientes por rango de fechas
/// Implementa "Cálculo Bajo Demanda" - calcula uso desde órdenes + recetas
final ingredientsUsageProvider =
    FutureProvider.family<List<IngredientUsage>, DateRange>((
      ref,
      dateRange,
    ) async {
      try {
        // 1. Obtener órdenes pagadas en el rango
        final ordersSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseConstants.ordersCollection)
            .where('status', isEqualTo: 'paid')
            .where(
              'timestamps.paid',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
            )
            .where(
              'timestamps.paid',
              isLessThan: Timestamp.fromDate(dateRange.end),
            )
            .get();

        if (ordersSnapshot.docs.isEmpty) {
          return [];
        }

        final orders = ordersSnapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();

        // 2. Obtener todos los menu items (con sus recetas de ingredientes)
        final menuItemsSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseConstants.menuItemsCollection)
            .get();

        // Map de menuItemId -> MenuItem data
        final menuItemsMap = <String, Map<String, dynamic>>{};
        for (var doc in menuItemsSnapshot.docs) {
          menuItemsMap[doc.id] = doc.data();
        }

        // 3. Obtener todos los ingredientes del inventario (para nombres)
        final ingredientsSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseConstants.inventoryCollection)
            .get();

        // Map de ingredientId -> {name, unit}
        final ingredientsInfoMap = <String, Map<String, String>>{};
        for (var doc in ingredientsSnapshot.docs) {
          final data = doc.data();
          ingredientsInfoMap[doc.id] = {
            'name': data['name'] as String? ?? 'Desconocido',
            'unit': data['unit'] as String? ?? 'unidades',
          };
        }

        // 4. Calcular uso de ingredientes desde las órdenes + recetas
        final ingredientsUsageMap = <String, Map<String, dynamic>>{};

        for (var order in orders) {
          for (var orderItem in order.items) {
            final menuItemData = menuItemsMap[orderItem.menuItemId];
            if (menuItemData == null) continue;

            final ingredients =
                menuItemData['ingredients'] as List<dynamic>? ?? [];

            for (var ingredientData in ingredients) {
              if (ingredientData is! Map<String, dynamic>) continue;

              // Estructura esperada: {ingredientId, quantity, unit}
              final ingredientId = ingredientData['ingredientId'] as String?;
              final quantity = (ingredientData['quantity'] as num?)?.toDouble();
              final unit = ingredientData['unit'] as String?;

              if (ingredientId == null || quantity == null) continue;

              // Obtener nombre del ingrediente desde el inventario
              final ingredientInfo = ingredientsInfoMap[ingredientId];
              final ingredientName =
                  ingredientInfo?['name'] ?? 'Ingrediente $ingredientId';
              final ingredientUnit =
                  unit ?? ingredientInfo?['unit'] ?? 'unidades';

              // Multiplicar por la cantidad del order item
              final totalQuantity = quantity * orderItem.quantity.toDouble();

              if (ingredientsUsageMap.containsKey(ingredientId)) {
                ingredientsUsageMap[ingredientId]!['quantity'] += totalQuantity;
              } else {
                ingredientsUsageMap[ingredientId] = {
                  'name': ingredientName,
                  'quantity': totalQuantity,
                  'unit': ingredientUnit,
                };
              }
            }
          }
        }

        // 5. Convertir a lista de IngredientUsage
        final result = <IngredientUsage>[];
        for (var entry in ingredientsUsageMap.entries) {
          result.add(
            IngredientUsage(
              ingredientId: entry.key,
              ingredientName: entry.value['name'] as String,
              quantityUsed: entry.value['quantity'] as double,
              unit: entry.value['unit'] as String,
              estimatedCost: 0, // TODO: Calcular costo desde inventario
            ),
          );
        }

        // Ordenar por cantidad usada (mayor a menor)
        result.sort((a, b) => b.quantityUsed.compareTo(a.quantityUsed));

        return result;
      } catch (e) {
        throw Exception('Error al calcular uso de ingredientes: $e');
      }
    });

/// Provider de ventas por item del menú
final menuItemsSalesProvider =
    FutureProvider.family<List<MenuItemSales>, DateRange>((
      ref,
      dateRange,
    ) async {
      try {
        // 1. Obtener órdenes pagadas en el rango
        final ordersSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseConstants.ordersCollection)
            .where('status', isEqualTo: 'paid')
            .where(
              'timestamps.paid',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
            )
            .where(
              'timestamps.paid',
              isLessThan: Timestamp.fromDate(dateRange.end),
            )
            .get();

        if (ordersSnapshot.docs.isEmpty) {
          return [];
        }

        final orders = ordersSnapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();

        // 2. Obtener todos los menu items para tener los nombres
        final menuItemsSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseConstants.menuItemsCollection)
            .get();

        final menuItemsMap = <String, String>{};
        for (var doc in menuItemsSnapshot.docs) {
          menuItemsMap[doc.id] = doc.data()['name'] as String;
        }

        // 3. Calcular ventas por item (filtrado por sección si aplica)
        final selectedSection = ref.watch(reportsSectionFilterProvider);
        final salesMap = <String, Map<String, dynamic>>{};

        for (var order in orders) {
          for (var orderItem in order.items) {
            // Filtrar por sección si está seleccionada
            if (selectedSection != null &&
                orderItem.section != selectedSection.name) {
              continue;
            }

            final itemId = orderItem.menuItemId;
            final itemName = menuItemsMap[itemId] ?? 'Item Desconocido';

            if (salesMap.containsKey(itemId)) {
              salesMap[itemId]!['quantity'] += orderItem.quantity;
              salesMap[itemId]!['revenue'] +=
                  orderItem.price * orderItem.quantity;
            } else {
              salesMap[itemId] = {
                'name': itemName,
                'quantity': orderItem.quantity,
                'revenue': orderItem.price * orderItem.quantity,
              };
            }
          }
        }

        // 4. Calcular revenue total para porcentajes
        double totalRevenue = 0;
        for (var data in salesMap.values) {
          totalRevenue += data['revenue'] as double;
        }

        // 5. Convertir a lista de MenuItemSales
        final result = <MenuItemSales>[];
        for (var entry in salesMap.entries) {
          final revenue = entry.value['revenue'] as double;
          result.add(
            MenuItemSales(
              itemId: entry.key,
              itemName: entry.value['name'],
              quantitySold: entry.value['quantity'] as int,
              revenue: revenue,
              percentage: totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0,
            ),
          );
        }

        // Ordenar por revenue (mayor a menor)
        result.sort((a, b) => b.revenue.compareTo(a.revenue));

        return result;
      } catch (e) {
        throw Exception('Error al calcular ventas por item: $e');
      }
    });

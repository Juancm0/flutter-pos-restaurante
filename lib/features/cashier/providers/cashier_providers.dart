import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_restaurante/core/constants/firebase_constants.dart';
import 'package:pos_restaurante/core/constants/sections.dart';
import 'package:pos_restaurante/core/utils/business_day.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';
import 'package:pos_restaurante/features/admin/data/repositories/inventory_repository.dart';
import 'package:pos_restaurante/features/cashier/data/models/shift_model.dart';

/// Provider para la sección seleccionada en caja
/// null = todas las secciones
final cashierSectionFilterProvider = StateProvider<Section?>((ref) => null);

/// Provider para el timestamp del último corte de caja del cajero actual
/// Se almacena en SharedPreferences por cajero (por UID)
final lastCashCutTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Provider para cargar el último corte desde SharedPreferences
final loadLastCashCutProvider = FutureProvider.family<DateTime?, String>((
  ref,
  cashierId,
) async {
  final prefs = await SharedPreferences.getInstance();
  final timestamp = prefs.getInt('lastCashCut_$cashierId');
  if (timestamp == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(timestamp);
});

/// Provider para órdenes pendientes de confirmación de pago
/// Incluye:
/// - Órdenes pendingPayment (dine-in procesadas por mesero)
/// - Órdenes delivered takeout (esperando que caja procese el pago)
final pendingPaymentsProvider = StreamProvider.autoDispose<List<OrderModel>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.ordersCollection)
      .where('status', whereIn: ['pendingPayment', 'delivered'])
      .orderBy('timestamps.delivered', descending: false) // FIFO
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
      );
});

/// Provider para órdenes pendientes FILTRADAS por sección
final filteredPendingPaymentsProvider =
    Provider.autoDispose<AsyncValue<List<OrderModel>>>((ref) {
      final ordersAsync = ref.watch(pendingPaymentsProvider);
      final selectedSection = ref.watch(cashierSectionFilterProvider);

      return ordersAsync.when(
        data: (orders) {
          if (selectedSection == null) {
            return AsyncValue.data(orders);
          }
          final filtered = orders.where((order) {
            return order.activeSections.contains(selectedSection.name) ||
                order.items.any((item) => item.section == selectedSection.name);
          }).toList();
          return AsyncValue.data(filtered);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });

/// Provider para contar órdenes pendientes de pago
/// OPTIMIZADO: Usa Provider simple en lugar de StreamProvider
final pendingPaymentsCountProvider = Provider.autoDispose<int>((ref) {
  return ref
      .watch(pendingPaymentsProvider)
      .when(
        data: (orders) => orders.length,
        loading: () => 0,
        error: (_, _) => 0,
      );
});

/// Provider para órdenes pagadas del día laboral actual
/// IMPORTANTE: Día laboral inicia a las 7am (no a medianoche)
final paidOrdersTodayProvider = StreamProvider.autoDispose<List<OrderModel>>((
  ref,
) {
  final startOfBusinessDay = getBusinessDayStart();

  return FirebaseFirestore.instance
      .collection(FirebaseConstants.ordersCollection)
      .where('status', isEqualTo: 'paid')
      .where(
        'timestamps.paid',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfBusinessDay),
      )
      .orderBy('timestamps.paid', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
      );
});

/// Provider para órdenes pagadas FILTRADAS por sección
final filteredPaidOrdersTodayProvider =
    Provider.autoDispose<AsyncValue<List<OrderModel>>>((ref) {
      final ordersAsync = ref.watch(paidOrdersTodayProvider);
      final selectedSection = ref.watch(cashierSectionFilterProvider);

      return ordersAsync.when(
        data: (orders) {
          if (selectedSection == null) {
            return AsyncValue.data(orders);
          }
          final filtered = orders.where((order) {
            return order.activeSections.contains(selectedSection.name) ||
                order.items.any((item) => item.section == selectedSection.name);
          }).toList();
          return AsyncValue.data(filtered);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });

/// Provider de acciones de caja
final cashierActionsProvider = Provider((ref) => CashierActions(ref));

/// Clase que maneja las acciones del cajero
class CashierActions {
  final Ref ref;
  final InventoryRepository _inventoryRepository;

  CashierActions(this.ref, {InventoryRepository? inventoryRepository})
    : _inventoryRepository = inventoryRepository ?? InventoryRepository();

  /// Confirmar pago de una orden
  /// Cambia estado de pendingPayment → paid
  /// Si la orden tiene mesa asociada, la libera
  ///
  /// PUNTO ÚNICO DE DESCUENTO DE INVENTARIO (cambio P0, nov 2026): el stock
  /// se descuenta aquí, UNA sola vez, en la misma transacción que marca la
  /// orden como pagada y pone `inventoryDeducted = true`. Antes el pago
  /// descontaba por segunda vez lo que ya se había descontado al crear la
  /// orden. Si la orden ya estaba pagada, no hace nada (reintento
  /// idempotente: ni el pago ni el descuento se repiten). Si la orden ya
  /// tenía `inventoryDeducted == true`, tampoco se vuelve a descontar.
  /// La firma pública no cambia.
  Future<void> confirmPayment({
    required String orderId,
    required String cashierId,
    required String cashierName,
  }) async {
    try {
      await _confirmPaymentInTransaction(
        orderId: orderId,
        freeTable: true,
        orderUpdates: {
          'status': OrderStatus.paid.name,
          'confirmedByUserId': cashierId,
          'confirmedByUserName': cashierName,
          'timestamps.paid': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      );
    } catch (e) {
      throw Exception('Error al confirmar pago: $e');
    }
  }

  /// Rechazar pago
  /// Regresa orden a delivered y re-ocupa mesa (si aplica)
  Future<void> rejectPayment({
    required String orderId,
    required String reason,
  }) async {
    try {
      // Obtener orden para saber si tiene mesa
      final orderDoc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Orden no encontrada');
      }

      final order = OrderModel.fromFirestore(orderDoc);

      // Limpiar campos de pago y regresar a delivered
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update({
            'status': OrderStatus.delivered.name,
            'paymentMethod': null,
            'tip': null,
            'cashReceived': null,
            'cashChange': null,
            'paidByUserId': null,
            'paidByUserName': null,
            'updatedAt': Timestamp.now(),
          });

      // Si es orden de mesa, volver a ocupar la mesa
      if (order.orderType == OrderType.dineIn && order.tableNumber != null) {
        final tablesSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseConstants.tablesCollection)
            .where('tableNumber', isEqualTo: order.tableNumber)
            .get();

        if (tablesSnapshot.docs.isNotEmpty) {
          await tablesSnapshot.docs.first.reference.update({
            'status': 'occupied',
            'currentOrderId': orderId,
          });
        }
      }
    } catch (e) {
      throw Exception('Error al rechazar pago: $e');
    }
  }

  /// Procesar pago para orden takeout (caja procesa directamente)
  /// Esto es para órdenes para llevar donde el cliente paga en caja
  Future<void> processTakeoutPayment({
    required String orderId,
    required PaymentMethod paymentMethod,
    required double tip,
    double? cashReceived,
    required String cashierId,
    required String cashierName,
  }) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Orden no encontrada');
      }

      final order = OrderModel.fromFirestore(orderDoc);

      // Calcular cambio si es efectivo
      double? cashChange;
      if (paymentMethod == PaymentMethod.cash && cashReceived != null) {
        cashChange = cashReceived - (order.total + tip);
      }

      // Pago + descuento de inventario en una sola transacción (ver
      // confirmPayment): si la orden ya estaba pagada, no hace nada.
      // La firma pública no cambia.
      await _confirmPaymentInTransaction(
        orderId: orderId,
        freeTable: false, // Para llevar: no hay mesa que liberar
        orderUpdates: {
          'status': OrderStatus.paid.name,
          'paymentMethod': paymentMethod.name,
          'tip': tip,
          'cashReceived': cashReceived,
          'cashChange': cashChange,
          'paidByUserId': cashierId, // En este caso el cajero procesa
          'paidByUserName': cashierName,
          'confirmedByUserId': cashierId, // Y también confirma
          'confirmedByUserName': cashierName,
          'timestamps.paid': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      );
    } catch (e) {
      throw Exception('Error al procesar pago: $e');
    }
  }

  /// Confirmación de pago transaccional e idempotente (uso interno de
  /// [confirmPayment] y [processTakeoutPayment]).
  ///
  /// En UNA transacción: lee la orden, descuenta el inventario UNA sola vez
  /// (solo si `inventoryDeducted` es false), marca la orden como pagada con
  /// `inventoryDeducted = true` y, si [freeTable] y hay mesa, la libera.
  /// Si la orden ya estaba pagada, sale sin tocar nada: un reintento (p. ej.
  /// doble tap en el botón o reintento de red) no descuenta dos veces.
  /// Si la orden está cancelada, lanza y no se escribe nada.
  /// Todas las lecturas ocurren antes que cualquier escritura, como exige
  /// Firestore para las transacciones.
  Future<void> _confirmPaymentInTransaction({
    required String orderId,
    required Map<String, dynamic> orderUpdates,
    required bool freeTable,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // Pre-lectura fuera de la transacción solo para resolver la referencia
    // de la mesa: las transacciones de Firestore no admiten consultas
    // (`where`). La lectura autoritativa de la orden ocurre dentro.
    DocumentReference<Map<String, dynamic>>? tableRef;
    if (freeTable) {
      final orderDocPre = await firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .get();
      final tableNumber = orderDocPre.data()?['tableNumber'] as int?;
      if (tableNumber != null) {
        final tablesSnapshot = await firestore
            .collection(FirebaseConstants.tablesCollection)
            .where('tableNumber', isEqualTo: tableNumber)
            .limit(1)
            .get();
        if (tablesSnapshot.docs.isNotEmpty) {
          tableRef = tablesSnapshot.docs.first.reference;
        }
      }
    }

    await firestore.runTransaction((transaction) async {
      // --- Fase de lecturas ---
      final orderRef = firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId);
      final orderDoc = await transaction.get(orderRef);

      if (!orderDoc.exists) {
        throw Exception('Orden no encontrada');
      }

      final order = OrderModel.fromFirestore(orderDoc);

      // Reintento idempotente: ya pagada, no hacer nada.
      if (order.status == OrderStatus.paid) return;
      if (order.status == OrderStatus.cancelled) {
        throw Exception('No se puede confirmar el pago de una orden cancelada');
      }

      // --- Fase de escrituras ---
      // Descuento único, solo si aún no se descontó. Hace sus propias
      // lecturas (recetas, stock) antes de escribir, así que va antes de
      // los updates de abajo y no hay lecturas después de él.
      if (!order.inventoryDeducted) {
        await _inventoryRepository.deductOrderIngredientsInTransaction(
          transaction,
          items: order.items,
          orderId: orderId,
        );
      }

      transaction.update(orderRef, {
        ...orderUpdates,
        'inventoryDeducted': true,
        'updatedAt': Timestamp.now(),
      });

      if (tableRef != null) {
        transaction.update(tableRef, {
          'status': 'available',
          'currentOrderId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Realizar corte de caja
  /// Guarda el timestamp del corte en SharedPreferences
  /// Crea registro en Firestore para histórico
  Future<void> performCashCut({
    required String cashierId,
    required String cashierName,
    required List<OrderModel> orders,
    required String branchId,
  }) async {
    try {
      final now = DateTime.now();

      // Calcular totales
      double totalCash = 0;
      double totalCard = 0;

      for (final order in orders) {
        if (order.paymentMethod == PaymentMethod.cash) {
          totalCash += order.total + (order.tip ?? 0);
        } else {
          totalCard += order.total + (order.tip ?? 0);
        }
      }

      final totalRevenue = totalCash + totalCard;

      // Obtener timestamp del último corte (o inicio del día)
      final prefs = await SharedPreferences.getInstance();
      final lastCutTimestamp = prefs.getInt('lastCashCut_$cashierId');
      final startTime = lastCutTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(lastCutTimestamp)
          : getBusinessDayStart();

      // Crear registro del corte en Firestore
      final shift = ShiftModel(
        id: '',
        userId: cashierId,
        userName: cashierName,
        startTime: startTime,
        endTime: now,
        initialCash: 0, // Se puede agregar input del cajero después
        expectedCash: totalCash,
        actualCash: totalCash, // Sin verificación manual por ahora
        expectedCard: totalCard,
        actualCard: totalCard,
        difference: 0,
        ordersCount: orders.length,
        totalRevenue: totalRevenue,
        cashRevenue: totalCash,
        cardRevenue: totalCard,
        branchId: branchId,
        createdAt: now,
      );

      await FirebaseFirestore.instance
          .collection('shifts')
          .add(shift.toFirestore());

      // Guardar timestamp del corte en SharedPreferences
      await prefs.setInt('lastCashCut_$cashierId', now.millisecondsSinceEpoch);

      // Actualizar el provider
      ref.read(lastCashCutTimeProvider.notifier).state = now;
    } catch (e) {
      throw Exception('Error al realizar corte de caja: $e');
    }
  }
}

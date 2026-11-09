import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sistema_eve/core/constants/firebase_constants.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';
import 'package:sistema_eve/features/admin/data/repositories/inventory_repository.dart';
import 'package:sistema_eve/features/admin/data/repositories/table_repository.dart';

/// REGLA DE DESCUENTO DE INVENTARIO (cambio P0, nov 2026):
/// el stock de una orden se descuenta UNA sola vez, al confirmar el pago
/// en caja (`CashierActions.confirmPayment` / `processTakeoutPayment` o
/// `markAsPaid`), NUNCA al crear la orden. Antes se descontaba al crear
/// (`_deductInventory`) y otra vez al confirmar el pago
/// (`_deductIngredients`), sin ninguna bandera de idempotencia.
/// La bandera `OrderModel.inventoryDeducted` garantiza que ni crear ni
/// confirmar el pago puedan descontar dos veces, ni siquiera si la
/// confirmación se reintenta: si ya es true, el descuento se salta.
///
/// ATOMICIDAD (cambio P0, nov 2026): `createOrder`, `markAsPaid`,
/// `cancelOrder` y `addItemsToExistingOrder` usan transacciones de
/// Firestore: orden + contador + mesa (+ inventario cuando aplica) se
/// escriben juntos o no se escribe nada. Si el descuento falla, la orden
/// NO se crea y el error se propaga con mensaje claro (sin `catch` vacíos).
///
/// NÚMERO DE ORDEN: ya no se cuenta `órdenes de hoy + 1` (dos órdenes
/// simultáneas podían salir con el mismo número). Ahora es un contador
/// transaccional en la colección `counters`, documento
/// `daily_orders_YYYYMMDD` (ver [dailyCounterDocId]).
///
/// NOTA: la colección `counters` necesita una regla en `firestore.rules`
/// (p. ej. `match /counters/{id} { allow read, write: if isAuthenticated(); }`);
/// sin ella Firestore rechaza el contador. Ver AGENT-A-CORE-REPORT.md.

/// Formatea el número de orden: `YYYYMMDD-NNN` (p. ej. `20261108-042`).
/// Función pura (testeable).
String formatOrderNumber(DateTime date, int sequence) {
  final datePrefix =
      '${date.year}${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';
  return '$datePrefix-${sequence.toString().padLeft(3, '0')}';
}

/// ID del documento contador del día: `daily_orders_YYYYMMDD`.
/// Función pura (testeable).
String dailyCounterDocId(DateTime date) {
  final datePrefix =
      '${date.year}${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';
  return 'daily_orders_$datePrefix';
}

/// ¿Debe la confirmación de pago descontar el inventario de esta orden?
/// Solo si aún no se descontó y la orden no está ya pagada ni cancelada.
/// Función pura (testeable).
bool shouldDeductInventoryAtPayment(OrderModel order) {
  return !order.inventoryDeducted &&
      order.status != OrderStatus.paid &&
      order.status != OrderStatus.cancelled;
}

/// ¿Debe la cancelación restaurar el inventario de esta orden?
/// Solo si el inventario llegó a descontarse. Función pura (testeable).
bool shouldRestoreInventoryOnCancel(OrderModel order) {
  return order.inventoryDeducted;
}

/// Repository para gestión de órdenes
class OrderRepository {
  final FirebaseFirestore _firestore;
  final InventoryRepository _inventoryRepository;
  // Se conserva en el constructor por compatibilidad con los providers
  // que lo inyectan; las lecturas/escrituras de mesa dentro de las
  // transacciones se hacen directamente con [_firestore] porque
  // TableRepository no opera dentro de transacciones.
  // ignore: unused_field
  final TableRepository _tableRepository;

  /// Colección del contador transaccional de números de orden.
  static const String _countersCollection = 'counters';

  OrderRepository({
    FirebaseFirestore? firestore,
    required InventoryRepository inventoryRepository,
    required TableRepository tableRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _inventoryRepository = inventoryRepository,
       _tableRepository = tableRepository;

  /// Obtener stream de órdenes de un mesero específico (mesas + para llevar)
  Stream<List<OrderModel>> getMyOrders(String waiterId) {
    return _firestore
        .collection(FirebaseConstants.ordersCollection)
        .where('createdBy', isEqualTo: waiterId)
        .where(
          'status',
          whereIn: ['pending', 'preparing', 'ready', 'delivered'],
        ) // Incluye delivered para permitir procesar pago
        .orderBy('timestamps.created', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Obtener stream de órdenes para llevar de un mesero específico
  Stream<List<OrderModel>> getMyTakeoutOrders(String waiterId) {
    return _firestore
        .collection(FirebaseConstants.ordersCollection)
        .where('createdBy', isEqualTo: waiterId)
        .where(
          'status',
          whereIn: ['pending', 'preparing', 'ready'],
        ) // Solo órdenes activas
        .where('orderType', isEqualTo: 'takeout') // Solo órdenes para llevar
        .orderBy('timestamps.created', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Obtener stream de todas las órdenes (para cocina/cajero)
  /// OPTIMIZADO: Limitado a últimas 50 órdenes para reducir lecturas
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection(FirebaseConstants.ordersCollection)
        .orderBy('timestamps.created', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Obtener stream de una orden específica
  Stream<OrderModel> getOrderById(String orderId) {
    return _firestore
        .collection(FirebaseConstants.ordersCollection)
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw Exception('Orden no encontrada');
          }
          return OrderModel.fromFirestore(doc);
        });
  }

  /// Crear nueva orden.
  ///
  /// Atómica (transacción): número de orden (contador transaccional) +
  /// documento de la orden + mesa ocupada se escriben juntos o no se
  /// escribe nada. NO descuenta inventario: el descuento ocurre al
  /// confirmar el pago (ver comentario al inicio del archivo).
  Future<String> createOrder(OrderModel order) async {
    final orderRef = _firestore
        .collection(FirebaseConstants.ordersCollection)
        .doc();
    final now = DateTime.now();

    try {
      // Firestore NO admite consultas (`where`) dentro de una transaccion:
      // la mesa se resuelve con una consulta normal ANTES de la transaccion
      // y dentro solo se lee su documento por referencia (lectura
      // consistente, con la comprobacion de disponibilidad dentro).
      final tableRef = order.tableNumber != null && order.tableSection != null
          ? await _findTableRefByNumberAndSection(
              order.tableNumber!,
              order.tableSection!,
            )
          : null;
      if (order.tableNumber != null &&
          order.tableSection != null &&
          tableRef == null) {
        throw Exception('Mesa no encontrada');
      }

      await _firestore.runTransaction((transaction) async {
        // --- Fase de lecturas (todas antes de cualquier escritura) ---
        if (tableRef != null) {
          final tableDoc = await transaction.get(tableRef);
          if (!tableDoc.exists) {
            throw Exception('Mesa no encontrada');
          }
          if (tableDoc.data()?['status'] != 'available') {
            throw Exception('Mesa no está disponible');
          }
        }

        // Contador transaccional del día: leer, sumar 1 y escribir dentro
        // de la misma transacción, así dos órdenes simultáneas no pueden
        // obtener el mismo número.
        final counterRef = _firestore
            .collection(_countersCollection)
            .doc(dailyCounterDocId(now));
        final counterSnap = await transaction.get(counterRef);
        final nextNumber =
            ((counterSnap.data()?['count'] as num?)?.toInt() ?? 0) + 1;
        final orderNumber = formatOrderNumber(now, nextNumber);

        // --- Fase de escrituras ---
        transaction.set(counterRef, {
          'count': nextNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final orderData = order
            .copyWith(
              id: orderRef.id,
              orderNumber: orderNumber,
              inventoryDeducted: false,
              timestamps: OrderTimestamps(created: now),
            )
            .toFirestore();
        // Se guarda el id dentro del documento, como hacía el código
        // anterior con un update separado.
        orderData['id'] = orderRef.id;
        transaction.set(orderRef, orderData);

        if (tableRef != null) {
          transaction.update(tableRef, {
            'status': 'occupied',
            'currentOrderId': orderRef.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return orderRef.id;
    } catch (e) {
      throw Exception('Error al crear orden: $e');
    }
  }

  /// Actualizar orden
  Future<void> updateOrder(OrderModel order) async {
    try {
      await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(order.id)
          .update(order.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar orden: $e');
    }
  }

  /// Añadir items a una orden existente (ya servida)
  /// Los nuevos items se marcan como isNewAddition=true
  /// La orden vuelve a pending para que pase por cocina/bar
  ///
  /// Atómica (transacción). Inventario: si la orden YA tenía el inventario
  /// descontado (p. ej. orden pagada a la que se añaden items), solo los
  /// items nuevos se descuentan ahora, en la misma transacción; si aún no
  /// se había descontado, todos los items (viejos + nuevos) se descontarán
  /// juntos al confirmar el pago.
  Future<void> addItemsToExistingOrder(
    String orderId,
    List<OrderItem> newItems,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore
            .collection(FirebaseConstants.ordersCollection)
            .doc(orderId);
        final orderDoc = await transaction.get(orderRef);

        if (!orderDoc.exists) {
          throw Exception('Orden no encontrada');
        }

        final order = OrderModel.fromFirestore(orderDoc);

        if (order.status == OrderStatus.cancelled) {
          throw Exception('No se pueden añadir items a una orden cancelada');
        }

        // Marcar nuevos items con isNewAddition = true
        final markedItems = newItems
            .map((item) => item.copyWith(isNewAddition: true))
            .toList();

        // Combinar items existentes + nuevos
        final allItems = [...order.items, ...markedItems];

        // Determinar secciones activas de los nuevos items
        final newSections = newItems.map((i) => i.section).toSet();

        // Actualizar sectionStatus: resetear solo secciones de nuevos items
        final newSectionStatus = Map<String, String>.from(order.sectionStatus);
        for (final section in newSections) {
          newSectionStatus[section] = 'pending';
        }

        // Combinar activeSections (pueden ser nuevas secciones)
        final allSections = {...order.activeSections, ...newSections};

        // Recalcular totales
        final newSubtotal = allItems.fold<double>(
          0.0,
          (total, item) => total + item.totalPrice,
        );

        // Descuento de los items nuevos, solo si la orden ya lo tenía
        // descontado (ver doc del método). Va antes del update de la orden
        // y no hay lecturas después de sus escrituras.
        if (order.inventoryDeducted) {
          await _inventoryRepository.deductOrderIngredientsInTransaction(
            transaction,
            items: markedItems,
            orderId: orderId,
          );
        }

        final now = DateTime.now();
        transaction.update(orderRef, {
          'items': allItems.map((i) => i.toMap()).toList(),
          'activeSections': allSections.toList(),
          'sectionStatus': newSectionStatus,
          'status': OrderStatus.pending.name, // Vuelve a pending
          'subtotal': newSubtotal,
          'total': newSubtotal, // Sin propina ni comisión aún
          'updatedAt': Timestamp.fromDate(now),
        });
      });
    } catch (e) {
      throw Exception('Error al añadir items: $e');
    }
  }

  /// Marcar items adicionales como procesados (ya no son nuevos)
  Future<void> clearNewAdditionFlags(String orderId) async {
    try {
      final orderDoc = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) return;

      final order = OrderModel.fromFirestore(orderDoc);

      // Resetear isNewAddition a false para todos los items
      final updatedItems = order.items
          .map((item) => item.copyWith(isNewAddition: false))
          .toList();

      await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update({
            'items': updatedItems.map((i) => i.toMap()).toList(),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      // Antes el error se silenciaba con un catch vacío: si la limpieza
      // fallaba nadie se enteraba y los items quedaban como "nuevos".
      // Ahora el error se propaga para que el llamador lo vea.
      throw Exception('Error al limpiar flags de items nuevos: $e');
    }
  }

  /// Actualizar estado de orden
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    // El paso a 'paid' SIEMPRE debe descontar el inventario (una sola vez,
    // con la bandera inventoryDeducted). Hacerlo por aquí lo saltaría, así
    // que se exige usar markAsPaid o la confirmación de caja.
    if (newStatus == OrderStatus.paid) {
      throw Exception(
        'Para marcar una orden como pagada usa markAsPaid o la confirmación '
        'de caja, que descuentan el inventario una sola vez',
      );
    }
    if (newStatus == OrderStatus.cancelled) {
      throw Exception(
        'Para cancelar una orden usa cancelOrder, que marca la orden como '
        'cancelada y restaura el inventario solo si se había descontado',
      );
    }

    try {
      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': Timestamp.fromDate(now),
      };

      // Agregar timestamps específicos según el estado
      switch (newStatus) {
        case OrderStatus.preparing:
          updateData['timestamps.preparing'] = Timestamp.fromDate(now);
          break;
        case OrderStatus.ready:
          updateData['timestamps.ready'] = Timestamp.fromDate(now);
          break;
        case OrderStatus.delivered:
          updateData['timestamps.delivered'] = Timestamp.fromDate(now);
          break;
        case OrderStatus.paid:
          updateData['timestamps.paid'] = Timestamp.fromDate(now);
          break;
        default:
          break;
      }

      await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  /// Actualizar estado de una sección específica (cocina o bar)
  /// section: 'combi' o 'bar'
  /// newStatus: 'pending', 'preparing', 'ready'
  /// Automáticamente actualiza el estado global si todas las secciones están listas
  Future<void> updateSectionStatus(
    String orderId,
    String section,
    String newStatus,
  ) async {
    try {
      // Obtener orden actual
      final orderDoc = await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Orden no encontrada');
      }

      final order = OrderModel.fromFirestore(orderDoc);
      final now = DateTime.now();

      // Actualizar sectionStatus
      final newSectionStatus = Map<String, String>.from(order.sectionStatus);
      newSectionStatus[section] = newStatus;

      final updateData = <String, dynamic>{
        'sectionStatus': newSectionStatus,
        'updatedAt': Timestamp.fromDate(now),
      };

      // Si la sección pasa a 'preparing', la orden global también
      if (newStatus == 'preparing' && order.status == OrderStatus.pending) {
        updateData['status'] = 'preparing';
        updateData['timestamps.preparing'] = Timestamp.fromDate(now);
      }

      // Verificar si TODAS las secciones activas están 'ready'
      if (newStatus == 'ready') {
        final allSectionsReady = order.activeSections.every((sec) {
          if (sec == section) return true; // Esta sección acaba de estar ready
          return newSectionStatus[sec] == 'ready';
        });

        if (allSectionsReady) {
          updateData['status'] = 'ready';
          updateData['timestamps.ready'] = Timestamp.fromDate(now);
        }
      }

      await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);
    } catch (e) {
      throw Exception('Error al actualizar estado de sección: $e');
    }
  }

  /// Marcar orden como entregada
  Future<void> markAsDelivered(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.delivered);
  }

  /// Marcar orden como pagada y liberar mesa.
  ///
  /// Atómica (transacción): si el inventario aún no se descontó, se
  /// descuenta aquí UNA sola vez y se marca `inventoryDeducted = true`
  /// junto con el cambio a `paid`; si ya estaba descontado, no se vuelve
  /// a descontar. Si la orden ya estaba pagada, no hace nada (reintento
  /// idempotente). Antes este método no tocaba el inventario: era una vía
  /// por la que una orden podía quedar pagada sin descontar nunca.
  Future<void> markAsPaid(String orderId, PaymentMethod paymentMethod) async {
    try {
      // Pre-lectura fuera de la transaccion solo para resolver la
      // referencia de la mesa (las transacciones no admiten consultas
      // `where`). La lectura autoritativa de la orden ocurre dentro.
      final tableRef = await _resolveTableRefForOrder(orderId);

      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore
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
          throw Exception('No se puede pagar una orden cancelada');
        }

        if (shouldDeductInventoryAtPayment(order)) {
          await _inventoryRepository.deductOrderIngredientsInTransaction(
            transaction,
            items: order.items,
            orderId: orderId,
          );
        }

        transaction.update(orderRef, {
          'status': OrderStatus.paid.name,
          'paymentMethod': paymentMethod.name,
          'inventoryDeducted': true,
          'timestamps.paid': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        if (tableRef != null) {
          transaction.update(tableRef, {
            'status': 'available',
            'currentOrderId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Error al marcar como pagada: $e');
    }
  }

  /// Cancelar orden (solo si está pending).
  ///
  /// Ya NO borra el documento: marca `status = 'cancelled'` para conservar
  /// el historial y no romper los reportes. Restaura el inventario SOLO
  /// si `inventoryDeducted` era true (en el flujo normal una orden pending
  /// aún no descontó nada, así que no se restaura nada; la restauración
  /// aplica a órdenes que sí llegaron a descontar). Tras restaurar marca
  /// `inventoryDeducted = false`. Si la orden ya estaba cancelada, no hace
  /// nada (reintento idempotente). Todo en una transacción: orden + mesa
  /// (+ inventario cuando aplica) se escriben juntos o nada.
  /// Sin `catch` vacíos: cualquier fallo se propaga.
  Future<void> cancelOrder(String orderId) async {
    try {
      // Pre-lectura fuera de la transaccion solo para resolver la
      // referencia de la mesa (las transacciones no admiten consultas
      // `where`). La lectura autoritativa de la orden ocurre dentro.
      final tableRef = await _resolveTableRefForOrder(orderId);

      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore
            .collection(FirebaseConstants.ordersCollection)
            .doc(orderId);
        final orderDoc = await transaction.get(orderRef);

        if (!orderDoc.exists) {
          throw Exception('Orden no encontrada');
        }

        final order = OrderModel.fromFirestore(orderDoc);

        // Reintento idempotente: ya cancelada, no hacer nada.
        if (order.status == OrderStatus.cancelled) return;

        // Solo se puede cancelar si está pending
        if (order.status != OrderStatus.pending) {
          throw Exception('Solo se pueden cancelar órdenes pendientes');
        }

        // Restaurar inventario solo si se había descontado.
        if (shouldRestoreInventoryOnCancel(order)) {
          await _inventoryRepository.restoreOrderIngredientsInTransaction(
            transaction,
            items: order.items,
            orderId: orderId,
          );
        }

        transaction.update(orderRef, {
          'status': OrderStatus.cancelled.name,
          'inventoryDeducted': false,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Liberar mesa si corresponde
        if (tableRef != null) {
          transaction.update(tableRef, {
            'status': 'available',
            'currentOrderId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Error al cancelar orden: $e');
    }
  }

  /// Resuelve la referencia de la mesa de una orden con lecturas normales
  /// (fuera de transacción): las transacciones de Firestore no admiten
  /// consultas (`where`), solo `transaction.get` por referencia de
  /// documento. La lectura autoritativa de la orden ocurre dentro de la
  /// transacción; esta pre-lectura solo sirve para localizar la mesa.
  Future<DocumentReference<Map<String, dynamic>>?> _resolveTableRefForOrder(
    String orderId,
  ) async {
    final orderDoc = await _firestore
        .collection(FirebaseConstants.ordersCollection)
        .doc(orderId)
        .get();
    final tableNumber = orderDoc.data()?['tableNumber'] as int?;
    if (tableNumber == null) return null;
    return _findFirstTableRefByNumber(tableNumber);
  }

  /// Busca una mesa por número y sección y devuelve su referencia (o null
  /// si no existe). Consulta normal: debe llamarse FUERA de una transacción.
  /// (Equivale a `TableRepository.getTableByNumberAndSection`.)
  Future<DocumentReference<Map<String, dynamic>>?>
  _findTableRefByNumberAndSection(int tableNumber, String section) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.tablesCollection)
        .where('tableNumber', isEqualTo: tableNumber)
        .get();
    for (final doc in snapshot.docs) {
      if (doc.data()['section'] == section) return doc.reference;
    }
    return null;
  }

  /// Busca la primera mesa con ese número y devuelve su referencia (o null).
  /// Consulta normal: debe llamarse FUERA de una transacción.
  /// (Equivale a `TableRepository.getTableByNumber`.)
  Future<DocumentReference<Map<String, dynamic>>?> _findFirstTableRefByNumber(
    int tableNumber,
  ) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.tablesCollection)
        .where('tableNumber', isEqualTo: tableNumber)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.reference;
  }
}

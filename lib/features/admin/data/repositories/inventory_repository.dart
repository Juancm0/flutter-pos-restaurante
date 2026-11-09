import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sistema_eve/core/constants/firebase_constants.dart';
import 'package:sistema_eve/features/admin/data/models/inventory_item_model.dart';
import 'package:sistema_eve/features/waiter/data/models/menu_item_model.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';

/// Repositorio para gestión de inventario.
///
/// REGLA DE DESCUENTO (cambio P0, nov 2026 — ver AGENT-A-CORE-REPORT.md):
/// el stock de una orden se descuenta UNA sola vez, al confirmar el pago
/// en caja, nunca al crear la orden. La bandera `OrderModel.inventoryDeducted`
/// hace idempotente ese descuento: si ya es true, no se vuelve a descontar,
/// ni siquiera si la confirmación de pago se reintenta.
class InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener stream de items de inventario
  Stream<List<InventoryItemModel>> getInventoryItemsStream() {
    return _firestore
        .collection(FirebaseConstants.inventoryCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => InventoryItemModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Crear item de inventario
  Future<void> createItem(InventoryItemModel item) async {
    try {
      await _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .add(item.toFirestore());
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar item de inventario
  Future<void> updateItem(InventoryItemModel item) async {
    try {
      await _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .doc(item.id)
          .update(item.toFirestore());
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Calcula el stock resultante de un movimiento. Función pura (testeable).
  ///
  /// - 'entrada' suma, cualquier otro tipo ('salida', 'merma', ...) resta.
  /// - Lanza [StateError] si el resultado sería negativo: el llamador decide
  ///   si eso es un error (ajuste manual) o si limita a cero (descuento al
  ///   pagar, que nunca debe bloquear una venta; ver
  ///   [deductOrderIngredientsInTransaction]).
  static double computeNewStock({
    required double currentStock,
    required double amount,
    required String type,
  }) {
    final newStock = type == 'entrada'
        ? currentStock + amount
        : currentStock - amount;
    if (newStock < 0) {
      throw StateError(
        'Stock no puede ser negativo '
        '(actual: $currentStock, movimiento: $amount, tipo: $type)',
      );
    }
    return newStock;
  }

  /// Suma las cantidades de cada ingrediente necesarias para una lista de
  /// items de orden, según las recetas. Función pura (testeable).
  ///
  /// [recipesByMenuItemId] mapea menuItemId -> lista de ingredientes de su
  /// receta. Los items sin receta se ignoran (antes se saltaban igual).
  /// Devuelve ingredientId -> cantidad total a descontar.
  static Map<String, double> aggregateIngredientQuantities(
    List<OrderItem> items,
    Map<String, List<MenuItemIngredient>> recipesByMenuItemId,
  ) {
    final totals = <String, double>{};
    for (final orderItem in items) {
      final recipe = recipesByMenuItemId[orderItem.menuItemId];
      if (recipe == null) continue;
      for (final ingredient in recipe) {
        final quantity = ingredient.quantity * orderItem.quantity;
        totals[ingredient.ingredientId] =
            (totals[ingredient.ingredientId] ?? 0) + quantity;
      }
    }
    return totals;
  }

  /// Ajusta el stock de un item dentro de una transacción de Firestore.
  ///
  /// Lee el documento con [transaction], calcula el nuevo stock con
  /// [computeNewStock] (lanza si quedaría negativo) y escribe el nuevo
  /// stock + el movimiento en `inventory_movements`, todo dentro de la
  /// misma transacción. El llamador debe hacer TODAS sus lecturas antes de
  /// llamar a este método (Firestore no permite leer después de escribir
  /// dentro de una transacción) y no leer nada después de él.
  Future<void> adjustStockInTransaction(
    Transaction transaction, {
    required String itemId,
    required double amount,
    required String type, // 'entrada', 'salida', 'merma'
    String? reason,
    String? orderId,
  }) async {
    final itemRef = _firestore
        .collection(FirebaseConstants.inventoryCollection)
        .doc(itemId);
    final doc = await transaction.get(itemRef);

    if (!doc.exists) {
      throw StateError('Item de inventario no encontrado: $itemId');
    }

    final item = InventoryItemModel.fromFirestore(doc);
    final newStock = computeNewStock(
      currentStock: item.currentStock,
      amount: amount,
      type: type,
    );

    transaction.update(itemRef, {
      'currentStock': newStock,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    _recordMovementInTransaction(
      transaction,
      itemId: itemId,
      type: type,
      amount: amount,
      reason: reason,
      orderId: orderId,
    );
  }

  /// Descuenta los ingredientes de [items] dentro de [transaction].
  ///
  /// Es el ÚNICO punto de descuento de inventario por pago de orden
  /// (lo usan `CashierActions` y `OrderRepository.markAsPaid`). Comportamiento:
  /// - Lee las recetas de los items del menú y agrega cantidades por
  ///   ingrediente (un solo read/write por ingrediente aunque varios items
  ///   compartan ingrediente).
  /// - Items del menú o de inventario inexistentes se saltan, como hacía el
  ///   código anterior de caja: un dato borrado no debe bloquear un pago.
  /// - Si el stock no alcanza, se descuenta lo que hay y se limita a cero
  ///   (no se bloquea la venta); el movimiento registra la cantidad
  ///   realmente descontada y la razón lo indica.
  Future<void> deductOrderIngredientsInTransaction(
    Transaction transaction, {
    required List<OrderItem> items,
    required String orderId,
  }) async {
    final totals = await _readIngredientTotalsInTransaction(
      transaction,
      items,
    );

    // Fase de lecturas: leer TODOS los documentos de inventario antes de
    // escribir ninguno (Firestore no permite leer después de escribir
    // dentro de una transacción).
    final inventoryDocs = <String, DocumentSnapshot>{};
    for (final ingredientId in totals.keys) {
      final itemRef = _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .doc(ingredientId);
      final doc = await transaction.get(itemRef);
      if (doc.exists) inventoryDocs[ingredientId] = doc;
    }

    // Fase de escrituras.
    for (final entry in totals.entries) {
      final doc = inventoryDocs[entry.key];
      if (doc == null) continue;

      final item = InventoryItemModel.fromFirestore(doc);
      // Limitar a cero: el pago nunca se bloquea por falta de stock.
      final applied = entry.value.clamp(0.0, item.currentStock);
      if (applied <= 0) continue;

      final itemRef = _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .doc(entry.key);
      transaction.update(itemRef, {
        'currentStock': item.currentStock - applied,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _recordMovementInTransaction(
        transaction,
        itemId: entry.key,
        type: 'salida',
        amount: applied,
        reason:
            'Orden #$orderId${applied < entry.value ? ' (stock insuficiente, se desconto lo disponible)' : ''}',
        orderId: orderId,
      );
    }
  }

  /// Restaura (entrada) los ingredientes de [items] dentro de [transaction].
  ///
  /// Complemento de [deductOrderIngredientsInTransaction]: solo lo llama
  /// `OrderRepository.cancelOrder` cuando la orden tenía
  /// `inventoryDeducted == true`. Los items inexistentes se saltan.
  Future<void> restoreOrderIngredientsInTransaction(
    Transaction transaction, {
    required List<OrderItem> items,
    required String orderId,
  }) async {
    final totals = await _readIngredientTotalsInTransaction(
      transaction,
      items,
    );

    // Fase de lecturas: leer TODOS los documentos de inventario antes de
    // escribir ninguno (Firestore no permite leer después de escribir
    // dentro de una transacción).
    final inventoryDocs = <String, DocumentSnapshot>{};
    for (final ingredientId in totals.keys) {
      final itemRef = _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .doc(ingredientId);
      final doc = await transaction.get(itemRef);
      if (doc.exists) inventoryDocs[ingredientId] = doc;
    }

    // Fase de escrituras.
    for (final entry in totals.entries) {
      final doc = inventoryDocs[entry.key];
      if (doc == null) continue;

      final item = InventoryItemModel.fromFirestore(doc);
      final itemRef = _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .doc(entry.key);
      transaction.update(itemRef, {
        'currentStock': item.currentStock + entry.value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _recordMovementInTransaction(
        transaction,
        itemId: entry.key,
        type: 'entrada',
        amount: entry.value,
        reason: 'Cancelación Orden #$orderId',
        orderId: orderId,
      );
    }
  }

  /// Lee las recetas de los items y devuelve ingredientId -> cantidad total.
  /// Solo lee (no escribe): debe llamarse antes de cualquier escritura de
  /// la transacción que lo invoca.
  Future<Map<String, double>> _readIngredientTotalsInTransaction(
    Transaction transaction,
    List<OrderItem> items,
  ) async {
    final recipes = <String, List<MenuItemIngredient>>{};
    for (final orderItem in items) {
      if (recipes.containsKey(orderItem.menuItemId)) continue;
      final menuItemDoc = await transaction.get(
        _firestore
            .collection(FirebaseConstants.menuItemsCollection)
            .doc(orderItem.menuItemId),
      );
      if (!menuItemDoc.exists) continue;
      recipes[orderItem.menuItemId] =
          MenuItemModel.fromFirestore(menuItemDoc).ingredients;
    }
    return aggregateIngredientQuantities(items, recipes);
  }

  /// Registra un movimiento en `inventory_movements` dentro de [transaction].
  void _recordMovementInTransaction(
    Transaction transaction, {
    required String itemId,
    required String type,
    required double amount,
    String? reason,
    String? orderId,
  }) {
    final movementRef = _firestore
        .collection(FirebaseConstants.inventoryMovementsCollection)
        .doc();
    transaction.set(movementRef, {
      'itemId': itemId,
      'type': type,
      'amount': amount,
      'reason': reason,
      'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ajustar stock (ajuste manual, p. ej. desde el panel de admin).
  ///
  /// Ahora es transaccional: lee y escribe dentro de una transacción de
  /// Firestore, así que dos ajustes simultáneos ya no se pisan (antes era
  /// read-modify-write en cliente). Además registra el movimiento en
  /// `inventory_movements` (antes había un TODO y nunca se escribía).
  /// Lanza si el item no existe o si el stock quedaría negativo.
  Future<void> adjustStock({
    required String itemId,
    required double amount,
    required String type, // 'entrada', 'salida', 'merma'
    String? reason,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        await adjustStockInTransaction(
          transaction,
          itemId: itemId,
          amount: amount,
          type: type,
          reason: reason,
        );
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar item
  Future<void> deleteItem(String itemId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .doc(itemId)
          .delete();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Manejo de errores
  String _handleError(dynamic error) {
    if (error is FirebaseException) {
      return 'Error de Firestore: ${error.message}';
    }
    return 'Error desconocido: $error';
  }
}

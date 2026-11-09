import 'package:flutter_test/flutter_test.dart';

import 'package:pos_restaurante/features/admin/data/repositories/inventory_repository.dart';

import 'package:pos_restaurante/features/waiter/data/models/menu_item_model.dart';

import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';

import 'package:pos_restaurante/features/waiter/data/repositories/order_repository.dart';



/// Tests de la lógica pura del arreglo P0 (doble descuento de inventario).

///

/// No necesitan Firestore: cubren las funciones puras que deciden si se

/// descuenta / se restaura, el cálculo de stock, la agregación de

/// ingredientes y el número de orden. Las rutas que tocan Firestore

/// (transacciones de createOrder / confirmPayment / cancelOrder) no se

/// pueden probar aquí: no hay Flutter instalado en esta VM y el paquete

/// `fake_cloud_firestore` no está en pubspec (no se puede añadir sin

/// tocar pubspec.yaml, fuera de ámbito). Ver AGENT-A-CORE-REPORT.md.



OrderModel _testOrder({

  bool inventoryDeducted = false,

  OrderStatus status = OrderStatus.pending,

}) {

  return OrderModel(

    id: 'order-1',

    orderNumber: '20261108-001',

    status: status,

    orderType: OrderType.dineIn,

    tableNumber: 1,

    items: [

      OrderItem(

        menuItemId: 'burger',

        menuItemName: 'Hamburguesa',

        section: 'combi',

        quantity: 2,

        price: 50.0,

        selectedModifiers: [],

      ),

    ],

    subtotal: 100.0,

    total: 100.0,

    createdBy: 'waiter-1',

    createdByName: 'Mesero',

    branchId: 'main',

    timestamps: OrderTimestamps(created: DateTime(2026, 11, 8, 12)),

    updatedAt: DateTime(2026, 11, 8, 12),

    inventoryDeducted: inventoryDeducted,

  );

}



void main() {

  group('formatOrderNumber / dailyCounterDocId', () {

    test('formatea YYYYMMDD-NNN con ceros a la izquierda', () {

      expect(formatOrderNumber(DateTime(2026, 11, 8), 42), '20261108-042');

      expect(formatOrderNumber(DateTime(2026, 1, 5), 5), '20260105-005');

    });



    test('no trunca secuencias de más de 3 dígitos', () {

      expect(formatOrderNumber(DateTime(2026, 11, 8), 1234), '20261108-1234');

    });



    test('el contador del día es un documento por fecha', () {

      expect(dailyCounterDocId(DateTime(2026, 11, 8)), 'daily_orders_20261108');

      expect(

        dailyCounterDocId(DateTime(2026, 11, 9)),

        isNot(dailyCounterDocId(DateTime(2026, 11, 8))),

      );

    });

  });



  group('shouldDeductInventoryAtPayment (idempotencia del descuento)', () {

    test('orden pendiente sin descontar: SÍ se descuenta al pagar', () {

      expect(shouldDeductInventoryAtPayment(_testOrder()), isTrue);

    });



    test('orden con inventoryDeducted=true: NO se descuenta otra vez', () {

      expect(

        shouldDeductInventoryAtPayment(

          _testOrder(inventoryDeducted: true),

        ),

        isFalse,

      );

    });



    test('orden ya pagada: NO se descuenta (reintento idempotente)', () {

      expect(

        shouldDeductInventoryAtPayment(

          _testOrder(status: OrderStatus.paid),

        ),

        isFalse,

      );

    });



    test('orden cancelada: NO se descuenta', () {

      expect(

        shouldDeductInventoryAtPayment(

          _testOrder(status: OrderStatus.cancelled),

        ),

        isFalse,

      );

    });

  });



  group('shouldRestoreInventoryOnCancel', () {

    test('solo restaura si el inventario se había descontado', () {

      expect(

        shouldRestoreInventoryOnCancel(_testOrder(inventoryDeducted: true)),

        isTrue,

      );

      expect(

        shouldRestoreInventoryOnCancel(_testOrder(inventoryDeducted: false)),

        isFalse,

      );

    });

  });



  group('OrderModel.inventoryDeducted', () {

    test('por defecto es false', () {

      final order = _testOrder();

      expect(order.inventoryDeducted, isFalse);

    });



    test('toFirestore persiste la bandera', () {

      final order = _testOrder(inventoryDeducted: true);

      expect(order.toFirestore()['inventoryDeducted'], isTrue);

      expect(_testOrder().toFirestore()['inventoryDeducted'], isFalse);

    });



    test('copyWith la cambia y la conserva si no se pasa', () {

      final order = _testOrder();

      expect(order.copyWith(inventoryDeducted: true).inventoryDeducted, isTrue);

      expect(

        _testOrder(inventoryDeducted: true).copyWith().inventoryDeducted,

        isTrue,

      );

    });



    test('el estado cancelled existe y se muestra como Cancelada', () {

      expect(OrderStatus.cancelled.displayName, 'Cancelada');

    });

  });



  group('InventoryRepository.computeNewStock', () {

    test('entrada suma y salida resta', () {

      expect(

        InventoryRepository.computeNewStock(

          currentStock: 10,

          amount: 5,

          type: 'entrada',

        ),

        15,

      );

      expect(

        InventoryRepository.computeNewStock(

          currentStock: 10,

          amount: 4,

          type: 'salida',

        ),

        6,

      );

    });



    test('permite llegar exactamente a cero', () {

      expect(

        InventoryRepository.computeNewStock(

          currentStock: 10,

          amount: 10,

          type: 'salida',

        ),

        0,

      );

    });



    test('lanza si el stock quedaría negativo', () {

      expect(

        () => InventoryRepository.computeNewStock(

          currentStock: 3,

          amount: 5,

          type: 'salida',

        ),

        throwsStateError,

      );

    });

  });



  group('InventoryRepository.aggregateIngredientQuantities', () {

    test('suma por ingrediente multiplicando por la cantidad pedida', () {

      final items = [

        OrderItem(

          menuItemId: 'burger',

          menuItemName: 'Hamburguesa',

          section: 'combi',

          quantity: 2,

          price: 50.0,

          selectedModifiers: [],

        ),

        OrderItem(

          menuItemId: 'burger',

          menuItemName: 'Hamburguesa',

          section: 'combi',

          quantity: 3,

          price: 50.0,

          selectedModifiers: [],

        ),

      ];

      final recipes = {

        'burger': [

          MenuItemIngredient(ingredientId: 'queso', quantity: 0.2, unit: 'kg'),

          MenuItemIngredient(ingredientId: 'pan', quantity: 1, unit: 'pz'),

        ],

      };



      final totals = InventoryRepository.aggregateIngredientQuantities(

        items,

        recipes,

      );



      expect(totals['queso'], closeTo(1.0, 0.0001)); // 0.2 * (2 + 3)

      expect(totals['pan'], 5.0); // 1 * (2 + 3)

    });



    test('ignora items sin receta y devuelve vacío sin items', () {

      final items = [

        OrderItem(

          menuItemId: 'sin-receta',

          menuItemName: 'Refresco',

          section: 'bar',

          quantity: 1,

          price: 20.0,

          selectedModifiers: [],

        ),

      ];

      expect(

        InventoryRepository.aggregateIngredientQuantities(items, {}),

        isEmpty,

      );

      expect(

        InventoryRepository.aggregateIngredientQuantities([], {}),

        isEmpty,

      );

    });

  });

}


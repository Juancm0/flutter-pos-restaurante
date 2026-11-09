import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados de una orden
enum OrderStatus {
  pending, // Pendiente (recién creada)
  preparing, // En preparación (cocina trabajando)
  ready, // Lista (esperando entrega)
  delivered, // Entregada (cliente la recibió)
  pendingPayment, // Pago registrado, pendiente confirmación de caja
  paid, // Pagada (completada)
  cancelled; // Cancelada (se conserva el documento, no se borra)

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.preparing:
        return 'En Preparación';
      case OrderStatus.ready:
        return 'Lista';
      case OrderStatus.delivered:
        return 'Entregada';
      case OrderStatus.pendingPayment:
        return 'Pendiente de Pago';
      case OrderStatus.paid:
        return 'Pagada';
      case OrderStatus.cancelled:
        return 'Cancelada';
    }
  }
}

/// Tipo de orden
enum OrderType {
  dineIn, // Para comer aquí (mesa)
  takeout; // Para llevar

  String get displayName {
    switch (this) {
      case OrderType.dineIn:
        return 'Mesa';
      case OrderType.takeout:
        return 'Para Llevar';
    }
  }
}

/// Método de pago
enum PaymentMethod {
  cash, // Efectivo
  card; // Tarjeta

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
    }
  }
}

/// Modificador seleccionado en un item de orden
class SelectedModifier {
  final String modifierName; // "Término de la carne"
  final String optionName; // "Poco cocida"
  final double priceModifier; // +$0

  SelectedModifier({
    required this.modifierName,
    required this.optionName,
    required this.priceModifier,
  });

  factory SelectedModifier.fromMap(Map<String, dynamic> map) {
    return SelectedModifier(
      modifierName: map['modifierName'] as String,
      optionName: map['optionName'] as String,
      priceModifier: (map['priceModifier'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modifierName': modifierName,
      'optionName': optionName,
      'priceModifier': priceModifier,
    };
  }
}

/// Item dentro de una orden
class OrderItem {
  final String menuItemId;
  final String menuItemName;
  final String section; // 'combi' o 'bar'
  final int quantity;
  final double price; // Precio al momento de la orden
  final List<SelectedModifier> selectedModifiers;
  final String? notes; // "Sin sal", "Extra picante", etc
  final int prepTime; // Tiempo de preparación en minutos
  final bool isNewAddition; // true si es un item añadido a orden ya servida

  OrderItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.section,
    required this.quantity,
    required this.price,
    required this.selectedModifiers,
    this.notes,
    this.prepTime = 10, // Default 10 minutos
    this.isNewAddition = false, // Por defecto no es adicional
  });

  // Precio total de este item (precio base + modificadores) * cantidad
  double get totalPrice {
    final modifiersTotal = selectedModifiers.fold<double>(
      0.0,
      (total, mod) => total + mod.priceModifier,
    );
    return (price + modifiersTotal) * quantity;
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] as String,
      menuItemName: map['menuItemName'] as String,
      section: map['section'] as String? ?? 'combi',
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      selectedModifiers: (map['selectedModifiers'] as List<dynamic>? ?? [])
          .map((e) => SelectedModifier.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: map['notes'] as String?,
      prepTime: map['prepTime'] as int? ?? 10,
      isNewAddition: map['isNewAddition'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'section': section,
      'quantity': quantity,
      'price': price,
      'selectedModifiers': selectedModifiers.map((e) => e.toMap()).toList(),
      'notes': notes,
      'prepTime': prepTime,
      'isNewAddition': isNewAddition,
    };
  }

  /// Crear copia con campos modificados
  OrderItem copyWith({
    String? menuItemId,
    String? menuItemName,
    String? section,
    int? quantity,
    double? price,
    List<SelectedModifier>? selectedModifiers,
    String? notes,
    int? prepTime,
    bool? isNewAddition,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      section: section ?? this.section,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      notes: notes ?? this.notes,
      prepTime: prepTime ?? this.prepTime,
      isNewAddition: isNewAddition ?? this.isNewAddition,
    );
  }
}

/// Timestamps de una orden (ciclo de vida)
class OrderTimestamps {
  final DateTime created;
  final DateTime? sentToKitchen;
  final DateTime? preparing;
  final DateTime? ready;
  final DateTime? delivered;
  final DateTime? paid;

  OrderTimestamps({
    required this.created,
    this.sentToKitchen,
    this.preparing,
    this.ready,
    this.delivered,
    this.paid,
  });

  factory OrderTimestamps.fromMap(Map<String, dynamic> map) {
    return OrderTimestamps(
      created: (map['created'] as Timestamp).toDate(),
      sentToKitchen: map['sentToKitchen'] != null
          ? (map['sentToKitchen'] as Timestamp).toDate()
          : null,
      preparing: map['preparing'] != null
          ? (map['preparing'] as Timestamp).toDate()
          : null,
      ready: map['ready'] != null ? (map['ready'] as Timestamp).toDate() : null,
      delivered: map['delivered'] != null
          ? (map['delivered'] as Timestamp).toDate()
          : null,
      paid: map['paid'] != null ? (map['paid'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'created': Timestamp.fromDate(created),
      if (sentToKitchen != null)
        'sentToKitchen': Timestamp.fromDate(sentToKitchen!),
      if (preparing != null) 'preparing': Timestamp.fromDate(preparing!),
      if (ready != null) 'ready': Timestamp.fromDate(ready!),
      if (delivered != null) 'delivered': Timestamp.fromDate(delivered!),
      if (paid != null) 'paid': Timestamp.fromDate(paid!),
    };
  }

  // Duración desde creación hasta ahora
  Duration get timeSinceCreated => DateTime.now().difference(created);

  // Duración desde que llegó a cocina
  Duration? get timeSinceSentToKitchen =>
      sentToKitchen != null ? DateTime.now().difference(sentToKitchen!) : null;
}

/// Modelo de orden
class OrderModel {
  final String id;
  final String orderNumber; // "ORD-042"
  final OrderStatus status;
  final OrderType orderType;
  final int? tableNumber; // 1-5 o null si es para llevar
  final String? tableSection; // 'combi' o 'bar' - sección de la mesa
  final String? customerName;
  final String? customerPhone; // Teléfono para órdenes para llevar
  final List<OrderItem> items;
  final double subtotal;
  final double total;
  final PaymentMethod? paymentMethod;
  final double? tip; // Propina
  final double? cashReceived; // Efectivo recibido (si aplica)
  final double? cashChange; // Cambio entregado
  final String? paidByUserId; // ID del mesero que procesó pago
  final String? paidByUserName; // Nombre del mesero que procesó pago
  final String? confirmedByUserId; // ID del cajero que confirmó
  final String? confirmedByUserName; // Nombre del cajero que confirmó
  final String createdBy; // UID del mesero
  final String createdByName;
  final String? shiftId; // ID del turno
  final String branchId;
  final List<String> activeSections; // ['combi'], ['bar'], o ['combi', 'bar']
  final Map<String, String>
  sectionStatus; // {'combi': 'ready', 'bar': 'preparing'}
  /// Bandera de idempotencia del descuento de inventario.
  /// true = los ingredientes de esta orden YA se descontaron del stock
  /// (al confirmar el pago). false = aún no se descontaron.
  /// Existe para que ni crear la orden ni confirmar el pago puedan
  /// descontar dos veces, ni siquiera si la confirmación se reintenta.
  final bool inventoryDeducted;
  final OrderTimestamps timestamps;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.orderType,
    this.tableNumber,
    this.tableSection,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.total,
    this.paymentMethod,
    this.tip,
    this.cashReceived,
    this.cashChange,
    this.paidByUserId,
    this.paidByUserName,
    this.confirmedByUserId,
    this.confirmedByUserName,
    required this.createdBy,
    required this.createdByName,
    this.shiftId,
    required this.branchId,
    this.activeSections = const [],
    this.sectionStatus = const {},
    this.inventoryDeducted = false,
    required this.timestamps,
    required this.updatedAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] as String,
      status: OrderStatus.values.firstWhere((e) => e.name == data['status']),
      orderType: OrderType.values.firstWhere(
        (e) => e.name == data['orderType'],
      ),
      tableNumber: data['tableNumber'] as int?,
      tableSection: data['tableSection'] as String?,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      items: (data['items'] as List<dynamic>)
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      paymentMethod: data['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == data['paymentMethod'],
            )
          : null,
      tip: (data['tip'] as num?)?.toDouble(),
      cashReceived: (data['cashReceived'] as num?)?.toDouble(),
      cashChange: (data['cashChange'] as num?)?.toDouble(),
      paidByUserId: data['paidByUserId'] as String?,
      paidByUserName: data['paidByUserName'] as String?,
      confirmedByUserId: data['confirmedByUserId'] as String?,
      confirmedByUserName: data['confirmedByUserName'] as String?,
      createdBy: data['createdBy'] as String,
      createdByName: data['createdByName'] as String,
      shiftId: data['shiftId'] as String?,
      branchId: data['branchId'] as String? ?? 'default',
      activeSections:
          (data['activeSections'] as List<dynamic>?)?.cast<String>() ?? [],
      sectionStatus:
          (data['sectionStatus'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
      // Documentos creados antes de este cambio no tienen el campo:
      // se asume no descontado. Ver AGENT-A-CORE-REPORT.md (limitación).
      inventoryDeducted: data['inventoryDeducted'] as bool? ?? false,
      timestamps: OrderTimestamps.fromMap(
        data['timestamps'] as Map<String, dynamic>,
      ),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'status': status.name,
      'orderType': orderType.name,
      'tableNumber': tableNumber,
      'tableSection': tableSection,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'total': total,
      'paymentMethod': paymentMethod?.name,
      'tip': tip,
      'cashReceived': cashReceived,
      'cashChange': cashChange,
      'paidByUserId': paidByUserId,
      'paidByUserName': paidByUserName,
      'confirmedByUserId': confirmedByUserId,
      'confirmedByUserName': confirmedByUserName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'shiftId': shiftId,
      'branchId': branchId,
      'activeSections': activeSections,
      'sectionStatus': sectionStatus,
      'inventoryDeducted': inventoryDeducted,
      'timestamps': timestamps.toMap(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    OrderStatus? status,
    OrderType? orderType,
    int? tableNumber,
    String? tableSection,
    String? customerName,
    String? customerPhone,
    List<OrderItem>? items,
    double? subtotal,
    double? total,
    PaymentMethod? paymentMethod,
    double? tip,
    double? cashReceived,
    double? cashChange,
    String? paidByUserId,
    String? paidByUserName,
    String? confirmedByUserId,
    String? confirmedByUserName,
    String? createdBy,
    String? createdByName,
    String? shiftId,
    String? branchId,
    List<String>? activeSections,
    Map<String, String>? sectionStatus,
    bool? inventoryDeducted,
    OrderTimestamps? timestamps,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      tableSection: tableSection ?? this.tableSection,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tip: tip ?? this.tip,
      cashReceived: cashReceived ?? this.cashReceived,
      cashChange: cashChange ?? this.cashChange,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      paidByUserName: paidByUserName ?? this.paidByUserName,
      confirmedByUserId: confirmedByUserId ?? this.confirmedByUserId,
      confirmedByUserName: confirmedByUserName ?? this.confirmedByUserName,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      shiftId: shiftId ?? this.shiftId,
      branchId: branchId ?? this.branchId,
      activeSections: activeSections ?? this.activeSections,
      sectionStatus: sectionStatus ?? this.sectionStatus,
      inventoryDeducted: inventoryDeducted ?? this.inventoryDeducted,
      timestamps: timestamps ?? this.timestamps,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper para obtener display de mesa/cliente
  String get displayReference {
    if (orderType == OrderType.dineIn && tableNumber != null) {
      return 'Mesa $tableNumber';
    } else if (customerName != null && customerName!.isNotEmpty) {
      return customerName!;
    } else {
      return 'Para Llevar';
    }
  }
}

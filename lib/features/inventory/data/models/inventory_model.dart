import 'package:cloud_firestore/cloud_firestore.dart';

/// Item de inventario (ingrediente)
class InventoryItemModel {
  final String id;
  final String name;
  final String category; // "vegetables", "meats", "dairy", etc
  final double currentStock;
  final String unit; // "kg", "unidades", "litros"
  final double minStock; // Umbral de alerta
  final double cost; // Costo por unidad
  final String? supplier;
  final String branchId;
  final DateTime? lastRestocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.unit,
    required this.minStock,
    required this.cost,
    this.supplier,
    required this.branchId,
    this.lastRestocked,
    required this.createdAt,
    required this.updatedAt,
  });

  // Chequear si está bajo stock
  bool get isLowStock => currentStock <= minStock;

  // Porcentaje de stock restante
  double get stockPercentage {
    if (minStock == 0) return 100;
    return (currentStock / minStock) * 100;
  }

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItemModel(
      id: doc.id,
      name: data['name'] as String,
      category: data['category'] as String,
      currentStock: (data['currentStock'] as num).toDouble(),
      unit: data['unit'] as String,
      minStock: (data['minStock'] as num).toDouble(),
      cost: (data['cost'] as num).toDouble(),
      supplier: data['supplier'] as String?,
      branchId: data['branchId'] as String? ?? 'default',
      lastRestocked: data['lastRestocked'] != null
          ? (data['lastRestocked'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'currentStock': currentStock,
      'unit': unit,
      'minStock': minStock,
      'cost': cost,
      'supplier': supplier,
      'branchId': branchId,
      if (lastRestocked != null)
        'lastRestocked': Timestamp.fromDate(lastRestocked!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? category,
    double? currentStock,
    String? unit,
    double? minStock,
    double? cost,
    String? supplier,
    String? branchId,
    DateTime? lastRestocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      minStock: minStock ?? this.minStock,
      cost: cost ?? this.cost,
      supplier: supplier ?? this.supplier,
      branchId: branchId ?? this.branchId,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Tipo de movimiento de inventario
enum MovementType {
  purchase, // Compra
  deduction, // Deducción (por orden)
  adjustment, // Ajuste manual
  waste; // Merma/desperdicio

  String get displayName {
    switch (this) {
      case MovementType.purchase:
        return 'Compra';
      case MovementType.deduction:
        return 'Deducción';
      case MovementType.adjustment:
        return 'Ajuste';
      case MovementType.waste:
        return 'Merma';
    }
  }
}

/// Movimiento de inventario (historial)
class InventoryMovementModel {
  final String id;
  final String ingredientId;
  final String ingredientName;
  final MovementType type;
  final double quantity; // Positivo o negativo
  final double previousStock;
  final double newStock;
  final String? reason;
  final String? orderId; // Si es deducción automática
  final String userId; // Usuario que realizó el movimiento
  final String userName;
  final String branchId;
  final DateTime createdAt;

  InventoryMovementModel({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.reason,
    this.orderId,
    required this.userId,
    required this.userName,
    required this.branchId,
    required this.createdAt,
  });

  factory InventoryMovementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryMovementModel(
      id: doc.id,
      ingredientId: data['ingredientId'] as String,
      ingredientName: data['ingredientName'] as String,
      type: MovementType.values.firstWhere((e) => e.name == data['type']),
      quantity: (data['quantity'] as num).toDouble(),
      previousStock: (data['previousStock'] as num).toDouble(),
      newStock: (data['newStock'] as num).toDouble(),
      reason: data['reason'] as String?,
      orderId: data['orderId'] as String?,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      branchId: data['branchId'] as String? ?? 'default',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'type': type.name,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'branchId': branchId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

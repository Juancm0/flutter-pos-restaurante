import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de turno de caja
class ShiftModel {
  final String id;
  final String userId;
  final String userName;
  final DateTime startTime;
  final DateTime? endTime;

  // Control de dinero
  final double initialCash;
  final double expectedCash; // Calculado de órdenes
  final double? actualCash; // Ingresado al cerrar
  final double expectedCard; // Calculado de órdenes
  final double? actualCard; // Siempre igual (confirmado)
  final double? difference; // actualCash - expectedCash

  // Resumen del turno
  final int ordersCount;
  final double totalRevenue;
  final double cashRevenue;
  final double cardRevenue;

  final String? notes; // Explicación de diferencias
  final String branchId;
  final DateTime createdAt;

  ShiftModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.startTime,
    this.endTime,
    required this.initialCash,
    required this.expectedCash,
    this.actualCash,
    required this.expectedCard,
    this.actualCard,
    this.difference,
    required this.ordersCount,
    required this.totalRevenue,
    required this.cashRevenue,
    required this.cardRevenue,
    this.notes,
    required this.branchId,
    required this.createdAt,
  });

  // Chequear si el turno está abierto
  bool get isOpen => endTime == null;

  // Duración del turno
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  factory ShiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShiftModel(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      initialCash: (data['initialCash'] as num).toDouble(),
      expectedCash: (data['expectedCash'] as num).toDouble(),
      actualCash: data['actualCash'] != null
          ? (data['actualCash'] as num).toDouble()
          : null,
      expectedCard: (data['expectedCard'] as num).toDouble(),
      actualCard: data['actualCard'] != null
          ? (data['actualCard'] as num).toDouble()
          : null,
      difference: data['difference'] != null
          ? (data['difference'] as num).toDouble()
          : null,
      ordersCount: data['ordersCount'] as int? ?? 0,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      cashRevenue: (data['cashRevenue'] as num?)?.toDouble() ?? 0.0,
      cardRevenue: (data['cardRevenue'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'] as String?,
      branchId: data['branchId'] as String? ?? 'default',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'startTime': Timestamp.fromDate(startTime),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      'initialCash': initialCash,
      'expectedCash': expectedCash,
      if (actualCash != null) 'actualCash': actualCash,
      'expectedCard': expectedCard,
      if (actualCard != null) 'actualCard': actualCard,
      if (difference != null) 'difference': difference,
      'ordersCount': ordersCount,
      'totalRevenue': totalRevenue,
      'cashRevenue': cashRevenue,
      'cardRevenue': cardRevenue,
      'notes': notes,
      'branchId': branchId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ShiftModel copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? startTime,
    DateTime? endTime,
    double? initialCash,
    double? expectedCash,
    double? actualCash,
    double? expectedCard,
    double? actualCard,
    double? difference,
    int? ordersCount,
    double? totalRevenue,
    double? cashRevenue,
    double? cardRevenue,
    String? notes,
    String? branchId,
    DateTime? createdAt,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      initialCash: initialCash ?? this.initialCash,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      expectedCard: expectedCard ?? this.expectedCard,
      actualCard: actualCard ?? this.actualCard,
      difference: difference ?? this.difference,
      ordersCount: ordersCount ?? this.ordersCount,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      cashRevenue: cashRevenue ?? this.cashRevenue,
      cardRevenue: cardRevenue ?? this.cardRevenue,
      notes: notes ?? this.notes,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Modelo de mesa
class TableModel {
  final String id;
  final int number; // 1-5
  final TableStatus status;
  final String? currentOrderId; // null si está libre
  final String? assignedTo; // UID del mesero
  final String? assignedToName;
  final String branchId;
  final DateTime updatedAt;

  TableModel({
    required this.id,
    required this.number,
    required this.status,
    this.currentOrderId,
    this.assignedTo,
    this.assignedToName,
    required this.branchId,
    required this.updatedAt,
  });

  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel(
      id: doc.id,
      number: data['number'] as int,
      status: TableStatus.values.firstWhere((e) => e.name == data['status']),
      currentOrderId: data['currentOrderId'] as String?,
      assignedTo: data['assignedTo'] as String?,
      assignedToName: data['assignedToName'] as String?,
      branchId: data['branchId'] as String? ?? 'default',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'number': number,
      'status': status.name,
      'currentOrderId': currentOrderId,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'branchId': branchId,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TableModel copyWith({
    String? id,
    int? number,
    TableStatus? status,
    String? currentOrderId,
    String? assignedTo,
    String? assignedToName,
    String? branchId,
    DateTime? updatedAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      branchId: branchId ?? this.branchId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Estados de mesa
enum TableStatus {
  available, // Disponible
  occupied, // Ocupada (con orden activa)
  ready, // Orden lista (esperando entrega)
  needsCleaning; // Necesita limpieza

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Disponible';
      case TableStatus.occupied:
        return 'Ocupada';
      case TableStatus.ready:
        return 'Lista';
      case TableStatus.needsCleaning:
        return 'Por Limpiar';
    }
  }
}

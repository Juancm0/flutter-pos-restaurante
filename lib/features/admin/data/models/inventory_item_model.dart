import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de item de inventario
class InventoryItemModel {
  final String id;
  final String name;
  final String unit; // 'kg', 'L', 'units', 'pieces'
  final double currentStock;
  final double minStock;
  final double costPerUnit;
  final String? supplier;
  final DateTime lastUpdated;
  final String branchId;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    required this.costPerUnit,
    this.supplier,
    required this.lastUpdated,
    required this.branchId,
  });

  /// Estado del stock
  String get stockStatus {
    if (currentStock <= minStock) return 'critical';
    if (currentStock <= minStock * 1.5) return 'low';
    return 'sufficient';
  }

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItemModel(
      id: doc.id,
      name: data['name'] as String,
      unit: data['unit'] as String,
      currentStock: (data['currentStock'] as num).toDouble(),
      minStock: (data['minStock'] as num).toDouble(),
      costPerUnit: (data['costPerUnit'] as num).toDouble(),
      supplier: data['supplier'] as String?,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      branchId: data['branchId'] as String? ?? 'main',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'unit': unit,
      'currentStock': currentStock,
      'minStock': minStock,
      'costPerUnit': costPerUnit,
      'supplier': supplier,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'branchId': branchId,
    };
  }

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? unit,
    double? currentStock,
    double? minStock,
    double? costPerUnit,
    String? supplier,
    DateTime? lastUpdated,
    String? branchId,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      supplier: supplier ?? this.supplier,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      branchId: branchId ?? this.branchId,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos_restaurante/core/constants/sections.dart';

/// Modelo para gestión de mesas
class TableModel {
  final String id;
  final int tableNumber;
  final int capacity;
  final Section section; // combi o bar
  final String status; // 'available', 'occupied', 'reserved', 'cleaning'
  final String? currentOrderId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.section,
    required this.status,
    this.currentOrderId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel(
      id: doc.id,
      tableNumber: data['tableNumber'] as int,
      capacity: data['capacity'] as int,
      section: data['section'] != null
          ? Section.fromString(data['section'] as String)
          : Section.combi, // default
      status: data['status'] as String? ?? 'available',
      currentOrderId: data['currentOrderId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tableNumber': tableNumber,
      'capacity': capacity,
      'section': section.toFirestore(),
      'status': status,
      'currentOrderId': currentOrderId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TableModel copyWith({
    String? id,
    int? tableNumber,
    int? capacity,
    Section? section,
    String? status,
    String? currentOrderId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      section: section ?? this.section,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

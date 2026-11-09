import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles de usuario en el sistema
enum UserRole {
  admin,
  waiter, // mesero
  kitchen, // cocina
  bar, // barra
  cashier, // caja
}

/// Extensión para convertir UserRole a/desde String
extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.waiter:
        return 'waiter';
      case UserRole.kitchen:
        return 'kitchen';
      case UserRole.bar:
        return 'bar';
      case UserRole.cashier:
        return 'cashier';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'waiter':
        return UserRole.waiter;
      case 'kitchen':
        return UserRole.kitchen;
      case 'bar':
        return UserRole.bar;
      case 'cashier':
        return UserRole.cashier;
      default:
        return UserRole.waiter;
    }
  }
}

/// Modelo de usuario del sistema
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String branchId;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.branchId,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear desde Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] as String,
      name: data['name'] as String,
      role: UserRoleExtension.fromString(data['role'] as String),
      branchId: data['branchId'] as String,
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'branchId': branchId,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copiar con cambios
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? branchId,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

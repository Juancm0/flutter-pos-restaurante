import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de categoría del menú
class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final int order;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.order,
    this.icon,
    this.isActive = true,
    required this.createdAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String,
      slug: data['slug'] as String,
      order: (data['order'] as num?)?.toInt() ?? 0,
      icon: data['icon'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'slug': slug,
      'order': order,
      'icon': icon,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    int? order,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      order: order ?? this.order,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Genera slug a partir del nombre
  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sistema_eve/core/constants/sections.dart';

/// Modificador de un producto (ej: "Sin cebolla", "Extra queso")
class ProductModifier {
  final String id;
  final String name; // "Término de la carne", "Ingredientes"
  final String type; // "single" o "multiple"
  final bool required; // ¿Es obligatorio seleccionar?
  final List<ModifierOption> options;

  ProductModifier({
    required this.id,
    required this.name,
    required this.type,
    required this.required,
    required this.options,
  });

  factory ProductModifier.fromMap(Map<String, dynamic> map) {
    return ProductModifier(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      required: map['required'] as bool? ?? false,
      options: (map['options'] as List<dynamic>? ?? [])
          .map((e) => ModifierOption.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'required': required,
      'options': options.map((e) => e.toMap()).toList(),
    };
  }
}

/// Opción de un modificador
class ModifierOption {
  final String id;
  final String name; // "Poco cocida", "Sin cebolla"
  final double priceModifier; // +$0, +$20, etc
  final bool available;

  ModifierOption({
    required this.id,
    required this.name,
    required this.priceModifier,
    required this.available,
  });

  factory ModifierOption.fromMap(Map<String, dynamic> map) {
    return ModifierOption(
      id: map['id'] as String,
      name: map['name'] as String,
      priceModifier: (map['priceModifier'] as num?)?.toDouble() ?? 0.0,
      available: map['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'priceModifier': priceModifier,
      'available': available,
    };
  }
}

/// Ingrediente de un item del menú (para deducción de inventario)
class MenuItemIngredient {
  final String ingredientId;
  final double quantity;
  final String unit; // "kg", "unidades", "litros"

  MenuItemIngredient({
    required this.ingredientId,
    required this.quantity,
    required this.unit,
  });

  factory MenuItemIngredient.fromMap(Map<String, dynamic> map) {
    return MenuItemIngredient(
      ingredientId: map['ingredientId'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'ingredientId': ingredientId, 'quantity': quantity, 'unit': unit};
  }
}

/// Item del menú (producto)
class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category; // "burgers", "drinks", "sides", etc
  final Section section; // Combi o Bar
  final String? imageUrl;
  final bool available;
  final List<ProductModifier> modifiers;
  final List<MenuItemIngredient> ingredients;
  final int preparationTime; // minutos
  final String branchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.section,
    this.imageUrl,
    required this.available,
    required this.modifiers,
    required this.ingredients,
    required this.preparationTime,
    required this.branchId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItemModel(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String? ?? '',
      price: (data['price'] as num).toDouble(),
      category: data['category'] as String,
      section: data['section'] != null
          ? Section.fromString(data['section'] as String)
          : Section.combi, // default
      imageUrl: data['imageUrl'] as String?,
      available: data['available'] as bool? ?? true,
      modifiers: (data['modifiers'] as List<dynamic>? ?? [])
          .map((e) => ProductModifier.fromMap(e as Map<String, dynamic>))
          .toList(),
      ingredients: (data['ingredients'] as List<dynamic>? ?? [])
          .map((e) => MenuItemIngredient.fromMap(e as Map<String, dynamic>))
          .toList(),
      preparationTime: data['preparationTime'] as int? ?? 10,
      branchId: data['branchId'] as String? ?? 'default',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'section': section.toFirestore(),
      'imageUrl': imageUrl,
      'available': available,
      'modifiers': modifiers.map((e) => e.toMap()).toList(),
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'preparationTime': preparationTime,
      'branchId': branchId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    Section? section,
    String? imageUrl,
    bool? available,
    List<ProductModifier>? modifiers,
    List<MenuItemIngredient>? ingredients,
    int? preparationTime,
    String? branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      section: section ?? this.section,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      modifiers: modifiers ?? this.modifiers,
      ingredients: ingredients ?? this.ingredients,
      preparationTime: preparationTime ?? this.preparationTime,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

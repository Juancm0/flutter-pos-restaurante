import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/features/admin/data/models/category_model.dart';

/// Stream provider para categorías del menú
final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('categories')
      .orderBy('order')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList(),
      );
});

/// Provider para categorías activas solamente
final activeCategoriesProvider = Provider<AsyncValue<List<CategoryModel>>>((
  ref,
) {
  return ref
      .watch(categoriesStreamProvider)
      .whenData((categories) => categories.where((c) => c.isActive).toList());
});

/// Provider de mapa slug -> CategoryModel para traducciones rápidas
final categoryMapProvider = Provider<Map<String, CategoryModel>>((ref) {
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  return categoriesAsync.when(
    data: (categories) => {for (var c in categories) c.slug: c},
    loading: () => {},
    error: (_, _) => {},
  );
});

/// Provider para gestión de categorías
final categoryManagementProvider = Provider<CategoryManagement>((ref) {
  return CategoryManagement();
});

/// Clase para gestionar operaciones CRUD de categorías
class CategoryManagement {
  final _collection = FirebaseFirestore.instance.collection('categories');

  /// Crear nueva categoría
  Future<bool> createCategory(String name, {String? icon}) async {
    try {
      // Obtener el máximo orden actual
      final snapshot = await _collection
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      final maxOrder = snapshot.docs.isEmpty
          ? 0
          : (snapshot.docs.first.data()['order'] as num?)?.toInt() ?? 0;

      final category = CategoryModel(
        id: '',
        name: name.trim(),
        slug: CategoryModel.generateSlug(name),
        order: maxOrder + 1,
        icon: icon,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _collection.add(category.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar categoría
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      await _collection.doc(category.id).update(category.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Eliminar categoría
  Future<bool> deleteCategory(String id) async {
    try {
      // Verificar que no haya items con esta categoría
      final menuItems = await FirebaseFirestore.instance
          .collection('menu_items') // Corregido: era 'menuItems'
          .where('category', isEqualTo: id)
          .limit(1)
          .get();

      if (menuItems.docs.isNotEmpty) {
        throw Exception(
          'No se puede eliminar: hay items usando esta categoría',
        );
      }

      await _collection.doc(id).delete();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Reordenar categorías
  Future<void> reorderCategories(List<CategoryModel> categories) async {
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < categories.length; i++) {
      batch.update(_collection.doc(categories[i].id), {'order': i});
    }

    await batch.commit();
  }

  /// Inicializar categorías por defecto si no existen
  Future<void> initializeDefaultCategories() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Ya hay categorías

    final defaults = [
      {'name': 'Entradas', 'slug': 'entradas', 'icon': '🥗'},
      {'name': 'Platos Fuertes', 'slug': 'platos_fuertes', 'icon': '🍔'},
      {'name': 'Bebidas', 'slug': 'bebidas', 'icon': '🥤'},
      {'name': 'Postres', 'slug': 'postres', 'icon': '🍰'},
      {'name': 'Acompañamientos', 'slug': 'acompañamientos', 'icon': '🍟'},
      {'name': 'Otros', 'slug': 'otros', 'icon': '📦'},
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < defaults.length; i++) {
      final docRef = _collection.doc();
      batch.set(docRef, {
        ...defaults[i],
        'order': i,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }
}

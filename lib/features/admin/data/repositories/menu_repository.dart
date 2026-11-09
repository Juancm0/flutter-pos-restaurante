import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos_restaurante/core/constants/firebase_constants.dart';
import 'package:pos_restaurante/features/waiter/data/models/menu_item_model.dart';

/// Repositorio para gestión de menú
class MenuRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener stream de items del menú
  Stream<List<MenuItemModel>> getMenuItemsStream() {
    return _firestore
        .collection(FirebaseConstants.menuItemsCollection)
        .orderBy('name') // Solo un orderBy para evitar índice compuesto
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => MenuItemModel.fromFirestore(doc))
              .toList();

          // Ordenar por categoría y luego por nombre en memoria
          items.sort((a, b) {
            final categoryCompare = a.category.compareTo(b.category);
            if (categoryCompare != 0) return categoryCompare;
            return a.name.compareTo(b.name);
          });

          return items;
        });
  }

  /// Crear item del menú
  Future<void> createMenuItem(MenuItemModel item) async {
    try {
      await _firestore
          .collection(FirebaseConstants.menuItemsCollection)
          .add(item.toFirestore());
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar item del menú
  Future<void> updateMenuItem(MenuItemModel item) async {
    try {
      await _firestore
          .collection(FirebaseConstants.menuItemsCollection)
          .doc(item.id)
          .update(item.toFirestore());
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Toggle disponibilidad
  Future<void> toggleAvailability(String itemId, bool available) async {
    try {
      await _firestore
          .collection(FirebaseConstants.menuItemsCollection)
          .doc(itemId)
          .update({'available': available});
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar item del menú
  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.menuItemsCollection)
          .doc(itemId)
          .delete();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Manejo de errores
  String _handleError(dynamic error) {
    if (error is FirebaseException) {
      return 'Error de Firestore: ${error.message}';
    }
    return 'Error desconocido: $error';
  }
}

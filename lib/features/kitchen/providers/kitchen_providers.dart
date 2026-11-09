import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos_restaurante/core/constants/firebase_constants.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';
import 'package:pos_restaurante/features/waiter/providers/order_providers.dart';

/// Provider para órdenes pendientes de COCINA (sección combi pendiente)
/// Filtra por sectionStatus.combi = 'pending'
final pendingOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.ordersCollection)
      .where('sectionStatus.combi', isEqualTo: 'pending')
      .orderBy('timestamps.created', descending: false)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
      });
});

/// Provider para órdenes pendientes (compatibilidad - usa el provider base)
final filteredPendingOrdersProvider =
    Provider.autoDispose<AsyncValue<List<OrderModel>>>((ref) {
      return ref.watch(pendingOrdersProvider);
    });

/// Provider para órdenes en preparación de COCINA (sección combi en preparación)
/// Filtra por sectionStatus.combi = 'preparing'
final preparingOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.ordersCollection)
      .where('sectionStatus.combi', isEqualTo: 'preparing')
      .orderBy('timestamps.created', descending: false)
      .snapshots()
      .map((snapshot) {
        final orders = snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();

        // Ordenar por urgencia (>15 min primero)
        orders.sort((a, b) {
          final aMinutes = DateTime.now()
              .difference(a.timestamps.preparing ?? a.timestamps.created)
              .inMinutes;
          final bMinutes = DateTime.now()
              .difference(b.timestamps.preparing ?? b.timestamps.created)
              .inMinutes;

          if ((aMinutes > 15 && bMinutes > 15) ||
              (aMinutes <= 15 && bMinutes <= 15)) {
            return (a.timestamps.preparing ?? a.timestamps.created).compareTo(
              b.timestamps.preparing ?? b.timestamps.created,
            );
          }
          return bMinutes > 15 ? 1 : -1;
        });

        return orders;
      });
});

/// Provider para órdenes en preparación (compatibilidad - usa el provider base)
final filteredPreparingOrdersProvider =
    Provider.autoDispose<AsyncValue<List<OrderModel>>>((ref) {
      return ref.watch(preparingOrdersProvider);
    });

/// Provider para contar órdenes pendientes (deriva de pendingOrdersProvider)
/// OPTIMIZADO: Usa Provider simple en lugar de StreamProvider para evitar streams redundantes
final pendingOrdersCountProvider = Provider.autoDispose<int>((ref) {
  return ref
      .watch(pendingOrdersProvider)
      .when(
        data: (orders) => orders.length,
        loading: () => 0,
        error: (_, _) => 0,
      );
});

/// Provider para contar órdenes en preparación (deriva de preparingOrdersProvider)
/// OPTIMIZADO: Usa Provider simple en lugar de StreamProvider
final preparingOrdersCountProvider = Provider.autoDispose<int>((ref) {
  return ref
      .watch(preparingOrdersProvider)
      .when(
        data: (orders) => orders.length,
        loading: () => 0,
        error: (_, _) => 0,
      );
});

/// Provider para acciones de cocina
final kitchenActionsProvider = Provider((ref) => KitchenActions(ref));

/// Clase que maneja las acciones de cocina
class KitchenActions {
  final Ref ref;

  KitchenActions(this.ref);

  /// Marcar sección COMBI como "en preparación"
  Future<void> startPreparing(String orderId) async {
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      await orderRepo.updateSectionStatus(orderId, 'combi', 'preparing');
    } catch (e) {
      throw Exception('Error al iniciar preparación: $e');
    }
  }

  /// Marcar sección COMBI como "lista"
  /// El estado global solo cambiará a ready si BAR también está ready
  Future<void> markAsReady(String orderId) async {
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      await orderRepo.updateSectionStatus(orderId, 'combi', 'ready');
    } catch (e) {
      throw Exception('Error al marcar orden lista: $e');
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sistema_eve/core/constants/firebase_constants.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';
import 'package:sistema_eve/features/waiter/providers/order_providers.dart';

/// Provider para órdenes pendientes de BARRA (sección bar pendiente)
/// Filtra por sectionStatus.bar = 'pending'
final barPendingOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.ordersCollection)
      .where('sectionStatus.bar', isEqualTo: 'pending')
      .orderBy('timestamps.created', descending: false)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
      });
});

/// Provider para órdenes en preparación de BARRA (sección bar en preparación)
/// Filtra por sectionStatus.bar = 'preparing'
final barPreparingOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>(
  (ref) {
    return FirebaseFirestore.instance
        .collection(FirebaseConstants.ordersCollection)
        .where('sectionStatus.bar', isEqualTo: 'preparing')
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
  },
);

/// Provider para contar órdenes pendientes de bar
/// OPTIMIZADO: Usa Provider simple en lugar de StreamProvider
final barPendingOrdersCountProvider = Provider.autoDispose<int>((ref) {
  return ref
      .watch(barPendingOrdersProvider)
      .when(
        data: (orders) => orders.length,
        loading: () => 0,
        error: (_, _) => 0,
      );
});

/// Provider para contar órdenes en preparación de bar
/// OPTIMIZADO: Usa Provider simple en lugar de StreamProvider
final barPreparingOrdersCountProvider = Provider.autoDispose<int>((ref) {
  return ref
      .watch(barPreparingOrdersProvider)
      .when(
        data: (orders) => orders.length,
        loading: () => 0,
        error: (_, _) => 0,
      );
});

/// Provider para acciones de barra
final barActionsProvider = Provider((ref) => BarActions(ref));

/// Clase que maneja las acciones de la barra
class BarActions {
  final Ref ref;

  BarActions(this.ref);

  /// Marcar sección BAR como "en preparación"
  Future<void> startPreparing(String orderId) async {
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      await orderRepo.updateSectionStatus(orderId, 'bar', 'preparing');
    } catch (e) {
      throw Exception('Error al iniciar preparación: $e');
    }
  }

  /// Marcar sección BAR como "lista"
  /// El estado global solo cambiará a ready si COMBI también está ready
  Future<void> markAsReady(String orderId) async {
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      await orderRepo.updateSectionStatus(orderId, 'bar', 'ready');
    } catch (e) {
      throw Exception('Error al marcar orden lista: $e');
    }
  }
}

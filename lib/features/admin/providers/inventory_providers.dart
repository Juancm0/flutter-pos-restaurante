import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/features/admin/data/models/inventory_item_model.dart';
import 'package:sistema_eve/features/admin/data/repositories/inventory_repository.dart';

/// Provider del repositorio
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

/// Provider del stream de items de inventario
final inventoryItemsStreamProvider = StreamProvider<List<InventoryItemModel>>((
  ref,
) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getInventoryItemsStream();
});

/// Provider para items con stock bajo
final lowStockItemsProvider = Provider<List<InventoryItemModel>>((ref) {
  final itemsAsync = ref.watch(inventoryItemsStreamProvider);
  return itemsAsync.when(
    data: (items) =>
        items.where((item) => item.stockStatus != 'sufficient').toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Estado para operaciones CRUD
class InventoryManagementState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const InventoryManagementState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  InventoryManagementState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return InventoryManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

/// Notifier para operaciones CRUD de inventario
class InventoryManagementNotifier
    extends StateNotifier<InventoryManagementState> {
  final InventoryRepository _repository;

  InventoryManagementNotifier(this._repository)
    : super(const InventoryManagementState());

  /// Crear item
  Future<bool> createItem(InventoryItemModel item) async {
    state = const InventoryManagementState(isLoading: true);

    try {
      await _repository.createItem(item);

      state = const InventoryManagementState(
        isLoading: false,
        successMessage: 'Item creado exitosamente',
      );
      return true;
    } catch (e) {
      state = InventoryManagementState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Actualizar item
  Future<bool> updateItem(InventoryItemModel item) async {
    state = const InventoryManagementState(isLoading: true);

    try {
      await _repository.updateItem(item);

      state = const InventoryManagementState(
        isLoading: false,
        successMessage: 'Item actualizado exitosamente',
      );
      return true;
    } catch (e) {
      state = InventoryManagementState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Ajustar stock
  Future<bool> adjustStock(
    String itemId,
    double amount,
    String type,
    String? reason,
  ) async {
    state = const InventoryManagementState(isLoading: true);

    try {
      await _repository.adjustStock(
        itemId: itemId,
        amount: amount,
        type: type,
        reason: reason,
      );

      state = const InventoryManagementState(
        isLoading: false,
        successMessage: 'Stock ajustado exitosamente',
      );
      return true;
    } catch (e) {
      state = InventoryManagementState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Eliminar item
  Future<bool> deleteItem(String itemId) async {
    state = const InventoryManagementState(isLoading: true);

    try {
      await _repository.deleteItem(itemId);

      state = const InventoryManagementState(
        isLoading: false,
        successMessage: 'Item eliminado exitosamente',
      );
      return true;
    } catch (e) {
      state = InventoryManagementState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Limpiar mensajes
  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

/// Provider del notifier
final inventoryManagementProvider =
    StateNotifierProvider<
      InventoryManagementNotifier,
      InventoryManagementState
    >((ref) {
      final repository = ref.watch(inventoryRepositoryProvider);
      return InventoryManagementNotifier(repository);
    });

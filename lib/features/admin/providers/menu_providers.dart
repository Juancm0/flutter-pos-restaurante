import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/features/admin/data/repositories/menu_repository.dart';
import 'package:sistema_eve/features/waiter/data/models/menu_item_model.dart';

/// Provider del repositorio
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository();
});

/// Provider del stream de items del menú
final menuItemsListProvider = StreamProvider<List<MenuItemModel>>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  return repository.getMenuItemsStream();
});

/// Alias para compatibilidad
final menuItemsStreamProvider = menuItemsListProvider;

/// Estado para operaciones CRUD
class MenuManagementState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const MenuManagementState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  MenuManagementState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return MenuManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

/// Notifier para operaciones CRUD de menú
class MenuManagementNotifier extends StateNotifier<MenuManagementState> {
  final MenuRepository _repository;

  MenuManagementNotifier(this._repository) : super(const MenuManagementState());

  /// Crear item
  Future<bool> createMenuItem(MenuItemModel item) async {
    state = const MenuManagementState(isLoading: true);

    try {
      await _repository.createMenuItem(item);

      state = const MenuManagementState(
        isLoading: false,
        successMessage: 'Item creado exitosamente',
      );
      return true;
    } catch (e) {
      state = MenuManagementState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Actualizar item
  Future<bool> updateMenuItem(MenuItemModel item) async {
    state = const MenuManagementState(isLoading: true);

    try {
      await _repository.updateMenuItem(item);

      state = const MenuManagementState(
        isLoading: false,
        successMessage: 'Item actualizado exitosamente',
      );
      return true;
    } catch (e) {
      state = MenuManagementState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Toggle disponibilidad
  Future<bool> toggleAvailability(String itemId, bool available) async {
    state = const MenuManagementState(isLoading: true);

    try {
      await _repository.toggleAvailability(itemId, available);

      state = MenuManagementState(
        isLoading: false,
        successMessage: available ? 'Item disponible' : 'Item no disponible',
      );
      return true;
    } catch (e) {
      state = MenuManagementState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Eliminar item
  Future<bool> deleteMenuItem(String itemId) async {
    state = const MenuManagementState(isLoading: true);

    try {
      await _repository.deleteMenuItem(itemId);

      state = const MenuManagementState(
        isLoading: false,
        successMessage: 'Item eliminado exitosamente',
      );
      return true;
    } catch (e) {
      state = MenuManagementState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Limpiar mensajes
  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

/// Provider del notifier
final menuManagementProvider =
    StateNotifierProvider<MenuManagementNotifier, MenuManagementState>((ref) {
      final repository = ref.watch(menuRepositoryProvider);
      return MenuManagementNotifier(repository);
    });

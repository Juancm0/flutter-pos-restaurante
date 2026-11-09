import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/features/admin/data/repositories/user_management_repository.dart';
import 'package:pos_restaurante/features/auth/data/models/user_model.dart';

/// Provider del repositorio
final userManagementRepositoryProvider = Provider<UserManagementRepository>((
  ref,
) {
  return UserManagementRepository();
});

/// Provider del stream de usuarios
final usersListProvider = StreamProvider<List<UserModel>>((ref) {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.getUsersStream();
});

/// Estado para operaciones CRUD
class UserManagementState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const UserManagementState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  UserManagementState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return UserManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

/// Notifier para operaciones CRUD de usuarios
class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final UserManagementRepository _repository;

  UserManagementNotifier(this._repository) : super(const UserManagementState());

  /// Crear usuario
  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required String branchId,
  }) async {
    state = const UserManagementState(isLoading: true);

    try {
      await _repository.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
        branchId: branchId,
      );

      state = const UserManagementState(
        isLoading: false,
        successMessage: 'Usuario creado exitosamente',
      );
      return true;
    } catch (e) {
      state = UserManagementState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Actualizar usuario
  Future<bool> updateUser(UserModel user) async {
    state = const UserManagementState(isLoading: true);

    try {
      await _repository.updateUser(user);

      state = const UserManagementState(
        isLoading: false,
        successMessage: 'Usuario actualizado exitosamente',
      );
      return true;
    } catch (e) {
      state = UserManagementState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Activar/Desactivar usuario
  Future<bool> toggleUserActive(String userId, bool active) async {
    state = const UserManagementState(isLoading: true);

    try {
      await _repository.toggleUserActive(userId, active);

      state = UserManagementState(
        isLoading: false,
        successMessage: active
            ? 'Usuario activado exitosamente'
            : 'Usuario desactivado exitosamente',
      );
      return true;
    } catch (e) {
      state = UserManagementState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Eliminar usuario
  Future<bool> deleteUser(String userId) async {
    state = const UserManagementState(isLoading: true);

    try {
      await _repository.deleteUser(userId);

      state = const UserManagementState(
        isLoading: false,
        successMessage: 'Usuario eliminado exitosamente',
      );
      return true;
    } catch (e) {
      state = UserManagementState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Limpiar mensajes
  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

/// Provider del notifier
final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
      final repository = ref.watch(userManagementRepositoryProvider);
      return UserManagementNotifier(repository);
    });

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

/// Provider del repositorio de autenticación
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider del estado de autenticación (Firebase User)
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider del UserModel actual
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  // Watch authStateProvider para que se invalide cuando cambia el usuario
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      final authRepository = ref.watch(authRepositoryProvider);
      return authRepository.getUserDataStream();
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

/// Estado del login
class LoginState {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({this.isLoading = false, this.errorMessage});

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier para el login
class LoginNotifier extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  LoginNotifier(this._authRepository, this._ref) : super(const LoginState());

  /// Login con email y contraseña
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    state = const LoginState(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      state = const LoginState(isLoading: false, errorMessage: null);
      return user;
    } catch (e) {
      state = LoginState(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _authRepository.signOut();

    // Invalidar providers para limpiar cache
    _ref.invalidate(currentUserProvider);
    _ref.invalidate(authStateProvider);

    // Resetear estado completamente
    state = const LoginState();
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Resetear estado completamente
  void reset() {
    state = const LoginState();
  }
}

/// Provider del LoginNotifier
final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginNotifier(authRepository, ref);
});

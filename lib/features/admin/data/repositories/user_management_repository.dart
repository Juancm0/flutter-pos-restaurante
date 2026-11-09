import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sistema_eve/core/constants/firebase_constants.dart';
import 'package:sistema_eve/features/auth/data/models/user_model.dart';

/// Repositorio para gestión de usuarios (Admin)
class UserManagementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtener stream de todos los usuarios
  Stream<List<UserModel>> getUsersStream() {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Crear nuevo usuario (Authentication + Firestore)
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required String branchId,
  }) async {
    try {
      // Guardar credenciales del admin actual
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'No hay sesión de administrador activa';
      }

      // **IMPORTANTE**: Esto hará logout temporal del admin
      // 1. Crear usuario en Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Crear documento en Firestore
      final userModel = UserModel(
        id: uid,
        email: email,
        name: name,
        role: role,
        branchId: branchId,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .set(userModel.toFirestore());

      // 3. Hacer logout del usuario recién creado
      await _auth.signOut();

      // 4. Restaurar sesión del admin
      // Nota: El admin tendrá que volver a iniciar sesión manualmente
      // Esta es una limitación de Firebase Auth en Flutter
      // Una solución mejor sería usar Firebase Admin SDK con Cloud Functions
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar usuario existente
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.id)
          .update({
            ...user.toFirestore(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Activar/Desactivar usuario
  Future<void> toggleUserActive(String userId, bool active) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
            'active': active,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar usuario (solo Firestore, no Authentication)
  Future<void> deleteUser(String userId) async {
    try {
      // Solo marcar como inactivo o eliminar de Firestore
      // No eliminamos de Authentication por seguridad
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Manejo de errores
  String _handleError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'El correo electrónico ya está en uso';
        case 'invalid-email':
          return 'Correo electrónico inválido';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres';
        default:
          return 'Error de autenticación: ${error.message}';
      }
    } else if (error is FirebaseException) {
      return 'Error de Firestore: ${error.message}';
    }
    return 'Error desconocido: $error';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pos_restaurante/core/constants/firebase_constants.dart';
import 'package:pos_restaurante/features/auth/data/models/user_model.dart';

/// Repositorio de autenticación
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Usuario actual
  User? get currentUser => _auth.currentUser;

  /// Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login con email y contraseña
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtener datos del usuario desde Firestore
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        throw 'Usuario no encontrado en la base de datos';
      }

      return UserModel.fromFirestore(doc.data()!, doc.id);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Error de autenticación: $e';
    }
  }

  /// Obtener datos del usuario actual
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Stream de datos del usuario actual
  Stream<UserModel?> getUserDataStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc.data()!, doc.id);
        });
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Manejo de errores de autenticación
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}

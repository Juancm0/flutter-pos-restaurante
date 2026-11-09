import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sistema_eve/core/constants/firebase_constants.dart';
import 'package:sistema_eve/features/admin/data/models/table_model.dart';

/// Repositorio para gestión de mesas
class TableRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener stream de mesas
  Stream<List<TableModel>> getTablesStream() {
    return _firestore
        .collection(FirebaseConstants.tablesCollection)
        .orderBy('tableNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TableModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Crear mesa
  Future<void> createTable(TableModel table) async {
    await _firestore
        .collection(FirebaseConstants.tablesCollection)
        .add(table.toFirestore());
  }

  /// Actualizar mesa
  Future<void> updateTable(TableModel table) async {
    await _firestore
        .collection(FirebaseConstants.tablesCollection)
        .doc(table.id)
        .update(table.toFirestore());
  }

  /// Actualizar estado
  Future<void> updateTableStatus(
    String tableId,
    String status, {
    String? orderId,
  }) async {
    await _firestore
        .collection(FirebaseConstants.tablesCollection)
        .doc(tableId)
        .update({
          'status': status,
          if (orderId != null) 'currentOrderId': orderId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Obtener mesa por número y sección
  /// section debe ser el name del enum Section ('combi' o 'bar')
  Future<TableModel?> getTableByNumberAndSection(
    int tableNumber,
    String section,
  ) async {
    // Query por tableNumber y filtrar localmente por sección
    // (esto evita necesitar índice compuesto en Firestore)
    final querySnapshot = await _firestore
        .collection(FirebaseConstants.tablesCollection)
        .where('tableNumber', isEqualTo: tableNumber)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    // Filtrar localmente por sección
    final matchingDocs = querySnapshot.docs.where((doc) {
      final data = doc.data();
      return data['section'] == section;
    }).toList();

    if (matchingDocs.isEmpty) {
      return null;
    }

    return TableModel.fromFirestore(matchingDocs.first);
  }

  /// Obtener mesa por número (legacy - busca la primera que encuentre)
  Future<TableModel?> getTableByNumber(int tableNumber) async {
    final querySnapshot = await _firestore
        .collection(FirebaseConstants.tablesCollection)
        .where('tableNumber', isEqualTo: tableNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return TableModel.fromFirestore(querySnapshot.docs.first);
  }

  /// Eliminar mesa
  Future<void> deleteTable(String tableId) async {
    await _firestore
        .collection(FirebaseConstants.tablesCollection)
        .doc(tableId)
        .delete();
  }
}

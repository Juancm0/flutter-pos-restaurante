import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/features/admin/data/models/table_model.dart';
import 'package:pos_restaurante/features/admin/data/repositories/table_repository.dart';

final tableRepositoryProvider = Provider<TableRepository>(
  (ref) => TableRepository(),
);

final tablesStreamProvider = StreamProvider<List<TableModel>>((ref) {
  final repository = ref.watch(tableRepositoryProvider);
  return repository.getTablesStream();
});

class TableManagementState {
  final bool isLoading;
  final String? errorMessage;

  const TableManagementState({this.isLoading = false, this.errorMessage});

  TableManagementState copyWith({bool? isLoading, String? errorMessage}) =>
      TableManagementState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class TableManagementNotifier extends StateNotifier<TableManagementState> {
  final TableRepository _repository;

  TableManagementNotifier(this._repository)
    : super(const TableManagementState());

  Future<bool> createTable(TableModel table) async {
    state = const TableManagementState(isLoading: true);
    try {
      await _repository.createTable(table);
      state = const TableManagementState();
      return true;
    } catch (e) {
      state = TableManagementState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateTable(TableModel table) async {
    state = const TableManagementState(isLoading: true);
    try {
      await _repository.updateTable(table);
      state = const TableManagementState();
      return true;
    } catch (e) {
      state = TableManagementState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteTable(String tableId) async {
    try {
      await _repository.deleteTable(tableId);
      return true;
    } catch (e) {
      state = TableManagementState(errorMessage: e.toString());
      return false;
    }
  }
}

final tableManagementProvider =
    StateNotifierProvider<TableManagementNotifier, TableManagementState>((ref) {
      final repository = ref.watch(tableRepositoryProvider);
      return TableManagementNotifier(repository);
    });

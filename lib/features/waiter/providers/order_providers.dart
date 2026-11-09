import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/firebase_constants.dart';
import 'package:sistema_eve/core/utils/prep_time_calculator.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';
import 'package:sistema_eve/features/waiter/data/repositories/order_repository.dart';
import 'package:sistema_eve/features/admin/providers/inventory_providers.dart';
import 'package:sistema_eve/features/admin/providers/table_providers.dart';
import 'package:sistema_eve/features/auth/providers/auth_providers.dart';

/// Provider del OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(
    inventoryRepository: ref.watch(inventoryRepositoryProvider),
    tableRepository: ref.watch(tableRepositoryProvider),
  );
});

/// Stream de órdenes del mesero actual
final myOrdersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) {
        return Stream.value([]);
      }
      final repository = ref.watch(orderRepositoryProvider);
      return repository.getMyOrders(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

/// Stream de órdenes para llevar del mesero actual
/// OPTIMIZADO: Filtra del stream principal en lugar de hacer query separada
final myTakeoutOrdersStreamProvider = Provider<AsyncValue<List<OrderModel>>>((
  ref,
) {
  final ordersAsync = ref.watch(myOrdersStreamProvider);
  return ordersAsync.whenData((orders) {
    return orders.where((o) => o.orderType == OrderType.takeout).toList();
  });
});

/// Stream de todas las órdenes (para cocina/cajero)
final allOrdersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getAllOrders();
});

/// Stream de una orden específica por ID
final orderByIdProvider = StreamProvider.family<OrderModel, String>((
  ref,
  orderId,
) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});

/// Provider para filtrar órdenes por estado
final ordersByStatusProvider = Provider.family<List<OrderModel>, OrderStatus>((
  ref,
  status,
) {
  final ordersAsync = ref.watch(myOrdersStreamProvider);

  return ordersAsync.when(
    data: (orders) => orders.where((order) => order.status == status).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Órdenes pendientes
final pendingOrdersProvider = Provider<List<OrderModel>>((ref) {
  return ref.watch(ordersByStatusProvider(OrderStatus.pending));
});

/// Órdenes en preparación
final preparingOrdersProvider = Provider<List<OrderModel>>((ref) {
  return ref.watch(ordersByStatusProvider(OrderStatus.preparing));
});

/// Órdenes listas para servir
final readyOrdersProvider = Provider<List<OrderModel>>((ref) {
  return ref.watch(ordersByStatusProvider(OrderStatus.ready));
});

/// Estado de creación de orden
class CreateOrderState {
  final bool isLoading;
  final String? error;
  final List<OrderItem> items;
  final int? tableNumber;
  final String? tableSection; // 'combi' o 'bar'
  final String notes;
  final String customerName;
  final String customerPhone;

  CreateOrderState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.tableNumber,
    this.tableSection,
    this.notes = '',
    this.customerName = '',
    this.customerPhone = '',
  });

  CreateOrderState copyWith({
    bool? isLoading,
    String? error,
    List<OrderItem>? items,
    int? tableNumber,
    String? tableSection,
    String? notes,
    String? customerName,
    String? customerPhone,
  }) {
    return CreateOrderState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      tableNumber: tableNumber ?? this.tableNumber,
      tableSection: tableSection ?? this.tableSection,
      notes: notes ?? this.notes,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }

  double get subtotal {
    return items.fold(0.0, (total, item) => total + item.totalPrice);
  }

  double get total =>
      subtotal; // Aquí se pueden agregar propinas, descuentos, etc.

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  /// Tiempo estimado de preparación considerando cantidades
  /// Usa multiplicador de +30% por cada item adicional
  int get estimatedPrepTime {
    return PrepTimeCalculator.calculateEstimatedTime(items);
  }
}

/// Notifier para crear/editar órdenes
class CreateOrderNotifier extends StateNotifier<CreateOrderState> {
  final OrderRepository _repository;
  final Ref _ref;

  CreateOrderNotifier(this._repository, this._ref) : super(CreateOrderState());

  /// Establecer mesa y sección para la orden
  void setTable(int tableNumber, {String? section}) {
    state = state.copyWith(tableNumber: tableNumber, tableSection: section);
  }

  /// Establecer nombre del cliente
  void setCustomerName(String name) {
    state = state.copyWith(customerName: name);
  }

  /// Establecer teléfono del cliente (para órdenes para llevar)
  void setCustomerPhone(String phone) {
    state = state.copyWith(customerPhone: phone);
  }

  /// Agregar item a la orden
  void addItem(OrderItem item) {
    // Verificar si el item ya existe
    final existingIndex = state.items.indexWhere(
      (i) => i.menuItemId == item.menuItemId,
    );

    if (existingIndex >= 0) {
      // Incrementar cantidad creando nuevo OrderItem
      final existingItem = state.items[existingIndex];
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = OrderItem(
        menuItemId: existingItem.menuItemId,
        menuItemName: existingItem.menuItemName,
        section: existingItem.section,
        quantity: existingItem.quantity + item.quantity,
        price: existingItem.price,
        selectedModifiers: existingItem.selectedModifiers,
        notes: existingItem.notes,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Agregar nuevo item
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  /// Actualizar cantidad de un item
  void updateItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }

    final updatedItems = [...state.items];
    final oldItem = updatedItems[index];
    updatedItems[index] = OrderItem(
      menuItemId: oldItem.menuItemId,
      menuItemName: oldItem.menuItemName,
      section: oldItem.section,
      quantity: newQuantity,
      price: oldItem.price,
      selectedModifiers: oldItem.selectedModifiers,
      notes: oldItem.notes,
    );
    state = state.copyWith(items: updatedItems);
  }

  /// Eliminar item
  void removeItem(int index) {
    final updatedItems = [...state.items];
    updatedItems.removeAt(index);
    state = state.copyWith(items: updatedItems);
  }

  /// Actualizar notas
  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  /// Limpiar orden
  void clear() {
    state = CreateOrderState();
  }

  /// Confirmar orden (crear en Firestore)
  Future<String?> confirmOrder({OrderType orderType = OrderType.dineIn}) async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Debe agregar al menos un item');
      return null;
    }

    // Solo validar mesa si NO es takeout
    if (orderType == OrderType.dineIn && state.tableNumber == null) {
      state = state.copyWith(error: 'Debe seleccionar una mesa');
      return null;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final userAsync = _ref.read(currentUserProvider);
      final user = userAsync.when(
        data: (user) => user,
        loading: () => null,
        error: (_, _) => null,
      );

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Calcular secciones activas de los items
      final activeSections = state.items
          .map((item) => item.section)
          .toSet()
          .toList();

      // Inicializar estado de cada sección como 'pending'
      final sectionStatus = Map<String, String>.fromEntries(
        activeSections.map((section) => MapEntry(section, 'pending')),
      );

      // Crear modelo de orden
      final order = OrderModel(
        id: '', // Se generará en Firestore
        orderNumber: '', // Se generará en repository
        status: OrderStatus.pending,
        orderType: orderType,
        tableNumber: orderType == OrderType.dineIn ? state.tableNumber : null,
        tableSection: orderType == OrderType.dineIn ? state.tableSection : null,
        customerName: state.customerName.isEmpty ? null : state.customerName,
        customerPhone: state.customerPhone.isEmpty ? null : state.customerPhone,
        items: state.items,
        subtotal: state.subtotal,
        total: state.total,
        paymentMethod: null, // Se asignará al pagar
        createdBy: user.id,
        createdByName: user.name,
        shiftId: null, // TODO: Implementar shifts
        branchId: 'default',
        activeSections: activeSections,
        sectionStatus: sectionStatus,
        timestamps: OrderTimestamps(created: DateTime.now()),
        updatedAt: DateTime.now(),
      );

      final orderId = await _repository.createOrder(order);

      // Limpiar estado después de crear
      clear();

      state = state.copyWith(isLoading: false);
      return orderId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Cargar orden existente para edición
  void loadOrderForEdit(OrderModel order) {
    state = CreateOrderState(
      items: order.items,
      tableNumber: order.tableNumber,
      customerName: order.customerName ?? '',
      customerPhone: order.customerPhone ?? '',
    );
  }

  /// Actualizar orden existente
  Future<bool> updateExistingOrder(String orderId, OrderType orderType) async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Debe agregar al menos un item');
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Calcular totales
      final subtotal = state.subtotal;
      final total = state.total;

      // Actualizar solo los campos editables
      await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update({
            'items': state.items.map((e) => e.toMap()).toList(),
            'customerName': state.customerName.isEmpty
                ? null
                : state.customerName,
            'customerPhone': state.customerPhone.isEmpty
                ? null
                : state.customerPhone,
            'subtotal': subtotal,
            'total': total,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      clear();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Referencia a Firestore para updates
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
}

/// Provider del notifier de creación de orden
final createOrderProvider =
    StateNotifierProvider<CreateOrderNotifier, CreateOrderState>((ref) {
      return CreateOrderNotifier(ref.watch(orderRepositoryProvider), ref);
    });

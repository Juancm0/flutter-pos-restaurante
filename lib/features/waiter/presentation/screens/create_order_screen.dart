import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/features/waiter/data/models/menu_item_model.dart';
import 'package:sistema_eve/features/admin/providers/menu_providers.dart';
import 'package:sistema_eve/features/admin/providers/category_providers.dart';
import 'package:sistema_eve/features/waiter/data/models/order_model.dart';
import 'package:sistema_eve/features/waiter/providers/order_providers.dart';
import 'package:sistema_eve/core/widgets/app_text_field.dart';
import 'package:sistema_eve/features/waiter/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:sistema_eve/features/waiter/presentation/widgets/create_order_floating_bar.dart';
import 'package:sistema_eve/features/waiter/presentation/widgets/menu_item_card.dart';
import 'package:sistema_eve/features/waiter/presentation/widgets/order_summary_sheet.dart';

/// Pantalla para crear una nueva orden - Diseño "Sandwich" UI
/// 1. Encabezado fijo con inputs colapsables
/// 2. Cuerpo central con menú scrolleable
/// 3. Barra inferior flotante con resumen
class CreateOrderScreen extends ConsumerStatefulWidget {
  final int? tableNumber;
  final String? tableSection;
  final OrderModel? orderToEdit;

  const CreateOrderScreen({
    super.key,
    this.tableNumber,
    this.tableSection,
    this.orderToEdit,
  });

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  String _selectedCategory = 'Todos';
  String? _selectedSection;

  // Controllers para inputs de cliente
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // Scroll controller para detectar colapso del header
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderCollapsed = false;

  bool get isEditMode => widget.orderToEdit != null;
  bool get isTakeout => widget.tableNumber == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditMode) {
        ref
            .read(createOrderProvider.notifier)
            .loadOrderForEdit(widget.orderToEdit!);
        _nameController.text = widget.orderToEdit!.customerName ?? '';
        _phoneController.text = widget.orderToEdit!.customerPhone ?? '';
      } else {
        ref.read(createOrderProvider.notifier).clear();
        if (widget.tableNumber != null) {
          ref
              .read(createOrderProvider.notifier)
              .setTable(widget.tableNumber!, section: widget.tableSection);
        }
      }
    });
  }

  void _onScroll() {
    final shouldCollapse = _scrollController.offset > 60;
    if (shouldCollapse != _isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = shouldCollapse);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    if (!isEditMode) {
      ref.read(createOrderProvider.notifier).clear();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuItemsAsync = ref.watch(menuItemsStreamProvider);
    final orderState = ref.watch(createOrderProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ========== 1. ENCABEZADO FIJO ==========
            _buildHeader(orderState),

            // ========== 2. CUERPO CENTRAL ==========
            Expanded(
              child: menuItemsAsync.when(
                data: (menuItems) => _buildMenuBody(menuItems),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),

            // ========== 3. BARRA INFERIOR FLOTANTE ==========
            if (orderState.itemCount > 0)
              CreateOrderFloatingBar(
                itemCount: orderState.itemCount,
                total: orderState.total,
                onTap: _showOrderSummary,
              ),
          ],
        ),
      ),
    );
  }

  /// Encabezado fijo con contexto y datos del cliente
  Widget _buildHeader(CreateOrderState orderState) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila 1: Navegación y título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Botón atrás
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                ),
                // Icono contextual
                Icon(
                  isEditMode
                      ? Icons.edit
                      : (isTakeout
                            ? Icons.shopping_bag
                            : Icons.table_restaurant),
                  size: 22,
                  color: AppColors.waiterPrimary,
                ),
                const SizedBox(width: 8),
                // Título
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Al tocar el título, expandir/colapsar header
                      if (_isHeaderCollapsed) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(
                      isEditMode
                          ? 'Editar Orden #${widget.orderToEdit!.orderNumber}'
                          : (isTakeout
                                ? 'Para Llevar'
                                : 'Mesa ${widget.tableNumber}'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Badge del carrito
                _buildCartBadge(orderState),
              ],
            ),
          ),

          // Fila 2: Inputs de cliente (colapsable)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isHeaderCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildCustomerInputs(),
            secondChild: const SizedBox(height: 0),
          ),
        ],
      ),
    );
  }

  /// Badge del carrito con contador y animación
  Widget _buildCartBadge(CreateOrderState orderState) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          color: Colors.white,
          onPressed: orderState.itemCount > 0
              ? () => _showOrderSummary()
              : null,
        ),
        if (orderState.itemCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(orderState.itemCount),
              tween: Tween(begin: 1.3, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${orderState.itemCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Inputs de cliente (Nombre + Teléfono para takeout, solo Nombre para mesa)
  ///
  /// Usa AppTextField (mismo fondo oscuro, mismo borde azul de foco que
  /// tenía el TextField manual: AppColors.info == AppColors.waiterPrimary).
  Widget _buildCustomerInputs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          // Campo Nombre
          Expanded(
            child: AppTextField(
              controller: _nameController,
              hint: 'Nombre del cliente',
              prefixIcon: Icon(
                Icons.person_outline,
                color: Colors.grey.shade500,
                size: 20,
              ),
              onChanged: (value) {
                ref.read(createOrderProvider.notifier).setCustomerName(value);
              },
            ),
          ),

          // Campo Teléfono (solo para takeout)
          if (isTakeout) ...[
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: _phoneController,
                hint: 'Teléfono',
                keyboardType: TextInputType.phone,
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onChanged: (value) {
                  ref
                      .read(createOrderProvider.notifier)
                      .setCustomerPhone(value);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Cuerpo central con filtros y grid de productos
  Widget _buildMenuBody(List<MenuItemModel> menuItems) {
    final availableItems = menuItems.where((item) => item.available).toList();

    if (availableItems.isEmpty) {
      return const Center(
        child: Text(
          'No hay items disponibles en el menú',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Filtrar por sección
    var sectionFiltered = _selectedSection == null
        ? availableItems
        : availableItems
              .where((item) => item.section.name == _selectedSection)
              .toList();

    // Filtrar por categoría
    final filteredItems = _selectedCategory == 'Todos'
        ? sectionFiltered
        : sectionFiltered
              .where((item) => item.category == _selectedCategory)
              .toList();

    // Obtener categorías únicas
    final categories = {
      'Todos',
      ...availableItems.map((item) => item.category),
    };

    return Column(
      children: [
        // Filtros combinados: Sección + Categoría en una fila
        _buildCombinedFilters(categories),

        // Grid de productos
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    'No hay items en esta categoría',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    return MenuItemCard(
                      item: filteredItems[index],
                      onTap: () => _showAddItemSheet(filteredItems[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Filtros combinados: Sección + Categoría en una sola fila
  Widget _buildCombinedFilters(Set<String> categories) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Filtros de sección
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSectionChip(
                    label: 'Todo',
                    icon: Icons.apps,
                    isSelected: _selectedSection == null,
                    color: Colors.grey,
                    onTap: () => setState(() => _selectedSection = null),
                  ),
                  _buildSectionChip(
                    label: 'Combi',
                    icon: Icons.restaurant,
                    isSelected: _selectedSection == 'combi',
                    color: Colors.orange,
                    onTap: () => setState(() => _selectedSection = 'combi'),
                  ),
                  _buildSectionChip(
                    label: 'Bar',
                    icon: Icons.local_bar,
                    isSelected: _selectedSection == 'bar',
                    color: Colors.purple,
                    onTap: () => setState(() => _selectedSection = 'bar'),
                  ),
                ],
              ),
            ),
          ),

          // Separador vertical
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade700,
          ),

          // Dropdown de categoría
          Consumer(
            builder: (context, ref, _) {
              final categoryMap = ref.watch(categoryMapProvider);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    dropdownColor: AppColors.darkSurface,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: categories.map((category) {
                      final categoryModel = categoryMap[category];
                      final displayName = category == 'Todos'
                          ? 'Categoría'
                          : (categoryModel?.name ?? category);
                      final emoji = categoryModel?.icon;

                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (emoji != null) ...[
                              Text(emoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: color,
        backgroundColor: AppColors.darkSurfaceVariant,
        side: BorderSide(color: isSelected ? color : Colors.grey.shade700),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade300,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        showCheckmark: false,
      ),
    );
  }

  /// Mostrar bottom sheet para agregar item
  void _showAddItemSheet(MenuItemModel menuItem) {
    AddItemBottomSheet.show(
      context: context,
      menuItem: menuItem,
      onAdd: (quantity, notes) {
        final orderItem = OrderItem(
          menuItemId: menuItem.id,
          menuItemName: menuItem.name,
          section: menuItem.section.name,
          quantity: quantity,
          price: menuItem.price,
          notes: notes,
          selectedModifiers: const [],
        );
        ref.read(createOrderProvider.notifier).addItem(orderItem);
      },
    );
  }

  /// Mostrar sheet de resumen de orden
  void _showOrderSummary() {
    OrderSummarySheet.show(
      context: context,
      isTakeout: isTakeout,
      isEditMode: isEditMode,
      orderToEditId: widget.orderToEdit?.id,
      onConfirm: _confirmOrder,
    );
  }

  /// Confirmar y enviar la orden
  Future<void> _confirmOrder() async {
    final orderType = isTakeout ? OrderType.takeout : OrderType.dineIn;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      String? result;

      if (isEditMode) {
        final success = await ref
            .read(createOrderProvider.notifier)
            .updateExistingOrder(widget.orderToEdit!.id, orderType);
        if (success) {
          result = widget.orderToEdit!.id;
        }
      } else {
        result = await ref
            .read(createOrderProvider.notifier)
            .confirmOrder(orderType: orderType);
      }

      if (result != null && mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(isEditMode ? 'Orden actualizada' : '¡Orden enviada!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

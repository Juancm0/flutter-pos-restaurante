import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/features/waiter/data/models/menu_item_model.dart';
import 'package:pos_restaurante/features/admin/providers/menu_providers.dart';
import 'package:pos_restaurante/features/admin/providers/category_providers.dart';
import 'package:pos_restaurante/features/waiter/data/models/order_model.dart';
import 'package:pos_restaurante/features/waiter/providers/order_providers.dart';
import 'package:pos_restaurante/features/waiter/presentation/widgets/add_item_bottom_sheet.dart';

/// Pantalla para añadir items adicionales a una orden ya servida
class AddItemsScreen extends ConsumerStatefulWidget {
  final OrderModel existingOrder;

  const AddItemsScreen({super.key, required this.existingOrder});

  @override
  ConsumerState<AddItemsScreen> createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends ConsumerState<AddItemsScreen> {
  String _selectedCategory = 'Todos';
  String? _selectedSection;

  // Items a añadir (carrito temporal)
  final List<OrderItem> _newItems = [];
  bool _isProcessing = false;

  double get _newTotal =>
      _newItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice);

  int get _newItemCount =>
      _newItems.fold<int>(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    final menuItemsAsync = ref.watch(menuItemsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Body con menú
            Expanded(
              child: menuItemsAsync.when(
                data: (menuItems) => _buildMenuBody(menuItems),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),

            // Barra inferior con resumen y botón confirmar
            if (_newItems.isNotEmpty) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Icon(
                Icons.add_shopping_cart,
                color: Colors.orange,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Añadir a Orden',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.existingOrder.orderType == OrderType.takeout
                          ? 'Para Llevar - ${widget.existingOrder.customerName ?? ""}'
                          : 'Mesa ${widget.existingOrder.tableNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge del carrito
              if (_newItemCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_newItemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Info de orden existente
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Orden #${widget.existingOrder.orderNumber} • ${widget.existingOrder.items.length} items existentes • \$${widget.existingOrder.total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        // Filtros de sección
        _buildSectionFilters(),

        // Filtros de categoría
        _buildCategoryFilters(categories),

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
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    return _buildMenuItemCard(filteredItems[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionFilters() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSectionChip(
              label: 'Todos',
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

  Widget _buildCategoryFilters(Set<String> categories) {
    return Consumer(
      builder: (context, ref, _) {
        final categoryMap = ref.watch(categoryMapProvider);

        return Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final categorySlug = categories.elementAt(index);
              final isSelected = categorySlug == _selectedCategory;

              // Obtener nombre legible y emoji
              final categoryModel = categoryMap[categorySlug];
              final displayName = categorySlug == 'Todos'
                  ? 'Todos'
                  : (categoryModel?.name ?? categorySlug);
              final emoji = categoryModel?.icon;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (emoji != null) ...[
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                      ],
                      Text(displayName),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = categorySlug),
                  selectedColor: AppColors.waiterPrimary,
                  backgroundColor: AppColors.darkSurfaceVariant,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.waiterPrimary
                        : Colors.grey.shade700,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade300,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item) {
    // Verificar si ya está en el carrito temporal
    final existingIndex = _newItems.indexWhere((i) => i.menuItemId == item.id);
    final quantityInCart = existingIndex >= 0
        ? _newItems[existingIndex].quantity
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.darkSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAddItemSheet(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Info del item
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de sección + Nombre
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.section.name == 'bar'
                                ? Colors.purple.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.section.name == 'bar'
                                  ? Colors.purple.withValues(alpha: 0.5)
                                  : Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            item.section.name == 'bar'
                                ? Icons.local_bar
                                : Icons.restaurant,
                            size: 12,
                            color: item.section.name == 'bar'
                                ? Colors.purple
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Precio
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Icono agregar o cantidad en carrito
              quantityInCart > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x$quantityInCart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.success,
                        size: 28,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Resumen de items nuevos
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Items nuevos:',
                        style: TextStyle(color: Colors.orange),
                      ),
                      Text(
                        '$_newItemCount',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.orange),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Adicional a pagar:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${_newTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total orden actualizada:',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '\$${(widget.existingOrder.total + _newTotal).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Botón confirmar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _confirmAddItems,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_task),
                label: Text(
                  _isProcessing ? 'Añadiendo...' : 'AÑADIR A LA ORDEN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemSheet(MenuItemModel menuItem) {
    AddItemBottomSheet.show(
      context: context,
      menuItem: menuItem,
      onAdd: (quantity, notes) {
        setState(() {
          // Verificar si ya existe en el carrito
          final existingIndex = _newItems.indexWhere(
            (i) => i.menuItemId == menuItem.id && i.notes == notes,
          );

          if (existingIndex >= 0) {
            // Actualizar cantidad
            final existing = _newItems[existingIndex];
            _newItems[existingIndex] = existing.copyWith(
              quantity: existing.quantity + quantity,
            );
          } else {
            // Añadir nuevo item
            _newItems.add(
              OrderItem(
                menuItemId: menuItem.id,
                menuItemName: menuItem.name,
                section: menuItem.section.name,
                quantity: quantity,
                price: menuItem.price,
                notes: notes,
                selectedModifiers: const [],
                prepTime: menuItem.preparationTime,
              ),
            );
          }
        });
      },
    );
  }

  Future<void> _confirmAddItems() async {
    if (_newItems.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(orderRepositoryProvider);
      await repository.addItemsToExistingOrder(
        widget.existingOrder.id,
        _newItems,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '✅ ${_newItems.length} item(s) añadido(s) - Enviado a cocina',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

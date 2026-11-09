import 'package:flutter/material.dart';
import 'package:sistema_eve/core/constants/app_colors.dart';
import 'package:sistema_eve/features/waiter/data/models/menu_item_model.dart';

/// Bottom sheet para agregar un item al carrito con cantidad y notas
class AddItemBottomSheet extends StatefulWidget {
  final MenuItemModel menuItem;
  final int initialQuantity;
  final String? initialNotes;
  final Function(int quantity, String? notes) onAdd;

  const AddItemBottomSheet({
    super.key,
    required this.menuItem,
    this.initialQuantity = 1,
    this.initialNotes,
    required this.onAdd,
  });

  /// Método estático para mostrar el bottom sheet
  static Future<void> show({
    required BuildContext context,
    required MenuItemModel menuItem,
    int initialQuantity = 1,
    String? initialNotes,
    required Function(int quantity, String? notes) onAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemBottomSheet(
        menuItem: menuItem,
        initialQuantity: initialQuantity,
        initialNotes: initialNotes,
        onAdd: onAdd,
      ),
    );
  }

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  late int _quantity;
  late TextEditingController _notesController;
  final FocusNode _notesFocusNode = FocusNode();

  // Chips rápidos por sección
  List<String> get _quickNotes {
    // Notas para bebidas/bar
    if (widget.menuItem.section.name == 'bar') {
      return [
        'Sin hielo',
        'Con sal',
        'Bien frío',
        'Doble',
        'Con limón',
        'Sin azúcar',
      ];
    }
    // Notas para comida/combi
    return [
      'Sin cebolla',
      'Sin salsa',
      'Extra queso',
      'Término 3/4',
      'Término medio',
      'Sin picante',
    ];
  }

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _addQuickNote(String note) {
    final currentText = _notesController.text;
    if (currentText.isEmpty) {
      _notesController.text = note;
    } else if (!currentText.contains(note)) {
      _notesController.text = '$currentText, $note';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header con info del producto
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Badge de sección
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.menuItem.section.name == 'bar'
                          ? Colors.purple.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.menuItem.section.name == 'bar'
                          ? Icons.local_bar
                          : Icons.restaurant,
                      size: 20,
                      color: widget.menuItem.section.name == 'bar'
                          ? Colors.purple
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info del producto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.menuItem.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${widget.menuItem.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón cerrar
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.grey),

            // Selector de cantidad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Text(
                    '¿Cuántos?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const Spacer(),
                  // Botones de cantidad
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade700, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón menos
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12),
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.remove,
                                color: _quantity > 1
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        // Cantidad
                        Container(
                          width: 56,
                          alignment: Alignment.center,
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Botón más
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _quantity++),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(12),
                            ),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.add,
                                color: AppColors.success,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Campo de notas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notas especiales (opcional)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    focusNode: _notesFocusNode,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ej: Sin cebolla, término medio...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: AppColors.darkSurfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.waiterPrimary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            // Chips rápidos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickNotes.map((note) {
                  final isSelected = _notesController.text.contains(note);
                  return FilterChip(
                    label: Text(
                      note,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey.shade300,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _addQuickNote(note),
                    selectedColor: AppColors.waiterPrimary.withValues(alpha: 0.3),
                    backgroundColor: AppColors.darkSurfaceVariant,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.waiterPrimary
                          : Colors.grey.shade700,
                    ),
                    checkmarkColor: AppColors.waiterPrimary,
                  );
                }).toList(),
              ),
            ),

            // Subtotal y botón agregar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Subtotal
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        '\$${(widget.menuItem.price * _quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Botón agregar
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onAdd(
                          _quantity,
                          _notesController.text.isEmpty
                              ? null
                              : _notesController.text,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Agregar a la Orden',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

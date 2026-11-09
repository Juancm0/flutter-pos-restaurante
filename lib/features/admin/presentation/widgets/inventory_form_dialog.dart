import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/app_sizes.dart';
import 'package:pos_restaurante/core/widgets/app_button.dart';
import 'package:pos_restaurante/core/widgets/app_text_field.dart';
import 'package:pos_restaurante/core/utils/validators.dart';
import 'package:pos_restaurante/features/admin/data/models/inventory_item_model.dart';
import 'package:pos_restaurante/features/admin/providers/inventory_providers.dart';

/// Dialog para crear/editar items de inventario
class InventoryFormDialog extends ConsumerStatefulWidget {
  final InventoryItemModel? item;

  const InventoryFormDialog({super.key, this.item});

  @override
  ConsumerState<InventoryFormDialog> createState() =>
      _InventoryFormDialogState();
}

class _InventoryFormDialogState extends ConsumerState<InventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _currentStockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _costPerUnitController;
  late final TextEditingController _supplierController;

  String _selectedUnit = 'kg';

  bool get _isEditing => widget.item != null;

  final List<Map<String, String>> _units = [
    {'value': 'kg', 'label': 'Kilogramos (kg)'},
    {'value': 'L', 'label': 'Litros (L)'},
    {'value': 'units', 'label': 'Unidades'},
    {'value': 'pieces', 'label': 'Piezas'},
    {'value': 'g', 'label': 'Gramos (g)'},
    {'value': 'ml', 'label': 'Mililitros (ml)'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _currentStockController = TextEditingController(
      text: widget.item?.currentStock.toString() ?? '0',
    );
    _minStockController = TextEditingController(
      text: widget.item?.minStock.toString() ?? '0',
    );
    _costPerUnitController = TextEditingController(
      text: widget.item?.costPerUnit.toStringAsFixed(2) ?? '0.00',
    );
    _supplierController = TextEditingController(
      text: widget.item?.supplier ?? '',
    );

    if (widget.item != null) {
      _selectedUnit = widget.item!.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _costPerUnitController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final item = InventoryItemModel(
      id: widget.item?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      unit: _selectedUnit,
      currentStock: double.parse(_currentStockController.text),
      minStock: double.parse(_minStockController.text),
      costPerUnit: double.parse(_costPerUnitController.text),
      supplier: _supplierController.text.trim().isEmpty
          ? null
          : _supplierController.text.trim(),
      lastUpdated: now,
      branchId: widget.item?.branchId ?? 'main',
    );

    bool success;
    if (_isEditing) {
      success = await ref
          .read(inventoryManagementProvider.notifier)
          .updateItem(item);
    } else {
      success = await ref
          .read(inventoryManagementProvider.notifier)
          .createItem(item);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Item de inventario actualizado'
                : 'Item de inventario creado',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final state = ref.read(inventoryManagementProvider);
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryManagementProvider);

    return AlertDialog(
      title: Text(
        _isEditing ? 'Editar Item de Inventario' : 'Nuevo Item de Inventario',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre
                AppTextField(
                  controller: _nameController,
                  label: 'Nombre del Item',
                  hint: 'Ej: Carne de res',
                  prefixIcon: const Icon(Icons.inventory_2),
                  validator: Validators.required,
                  enabled: !state.isLoading,
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Unidad de medida
                DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unidad de Medida',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  items: _units.map((unit) {
                    return DropdownMenuItem(
                      value: unit['value'],
                      child: Text(unit['label']!),
                    );
                  }).toList(),
                  onChanged: state.isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUnit = value;
                            });
                          }
                        },
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Stock actual y mínimo
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _currentStockController,
                        label: 'Stock Actual',
                        hint: '0',
                        prefixIcon: const Icon(Icons.inventory),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          final stock = double.tryParse(value);
                          if (stock == null || stock < 0) {
                            return 'Inválido';
                          }
                          return null;
                        },
                        enabled: !state.isLoading,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: AppTextField(
                        controller: _minStockController,
                        label: 'Stock Mínimo',
                        hint: '0',
                        prefixIcon: const Icon(Icons.warning),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          final stock = double.tryParse(value);
                          if (stock == null || stock < 0) {
                            return 'Inválido';
                          }
                          return null;
                        },
                        enabled: !state.isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Costo por unidad
                AppTextField(
                  controller: _costPerUnitController,
                  label: 'Costo por Unidad',
                  hint: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el costo';
                    }
                    final cost = double.tryParse(value);
                    if (cost == null || cost < 0) {
                      return 'Costo inválido';
                    }
                    return null;
                  },
                  enabled: !state.isLoading,
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Proveedor (opcional)
                AppTextField(
                  controller: _supplierController,
                  label: 'Proveedor (Opcional)',
                  hint: 'Nombre del proveedor',
                  prefixIcon: const Icon(Icons.store),
                  enabled: !state.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton(
          text: _isEditing ? 'Actualizar' : 'Crear',
          onPressed: state.isLoading ? null : _handleSave,
          isLoading: state.isLoading,
          type: AppButtonType.primary,
        ),
      ],
    );
  }
}

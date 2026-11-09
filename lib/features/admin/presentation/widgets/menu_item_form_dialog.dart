import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/app_sizes.dart';
import 'package:pos_restaurante/core/constants/sections.dart';
import 'package:pos_restaurante/core/widgets/app_button.dart';
import 'package:pos_restaurante/core/widgets/app_text_field.dart';
import 'package:pos_restaurante/core/utils/validators.dart';
import 'package:pos_restaurante/features/admin/providers/menu_providers.dart';
import 'package:pos_restaurante/features/admin/providers/inventory_providers.dart';
import 'package:pos_restaurante/features/admin/providers/category_providers.dart';
import 'package:pos_restaurante/features/waiter/data/models/menu_item_model.dart';

/// Dialog para crear/editar items del menú
class MenuItemFormDialog extends ConsumerStatefulWidget {
  final MenuItemModel? menuItem;

  const MenuItemFormDialog({super.key, this.menuItem});

  @override
  ConsumerState<MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends ConsumerState<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _prepTimeController;

  String? _selectedCategory;
  Section _selectedSection = Section.combi;
  bool _isAvailable = true;
  List<MenuItemIngredient> _selectedIngredients = [];

  bool get _isEditing => widget.menuItem != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menuItem?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.menuItem?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.menuItem?.price.toStringAsFixed(2) ?? '',
    );
    _prepTimeController = TextEditingController(
      text: widget.menuItem?.preparationTime.toString() ?? '10',
    );

    if (widget.menuItem != null) {
      _selectedCategory = widget.menuItem!.category;
      _selectedSection = widget.menuItem!.section;
      _isAvailable = widget.menuItem!.available;
      _selectedIngredients = List.from(widget.menuItem!.ingredients);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final menuItem = MenuItemModel(
      id: widget.menuItem?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      category: _selectedCategory ?? 'otros',
      section: _selectedSection,
      imageUrl: widget.menuItem?.imageUrl,
      available: _isAvailable,
      modifiers: widget.menuItem?.modifiers ?? [],
      ingredients: _selectedIngredients,
      preparationTime: int.parse(_prepTimeController.text),
      branchId: widget.menuItem?.branchId ?? 'main',
      createdAt: widget.menuItem?.createdAt ?? now,
      updatedAt: now,
    );

    bool success;
    if (_isEditing) {
      success = await ref
          .read(menuManagementProvider.notifier)
          .updateMenuItem(menuItem);
    } else {
      success = await ref
          .read(menuManagementProvider.notifier)
          .createMenuItem(menuItem);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Item actualizado exitosamente'
                : 'Item creado exitosamente',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final state = ref.read(menuManagementProvider);
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
    final state = ref.watch(menuManagementProvider);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar Item' : 'Nuevo Item del Menú'),
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
                  label: 'Nombre del Producto',
                  hint: 'Ej: Hamburguesa Clásica',
                  prefixIcon: const Icon(Icons.fastfood),
                  validator: Validators.required,
                  enabled: !state.isLoading,
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Descripción
                AppTextField(
                  controller: _descriptionController,
                  label: 'Descripción',
                  hint: 'Breve descripción del producto',
                  prefixIcon: const Icon(Icons.description),
                  maxLines: 3,
                  enabled: !state.isLoading,
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Precio y Tiempo de Preparación
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _priceController,
                        label: 'Precio',
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
                            return 'Ingrese el precio';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Precio inválido';
                          }
                          return null;
                        },
                        enabled: !state.isLoading,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: AppTextField(
                        controller: _prepTimeController,
                        label: 'Tiempo (min)',
                        hint: '10',
                        prefixIcon: const Icon(Icons.timer),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: Validators.required,
                        enabled: !state.isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Categoría (dinámico desde Firestore)
                Consumer(
                  builder: (context, ref, _) {
                    final categoriesAsync = ref.watch(categoriesStreamProvider);

                    return categoriesAsync.when(
                      data: (categories) {
                        // Si no hay categoría seleccionada, usar la primera
                        if (_selectedCategory == null &&
                            categories.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _selectedCategory = categories.first.slug;
                            });
                          });
                        }

                        return DropdownButtonFormField<String>(
                          // NOTA: se mantiene `value` (deprecado) porque
                          // _selectedCategory se asigna por código después
                          // del primer build (auto-selección de la primera
                          // categoría al cargar); con initialValue el campo
                          // no reflejaría ese cambio ni el validador lo vería.
                          // ignore: deprecated_member_use
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.slug,
                              child: Row(
                                children: [
                                  if (cat.icon != null) ...[
                                    Text(
                                      cat.icon!,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(cat.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: state.isLoading
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  }
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona una categoría';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error cargando categorías: $e'),
                    );
                  },
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Sección (Combi/Bar)
                DropdownButtonFormField<Section>(
                  initialValue: _selectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Sección',
                    prefixIcon: Icon(Icons.store),
                  ),
                  items: Section.values.map((section) {
                    return DropdownMenuItem(
                      value: section,
                      child: Row(
                        children: [
                          Icon(
                            section == Section.combi
                                ? Icons.restaurant
                                : Icons.local_bar,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(section.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: state.isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSection = value;
                            });
                          }
                        },
                ),

                // Disponible
                SwitchListTile(
                  title: const Text('Disponible para la venta'),
                  value: _isAvailable,
                  onChanged: state.isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _isAvailable = value;
                          });
                        },
                  activeThumbColor: AppColors.success,
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Sección de ingredientes
                _buildIngredientsSection(context, ref, state),
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

  Widget _buildIngredientsSection(BuildContext context, WidgetRef ref, state) {
    final inventoryAsync = ref.watch(inventoryItemsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_basket, size: 18), // Reducido de 20
            const SizedBox(width: 6), // Reducido de 8
            Flexible(
              child: Text(
                'Ingredientes del Inventario',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15, // Reducido para evitar overflow
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Asocia ingredientes para deducción automática de stock',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: AppSizes.spacing12),

        // Lista de ingredientes seleccionados
        if (_selectedIngredients.isNotEmpty) ...[
          ..._selectedIngredients.map((ingredient) {
            return inventoryAsync.when(
              data: (items) {
                final item = items.firstWhere(
                  (i) => i.id == ingredient.ingredientId,
                  orElse: () => items.first,
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.inventory_2, size: 20),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${ingredient.quantity} ${ingredient.unit}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedIngredients.removeWhere(
                            (i) => i.ingredientId == ingredient.ingredientId,
                          );
                        });
                      },
                      color: AppColors.error,
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Botón agregar ingrediente
        OutlinedButton.icon(
          onPressed: state.isLoading
              ? null
              : () => _showIngredientSelector(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Agregar Ingrediente'),
        ),
      ],
    );
  }

  Future<void> _showIngredientSelector(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final inventoryAsync = ref.read(inventoryItemsStreamProvider);
    final items = inventoryAsync.value ?? [];

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay items en el inventario. Agrega items primero.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        String? selectedItemId;
        final quantityController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedItem = selectedItemId != null
                ? items.firstWhere((i) => i.id == selectedItemId)
                : null;

            return AlertDialog(
              title: const Text('Seleccionar Ingrediente'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedItemId,
                    decoration: const InputDecoration(
                      labelText: 'Item de Inventario',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    items: items.map((item) {
                      return DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} (${item.unit})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedItemId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: quantityController,
                    label: selectedItem != null
                        ? 'Cantidad (${selectedItem.unit})'
                        : 'Cantidad',
                    hint: '0',
                    prefixIcon: const Icon(Icons.numbers),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedItemId == null ||
                        quantityController.text.isEmpty) {
                      return;
                    }

                    final quantity = double.tryParse(quantityController.text);
                    if (quantity == null || quantity <= 0) {
                      return;
                    }

                    final item = items.firstWhere(
                      (i) => i.id == selectedItemId,
                    );
                    setState(() {
                      _selectedIngredients.add(
                        MenuItemIngredient(
                          ingredientId: selectedItemId!,
                          quantity: quantity,
                          unit: item.unit,
                        ),
                      );
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

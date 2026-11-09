import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/app_sizes.dart';
import 'package:pos_restaurante/core/constants/sections.dart';
import 'package:pos_restaurante/core/widgets/app_button.dart';
import 'package:pos_restaurante/core/widgets/app_text_field.dart';
import 'package:pos_restaurante/features/admin/data/models/table_model.dart';
import 'package:pos_restaurante/features/admin/providers/table_providers.dart';

/// Dialog para crear/editar mesas
class TableFormDialog extends ConsumerStatefulWidget {
  final TableModel? table;

  const TableFormDialog({super.key, this.table});

  @override
  ConsumerState<TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends ConsumerState<TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tableNumberController;
  late final TextEditingController _capacityController;

  Section _selectedSection = Section.combi;
  bool _isActive = true;

  bool get _isEditing => widget.table != null;

  @override
  void initState() {
    super.initState();
    _tableNumberController = TextEditingController(
      text: widget.table?.tableNumber.toString() ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.table?.capacity.toString() ?? '4',
    );

    if (widget.table != null) {
      _selectedSection = widget.table!.section;
      _isActive = widget.table!.isActive;
    }
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final table = TableModel(
      id: widget.table?.id ?? const Uuid().v4(),
      tableNumber: int.parse(_tableNumberController.text),
      capacity: int.parse(_capacityController.text),
      section: _selectedSection,
      status: widget.table?.status ?? 'available',
      currentOrderId: widget.table?.currentOrderId,
      isActive: _isActive,
      createdAt: widget.table?.createdAt ?? now,
      updatedAt: now,
    );

    bool success;
    if (_isEditing) {
      success = await ref
          .read(tableManagementProvider.notifier)
          .updateTable(table);
    } else {
      success = await ref
          .read(tableManagementProvider.notifier)
          .createTable(table);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Mesa actualizada' : 'Mesa creada'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final state = ref.read(tableManagementProvider);
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
    final state = ref.watch(tableManagementProvider);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar Mesa' : 'Nueva Mesa'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Número de mesa y capacidad
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _tableNumberController,
                        label: 'Número de Mesa',
                        hint: '1',
                        prefixIcon: const Icon(Icons.table_restaurant),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num <= 0) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                        enabled: !state.isLoading,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing16),
                    Expanded(
                      child: AppTextField(
                        controller: _capacityController,
                        label: 'Capacidad',
                        hint: '4',
                        prefixIcon: const Icon(Icons.people),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          final capacity = int.tryParse(value);
                          if (capacity == null || capacity <= 0) {
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

                // Sección
                DropdownButtonFormField<Section>(
                  initialValue: _selectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Sección',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: Section.values.map((section) {
                    return DropdownMenuItem(
                      value: section,
                      child: Text(section.displayName),
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
                const SizedBox(height: AppSizes.spacing16),

                // Activa (solo al editar)
                if (_isEditing)
                  SwitchListTile(
                    title: const Text('Mesa Activa'),
                    subtitle: const Text(
                      'Desactivar si está fuera de servicio',
                    ),
                    value: _isActive,
                    onChanged: state.isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                    activeThumbColor: AppColors.success,
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

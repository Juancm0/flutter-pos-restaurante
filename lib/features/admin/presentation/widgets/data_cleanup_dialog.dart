import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos_restaurante/core/constants/app_colors.dart';
import 'package:pos_restaurante/core/constants/firebase_constants.dart';

/// Diálogo para limpiar datos antiguos
class DataCleanupDialog extends StatefulWidget {
  const DataCleanupDialog({super.key});

  @override
  State<DataCleanupDialog> createState() => _DataCleanupDialogState();
}

class _DataCleanupDialogState extends State<DataCleanupDialog> {
  DateTime? _selectedDate;
  final _confirmationController = TextEditingController();
  bool _isLoading = false;
  int? _ordersToDelete;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 90)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().subtract(
        const Duration(days: 30),
      ), // Min 30 días
      builder: (context, child) {
        return Theme(data: ThemeData.dark(), child: child!);
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _confirmationController.clear();
      });
      await _countOrdersToDelete();
    }
  }

  Future<void> _countOrdersToDelete() async {
    if (_selectedDate == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirebaseConstants.ordersCollection)
          .where(
            'timestamps.created',
            isLessThan: Timestamp.fromDate(_selectedDate!),
          )
          .get();

      setState(() {
        _ordersToDelete = snapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al contar órdenes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _executeCleanup() async {
    if (_selectedDate == null) return;
    if (_confirmationController.text.trim() != 'ELIMINAR') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes escribir "ELIMINAR" para confirmar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Obtener órdenes a eliminar
      final snapshot = await FirebaseFirestore.instance
          .collection(FirebaseConstants.ordersCollection)
          .where(
            'timestamps.created',
            isLessThan: Timestamp.fromDate(_selectedDate!),
          )
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay órdenes para eliminar'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      // Eliminar en batches de 500 (límite de Firestore)
      final batches = <WriteBatch>[];
      for (var i = 0; i < snapshot.docs.length; i += 500) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = snapshot.docs.skip(i).take(500);

        for (var doc in chunk) {
          batch.delete(doc.reference);
        }

        batches.add(batch);
      }

      // Ejecutar todos los batches
      await Future.wait(batches.map((batch) => batch.commit()));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${snapshot.docs.length} órdenes eliminadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete =
        _selectedDate != null &&
        _ordersToDelete != null &&
        _ordersToDelete! > 0 &&
        _confirmationController.text.trim() == 'ELIMINAR';

    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      title: const Row(
        children: [
          Icon(Icons.delete_sweep, color: Colors.orange),
          SizedBox(width: 12),
          Text('Limpieza de Datos'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ ADVERTENCIA\nEsta acción eliminará permanentemente órdenes antiguas.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Date selector
              const Text(
                'Eliminar órdenes anteriores a:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isLoading ? null : _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.adminPrimary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Seleccionar fecha'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Count
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_ordersToDelete != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Órdenes a eliminar: $_ordersToDelete',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Confirmation input
                const Text(
                  'Confirmación:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Escribe "ELIMINAR" para confirmar',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmationController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe ELIMINAR',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_selectedDate != null &&
            _ordersToDelete != null &&
            _ordersToDelete! > 0)
          ElevatedButton.icon(
            onPressed: (_isLoading || !canDelete) ? null : _executeCleanup,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever),
            label: const Text('ELIMINAR DATOS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: canDelete ? Colors.red : Colors.grey,
            ),
          ),
      ],
    );
  }
}

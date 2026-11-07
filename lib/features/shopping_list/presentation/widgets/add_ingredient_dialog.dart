import 'package:flutter/material.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../ingredients/domain/amount_unit.dart';
import '../../../ingredients/domain/ingredient.dart';

/// Modal dialog for adding a new ingredient with optional quantity, unit, and brand.
class AddIngredientDialog extends StatefulWidget {
  const AddIngredientDialog({super.key});

  /// Displays the dialog and returns the created [Ingredient], or null if canceled.
  static Future<Ingredient?> show(BuildContext context) {
    return showDialog<Ingredient>(
      context: context,
      builder: (context) => const AddIngredientDialog(),
    );
  }

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _brandController = TextEditingController();
  AmountUnit? _selectedUnit = AmountUnit.units;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final rawAmount = _amountController.text.trim();
    final amount = rawAmount.isNotEmpty ? double.tryParse(rawAmount) : null;
    final brand = _brandController.text.trim();

    final ingredient = Ingredient(
      name: name,
      brand: brand.isNotEmpty ? brand : null,
      amountValue: amount,
      amountUnit: amount != null ? _selectedUnit : null,
    );

    Navigator.of(context).pop(ingredient);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          AppSvgIcon(
            assetName: 'plus',
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Agregar ingrediente'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre del ingrediente *',
                  hintText: 'Ej. Tomate, Leche, Pollo',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del ingrediente';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        hintText: 'Ej. 2, 500',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<AmountUnit>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                      ),
                      items: AmountUnit.values.map((unit) {
                        return DropdownMenuItem<AmountUnit>(
                          value: unit,
                          child: Text(unit.pluralSpanish),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Marca (opcional)',
                  hintText: 'Ej. Trebolac, Ducal',
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

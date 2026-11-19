import 'package:flutter/material.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../ingredients/domain/ingredient.dart';

/// User selection returned by [showPantryDepletionSheet] after logging a cooked recipe.
class PantryDepletionSelection {
  const PantryDepletionSelection({
    required this.depletedIngredients,
    required this.addToShoppingList,
  });

  /// Pantry ingredients marked by the user as depleted.
  final List<Ingredient> depletedIngredients;

  /// Whether the depleted ingredients should also be added to `"Por comprar"`.
  final bool addToShoppingList;
}

/// Presents the quick post-cooking modal sheet (`"¿Qué se te acabó?"`) listing
/// the recipe's ingredients currently present in `"Mis ingredientes"`.
Future<PantryDepletionSelection?> showPantryDepletionSheet(
  BuildContext context, {
  required String recipeTitle,
  required List<Ingredient> matchingIngredients,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return showModalBottomSheet<PantryDepletionSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colorScheme.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => PantryDepletionSheet(
      recipeTitle: recipeTitle,
      matchingIngredients: matchingIngredients,
    ),
  );
}

/// Quick bottom sheet allowing one-tap selection of ingredients that ran out
/// while cooking, with direct actions to deduct them from `"Mis ingredientes"`
/// and optionally move them to `"Por comprar"`.
class PantryDepletionSheet extends StatefulWidget {
  const PantryDepletionSheet({
    super.key,
    required this.recipeTitle,
    required this.matchingIngredients,
  });

  final String recipeTitle;
  final List<Ingredient> matchingIngredients;

  @override
  State<PantryDepletionSheet> createState() => _PantryDepletionSheetState();
}

class _PantryDepletionSheetState extends State<PantryDepletionSheet> {
  final Set<String> _selectedNames = {};

  bool get _allSelected =>
      widget.matchingIngredients.isNotEmpty &&
      _selectedNames.length == widget.matchingIngredients.length;

  void _toggleItem(String name) {
    setState(() {
      if (_selectedNames.contains(name)) {
        _selectedNames.remove(name);
      } else {
        _selectedNames.add(name);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedNames.clear();
      } else {
        _selectedNames
          ..clear()
          ..addAll(widget.matchingIngredients.map((item) => item.name));
      }
    });
  }

  void _confirm({required bool addToShoppingList}) {
    final depleted = widget.matchingIngredients
        .where((item) => _selectedNames.contains(item.name))
        .toList();
    Navigator.of(context).pop(
      PantryDepletionSelection(
        depletedIngredients: depleted,
        addToShoppingList: addToShoppingList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final selectedCount = _selectedNames.length;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  AppSvgIcon(
                    assetName: 'check_circle',
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¿Qué se te acabó?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.matchingIngredients.length > 1)
                    TextButton(
                      onPressed: _toggleSelectAll,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        _allSelected ? 'Limpiar' : 'Seleccionar todos',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Toca los ingredientes que se terminaron al preparar "${widget.recipeTitle}".',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.matchingIngredients.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = widget.matchingIngredients[index];
                    final isSelected = _selectedNames.contains(item.name);
                    final amount = item.formattedAmount;

                    return Semantics(
                      button: true,
                      checked: isSelected,
                      label: item.name,
                      child: Material(
                        color: isSelected
                            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _toggleItem(item.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                AppSvgIcon(
                                  assetName: isSelected ? 'check_circle' : 'circle',
                                  size: 20,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outline,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (amount != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    amount,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (selectedCount == 0)
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: AppSvgIcon(
                    assetName: 'check',
                    size: 18,
                    color: colorScheme.onPrimary,
                  ),
                  label: const Text('Listo, no se acabó nada'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              else ...[
                FilledButton.icon(
                  onPressed: () => _confirm(addToShoppingList: true),
                  icon: AppSvgIcon(
                    assetName: 'shopping_cart',
                    size: 18,
                    color: colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Quitar y pasar a Por comprar ($selectedCount)',
                    textAlign: TextAlign.center,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirm(addToShoppingList: false),
                  icon: AppSvgIcon(
                    assetName: 'delete',
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: const Text(
                    'Solo quitar de Mis ingredientes',
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

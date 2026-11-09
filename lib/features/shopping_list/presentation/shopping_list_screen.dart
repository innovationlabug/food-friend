import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../ingredients/presentation/add_ingredient_screen.dart';
import '../../recipes/presentation/recipe_suggestions_screen.dart';

/// Screen presenting the user's shopping list and available pantry ingredients.
/// Allows viewing, selecting, adding, and removing ingredients with local persistence.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({
    super.key,
    this.storageService,
  });

  /// Optional storage service dependency for testing or custom persistence.
  final IngredientStorageService? storageService;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late final IngredientStorageService _storageService;
  List<Ingredient> _ingredients = [];
  final Set<String> _selectedIngredientNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? IngredientStorageService();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
    });

    final items = await _storageService.getIngredients();

    if (mounted) {
      setState(() {
        _ingredients = items;
        // Default newly loaded ingredients to selected
        for (final item in items) {
          _selectedIngredientNames.add(item.name);
        }
        // Remove items that no longer exist
        final currentNames = items.map((i) => i.name).toSet();
        _selectedIngredientNames.retainWhere(currentNames.contains);
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddIngredientScreen() async {
    await AddIngredientScreen.navigate(
      context,
      storageService: _storageService,
    );
    if (mounted) {
      await _loadIngredients();
    }
  }

  Future<void> _clearAllData() async {
    await _storageService.clearIngredients();
    if (!mounted) return;
    _selectedIngredientNames.clear();
    await _loadIngredients();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos borrados'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmClearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('¿Borrar todos los ingredientes?'),
          content: const Text(
            'Esta acción eliminará todos los ingredientes guardados en tu lista de compras y despensa. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Borrar todo'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _clearAllData();
    }
  }

  Future<void> _removeIngredient(String name) async {
    final updated = await _storageService.removeIngredient(name);

    if (mounted) {
      setState(() {
        _ingredients = updated;
        _selectedIngredientNames.remove(name);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingrediente "$name" eliminado'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIngredientNames.length == _ingredients.length) {
        _selectedIngredientNames.clear();
      } else {
        _selectedIngredientNames.addAll(_ingredients.map((i) => i.name));
      }
    });
  }

  void _toggleIngredientSelection(String name) {
    setState(() {
      if (_selectedIngredientNames.contains(name)) {
        _selectedIngredientNames.remove(name);
      } else {
        _selectedIngredientNames.add(name);
      }
    });
  }

  void _openRecipeSuggestions() {
    if (_selectedIngredientNames.isEmpty) return;
    RecipeSuggestionsScreen.navigate(
      context,
      selectedIngredientNames: _selectedIngredientNames.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de compras'),
        actions: [
          IconButton(
            tooltip: 'Borrar todos los ingredientes',
            icon: AppSvgIcon(
              assetName: 'delete',
              size: 22,
              color: colorScheme.onSurface,
            ),
            onPressed: _confirmClearAllData,
          ),
        ],
      ),
      floatingActionButton: _ingredients.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _openAddIngredientScreen,
              icon: AppSvgIcon(
                assetName: 'plus',
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
              label: const Text('Agregar ingrediente'),
            )
          : null,
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _ingredients.isEmpty
                  ? _buildEmptyState(context)
                  : _buildIngredientsView(context),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: AppSvgIcon(
                assetName: 'shopping_cart',
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes ingredientes guardados',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega los ingredientes que tienes disponibles en casa o los que necesitas comprar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openAddIngredientScreen,
              icon: AppSvgIcon(
                assetName: 'plus',
                size: 18,
                color: colorScheme.onPrimary,
              ),
              label: const Text('Agregar ingrediente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final allSelected = _ingredients.isNotEmpty &&
        _selectedIngredientNames.length == _ingredients.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Ingredientes disponibles (${_ingredients.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openAddIngredientScreen,
                icon: AppSvgIcon(
                  assetName: 'plus',
                  size: 16,
                  color: colorScheme.primary,
                ),
                label: const Text('Nuevo'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedIngredientNames.length} de ${_ingredients.length} seleccionados',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: _toggleSelectAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(allSelected ? 'Deseleccionar todos' : 'Seleccionar todos'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _ingredients.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _ingredients[index];
              return _buildIngredientCard(context, item);
            },
          ),
        ),
        if (_selectedIngredientNames.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openRecipeSuggestions,
              icon: AppSvgIcon(
                assetName: 'restaurant',
                size: 20,
                color: colorScheme.onPrimary,
              ),
              label: Text('Buscar recetas (${_selectedIngredientNames.length})'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIngredientCard(BuildContext context, Ingredient item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedIngredientNames.contains(item.name);

    final details = <String>[];
    if (item.formattedAmount != null) {
      details.add(item.formattedAmount!);
    }
    if (item.brand != null && item.brand!.isNotEmpty) {
      details.add(item.brand!);
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggleIngredientSelection(item.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleIngredientSelection(item.name),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppSvgIcon(
                  assetName: 'restaurant',
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details.join(' • '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Eliminar ingrediente',
                icon: AppSvgIcon(
                  assetName: 'delete',
                  size: 20,
                  color: colorScheme.error,
                ),
                onPressed: () => _removeIngredient(item.name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

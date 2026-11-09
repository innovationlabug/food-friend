import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../ingredients/presentation/add_ingredient_screen.dart';

/// Screen presenting the user's shopping list and available pantry ingredients.
/// Allows viewing, adding, and removing ingredients with local persistence.
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingrediente "$name" eliminado'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddIngredientScreen,
        icon: AppSvgIcon(
          assetName: 'plus',
          size: 20,
          color: colorScheme.onPrimaryContainer,
        ),
        label: const Text('Agregar ingrediente'),
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingredientes disponibles (${_ingredients.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _buildIngredientCard(BuildContext context, Ingredient item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final details = <String>[];
    if (item.formattedAmount != null) {
      details.add(item.formattedAmount!);
    }
    if (item.brand != null && item.brand!.isNotEmpty) {
      details.add(item.brand!);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppSvgIcon(
                assetName: 'restaurant',
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
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
    );
  }
}

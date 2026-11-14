import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/utils/string_normalizer.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../ingredients/presentation/add_ingredient_screen.dart';
import '../../recipes/data/external_recipe_service.dart';
import '../../recipes/presentation/recipe_suggestions_screen.dart';
import '../data/shopping_list_storage_service.dart';

/// Screen presenting the user's available home ingredients ("Mis ingredientes")
/// and dedicated shopping list ("Lista de compras") in two independent tabs.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({
    super.key,
    this.storageService,
    this.shoppingListService,
    this.externalRecipeService,
    this.initialTab = 0,
  });

  /// Optional storage service for available home ingredients.
  final IngredientStorageService? storageService;

  /// Optional storage service for the dedicated shopping list.
  final ShoppingListStorageService? shoppingListService;

  /// Optional external recipe service for testing or custom proxy routing.
  final ExternalRecipeService? externalRecipeService;

  /// Initial tab index: 0 = Mis ingredientes, 1 = Por comprar.
  final int initialTab;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final IngredientStorageService _storageService;
  late final ShoppingListStorageService _shoppingListService;

  List<Ingredient> _ingredients = [];
  List<Ingredient> _shoppingListItems = [];
  final Set<String> _selectedIngredientNames = {};
  bool _isLoading = true;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? IngredientStorageService();
    _shoppingListService = widget.shoppingListService ??
        ShoppingListStorageService(pantryStorageService: _storageService);
    _activeTabIndex = widget.initialTab.clamp(0, 1);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _activeTabIndex,
    );
    _tabController.addListener(_onTabChanged);
    _loadIngredients();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index != _activeTabIndex) {
      setState(() {
        _activeTabIndex = _tabController.index;
      });
    }
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
    });

    final items = await _storageService.getIngredients();
    final toBuy = await _shoppingListService.getIngredients();

    if (mounted) {
      setState(() {
        _ingredients = items;
        _shoppingListItems = toBuy;
        // Default newly loaded available ingredients to selected
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

  Future<void> _openAddShoppingItemScreen() async {
    await AddIngredientScreen.navigate(
      context,
      storageService: _shoppingListService,
      isShoppingList: true,
    );
    if (mounted) {
      await _loadIngredients();
    }
  }

  Future<void> _clearAllData() async {
    if (_activeTabIndex == 0) {
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
    } else {
      await _shoppingListService.clearIngredients();
      if (!mounted) return;
      await _loadIngredients();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista de compras vaciada'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmClearAllData() async {
    final isPantryTab = _activeTabIndex == 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            isPantryTab
                ? '¿Borrar todos los ingredientes?'
                : '¿Vaciar lista de compras?',
          ),
          content: Text(
            isPantryTab
                ? 'Esta acción eliminará todos los ingredientes disponibles guardados. ¿Deseas continuar?'
                : 'Esta acción eliminará todos los productos de tu lista de compras. Tus ingredientes disponibles no se verán afectados.',
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
              child: Text(isPantryTab ? 'Borrar todo' : 'Vaciar lista'),
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

  Future<void> _markItemAsBought(Ingredient item) async {
    final result = await _shoppingListService.markAsBought(item.name);

    if (mounted) {
      setState(() {
        _shoppingListItems = result.shoppingList;
        _ingredients = result.availableIngredients;
        // Make the bought ingredient immediately selected for recipe matching
        final currentNames = result.availableIngredients.map((i) => i.name).toSet();
        for (final available in result.availableIngredients) {
          if (StringNormalizer.areEquivalent(available.name, item.name)) {
            _selectedIngredientNames.add(available.name);
          }
        }
        _selectedIngredientNames.retainWhere(currentNames.contains);
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('"${item.name}" movido a Mis ingredientes'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _dismissShoppingItem(Ingredient item) async {
    final updated = await _shoppingListService.dismissItem(item.name);

    if (mounted) {
      setState(() {
        _shoppingListItems = updated;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('"${item.name}" descartado de la lista de compras'),
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
      externalService: widget.externalRecipeService,
      openedFromIngredientList: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPantryTab = _activeTabIndex == 0;

    return Scaffold(
      endDrawer: AppNavigationDrawer(
        currentDestination: isPantryTab
            ? AppDestination.availableIngredients
            : AppDestination.shoppingList,
      ),
      appBar: AppBar(
        title: Text(
          isPantryTab ? 'Ingredientes disponibles' : 'Lista de compras',
        ),
        actions: [
          IconButton(
            tooltip: isPantryTab
                ? 'Borrar todos los ingredientes'
                : 'Vaciar lista de compras',
            icon: AppSvgIcon(
              assetName: 'delete',
              size: 22,
              color: colorScheme.onSurface,
            ),
            onPressed: _confirmClearAllData,
          ),
          const AppMenuButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(assetName: 'restaurant', size: 18),
                  SizedBox(width: 8),
                  Text('Mis ingredientes'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(assetName: 'shopping_cart', size: 18),
                  SizedBox(width: 8),
                  Text('Por comprar'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(colorScheme, isPantryTab),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _ingredients.isEmpty
                        ? _buildEmptyState(context)
                        : _buildIngredientsView(context),
                    _shoppingListItems.isEmpty
                        ? _buildShoppingEmptyState(context)
                        : _buildShoppingListView(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(ColorScheme colorScheme, bool isPantryTab) {
    if (_isLoading) return null;
    if (isPantryTab && _ingredients.isEmpty) {
      return FloatingActionButton.extended(
        onPressed: _openAddIngredientScreen,
        icon: AppSvgIcon(
          assetName: 'plus',
          size: 20,
          color: colorScheme.onPrimaryContainer,
        ),
        label: const Text('Agregar ingrediente'),
      );
    }
    if (!isPantryTab && _shoppingListItems.isEmpty) {
      return FloatingActionButton.extended(
        onPressed: _openAddShoppingItemScreen,
        icon: AppSvgIcon(
          assetName: 'plus',
          size: 20,
          color: colorScheme.onPrimaryContainer,
        ),
        label: const Text('Agregar producto'),
      );
    }
    return null;
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
              'Agrega los ingredientes que tienes disponibles en casa.',
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

  Widget _buildShoppingEmptyState(BuildContext context) {
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
              'Tu lista de compras está vacía',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega los ingredientes que necesitas comprar en el supermercado.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openAddShoppingItemScreen,
              icon: AppSvgIcon(
                assetName: 'plus',
                size: 18,
                color: colorScheme.onPrimary,
              ),
              label: const Text('Agregar a lista de compras'),
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
              label: const Text('Buscar recetas'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShoppingListView(BuildContext context) {
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
              Expanded(
                child: Text(
                  'Por comprar (${_shoppingListItems.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openAddShoppingItemScreen,
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
            itemCount: _shoppingListItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _shoppingListItems[index];
              return _buildShoppingListItemCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  List<String> _formatItemDetails(Ingredient item) {
    final details = <String>[];
    if (item.formattedAmount != null) {
      details.add(item.formattedAmount!);
    }
    if (item.brand != null && item.brand!.isNotEmpty) {
      details.add(item.brand!);
    }
    return details;
  }

  Widget _buildIngredientCard(BuildContext context, Ingredient item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedIngredientNames.contains(item.name);
    final details = _formatItemDetails(item);

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

  Widget _buildShoppingListItemCard(BuildContext context, Ingredient item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final details = _formatItemDetails(item);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppSvgIcon(
                assetName: 'shopping_cart',
                size: 18,
                color: colorScheme.onSecondaryContainer,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details.join(' • '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Marcar como comprado',
              onPressed: () => _markItemAsBought(item),
              icon: AppSvgIcon(
                assetName: 'check',
                size: 18,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            IconButton(
              tooltip: 'Descartar de la lista',
              onPressed: () => _dismissShoppingItem(item),
              icon: AppSvgIcon(
                assetName: 'delete',
                size: 20,
                color: colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

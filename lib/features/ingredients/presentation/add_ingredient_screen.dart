import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';
import '../data/ingredient_catalog.dart';
import '../data/ingredient_storage_service.dart';
import '../data/fridge_vision_service.dart';
import '../data/receipt_parser_service.dart';
import '../domain/category_node.dart';
import '../domain/ingredient.dart';
import 'fridge_scanner_screen.dart';
import 'receipt_scanner_screen.dart';

/// Screen allowing the user to add ingredients via:
/// 1. Real-time text search with auto-suggestions and closest-match fallback (US-2.2).
/// 2. Hierarchical category browsing with at most 3-4 steps (US-2.3).
class AddIngredientScreen extends StatefulWidget {
  const AddIngredientScreen({
    super.key,
    this.storageService,
    this.visionService,
    this.parserService,
    this.initialTab = 0,
    this.openedFromShoppingList = false,
    this.isShoppingList = false,
  });

  /// Storage service used to persist ingredients.
  final IngredientStorageService? storageService;

  /// Optional vision service for fridge scanning.
  final FridgeVisionService? visionService;

  /// Optional parser service for receipt scanning.
  final ReceiptParserService? parserService;

  /// Initial tab index (0 = Buscar, 1 = Categorías).
  final int initialTab;

  /// Whether this screen was opened from the shopping list screen.
  final bool openedFromShoppingList;

  /// Whether additions target the Shopping List ("Lista de Compras") instead of available ingredients.
  final bool isShoppingList;

  /// Helper to navigate to this screen.
  static Future<Ingredient?> navigate(
    BuildContext context, {
    IngredientStorageService? storageService,
    FridgeVisionService? visionService,
    ReceiptParserService? parserService,
    int initialTab = 0,
    bool openedFromShoppingList = true,
    bool isShoppingList = false,
  }) {
    return Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(
        builder: (_) => AddIngredientScreen(
          storageService: storageService,
          visionService: visionService,
          parserService: parserService,
          initialTab: initialTab,
          openedFromShoppingList: openedFromShoppingList,
          isShoppingList: isShoppingList,
        ),
      ),
    );
  }

  @override
  State<AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final IngredientStorageService _storageService;
  final TextEditingController _searchController = TextEditingController();

  List<String> _suggestions = [];
  bool _isSaving = false;
  bool _showEnterTip = false;

  // Category navigation stack for US-2.3
  final List<CategoryNode> _categoryStack = [];

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? IngredientStorageService();
    final tabCount = widget.isShoppingList ? 2 : 3;
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, tabCount - 1),
    );
    _searchController.addListener(_onSearchChanged);
    SettingsController.instance.load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.trim().isEmpty) {
      if (_suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
        });
      }
      return;
    }

    // Trigger enter tip on the user's first text input
    if (!SettingsController.instance.hasSeenEnterTip && !_showEnterTip) {
      _showEnterTip = true;
      SettingsController.instance.markEnterTipSeen();
    }

    final results = IngredientCatalog.instance.searchSuggestions(query);
    setState(() {
      _suggestions = results;
    });
  }

  Future<void> _selectAndAddIngredient(String ingredientName) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    final newIngredient = Ingredient(name: ingredientName.trim());
    await _storageService.addIngredient(newIngredient);
    await SettingsController.instance.load();

    if (mounted) {
      _searchController.clear();
      setState(() {
        _suggestions = [];
        _isSaving = false;
        _showEnterTip = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isShoppingList
                ? '"$ingredientName" agregado a la lista de compras'
                : 'Ingrediente "$ingredientName" agregado',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      if (SettingsController.instance.autoReturnAfterAddingIngredient) {
        _goToIngredientList();
      }
    }
  }

  void _submitTextSearch() {
    final rawInput = _searchController.text.trim();
    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor escribe el nombre de un ingrediente'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Pressing enter auto-adds the first ingredient in the list
    final chosenName = _suggestions.isNotEmpty
        ? _suggestions.first
        : (IngredientCatalog.instance.getClosestMatch(rawInput) ?? rawInput);

    _selectAndAddIngredient(chosenName);
  }

  void _goToIngredientList() {
    if (widget.openedFromShoppingList) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ShoppingListScreen(
            storageService: widget.isShoppingList ? null : _storageService,
            initialTab: widget.isShoppingList ? 1 : 0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: _categoryStack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_tabController.index == 1 && _categoryStack.isNotEmpty) {
          setState(() {
            _categoryStack.removeLast();
          });
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        drawer: AppNavigationDrawer(
          currentDestination:
              widget.isShoppingList ? null : AppDestination.addIngredients,
          settingsSection: SettingsSection.ingredients,
        ),
        appBar: AppBar(
          leadingWidth: appBarLeadingWidth(context),
          leading: const AppBarLeading(),
          title: Text(
            widget.isShoppingList
                ? 'Agregar a lista de compras'
                : 'Agregar ingrediente',
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton.icon(
              onPressed: _goToIngredientList,
              icon: AppSvgIcon(
                assetName: 'shopping_cart',
                size: 18,
                color: colorScheme.primary,
              ),
              label: const Text('Ver lista'),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              const Tab(
                icon: AppSvgIcon(assetName: 'search', size: 20),
                text: 'Buscar',
              ),
              const Tab(
                icon: AppSvgIcon(assetName: 'category', size: 20),
                text: 'Categorías',
              ),
              if (!widget.isShoppingList)
                const Tab(
                  icon: AppSvgIcon(assetName: 'camera', size: 20),
                  text: 'Foto',
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: ResponsiveContainer(
            padding: const EdgeInsets.all(16),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(theme, colorScheme),
                _buildCategoriesTab(theme, colorScheme),
                if (!widget.isShoppingList) _buildPhotoTab(theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab(ThemeData theme, ColorScheme colorScheme) {
    final query = _searchController.text.trim();
    final closest = query.isNotEmpty
        ? IngredientCatalog.instance.getClosestMatch(query)
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitTextSearch(),
                  decoration: InputDecoration(
                    labelText: 'Nombre del ingrediente',
                    hintText: 'Ej. Pechuga de pollo, Tomate, Frijol',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AppSvgIcon(
                        assetName: 'search',
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: AppSvgIcon(
                              assetName: 'close',
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submitTextSearch,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AppSvgIcon(
                        assetName: 'check',
                        size: 18,
                        color: colorScheme.onPrimary,
                      ),
                label: const Text('Guardar'),
              ),
            ],
          ),
          if (_showEnterTip) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  AppSvgIcon(
                    assetName: 'info',
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Consejo: Al presionar Enter se agregará automáticamente el primer ingrediente de la lista.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: AppSvgIcon(
                      assetName: 'close',
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    tooltip: 'Cerrar consejo',
                    onPressed: () {
                      setState(() {
                        _showEnterTip = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (query.isNotEmpty) ...[
            if (_suggestions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sugerencias en tiempo real:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    title: Text(
                      suggestion,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: AppSvgIcon(
                      assetName: 'plus',
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    onTap: () => _selectAndAddIngredient(suggestion),
                  );
                },
              ),
            ] else ...[
              Card(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sin sugerencias exactas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Al presionar "Guardar", se aplicará la coincidencia más cercana: "${closest ?? query}".',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Ingredientes sugeridos para agregar rápido:',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Tomate',
                'Cebolla blanca',
                'Pechuga de pollo',
                'Frijoles negros',
                'Arroz blanco',
                'Huevos',
                'Limón',
                'Aguacate',
                'Ajo',
                'Papas',
              ].map((name) {
                return ActionChip(
                  label: Text(name),
                  avatar: AppSvgIcon(
                    assetName: 'plus',
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => _selectAndAddIngredient(name),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(ThemeData theme, ColorScheme colorScheme) {
    // Current category level
    final currentList = _categoryStack.isEmpty
        ? IngredientCatalog.instance.categories
        : _categoryStack.last.children;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_categoryStack.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Volver al nivel anterior',
                  icon: AppSvgIcon(
                    assetName: 'arrow_back',
                    size: 20,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  onPressed: () {
                    setState(() {
                      _categoryStack.removeLast();
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _categoryStack.map((n) => n.name).join(' > '),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Selecciona una categoría de alimentos:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        Expanded(
          child: ListView.separated(
            itemCount: currentList.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final node = currentList[index];
              if (node.isLeaf) {
                // Selectable ingredient leaf
                return ListTile(
                  title: Text(
                    node.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: AppSvgIcon(
                    assetName: 'plus',
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  onTap: () => _selectAndAddIngredient(node.name),
                );
              } else {
                // Intermediate category node
                return ListTile(
                  title: Text(
                    node.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: AppSvgIcon(
                    assetName: 'chevron_right',
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    setState(() {
                      _categoryStack.add(node);
                    });
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTab(ThemeData theme, ColorScheme colorScheme) {
    final fridgeCard = Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppSvgIcon(
                    assetName: 'fridge',
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escanear refrigerador',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detecta automáticamente los alimentos y productos en tu refrigerador o despensa a partir de una foto.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                FridgeScannerScreen.navigate(
                  context,
                  storageService: _storageService,
                  visionService: widget.visionService,
                );
              },
              icon: AppSvgIcon(
                assetName: 'fridge',
                size: 18,
                color: colorScheme.onPrimary,
              ),
              label: const Text('Escanear refrigerador'),
            ),
          ],
        ),
      ),
    );

    final receiptCard = Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppSvgIcon(
                    assetName: 'receipt',
                    color: colorScheme.onSecondaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escanear recibo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Extrae alimentos comprados y montos en Quetzales desde una fotografía de tu ticket o factura de supermercado.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ReceiptScannerScreen.navigate(
                  context,
                  storageService: _storageService,
                  parserService: widget.parserService,
                );
              },
              icon: AppSvgIcon(
                assetName: 'receipt',
                size: 18,
                color: colorScheme.onPrimary,
              ),
              label: const Text('Escanear recibo'),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      child: context.isDesktop
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: fridgeCard),
                  const SizedBox(width: 16),
                  Expanded(child: receiptCard),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fridgeCard,
                const SizedBox(height: 16),
                receiptCard,
              ],
            ),
    );
  }
}

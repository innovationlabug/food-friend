import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../data/ingredient_catalog.dart';
import '../data/ingredient_storage_service.dart';
import '../domain/category_node.dart';
import '../domain/ingredient.dart';

/// Screen allowing the user to add ingredients via:
/// 1. Real-time text search with auto-suggestions and closest-match fallback (US-2.2).
/// 2. Hierarchical category browsing with at most 3-4 steps (US-2.3).
class AddIngredientScreen extends StatefulWidget {
  const AddIngredientScreen({
    super.key,
    this.storageService,
    this.initialTab = 0,
  });

  /// Storage service used to persist ingredients.
  final IngredientStorageService? storageService;

  /// Initial tab index (0 = Buscar, 1 = Categorías).
  final int initialTab;

  /// Helper to navigate to this screen.
  static Future<Ingredient?> navigate(
    BuildContext context, {
    IngredientStorageService? storageService,
    int initialTab = 0,
  }) {
    return Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(
        builder: (_) => AddIngredientScreen(
          storageService: storageService,
          initialTab: initialTab,
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

  // Category navigation stack for US-2.3
  final List<CategoryNode> _categoryStack = [];

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? IngredientStorageService();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _searchController.addListener(_onSearchChanged);
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingrediente "$ingredientName" agregado'),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(newIngredient);
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

    // Apply closest match from catalog as required by US-2.2
    final match = IngredientCatalog.instance.getClosestMatch(rawInput);
    final chosenName = match ?? rawInput;

    _selectAndAddIngredient(chosenName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar ingrediente'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.search),
              text: 'Buscar',
            ),
            Tab(
              icon: Icon(Icons.category_outlined),
              text: 'Categorías',
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
            ],
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
                    labelText: 'Nombre del ingrediente *',
                    hintText: 'Ej. Pechuga de pollo, Tomate, Frijol',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
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
                    : const Icon(Icons.check, size: 18),
                label: const Text('Guardar'),
              ),
            ],
          ),
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
                    trailing: Icon(
                      Icons.add_circle_outline,
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
                  avatar: const Icon(Icons.add, size: 16),
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
                  icon: const Icon(Icons.arrow_back, size: 20),
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
                  trailing: Icon(
                    Icons.add_circle,
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
                  trailing: const Icon(Icons.chevron_right),
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
}

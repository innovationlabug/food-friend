import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';
import '../data/external_recipe_service.dart';
import '../data/recipe_history_service.dart';
import '../data/recipe_search_service.dart';
import '../domain/recipe_preference.dart';
import '../domain/recipe_search_result.dart';
import 'recipe_detail_screen.dart';

/// Screen presenting recipe suggestions generated from the user's selected ingredients.
/// Automatically prioritizes local recipes, queries external API when zero local matches,
/// and falls back gracefully to closest partial matches when offline or on network error.
class RecipeSuggestionsScreen extends StatefulWidget {
  const RecipeSuggestionsScreen({
    super.key,
    required this.selectedIngredientNames,
    this.searchService,
    this.externalService,
    this.historyService,
    this.openedFromIngredientList = false,
  });

  /// The list of ingredient names selected by the user.
  final List<String> selectedIngredientNames;

  /// Optional injected search service for local matching.
  final RecipeSearchService? searchService;

  /// Optional injected external service for API queries and fallback coordination.
  final ExternalRecipeService? externalService;

  /// Optional injected history service for preferences and cooking records.
  final RecipeHistoryService? historyService;

  /// Whether this screen was pushed from [ShoppingListScreen].
  final bool openedFromIngredientList;

  /// Helper static method for easy navigation.
  static Future<void> navigate(
    BuildContext context, {
    required List<String> selectedIngredientNames,
    RecipeSearchService? searchService,
    ExternalRecipeService? externalService,
    RecipeHistoryService? historyService,
    bool openedFromIngredientList = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeSuggestionsScreen(
          selectedIngredientNames: selectedIngredientNames,
          searchService: searchService,
          externalService: externalService,
          historyService: historyService,
          openedFromIngredientList: openedFromIngredientList,
        ),
      ),
    );
  }

  @override
  State<RecipeSuggestionsScreen> createState() => _RecipeSuggestionsScreenState();
}

class _RecipeSuggestionsScreenState extends State<RecipeSuggestionsScreen> {
  late final RecipeSearchService _searchService;
  late final ExternalRecipeService _externalService;
  late final RecipeHistoryService _historyService;

  bool _isLoading = true;
  bool _isGeneratingAi = false;
  RecipeDiscoveryResponse? _discoveryResponse;
  List<RecipeSearchResult> _results = [];
  bool _showingAllRecipes = false;
  String _selectedCategory = 'Todos';

  static const List<String> _baseMealCategories = [
    'Todos',
    'Desayuno',
    'Almuerzo',
    'Cena',
    'Sopas y Caldos',
    'Ensaladas',
  ];

  List<String> get _availableCategories {
    final list = <String>[..._baseMealCategories];
    for (final r in _results) {
      final cat = r.recipe.category?.trim();
      if (cat != null && cat.isNotEmpty) {
        final norm = cat[0].toUpperCase() + cat.substring(1);
        if (!list.any((existing) => existing.toLowerCase() == norm.toLowerCase())) {
          list.add(norm);
        }
      }
    }
    return list;
  }

  bool _matchesCategory(RecipeSearchResult r, String category) {
    if (category == 'Todos') return true;
    final rCat = r.recipe.category?.trim().toLowerCase();
    if (rCat == null) return false;
    final fCat = category.trim().toLowerCase();
    return rCat == fCat || rCat.contains(fCat) || fCat.contains(rCat);
  }

  int _countForCategory(String category) {
    if (category == 'Todos') return _results.length;
    return _results.where((r) => _matchesCategory(r, category)).length;
  }

  List<RecipeSearchResult> get _filteredResults {
    if (_selectedCategory == 'Todos') return _results;
    return _results.where((r) => _matchesCategory(r, _selectedCategory)).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchService = widget.searchService ?? RecipeSearchService();
    _externalService = widget.externalService ?? ExternalRecipeService();
    _historyService = widget.historyService ?? RecipeHistoryService();
    _performDiscovery();
  }

  Future<void> _performDiscovery() async {
    setState(() {
      _isLoading = true;
    });

    final history = await _historyService.getHistory();

    final response = await _externalService.discoverRecipes(
      selectedIngredients: widget.selectedIngredientNames,
      localSearchService: _searchService,
      history: history,
    );

    if (mounted) {
      final filteredResults = response.results
          .where((r) => history[r.recipe.id]?.preference != RecipePreference.never)
          .toList();

      setState(() {
        _discoveryResponse = response;
        _results = filteredResults;
        _isLoading = false;
        _showingAllRecipes = false;
        _selectedCategory = 'Todos';
      });
    }
  }

  Future<void> _showAllLocalRecipes() async {
    final history = await _historyService.getHistory();
    final all = _searchService
        .getAllRecipes()
        .where((r) => history[r.id]?.preference != RecipePreference.never)
        .map((r) {
      final matched = <String>{};
      final missing = <String>{};
      for (final ing in r.ingredients) {
        if (widget.selectedIngredientNames.any(
            (u) => RecipeSearchService.isIngredientMatch(u.toLowerCase(), ing.normalizedName))) {
          matched.add(ing.name);
        } else {
          missing.add(ing.name);
        }
      }

      return RecipeSearchResult(
        recipe: r,
        matchedIngredients: r.ingredients.where((i) => matched.contains(i.name)).toList(),
        missingIngredients: r.ingredients.where((i) => missing.contains(i.name)).toList(),
      );
    }).toList();

    // Sort by matchCount descending, then title
    all.sort((a, b) {
      final c = b.matchCount.compareTo(a.matchCount);
      if (c != 0) return c;
      return a.recipe.title.compareTo(b.recipe.title);
    });

    setState(() {
      _results = all;
      _showingAllRecipes = true;
      _selectedCategory = 'Todos';
    });
  }

  Future<void> _generateAiRecipes() async {
    if (_isGeneratingAi) return;

    setState(() {
      _isGeneratingAi = true;
    });

    try {
      final ingredients = widget.selectedIngredientNames.isNotEmpty
          ? widget.selectedIngredientNames
          : ['Pollo', 'Tomate'];

      final newRecipes = await _externalService.fetchExternalRecipes(ingredients);

      if (!mounted) return;

      if (newRecipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron generar recetas adicionales en este momento.'),
          ),
        );
      } else {
        final newResults = _searchService.searchRecipes(
          selectedIngredientNames: widget.selectedIngredientNames,
          recipePool: newRecipes,
          minMatchCount: 0,
        );

        setState(() {
          final existingIds = _results.map((r) => r.recipe.id).toSet();
          for (final res in newResults) {
            if (!existingIds.contains(res.recipe.id)) {
              _results.add(res);
              existingIds.add(res.recipe.id);
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newRecipes.length} receta(s) generada(s) con éxito con IA.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible conectar con el asistente de IA o te encuentras sin conexión. Tus recetas actuales siguen disponibles.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas sugeridas'),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: _isLoading
              ? _buildLoadingState(context)
              : _results.isEmpty
                  ? _buildEmptyState(context)
                  : _buildResultsView(context),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Buscando recetas sugeridas...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(BuildContext context) {
    final filtered = _filteredResults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_discoveryResponse?.isFallback == true && !_showingAllRecipes) ...[
          _buildFallbackNotice(context),
          const SizedBox(height: 12),
        ],
        _buildHeaderBanner(context, displayedCount: filtered.length),
        const SizedBox(height: 12),
        _buildCategoryFilters(context),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyFilteredState(context)
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final result = filtered[index];
                    return _buildRecipeCard(context, result);
                  },
                ),
        ),
        const SizedBox(height: 8),
        _buildAiGenerationButton(context),
      ],
    );
  }

  Widget _buildAiGenerationButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.primary),
        ),
        onPressed: _isGeneratingAi ? null : _generateAiRecipes,
        child: _isGeneratingAi
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generando recetas con IA...',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSvgIcon(
                    assetName: 'restaurant',
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Generar más recetas con IA',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context) {
    final categories = _availableCategories;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          final count = _countForCategory(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$cat ($count)'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFilteredState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin recetas de tipo "$_selectedCategory"',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay recetas disponibles bajo este filtro para tus ingredientes seleccionados.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'Todos';
                });
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Mostrar todas las recetas'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackNotice(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _discoveryResponse?.fallbackMessage ??
                  'Mostrando las sugerencias locales más cercanas disponibles.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToIngredientList() {
    if (widget.openedFromIngredientList && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    final route = MaterialPageRoute<void>(
      builder: (_) => ShoppingListScreen(
        externalRecipeService: widget.externalService,
      ),
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  Widget _buildHeaderBanner(BuildContext context, {int? displayedCount}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final count = displayedCount ?? _results.length;
    final totalCount = _results.length;
    final ingredientCount = widget.selectedIngredientNames.length;

    String bannerTitle = '$count receta(s) disponible(s)';
    if (_showingAllRecipes) {
      bannerTitle = 'Catálogo de recetas ($count)';
    } else if (_discoveryResponse?.isExternal == true) {
      bannerTitle = '$count receta(s) en línea';
    } else if (_discoveryResponse?.isFallback == true) {
      bannerTitle = '$count receta(s) sugerida(s)';
    }

    if (_selectedCategory != 'Todos' && count != totalCount) {
      bannerTitle = '$bannerTitle ($_selectedCategory)';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: AppSvgIcon(
                  assetName: 'restaurant',
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bannerTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Con base en $ingredientCount ingrediente(s) seleccionado(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _navigateToIngredientList,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  assetName: 'shopping_cart',
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Cambiar ingredientes para nuevas sugerencias',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeSearchResult result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipe = result.recipe;

    final metaDetails = <String>[];
    if (recipe.category != null) metaDetails.add(recipe.category!);
    if (recipe.totalTimeMinutes != null) metaDetails.add('${recipe.totalTimeMinutes} min');
    if (recipe.servings != null) metaDetails.add('${recipe.servings} porciones');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: result.hasAllIngredients
              ? colorScheme.primary.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: result.hasAllIngredients ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: RouteSettings(name: 'recipe_${result.recipe.id}'),
              builder: (_) => RecipeDetailScreen.fromResult(
                result: result,
                historyService: _historyService,
              ),
            ),
          ).then((_) {
            _performDiscovery();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (metaDetails.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  metaDetails.join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Match progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tienes ${result.matchCount} de ${result.totalIngredients} ingredientes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: result.hasAllIngredients
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${result.matchPercentageInt}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: result.hasAllIngredients
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.matchPercentage,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    result.hasAllIngredients
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Ingredient highlights
              if (result.matchedIngredients.isNotEmpty) ...[
                Text(
                  'Tienes: ${result.matchedIngredients.map((i) => i.name).join(', ')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (result.missingIngredients.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Te falta: ${result.missingIngredients.map((i) => i.name).join(', ')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
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
                assetName: 'restaurant',
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontraron recetas con los ingredientes seleccionados',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta seleccionando otros ingredientes o explora todas las recetas saludables del catálogo.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAllLocalRecipes,
              icon: AppSvgIcon(
                assetName: 'restaurant',
                size: 18,
                color: colorScheme.onPrimary,
              ),
              label: const Text('Ver todas las recetas'),
            ),
          ],
        ),
      ),
    );
  }
}


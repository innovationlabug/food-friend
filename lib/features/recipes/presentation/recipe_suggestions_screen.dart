import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/utils/string_normalizer.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../nutrition/data/health_goal_storage_service.dart';
import '../../nutrition/domain/health_goal.dart';
import '../../nutrition/presentation/nutrition_tips_screen.dart';
import '../../nutrition/presentation/widgets/goal_tooltip_banner.dart';
import '../../pricing/data/ingredient_price_storage_service.dart';
import '../../pricing/data/recipe_cost_calculator.dart';
import '../../pricing/domain/ingredient_price_entry.dart';
import '../../sales/data/fallback_sales_data.dart';
import '../../sales/data/sales_service.dart';
import '../../sales/domain/supermarket_deal.dart';
import '../../shopping_list/data/shopping_list_storage_service.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';
import '../data/external_recipe_service.dart';
import '../data/recipe_history_service.dart';
import '../data/recipe_search_service.dart';
import '../domain/recipe_preference.dart';
import '../domain/recipe_search_result.dart';
import '../domain/recipe_time_filter.dart';
import 'multi_day_planner_screen.dart';
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
    this.ingredientStorageService,
    this.shoppingListService,
    this.healthGoalStorageService,
    this.priceStorageService,
    this.salesService,
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

  /// Optional injected pantry storage service to select all saved ingredients.
  final IngredientStorageService? ingredientStorageService;

  /// Optional injected shopping list storage service forwarded to recipe detail.
  final ShoppingListStorageService? shoppingListService;

  /// Optional injected health goal storage service for goal-based ranking and tooltips.
  final HealthGoalStorageService? healthGoalStorageService;

  /// Optional injected ingredient GTQ price storage service.
  final IngredientPriceStorageService? priceStorageService;

  /// Optional injected sales service for cached supermarket deals.
  final SalesService? salesService;

  /// Whether this screen was pushed from [ShoppingListScreen].
  final bool openedFromIngredientList;

  /// Helper static method for easy navigation.
  static Future<void> navigate(
    BuildContext context, {
    required List<String> selectedIngredientNames,
    RecipeSearchService? searchService,
    ExternalRecipeService? externalService,
    RecipeHistoryService? historyService,
    IngredientStorageService? ingredientStorageService,
    ShoppingListStorageService? shoppingListService,
    HealthGoalStorageService? healthGoalStorageService,
    IngredientPriceStorageService? priceStorageService,
    SalesService? salesService,
    bool openedFromIngredientList = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeSuggestionsScreen(
          selectedIngredientNames: selectedIngredientNames,
          searchService: searchService,
          externalService: externalService,
          historyService: historyService,
          ingredientStorageService: ingredientStorageService,
          shoppingListService: shoppingListService,
          healthGoalStorageService: healthGoalStorageService,
          priceStorageService: priceStorageService,
          salesService: salesService,
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
  late final IngredientStorageService _ingredientStorageService;
  late final ShoppingListStorageService _shoppingListService;
  late final HealthGoalStorageService _healthGoalStorageService;
  late final IngredientPriceStorageService _priceStorageService;
  late final SalesService _salesService;

  late List<String> _selectedIngredientNames;
  List<Ingredient> _pantryIngredients = const [];
  Set<HealthGoal> _activeHealthGoals = <HealthGoal>{};
  Map<String, IngredientPriceEntry> _savedPrices = const {};
  List<SupermarketDeal> _cachedDeals = FallbackSalesData.deals;
  bool _isLoading = true;
  bool _isGeneratingAi = false;
  RecipeDiscoveryResponse? _discoveryResponse;
  List<RecipeSearchResult> _results = [];
  bool _showingAllRecipes = false;
  String _selectedCategory = 'Todos';
  RecipeTimeFilter _selectedTimeFilter = RecipeTimeFilter.all;

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
    final timeMatched = _results.where((r) => _selectedTimeFilter.matches(r.recipe));
    if (category == 'Todos') return timeMatched.length;
    return timeMatched.where((r) => _matchesCategory(r, category)).length;
  }

  List<RecipeSearchResult> get _filteredResults {
    return _results.where((r) {
      return _matchesCategory(r, _selectedCategory) &&
          _selectedTimeFilter.matches(r.recipe);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchService = widget.searchService ?? RecipeSearchService();
    _externalService = widget.externalService ?? ExternalRecipeService();
    _ingredientStorageService =
        widget.ingredientStorageService ?? IngredientStorageService();
    _historyService = widget.historyService ??
        RecipeHistoryService(
          ingredientStorageService: _ingredientStorageService,
        );
    _shoppingListService = widget.shoppingListService ??
        ShoppingListStorageService(
          pantryStorageService: _ingredientStorageService,
        );
    _healthGoalStorageService =
        widget.healthGoalStorageService ?? HealthGoalStorageService();
    _priceStorageService =
        widget.priceStorageService ?? IngredientPriceStorageService();
    _salesService = widget.salesService ?? SalesService();
    _selectedIngredientNames = List<String>.from(widget.selectedIngredientNames);
    _performDiscovery();
  }

  Future<void> _performDiscovery() async {
    setState(() {
      _isLoading = true;
    });

    final pantryFuture = _ingredientStorageService.getIngredients();
    final historyFuture = _historyService.getHistory();
    final goalsFuture = _healthGoalStorageService.getSelectedGoals();
    final pricesFuture = _priceStorageService.getPrices();
    final dealsFuture = _salesService.getCachedOrFallbackDeals();
    final pantry = await pantryFuture;
    final history = await historyFuture;
    final activeGoals = await goalsFuture;
    final savedPrices = await pricesFuture;
    final cachedDeals = await dealsFuture;

    if (_selectedIngredientNames.isEmpty) {
      if (!mounted) return;
      setState(() {
        _pantryIngredients = pantry;
        _activeHealthGoals = activeGoals;
        _savedPrices = savedPrices;
        _cachedDeals = cachedDeals;
        _discoveryResponse = null;
        _results = [];
        _isLoading = false;
        _showingAllRecipes = false;
        _selectedCategory = 'Todos';
        _selectedTimeFilter = RecipeTimeFilter.all;
      });
      return;
    }

    final response = await _externalService.discoverRecipes(
      selectedIngredients: _selectedIngredientNames,
      localSearchService: _searchService,
      history: history,
      activeHealthGoals: activeGoals,
    );

    if (mounted) {
      final filteredResults = response.results
          .where((r) => history[r.recipe.id]?.preference != RecipePreference.never)
          .toList();

      setState(() {
        _pantryIngredients = pantry;
        _activeHealthGoals = activeGoals;
        _savedPrices = savedPrices;
        _cachedDeals = cachedDeals;
        _discoveryResponse = response;
        _results = filteredResults;
        _isLoading = false;
        _showingAllRecipes = false;
        _selectedCategory = 'Todos';
        _selectedTimeFilter = RecipeTimeFilter.all;
      });
    }
  }

  /// Syncs selected ingredients with pantry changes made while inside
  /// [RecipeDetailScreen] (e.g., depleted ingredients removed via `"Lo cociné"`),
  /// then refreshes the recipe list.
  Future<void> _refreshAfterRecipeDetail(Set<String> previousPantryNorms) async {
    final latestPantry = await _ingredientStorageService.getIngredients();
    if (!mounted) return;

    final latestPantryNorms =
        latestPantry.map((item) => StringNormalizer.normalize(item.name)).toSet();
    final removedNorms = previousPantryNorms.difference(latestPantryNorms);

    if (removedNorms.isNotEmpty) {
      _selectedIngredientNames = _selectedIngredientNames
          .where((name) => !removedNorms.contains(StringNormalizer.normalize(name)))
          .toList();
    }

    if (_showingAllRecipes) {
      await _showAllLocalRecipes();
    } else {
      await _performDiscovery();
    }
  }

  Future<void> _selectAllPantryIngredientsAndRefresh() async {
    final pantry = await _ingredientStorageService.getIngredients();
    if (!mounted) return;
    if (pantry.isEmpty) {
      setState(() {
        _pantryIngredients = pantry;
      });
      return;
    }

    setState(() {
      _pantryIngredients = pantry;
      _selectedIngredientNames = pantry.map((i) => i.name).toList();
    });
    await _performDiscovery();
  }

  Future<void> _showAllLocalRecipes() async {
    final history = await _historyService.getHistory();
    final activeGoals = await _healthGoalStorageService.getSelectedGoals();
    final savedPrices = await _priceStorageService.getPrices();
    final cachedDeals = await _salesService.getCachedOrFallbackDeals();
    if (!mounted) return;

    final all = _searchService.searchRecipes(
      selectedIngredientNames: _selectedIngredientNames,
      minMatchCount: 0,
      history: history,
      activeHealthGoals: activeGoals,
    );

    if (activeGoals.isEmpty && _selectedIngredientNames.isEmpty) {
      all.sort((a, b) => a.recipe.title.compareTo(b.recipe.title));
    }

    setState(() {
      _activeHealthGoals = activeGoals;
      _savedPrices = savedPrices;
      _cachedDeals = cachedDeals;
      _results = all;
      _showingAllRecipes = true;
      _selectedCategory = 'Todos';
      _selectedTimeFilter = RecipeTimeFilter.all;
    });
  }

  Future<void> _generateAiRecipes() async {
    if (_isGeneratingAi) return;

    setState(() {
      _isGeneratingAi = true;
    });

    try {
      final ingredients = _selectedIngredientNames.isNotEmpty
          ? _selectedIngredientNames
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
          selectedIngredientNames: _selectedIngredientNames,
          recipePool: newRecipes,
          minMatchCount: 0,
          activeHealthGoals: _activeHealthGoals,
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

        final generatedLabel = newRecipes.length == 1
            ? '1 receta generada con éxito con IA.'
            : '${newRecipes.length} recetas generadas con éxito con IA.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(generatedLabel),
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
      drawer: const AppNavigationDrawer(
        currentDestination: AppDestination.recipeSuggestions,
      ),
      appBar: AppBar(
        leadingWidth: appBarLeadingWidth(context),
        leading: const AppBarLeading(),
        title: const Text(
          'Recetas sugeridas',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 480)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                key: const ValueKey('open_multi_day_planner_button'),
                onPressed: () => _openMultiDayPlanner(),
                icon: AppSvgIcon(
                  assetName: 'calendar',
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: const Text('Planificar días'),
              ),
            )
          else
            IconButton(
              key: const ValueKey('open_multi_day_planner_button'),
              tooltip: 'Planificar varios días',
              icon: const AppSvgIcon(assetName: 'calendar', size: 22),
              onPressed: () => _openMultiDayPlanner(),
            ),
        ],
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
        const SizedBox(height: 8),
        _buildTimeFilters(context),
        if (_activeHealthGoals.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildActiveGoalsBar(context),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyFilteredState(context)
              : _buildResultsList(context, filtered),
        ),
        const SizedBox(height: 8),
        _buildAiGenerationButton(context),
      ],
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    List<RecipeSearchResult> filtered,
  ) {
    if (!context.isDesktop) {
      return ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildRecipeCard(context, filtered[index]),
      );
    }

    final rowCount = (filtered.length + 1) ~/ 2;
    return ListView.separated(
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, rowIndex) {
        final firstIndex = rowIndex * 2;
        final secondIndex = firstIndex + 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildRecipeCard(context, filtered[firstIndex])),
              const SizedBox(width: 12),
              Expanded(
                child: secondIndex < filtered.length
                    ? _buildRecipeCard(context, filtered[secondIndex])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
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
                  Flexible(
                    child: Text(
                      'Generando recetas con IA...',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
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
                  Flexible(
                    child: Text(
                      'Generar más recetas con IA',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
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

  Widget _buildTimeFilters(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppSvgIcon(
            assetName: 'timer',
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            'Tiempo:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          ...RecipeTimeFilter.values.map((filter) {
            final isSelected = _selectedTimeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: ValueKey('time_filter_${filter.name}'),
                label: Text(filter.label),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (_) {
                  setState(() {
                    if (filter == RecipeTimeFilter.all) {
                      _selectedTimeFilter = RecipeTimeFilter.all;
                    } else {
                      _selectedTimeFilter = _selectedTimeFilter == filter
                          ? RecipeTimeFilter.all
                          : filter;
                    }
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _openMultiDayPlanner({int initialDaysCount = 3}) async {
    final previousPantryNorms = _pantryIngredients
        .map((item) => StringNormalizer.normalize(item.name))
        .toSet();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiDayPlannerScreen(
          initialIngredientNames: _selectedIngredientNames,
          initialDaysCount: initialDaysCount,
          initialCategory: _selectedCategory,
          initialTimeFilter: _selectedTimeFilter,
          ingredientStorageService: _ingredientStorageService,
          shoppingListService: _shoppingListService,
          historyService: _historyService,
          healthGoalStorageService: _healthGoalStorageService,
          priceStorageService: _priceStorageService,
          salesService: _salesService,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshAfterRecipeDetail(previousPantryNorms);
  }

  Future<void> _openNutritionGoals() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NutritionTipsScreen(
          historyService: _historyService,
          shoppingListService: _shoppingListService,
          healthGoalStorageService: _healthGoalStorageService,
        ),
      ),
    );
    if (!mounted) return;
    if (_showingAllRecipes) {
      await _showAllLocalRecipes();
    } else {
      await _performDiscovery();
    }
  }

  Widget _buildActiveGoalsBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goalSummary = _activeHealthGoals.map((g) => g.shortLabel).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            assetName: 'nutrition',
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Metas activas: $goalSummary',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _openNutritionGoals,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: const Text('Cambiar metas'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilteredState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasCategory = _selectedCategory != 'Todos';
    final hasTime = _selectedTimeFilter != RecipeTimeFilter.all;

    final String emptyTitle;
    if (hasCategory && hasTime) {
      emptyTitle =
          'Sin recetas de "$_selectedCategory" en ${_selectedTimeFilter.label}';
    } else if (hasTime) {
      emptyTitle = 'Sin recetas en ${_selectedTimeFilter.label}';
    } else {
      emptyTitle = 'Sin recetas de tipo "$_selectedCategory"';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              assetName: 'filter_off',
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
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
                  _selectedTimeFilter = RecipeTimeFilter.all;
                });
              },
              icon: AppSvgIcon(
                assetName: 'close',
                size: 16,
                color: colorScheme.primary,
              ),
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
          AppSvgIcon(
            assetName: 'info',
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
        storageService: widget.ingredientStorageService,
        shoppingListService: widget.shoppingListService,
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
    final ingredientCount = _selectedIngredientNames.length;
    final isSingleRecipe = count == 1;
    final isSingleIngredient = ingredientCount == 1;

    String bannerTitle = isSingleRecipe
        ? '1 receta disponible'
        : '$count recetas disponibles';
    if (_showingAllRecipes) {
      bannerTitle = 'Catálogo de recetas ($count)';
    } else if (_discoveryResponse?.isExternal == true) {
      bannerTitle = isSingleRecipe
          ? '1 receta en línea'
          : '$count recetas en línea';
    } else if (_discoveryResponse?.isFallback == true) {
      bannerTitle = isSingleRecipe
          ? '1 receta sugerida'
          : '$count recetas sugeridas';
    }

    final activeFilters = <String>[
      if (_selectedCategory != 'Todos') _selectedCategory,
      if (_selectedTimeFilter != RecipeTimeFilter.all) _selectedTimeFilter.label,
    ];
    if (activeFilters.isNotEmpty && count != totalCount) {
      bannerTitle = '$bannerTitle (${activeFilters.join(', ')})';
    }

    final ingredientSummary = _showingAllRecipes && ingredientCount == 0
        ? 'Explorando todas las recetas disponibles'
        : isSingleIngredient
            ? 'Con base en 1 ingrediente seleccionado'
            : 'Con base en $ingredientCount ingredientes seleccionados';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: AppSvgIcon(
              assetName: 'restaurant',
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bannerTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  ingredientSummary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Cambiar ingredientes para nuevas sugerencias',
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.isMobile ? 124 : 210,
              ),
              child: OutlinedButton(
                onPressed: _navigateToIngredientList,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      assetName: 'shopping_cart',
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Cambiar ingredientes',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    final costComparison = RecipeCostCalculator.compareRecipe(
      recipe,
      savedPrices: _savedPrices,
      deals: _cachedDeals,
    );

    final metaDetails = <String>[];
    if (recipe.category != null) metaDetails.add(recipe.category!);
    if (recipe.totalTimeMinutes != null) metaDetails.add('${recipe.totalTimeMinutes} min');
    if (recipe.servings != null) metaDetails.add('${recipe.servings} porciones');
    if (recipe.ingredients.isNotEmpty) {
      metaDetails.add('~${costComparison.formattedHomePerServing} / porción');
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: result.canCookNow
              ? colorScheme.primary.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: result.canCookNow ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final previousPantryNorms = _pantryIngredients
              .map((item) => StringNormalizer.normalize(item.name))
              .toSet();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: RouteSettings(name: 'recipe_${result.recipe.id}'),
              builder: (_) => RecipeDetailScreen.fromResult(
                result: result,
                historyService: _historyService,
                shoppingListService: _shoppingListService,
                ingredientStorageService: _ingredientStorageService,
                healthGoalStorageService: _healthGoalStorageService,
                priceStorageService: _priceStorageService,
                salesService: _salesService,
              ),
            ),
          ).then((_) {
            _refreshAfterRecipeDetail(previousPantryNorms);
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
                  AppSvgIcon(
                    assetName: 'chevron_right',
                    size: 20,
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
                  Expanded(
                    child: Text(
                      'Tienes ${result.matchCount} de ${result.totalIngredients} ingredientes',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: result.hasAllIngredients
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
              if (result.trulyMissingIngredients.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Te falta: ${result.trulyMissingIngredients.map((i) => i.name).join(', ')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (result.hasAvailabilityReplacements) ...[
                const SizedBox(height: 8),
                _buildAvailabilitySwapCallout(context, result),
              ],
              if (result.goalMatch.hasMatch) ...[
                const SizedBox(height: 10),
                GoalTooltipBanner(
                  tooltipKey: ValueKey('goal_tooltip_${recipe.id}'),
                  goalMatch: result.goalMatch,
                ),
              ],
              if (result.hasHealthGoalReplacements) ...[
                const SizedBox(height: 8),
                _buildHealthGoalSwapCallout(context, result),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilitySwapCallout(
    BuildContext context,
    RecipeSearchResult result,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final replacements = result.availabilityReplacements;
    final primaryText = replacements.length == 1
        ? replacements.first.message
        : '${replacements.first.message} (+${replacements.length - 1} '
            '${replacements.length - 1 == 1 ? 'reemplazo' : 'reemplazos'})';

    return Container(
      key: ValueKey('availability_swap_${result.recipe.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppSvgIcon(
              assetName: 'refresh',
              size: 15,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (result.isCookableWithReplacements) ...[
                  const SizedBox(height: 2),
                  Text(
                    replacements.length == 1
                        ? '¡Lista para cocinar con este cambio!'
                        : '¡Lista para cocinar con estos cambios!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthGoalSwapCallout(
    BuildContext context,
    RecipeSearchResult result,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final swap = result.healthGoalReplacements.first;

    return Container(
      key: ValueKey('health_swap_${result.recipe.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppSvgIcon(
              assetName: 'sparkles',
              size: 14,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              swap.cardMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasNoSelection = _selectedIngredientNames.isEmpty;
    final hasPantryItems = _pantryIngredients.isNotEmpty;

    final title = hasNoSelection
        ? 'Selecciona ingredientes para ver recetas'
        : 'No se encontraron recetas con los ingredientes seleccionados';

    final String subtitle;
    if (hasNoSelection) {
      if (hasPantryItems) {
        final count = _pantryIngredients.length;
        subtitle = count == 1
            ? 'Necesitas seleccionar ingredientes disponibles para ver recetas recomendadas. Tienes 1 ingrediente agregado en tu despensa.'
            : 'Necesitas seleccionar ingredientes disponibles para ver recetas recomendadas. Tienes $count ingredientes agregados en tu despensa.';
      } else {
        subtitle =
            'Necesitas seleccionar ingredientes disponibles para ver recetas recomendadas. Agrega ingredientes en tu lista para comenzar.';
      }
    } else {
      subtitle =
          'Intenta seleccionando otros ingredientes o explora todas las recetas saludables del catálogo.';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: AppSvgIcon(
                    assetName: 'restaurant',
                    size: 56,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (hasNoSelection) ...[
                if (hasPantryItems) ...[
                  // Highest emphasis on selecting all saved pantry ingredients when available
                  FilledButton.icon(
                    autofocus: true,
                    onPressed: _selectAllPantryIngredientsAndRefresh,
                    icon: AppSvgIcon(
                      assetName: 'check',
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                    label: const Text('Seleccionar todos mis ingredientes'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _navigateToIngredientList,
                    icon: AppSvgIcon(
                      assetName: 'shopping_cart',
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    label: const Text('Ir a mis ingredientes'),
                  ),
                ] else ...[
                  // Highest emphasis on going to the ingredient list when pantry has no saved items yet
                  FilledButton.icon(
                    autofocus: true,
                    onPressed: _navigateToIngredientList,
                    icon: AppSvgIcon(
                      assetName: 'shopping_cart',
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                    label: const Text('Ir a mis ingredientes'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: AppSvgIcon(
                      assetName: 'check',
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    label: const Text('Seleccionar todos mis ingredientes'),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showAllLocalRecipes,
                  icon: AppSvgIcon(
                    assetName: 'book',
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: const Text('Ver todas las recetas'),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  key: const ValueKey('empty_multi_day_planner_button'),
                  onPressed: () => _openMultiDayPlanner(),
                  icon: AppSvgIcon(
                    assetName: 'calendar',
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: const Text('Planificar varios días'),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: _showAllLocalRecipes,
                  icon: AppSvgIcon(
                    assetName: 'restaurant',
                    size: 18,
                    color: colorScheme.onPrimary,
                  ),
                  label: const Text('Ver todas las recetas'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _navigateToIngredientList,
                  icon: AppSvgIcon(
                    assetName: 'shopping_cart',
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: const Text('Ir a mis ingredientes'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const ValueKey('empty_multi_day_planner_button'),
                  onPressed: () => _openMultiDayPlanner(),
                  icon: AppSvgIcon(
                    assetName: 'calendar',
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: const Text('Planificar varios días'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


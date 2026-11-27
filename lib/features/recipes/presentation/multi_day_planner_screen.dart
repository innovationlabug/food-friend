import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/settings/settings_controller.dart';
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
import '../data/multi_day_planner_service.dart';
import '../data/recipe_history_service.dart';
import '../data/recipe_search_service.dart';
import '../domain/multi_day_meal_plan.dart';
import '../domain/recipe_history_record.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_time_filter.dart';
import 'recipe_detail_screen.dart';

/// Multi-day cooking and recipe variation planner (`2–7 días`).
/// Builds a deterministic day-by-day Spanish schedule prioritizing shared pantry
/// ingredients, rotating variations without consecutive repetition, and aggregating
/// missing ingredients for one-tap addition to `"Por comprar"`.
class MultiDayPlannerScreen extends StatefulWidget {
  const MultiDayPlannerScreen({
    super.key,
    this.initialIngredientNames,
    this.initialDaysCount = 3,
    this.initialCategory = 'Todos',
    this.initialTimeFilter = RecipeTimeFilter.all,
    this.plannerService,
    this.ingredientStorageService,
    this.shoppingListService,
    this.historyService,
    this.healthGoalStorageService,
    this.priceStorageService,
    this.salesService,
  });

  final List<String>? initialIngredientNames;
  final int initialDaysCount;
  final String initialCategory;
  final RecipeTimeFilter initialTimeFilter;
  final MultiDayPlannerService? plannerService;
  final IngredientStorageService? ingredientStorageService;
  final ShoppingListStorageService? shoppingListService;
  final RecipeHistoryService? historyService;
  final HealthGoalStorageService? healthGoalStorageService;
  final IngredientPriceStorageService? priceStorageService;
  final SalesService? salesService;

  @override
  State<MultiDayPlannerScreen> createState() => _MultiDayPlannerScreenState();
}

class _MultiDayPlannerScreenState extends State<MultiDayPlannerScreen> {
  static const List<String> _categories = <String>[
    'Todos',
    'Desayuno',
    'Almuerzo',
    'Cena',
    'Sopas y Caldos',
    'Ensaladas',
  ];

  late final IngredientStorageService _ingredientStorageService;
  late final ShoppingListStorageService _shoppingListService;
  late final RecipeHistoryService _historyService;
  late final HealthGoalStorageService _healthGoalStorageService;
  late final IngredientPriceStorageService _priceStorageService;
  late final SalesService _salesService;
  late final MultiDayPlannerService _plannerService;

  late int _selectedDays;
  late String _selectedCategory;
  late RecipeTimeFilter _selectedTimeFilter;

  bool _isLoading = true;
  bool _isAddingMissing = false;
  List<String> _availableIngredientNames = const [];
  Map<String, RecipeHistoryRecord> _history = const {};
  Set<HealthGoal> _activeHealthGoals = <HealthGoal>{};
  List<String> _shoppingListNorms = const [];
  Map<String, IngredientPriceEntry> _savedPrices = const {};
  List<SupermarketDeal> _cachedDeals = FallbackSalesData.deals;
  MultiDayMealPlan? _plan;

  @override
  void initState() {
    super.initState();
    _ingredientStorageService =
        widget.ingredientStorageService ?? IngredientStorageService();
    _shoppingListService = widget.shoppingListService ??
        ShoppingListStorageService(
          pantryStorageService: _ingredientStorageService,
        );
    _historyService = widget.historyService ??
        RecipeHistoryService(
          ingredientStorageService: _ingredientStorageService,
        );
    _healthGoalStorageService =
        widget.healthGoalStorageService ?? HealthGoalStorageService();
    _priceStorageService =
        widget.priceStorageService ?? IngredientPriceStorageService();
    _salesService = widget.salesService ?? SalesService();
    _plannerService = widget.plannerService ??
        MultiDayPlannerService(
          ingredientStorageService: _ingredientStorageService,
          historyService: _historyService,
          healthGoalStorageService: _healthGoalStorageService,
        );

    _selectedDays = widget.initialDaysCount.clamp(
      MultiDayPlannerService.minDays,
      MultiDayPlannerService.maxDays,
    );
    _selectedCategory = _categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'Todos';
    _selectedTimeFilter = widget.initialTimeFilter;
    SettingsController.instance.addListener(_onSettingsChanged);

    _loadData();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    _loadData();
  }

  @override
  void dispose() {
    SettingsController.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await SettingsController.instance.load();
    final settings = SettingsController.instance;

    final results = await Future.wait<dynamic>([
      _ingredientStorageService.getIngredients(),
      if (settings.enableRecipeManagement)
        _historyService.getHistory()
      else
        Future<Map<String, RecipeHistoryRecord>>.value(
          const <String, RecipeHistoryRecord>{},
        ),
      if (settings.enableNutritionAndGoals)
        _healthGoalStorageService.getSelectedGoals()
      else
        Future<Set<HealthGoal>>.value(<HealthGoal>{}),
      _shoppingListService.getIngredients(),
      if (settings.enableGtqPricing)
        _priceStorageService.getPrices()
      else
        Future<Map<String, IngredientPriceEntry>>.value(
          const <String, IngredientPriceEntry>{},
        ),
      if (settings.enableGtqPricing && settings.enableSupermarketDeals)
        _salesService.getCachedOrFallbackDeals()
      else
        Future<List<SupermarketDeal>>.value(const <SupermarketDeal>[]),
    ]);

    if (!mounted) return;

    final pantry = results[0] as List<Ingredient>;
    final history = results[1] as Map<String, RecipeHistoryRecord>;
    final goals = results[2] as Set<HealthGoal>;
    final shoppingItems = results[3] as List<Ingredient>;
    final savedPrices = results[4] as Map<String, IngredientPriceEntry>;
    final deals = results[5] as List<SupermarketDeal>;

    final initialNames = widget.initialIngredientNames;
    final availableNames = (initialNames != null && initialNames.isNotEmpty)
        ? List<String>.from(initialNames)
        : pantry.map((i) => i.name).toList();

    final shoppingNorms = shoppingItems
        .map((i) => StringNormalizer.normalize(i.name))
        .where((n) => n.isNotEmpty)
        .toList();

    setState(() {
      _availableIngredientNames = availableNames;
      _history = history;
      _activeHealthGoals = goals;
      _shoppingListNorms = shoppingNorms;
      _savedPrices = savedPrices;
      _cachedDeals = deals;
      _plan = _buildPlan();
      _isLoading = false;
    });
  }

  MultiDayMealPlan _buildPlan() {
    return _plannerService.generatePlan(
      daysCount: _selectedDays,
      availableIngredientNames: _availableIngredientNames,
      history: _history,
      activeHealthGoals: _activeHealthGoals,
      categoryFilter: _selectedCategory,
      maxTotalTimeMinutes: _selectedTimeFilter.maxMinutes,
    );
  }

  void _regeneratePlan() {
    setState(() {
      _plan = _buildPlan();
    });
  }

  bool _isInShoppingList(RecipeIngredient ingredient) {
    final targetNorm = ingredient.normalizedName;
    if (targetNorm.isEmpty) return false;
    return _shoppingListNorms.any(
      (existingNorm) =>
          RecipeSearchService.isIngredientMatch(existingNorm, targetNorm),
    );
  }

  Future<void> _addSingleMissing(RecipeIngredient ingredient) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_isInShoppingList(ingredient)) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${ingredient.name}" ya está en tu lista de compras'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final updated = await _shoppingListService.addIngredient(
      Ingredient(name: ingredient.name),
    );
    if (!mounted) return;

    setState(() {
      _shoppingListNorms = updated
          .map((i) => StringNormalizer.normalize(i.name))
          .where((n) => n.isNotEmpty)
          .toList();
    });

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${ingredient.name}" agregado a tu lista de compras'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addAllMissingToShoppingList(
    List<RecipeIngredient> missingToAdd,
  ) async {
    if (_isAddingMissing || missingToAdd.isEmpty) return;

    setState(() {
      _isAddingMissing = true;
    });

    try {
      final items = missingToAdd
          .map((ing) => Ingredient(name: ing.name))
          .toList();
      final updated = await _shoppingListService.addIngredients(items);
      if (!mounted) return;

      setState(() {
        _shoppingListNorms = updated
            .map((i) => StringNormalizer.normalize(i.name))
            .where((n) => n.isNotEmpty)
            .toList();
      });

      final count = missingToAdd.length;
      final message = count == 1
          ? 'Se agregó 1 ingrediente faltante a tu lista de compras'
          : 'Se agregaron $count ingredientes faltantes a tu lista de compras';
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingMissing = false;
        });
      }
    }
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
    await _loadData();
  }

  Future<void> _openDayRecipeDetail(MealPlanDay day) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: 'planner_day_${day.dayNumber}_${day.recipe.id}'),
        builder: (_) => RecipeDetailScreen(
          recipe: day.recipe,
          matchedIngredients: day.matchedPantryIngredients,
          missingIngredients: day.missingIngredients,
          goalMatch: day.goalMatch,
          historyService: _historyService,
          shoppingListService: _shoppingListService,
          ingredientStorageService: _ingredientStorageService,
          healthGoalStorageService: _healthGoalStorageService,
          priceStorageService: _priceStorageService,
          salesService: _salesService,
        ),
      ),
    );
    if (!mounted) return;
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppNavigationDrawer(
        currentDestination: AppDestination.multiDayPlanner,
      ),
      appBar: AppBar(
        leadingWidth: appBarLeadingWidth(context),
        leading: const AppBarLeading(),
        title: const Text(
          'Planificador de comidas',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: _isLoading
              ? _buildLoadingState(context)
              : _buildPlannerBody(context),
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
            'Organizando tu plan de comidas...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerBody(BuildContext context) {
    final plan = _plan ??
        const MultiDayMealPlan(
          daysCount: 3,
          days: [],
        );

    return ListView(
      children: [
        _buildDaySelectorCard(context),
        const SizedBox(height: 12),
        _buildCategoryFilters(context),
        const SizedBox(height: 8),
        _buildTimeFilters(context),
        if (SettingsController.instance.enableNutritionAndGoals &&
            _activeHealthGoals.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildActiveGoalsBar(context),
        ],
        const SizedBox(height: 12),
        if (plan.isEmpty)
          _buildEmptyPlanState(context)
        else ...[
          _buildPlanSummaryBanner(context, plan),
          const SizedBox(height: 12),
          _buildDaysList(context, plan),
          const SizedBox(height: 16),
          _buildMissingIngredientsSection(context, plan),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildDaySelectorCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pantryCount = _availableIngredientNames.length;
    final pantrySummary = pantryCount == 0
        ? 'Explorando recetas del catálogo local'
        : pantryCount == 1
            ? 'Priorizando 1 ingrediente de tu despensa'
            : 'Priorizando $pantryCount ingredientes de tu despensa';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
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
                  assetName: 'calendar',
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Para cuántos días quieres cocinar?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pantrySummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MultiDayPlannerService.supportedDayCounts.map((days) {
              final isSelected = _selectedDays == days;
              return ChoiceChip(
                key: ValueKey('day_count_chip_$days'),
                label: Text('$days días'),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected && _selectedDays != days) {
                    _selectedDays = days;
                    _regeneratePlan();
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: ValueKey('planner_category_$cat'),
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && _selectedCategory != cat) {
                  _selectedCategory = cat;
                  _regeneratePlan();
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
                key: ValueKey('planner_time_${filter.name}'),
                label: Text(filter.label),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (_) {
                  if (filter == RecipeTimeFilter.all) {
                    _selectedTimeFilter = RecipeTimeFilter.all;
                  } else {
                    _selectedTimeFilter = _selectedTimeFilter == filter
                        ? RecipeTimeFilter.all
                        : filter;
                  }
                  _regeneratePlan();
                },
              ),
            );
          }),
        ],
      ),
    );
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

  Widget _buildPlanSummaryBanner(BuildContext context, MultiDayMealPlan plan) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shared = plan.sharedCoreIngredients;
    final sharedPreview = shared.take(5).join(', ');
    final extraCount = shared.length > 5 ? shared.length - 5 : 0;
    final sharedLine = shared.isEmpty
        ? 'Platos variados para toda tu planificación.'
        : extraCount > 0
            ? 'Ingredientes compartidos: $sharedPreview (+$extraCount)'
            : 'Ingredientes compartidos: $sharedPreview';

    return Container(
      key: const ValueKey('plan_summary_banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSvgIcon(
            assetName: 'sparkles',
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan de ${plan.days.length} días con variaciones',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sharedLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList(BuildContext context, MultiDayMealPlan plan) {
    final days = plan.days;
    if (!context.isDesktop) {
      return Column(
        children: [
          for (int i = 0; i < days.length; i++) ...[
            _buildDayCard(context, days[i]),
            if (i < days.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    final rowCount = (days.length + 1) ~/ 2;
    return Column(
      children: [
        for (int rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildDayCard(context, days[rowIndex * 2])),
                const SizedBox(width: 12),
                Expanded(
                  child: (rowIndex * 2 + 1) < days.length
                      ? _buildDayCard(context, days[rowIndex * 2 + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (rowIndex < rowCount - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, MealPlanDay day) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipe = day.recipe;
    final settings = SettingsController.instance;
    final showGtqPricing = settings.enableGtqPricing;
    final costComparison = showGtqPricing
        ? RecipeCostCalculator.compareRecipe(
            recipe,
            savedPrices: _savedPrices,
            deals: settings.enableSupermarketDeals ? _cachedDeals : const [],
          )
        : null;

    final metaDetails = <String>[
      if (recipe.category != null) recipe.category!,
      if (recipe.totalTimeMinutes != null) '${recipe.totalTimeMinutes} min',
      if (recipe.servings != null) '${recipe.servings} porciones',
      if (showGtqPricing && costComparison != null && recipe.ingredients.isNotEmpty)
        '~${costComparison.formattedHomePerServing} / porción',
    ];

    return Card(
      key: ValueKey('meal_plan_day_${day.dayNumber}'),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: day.hasAllIngredients
              ? colorScheme.primary.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.55),
          width: day.hasAllIngredients ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDayRecipeDetail(day),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    day.dayLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  AppSvgIcon(
                    assetName: 'chevron_right',
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                recipe.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
              if (day.isVariation) ...[
                const SizedBox(height: 10),
                Container(
                  key: ValueKey('meal_plan_variation_${day.dayNumber}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
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
                              'Variación de ${day.baseRecipe!.title}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (day.variation!.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                day.variation!.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (day.sharedIngredientsWithPreviousDays.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Reutiliza: ${day.sharedIngredientsWithPreviousDays.join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Tienes ${day.matchedCount} de ${day.totalIngredients} ingredientes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: day.hasAllIngredients
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (day.missingIngredients.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Te falta: ${day.missingIngredients.map((i) => i.name).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
              if (settings.enableNutritionAndGoals && day.goalMatch.hasMatch) ...[
                const SizedBox(height: 10),
                GoalTooltipBanner(
                  tooltipKey: ValueKey(
                    'planner_goal_tooltip_${day.dayNumber}_${recipe.id}',
                  ),
                  goalMatch: day.goalMatch,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissingIngredientsSection(
    BuildContext context,
    MultiDayMealPlan plan,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allMissing = plan.consolidatedMissingIngredients;

    if (allMissing.isEmpty) {
      return Container(
        key: const ValueKey('plan_missing_ingredients_section'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            AppSvgIcon(
              assetName: 'check_circle',
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Tienes todos los ingredientes necesarios para cocinar los ${plan.days.length} días!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final pendingToAdd =
        allMissing.where((ing) => !_isInShoppingList(ing)).toList();

    return Container(
      key: const ValueKey('plan_missing_ingredients_section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppSvgIcon(
                assetName: 'shopping_cart',
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ingredientes faltantes del plan (${allMissing.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lista consolidada sin duplicados para completar los ${plan.days.length} días de comida.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('add_all_plan_missing_button'),
            onPressed: pendingToAdd.isEmpty || _isAddingMissing
                ? null
                : () => _addAllMissingToShoppingList(pendingToAdd),
            icon: AppSvgIcon(
              assetName: pendingToAdd.isEmpty ? 'check' : 'shopping_cart',
              size: 18,
              color: pendingToAdd.isEmpty
                  ? colorScheme.onSurface.withValues(alpha: 0.38)
                  : colorScheme.onPrimary,
            ),
            label: Text(
              pendingToAdd.isEmpty
                  ? 'Todos los faltantes están en Lista de compras'
                  : 'Agregar faltantes a Lista de compras (${pendingToAdd.length})',
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < allMissing.length; i++) ...[
            _buildMissingItemRow(context, allMissing[i]),
            if (i < allMissing.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildMissingItemRow(
    BuildContext context,
    RecipeIngredient ingredient,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inList = _isInShoppingList(ingredient);

    return Container(
      key: ValueKey('plan_missing_item_${ingredient.normalizedName}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ingredient.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: inList ? null : () => _addSingleMissing(ingredient),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            icon: AppSvgIcon(
              assetName: inList ? 'check' : 'plus',
              size: 16,
              color: inList
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.primary,
            ),
            label: Text(inList ? 'En lista' : 'Agregar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlanState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          AppSvgIcon(
            assetName: 'filter_off',
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay suficientes recetas bajo este filtro',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba limpiando los filtros de categoría o tiempo para armar tu plan de $_selectedDays días.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _selectedCategory = 'Todos';
              _selectedTimeFilter = RecipeTimeFilter.all;
              _regeneratePlan();
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
    );
  }
}

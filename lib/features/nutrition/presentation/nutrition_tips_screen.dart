import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/utils/string_normalizer.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../recipes/data/recipe_history_service.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';
import '../../recipes/presentation/recipe_suggestions_screen.dart';
import '../../shopping_list/data/shopping_list_storage_service.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';
import '../data/health_goal_storage_service.dart';
import '../data/nutrition_service.dart';
import '../domain/health_goal.dart';
import '../domain/nutrition_tip.dart';
import '../domain/recipe_goal_match.dart';
import 'widgets/goal_tooltip_banner.dart';

/// Displays interactive health-goal selection, dynamic goal-oriented nutrition
/// guidance derived from cooking history and active goals, and goal-matched
/// recipe suggestions with specific Spanish nutritional tooltips.
class NutritionTipsScreen extends StatefulWidget {
  const NutritionTipsScreen({
    super.key,
    this.nutritionService,
    this.historyService,
    this.shoppingListService,
    this.healthGoalStorageService,
  });

  /// Optional injected nutrition service for testing.
  final NutritionService? nutritionService;

  /// Optional injected recipe history service for testing.
  final RecipeHistoryService? historyService;

  /// Optional injected shopping list storage service for testing.
  final ShoppingListStorageService? shoppingListService;

  /// Optional injected health goal storage service for testing.
  final HealthGoalStorageService? healthGoalStorageService;

  /// Navigates to [NutritionTipsScreen].
  static Future<void> navigate(
    BuildContext context, {
    NutritionService? nutritionService,
    RecipeHistoryService? historyService,
    ShoppingListStorageService? shoppingListService,
    HealthGoalStorageService? healthGoalStorageService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NutritionTipsScreen(
          nutritionService: nutritionService,
          historyService: historyService,
          shoppingListService: shoppingListService,
          healthGoalStorageService: healthGoalStorageService,
        ),
      ),
    );
  }

  @override
  State<NutritionTipsScreen> createState() => _NutritionTipsScreenState();
}

class _NutritionTipsScreenState extends State<NutritionTipsScreen> {
  late final HealthGoalStorageService _healthGoalStorageService;
  late final NutritionService _nutritionService;
  late final ShoppingListStorageService _shoppingListService;

  NutritionReport? _report;
  Set<HealthGoal> _selectedGoals = <HealthGoal>{};
  Set<String> _shoppingListNormalized = <String>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _healthGoalStorageService =
        widget.healthGoalStorageService ?? HealthGoalStorageService();
    _nutritionService = widget.nutritionService ??
        NutritionService(
          historyService: widget.historyService,
          healthGoalStorageService: _healthGoalStorageService,
        );
    _shoppingListService =
        widget.shoppingListService ?? ShoppingListStorageService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await SettingsController.instance.load();
    final includeHistory = SettingsController.instance.enableRecipeManagement;

    final results = await Future.wait<dynamic>([
      _healthGoalStorageService.getSelectedGoals(),
      _nutritionService.generateReport(includeCookingHistory: includeHistory),
      _shoppingListService.getIngredients(),
    ]);

    if (!mounted) return;
    final selectedGoals = results[0] as Set<HealthGoal>;
    final report = results[1] as NutritionReport;
    final shoppingItems = results[2] as List<Ingredient>;

    setState(() {
      _selectedGoals = selectedGoals;
      _report = report;
      _shoppingListNormalized = shoppingItems
          .map((item) => StringNormalizer.normalize(item.name))
          .toSet();
      _isLoading = false;
    });
  }

  Future<void> _toggleGoal(HealthGoal goal) async {
    final updatedGoals = await _healthGoalStorageService.toggleGoal(goal);
    final updatedReport = await _nutritionService.generateReport(
      includeCookingHistory: SettingsController.instance.enableRecipeManagement,
    );
    if (!mounted) return;

    setState(() {
      _selectedGoals = updatedGoals;
      _report = updatedReport;
    });
  }

  bool _isInShoppingList(String ingredientName) {
    return _shoppingListNormalized.contains(
      StringNormalizer.normalize(ingredientName),
    );
  }

  Future<void> _addToShoppingList(String ingredientName) async {
    await _shoppingListService.addIngredient(Ingredient(name: ingredientName));

    if (!mounted) return;
    setState(() {
      _shoppingListNormalized.add(StringNormalizer.normalize(ingredientName));
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"$ingredientName" agregado a tu lista de compras'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openShoppingList() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShoppingListScreen(
          shoppingListService: _shoppingListService,
          historyService: widget.historyService,
          healthGoalStorageService: _healthGoalStorageService,
          initialTab: 1,
        ),
      ),
    );
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openSuggestionsWithGoals() async {
    final pantry = await IngredientStorageService().getIngredients();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeSuggestionsScreen(
          selectedIngredientNames: pantry.map((i) => i.name).toList(),
          historyService: widget.historyService,
          shoppingListService: _shoppingListService,
          healthGoalStorageService: _healthGoalStorageService,
        ),
      ),
    );
    if (mounted) {
      await _loadData();
    }
  }

  Future<void> _openRecipeDetail(
    Recipe recipe,
    RecipeGoalMatch goalMatch,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: 'recipe_${recipe.id}'),
        builder: (_) => RecipeDetailScreen(
          recipe: recipe,
          goalMatch: goalMatch,
          historyService: widget.historyService,
          shoppingListService: _shoppingListService,
          healthGoalStorageService: _healthGoalStorageService,
        ),
      ),
    );
    if (mounted) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const AppNavigationDrawer(
        currentDestination: AppDestination.nutritionTips,
      ),
      appBar: AppBar(
        leadingWidth: appBarLeadingWidth(context),
        leading: const AppBarLeading(),
        title: const Text(
          'Consejos de Nutrición',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Ver lista de compras',
            icon: AppSvgIcon(
              assetName: 'shopping_cart',
              size: 22,
              color: colorScheme.onSurface,
            ),
            onPressed: _openShoppingList,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final report = _report;
    if (report == null) {
      return const SizedBox.shrink();
    }

    final isDesktop = context.isDesktop;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          _buildGoalsSection(context),
          const SizedBox(height: 16),
          if (!report.hasCookingHistory && _selectedGoals.isEmpty) ...[
            _buildEmptyGuidanceCard(context),
          ] else ...[
            if (report.hasCookingHistory) ...[
              _buildSummaryHeader(context, report),
              const SizedBox(height: 16),
            ],
            if (report.tips.isEmpty && report.hasCookingHistory)
              _buildBalancedHistoryCard(context)
            else if (report.tips.isNotEmpty) ...[
              Text(
                report.hasCookingHistory
                    ? 'Consejos personalizados'
                    : 'Recomendaciones para tus metas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (!isDesktop)
                for (int i = 0; i < report.tips.length; i++) ...[
                  _buildTipCard(context, report.tips[i]),
                  if (i < report.tips.length - 1) const SizedBox(height: 12),
                ]
              else
                for (int i = 0; i < report.tips.length; i += 2) ...[
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildTipCard(context, report.tips[i])),
                        const SizedBox(width: 12),
                        Expanded(
                          child: i + 1 < report.tips.length
                              ? _buildTipCard(context, report.tips[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  if (i + 2 < report.tips.length) const SizedBox(height: 12),
                ],
            ],
          ],
          if (report.recommendedGoalRecipes.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildRecommendedGoalRecipesSection(
              context,
              report.recommendedGoalRecipes,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const goals = HealthGoal.values;
    final isDesktop = context.isDesktop;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppSvgIcon(
                  assetName: 'nutrition',
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tus metas de salud',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Elige una o más metas para priorizar recetas y recibir consejos a tu medida.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (!isDesktop)
              for (int i = 0; i < goals.length; i++) ...[
                _buildGoalTile(context, goals[i]),
                if (i < goals.length - 1) const SizedBox(height: 8),
              ]
            else
              for (int i = 0; i < goals.length; i += 2) ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildGoalTile(context, goals[i])),
                      const SizedBox(width: 10),
                      Expanded(
                        child: i + 1 < goals.length
                            ? _buildGoalTile(context, goals[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                if (i + 2 < goals.length) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTile(BuildContext context, HealthGoal goal) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedGoals.contains(goal);

    return Semantics(
      button: true,
      toggled: isSelected,
      label: goal.label,
      child: Card(
        key: ValueKey('health_goal_${goal.storageKey}'),
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.65),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: () => _toggleGoal(goal),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppSvgIcon(
                    assetName: goal.iconName,
                    size: 18,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        goal.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goal.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AppSvgIcon(
                    assetName: isSelected ? 'check_circle' : 'circle',
                    size: 20,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyGuidanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppSvgIcon(
                assetName: 'nutrition',
                size: 24,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personaliza tu nutrición',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selecciona una o más metas de salud arriba o usa el botón "Lo cociné" '
                    'al preparar cualquier receta para recibir consejos adaptados a tu alimentación.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, NutritionReport report) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mealLabel = report.recentMealsEvaluated == 1
        ? '1 comida reciente analizada'
        : '${report.recentMealsEvaluated} comidas recientes analizadas';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppSvgIcon(
                assetName: 'nutrition',
                size: 24,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de tu alimentación',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mealLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalancedHistoryCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppSvgIcon(
                assetName: 'check',
                size: 22,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tus comidas recientes se ven muy equilibradas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Has cubierto las vitaminas principales y mantenido buenas combinaciones de proteínas sin exceso de embutidos.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, NutritionTip tip) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (String iconName, Color containerColor, Color iconColor) =
        switch (tip.category) {
      NutritionTipCategory.healthAlert => (
          'block',
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
      NutritionTipCategory.goalGuidance => (
          tip.goal?.iconName ?? 'sparkles',
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      NutritionTipCategory.vitaminSuggestion => (
          'nutrition',
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      NutritionTipCategory.proteinPairing => (
          'heart',
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppSvgIcon(
                    assetName: iconName,
                    size: 22,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tip.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (tip.recommendedIngredients.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tip.recommendedIngredients.map((ingredient) {
                  final alreadyAdded = _isInShoppingList(ingredient);
                  return Tooltip(
                    message: alreadyAdded
                        ? '$ingredient ya está en tu lista de compras'
                        : 'Agregar $ingredient a tu lista de compras',
                    child: OutlinedButton.icon(
                      onPressed: alreadyAdded
                          ? null
                          : () => _addToShoppingList(ingredient),
                      icon: AppSvgIcon(
                        assetName: alreadyAdded ? 'check' : 'plus',
                        size: 16,
                        color: alreadyAdded
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        alreadyAdded
                            ? '$ingredient (en lista)'
                            : 'Agregar $ingredient',
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedGoalRecipesSection(
    BuildContext context,
    List<({Recipe recipe, RecipeGoalMatch goalMatch})> recommendations,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppSvgIcon(
              assetName: 'sparkles',
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recetas alineadas con tus metas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!isDesktop)
          for (int i = 0; i < recommendations.length; i++) ...[
            _buildRecommendedRecipeCard(context, recommendations[i]),
            if (i < recommendations.length - 1) const SizedBox(height: 10),
          ]
        else
          for (int i = 0; i < recommendations.length; i += 2) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildRecommendedRecipeCard(
                      context,
                      recommendations[i],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < recommendations.length
                        ? _buildRecommendedRecipeCard(
                            context,
                            recommendations[i + 1],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            if (i + 2 < recommendations.length) const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openSuggestionsWithGoals,
          icon: AppSvgIcon(
            assetName: 'restaurant',
            size: 18,
            color: colorScheme.primary,
          ),
          label: const Text('Ver todas en recetas sugeridas'),
        ),
      ],
    );
  }

  Widget _buildRecommendedRecipeCard(
    BuildContext context,
    ({Recipe recipe, RecipeGoalMatch goalMatch}) item,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipe = item.recipe;
    final goalMatch = item.goalMatch;

    final metaParts = <String>[
      if (recipe.category != null) recipe.category!,
      if (recipe.totalTimeMinutes != null) '${recipe.totalTimeMinutes} min',
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openRecipeDetail(recipe, goalMatch),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppSvgIcon(
                    assetName: 'chevron_right',
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (metaParts.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  metaParts.join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (goalMatch.hasMatch) ...[
                const SizedBox(height: 10),
                GoalTooltipBanner(
                  tooltipKey: ValueKey('nutrition_goal_tooltip_${recipe.id}'),
                  goalMatch: goalMatch,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

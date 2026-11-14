import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/utils/string_normalizer.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../recipes/data/recipe_history_service.dart';
import '../../shopping_list/data/shopping_list_storage_service.dart';
import '../../shopping_list/presentation/shopping_list_screen.dart';
import '../data/nutrition_service.dart';
import '../domain/nutrition_tip.dart';

/// Displays deterministic nutrition tips derived from the user's cooked recipe history,
/// allowing direct one-tap additions of recommended ingredients to Lista de Compras.
class NutritionTipsScreen extends StatefulWidget {
  const NutritionTipsScreen({
    super.key,
    this.nutritionService,
    this.historyService,
    this.shoppingListService,
  });

  /// Optional injected nutrition service for testing.
  final NutritionService? nutritionService;

  /// Optional injected recipe history service for testing.
  final RecipeHistoryService? historyService;

  /// Optional injected shopping list storage service for testing.
  final ShoppingListStorageService? shoppingListService;

  /// Navigates to [NutritionTipsScreen].
  static Future<void> navigate(
    BuildContext context, {
    NutritionService? nutritionService,
    RecipeHistoryService? historyService,
    ShoppingListStorageService? shoppingListService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NutritionTipsScreen(
          nutritionService: nutritionService,
          historyService: historyService,
          shoppingListService: shoppingListService,
        ),
      ),
    );
  }

  @override
  State<NutritionTipsScreen> createState() => _NutritionTipsScreenState();
}

class _NutritionTipsScreenState extends State<NutritionTipsScreen> {
  late final NutritionService _nutritionService;
  late final ShoppingListStorageService _shoppingListService;

  NutritionReport? _report;
  Set<String> _shoppingListNormalized = <String>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nutritionService = widget.nutritionService ??
        NutritionService(historyService: widget.historyService);
    _shoppingListService =
        widget.shoppingListService ?? ShoppingListStorageService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final report = await _nutritionService.generateReport();
    final shoppingItems = await _shoppingListService.getIngredients();

    if (mounted) {
      setState(() {
        _report = report;
        _shoppingListNormalized = shoppingItems
            .map((item) => StringNormalizer.normalize(item.name))
            .toSet();
        _isLoading = false;
      });
    }
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
          initialTab: 1,
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
      endDrawer: const AppNavigationDrawer(
        currentDestination: AppDestination.nutritionTips,
      ),
      appBar: AppBar(
        title: const Text('Consejos de Nutrición'),
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
          const AppMenuButton(),
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          if (!report.hasCookingHistory) ...[
            _buildEmptyHistoryBanner(context),
            const SizedBox(height: 16),
            Text(
              'Consejos básicos para tus comidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            _buildSummaryHeader(context, report),
            const SizedBox(height: 16),
          ],
          if (report.tips.isEmpty)
            _buildBalancedHistoryCard(context)
          else
            for (int i = 0; i < report.tips.length; i++) ...[
              _buildTipCard(context, report.tips[i]),
              if (i < report.tips.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryBanner(BuildContext context) {
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
                    'Aún no has registrado recetas cocinadas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Usa el botón "Lo cociné" al preparar cualquier receta para desbloquear '
                    'consejos personalizados según tus comidas recientes.',
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
      NutritionTipCategory.foundational => (
          'nutrition',
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
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
}


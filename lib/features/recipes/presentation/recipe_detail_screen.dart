import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/utils/string_normalizer.dart';
import '../../../core/widgets/app_navigation_drawer.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../shopping_list/data/shopping_list_storage_service.dart';
import '../data/local_recipe_dataset.dart';
import '../data/recipe_history_service.dart';
import '../domain/recipe.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_preference.dart';
import '../domain/recipe_search_result.dart';

/// Detailed view for a single recipe.
/// Displays title, required ingredients (highlighting available vs. missing items),
/// step-by-step preparation instructions, variations, and cooking history actions in Spanish.
class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.matchedIngredients = const [],
    this.missingIngredients = const [],
    this.previousRecipeIds = const [],
    this.historyService,
    this.shoppingListService,
  });

  /// Factory constructor when navigating with a [RecipeSearchResult].
  factory RecipeDetailScreen.fromResult({
    Key? key,
    required RecipeSearchResult result,
    List<String> previousRecipeIds = const [],
    RecipeHistoryService? historyService,
    ShoppingListStorageService? shoppingListService,
  }) {
    return RecipeDetailScreen(
      key: key,
      recipe: result.recipe,
      matchedIngredients: result.matchedIngredients,
      missingIngredients: result.missingIngredients,
      previousRecipeIds: previousRecipeIds,
      historyService: historyService,
      shoppingListService: shoppingListService,
    );
  }

  final Recipe recipe;
  final List<RecipeIngredient> matchedIngredients;
  final List<RecipeIngredient> missingIngredients;
  /// IDs of recipes previously opened in this navigation branch to prevent loops.
  final List<String> previousRecipeIds;
  final RecipeHistoryService? historyService;
  final ShoppingListStorageService? shoppingListService;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late final RecipeHistoryService _historyService;
  late final ShoppingListStorageService _shoppingListService;
  bool _isCookedToday = false;
  int _timesCooked = 0;
  RecipePreference _preference = RecipePreference.none;
  bool _isLoadingHistory = true;
  Set<String> _shoppingListNormalizedNames = {};

  @override
  void initState() {
    super.initState();
    _historyService = widget.historyService ?? RecipeHistoryService();
    _shoppingListService = widget.shoppingListService ?? ShoppingListStorageService();
    _loadHistoryStatus();
    _loadShoppingListStatus();
  }

  Future<void> _loadShoppingListStatus() async {
    final items = await _shoppingListService.getIngredients();
    if (!mounted) return;
    setState(() {
      _shoppingListNormalizedNames =
          items.map((item) => StringNormalizer.normalize(item.name)).toSet();
    });
  }

  Future<void> _addMissingToShoppingList(RecipeIngredient ingredient) async {
    final messenger = ScaffoldMessenger.of(context);
    final normalized = ingredient.normalizedName;

    if (_shoppingListNormalizedNames.contains(normalized)) {
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
      _shoppingListNormalizedNames =
          updated.map((item) => StringNormalizer.normalize(item.name)).toSet();
    });

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${ingredient.name}" agregado a la lista de compras'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addAllMissingToShoppingList(
    List<RecipeIngredient> missing,
  ) async {
    final toAdd = missing
        .where((i) => !_shoppingListNormalizedNames.contains(i.normalizedName))
        .map((i) => Ingredient(name: i.name))
        .toList();

    if (toAdd.isEmpty) return;

    final updated = await _shoppingListService.addIngredients(toAdd);
    if (!mounted) return;

    setState(() {
      _shoppingListNormalizedNames =
          updated.map((item) => StringNormalizer.normalize(item.name)).toSet();
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          toAdd.length == 1
              ? '"${toAdd.first.name}" agregado a la lista de compras'
              : '${toAdd.length} ingredientes agregados a la lista de compras',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadHistoryStatus() async {
    final record = await _historyService.getRecord(widget.recipe.id);
    if (!mounted) return;
    setState(() {
      _timesCooked = record.timesCooked;
      _isCookedToday = record.isCookedToday();
      _preference = record.preference;
      _isLoadingHistory = false;
    });
  }

  Future<void> _handleCookedTap() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_isCookedToday) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Esta receta ya fue registrada como cocinada hoy.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final updated = await _historyService.recordCooked(widget.recipe);
    if (!mounted) return;

    setState(() {
      _timesCooked = updated.timesCooked;
      _isCookedToday = true;
    });

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('¡Receta registrada como cocinada!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePreferenceToggle(RecipePreference target) async {
    final newPref = _preference == target ? RecipePreference.none : target;
    final updated = await _historyService.setPreference(
      widget.recipe.id,
      newPref,
      recipe: widget.recipe,
    );
    if (!mounted) return;

    setState(() {
      _preference = updated.preference;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          newPref == RecipePreference.none
              ? 'Preferencia eliminada'
              : newPref == RecipePreference.never
                  ? 'Receta oculta de sugerencias'
                  : 'Marcada como ${newPref.label}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final matchedIngredients = widget.matchedIngredients;
    final missingIngredients = widget.missingIngredients;

    // Determine missing items if not explicitly provided
    final matchedSet = matchedIngredients.map((i) => i.normalizedName).toSet();
    final effectiveMatched = matchedIngredients.isNotEmpty
        ? matchedIngredients
        : recipe.ingredients.where((i) => matchedSet.contains(i.normalizedName)).toList();
    final effectiveMissing = missingIngredients.isNotEmpty
        ? missingIngredients
        : recipe.ingredients.where((i) => !matchedSet.contains(i.normalizedName)).toList();

    return Scaffold(
      endDrawer: const AppNavigationDrawer(),
      appBar: AppBar(
        title: Text(recipe.title),
        actions: const [AppMenuButton()],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildMetadataRow(context),
                const SizedBox(height: 16),
                _buildActionButtons(context),
                const SizedBox(height: 24),
                _buildIngredientsSection(
                  context,
                  matched: effectiveMatched,
                  missing: effectiveMissing,
                ),
                const SizedBox(height: 24),
                _buildInstructionsSection(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipe = widget.recipe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (recipe.description != null && recipe.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            recipe.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipe = widget.recipe;

    final items = <Widget>[];

    if (recipe.totalTimeMinutes != null) {
      items.add(_buildMetaItem(
        context,
        icon: Icons.timer_outlined,
        label: '${recipe.totalTimeMinutes} min',
      ));
    }

    if (recipe.servings != null) {
      items.add(_buildMetaItem(
        context,
        icon: Icons.people_outline,
        label: '${recipe.servings} porciones',
      ));
    }

    if (recipe.category != null) {
      items.add(_buildMetaItem(
        context,
        icon: Icons.restaurant_menu,
        label: recipe.category!,
      ));
    }

    if (recipe.difficulty != null) {
      items.add(_buildMetaItem(
        context,
        icon: Icons.bar_chart,
        label: recipe.difficulty!,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: items,
      ),
    );
  }

  Widget _buildMetaItem(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final recipe = widget.recipe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCookedButton(context),
        if (recipe.hasVariations) ...[
          const SizedBox(height: 12),
          _buildVariationsButton(context),
        ],
        const SizedBox(height: 16),
        _buildPreferencesSection(context),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildPreferenceChip(
            context,
            preference: RecipePreference.favorite,
            iconName: 'heart',
            label: 'Favorita',
            activeColor: Colors.red.shade600,
          ),
          _buildPreferenceChip(
            context,
            preference: RecipePreference.liked,
            iconName: 'thumb_up',
            label: 'Me gustó',
            activeColor: Colors.green.shade700,
          ),
          _buildPreferenceChip(
            context,
            preference: RecipePreference.disliked,
            iconName: 'thumb_down',
            label: 'No me gustó',
            activeColor: Colors.orange.shade800,
          ),
          _buildPreferenceChip(
            context,
            preference: RecipePreference.never,
            iconName: 'block',
            label: _preference == RecipePreference.never ? 'Oculta' : 'Ocultar',
            activeColor: colorScheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceChip(
    BuildContext context, {
    required RecipePreference preference,
    required String iconName,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _preference == preference;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: AppSvgIcon(
        assetName: iconName,
        size: 16,
        color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? activeColor : colorScheme.onSurface,
      ),
      selectedColor: activeColor.withValues(alpha: 0.15),
      backgroundColor: colorScheme.surface,
      side: BorderSide(
        color: isSelected ? activeColor : colorScheme.outlineVariant.withValues(alpha: 0.6),
        width: isSelected ? 1.5 : 1.0,
      ),
      onSelected: (_) => _handlePreferenceToggle(preference),
    );
  }

  Widget _buildCookedButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isCookedToday) {
      return FilledButton.tonalIcon(
        onPressed: _handleCookedTap,
        icon: AppSvgIcon(
          assetName: 'check',
          size: 18,
          color: colorScheme.onSecondaryContainer,
        ),
        label: Text(
          _timesCooked > 1
              ? 'Cocinada hoy (Total: $_timesCooked veces)'
              : 'Cocinada hoy (1 vez)',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _isLoadingHistory ? null : _handleCookedTap,
      icon: AppSvgIcon(
        assetName: 'check',
        size: 18,
        color: colorScheme.primary,
      ),
      label: Text(
        _timesCooked > 0 ? 'Lo cociné ($_timesCooked veces)' : 'Lo cociné',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  Widget _buildVariationsButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipe = widget.recipe;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: colorScheme.primary),
      ),
      icon: AppSvgIcon(
        assetName: 'restaurant',
        size: 18,
        color: colorScheme.primary,
      ),
      label: Text(
        'Ver variaciones (${recipe.variations.length})',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
      onPressed: () => _showVariationsSheet(context),
    );
  }

  void _showVariationsSheet(BuildContext rootContext) {
    final theme = Theme.of(rootContext);
    final colorScheme = theme.colorScheme;
    final dataset = LocalRecipeDataset.instance;
    final recipe = widget.recipe;
    final matchedIngredients = widget.matchedIngredients;
    final previousRecipeIds = widget.previousRecipeIds;

    showModalBottomSheet<void>(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetContext, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      AppSvgIcon(
                        assetName: 'restaurant',
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Variaciones de la receta',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cambia 1 o 2 ingredientes para disfrutar un plato diferente:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: recipe.variations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final variation = recipe.variations[index];
                        final linkedRecipe = dataset.getRecipeById(variation.recipeId);

                        return Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: linkedRecipe == null
                                ? null
                                : () {
                                    if (previousRecipeIds.contains(linkedRecipe.id)) {
                                      // Already in the navigation stack: pop back to the existing route instance!
                                      Navigator.popUntil(
                                        rootContext,
                                        (route) =>
                                            route.settings.name == 'recipe_${linkedRecipe.id}' ||
                                            (route.isFirst && previousRecipeIds.first == linkedRecipe.id),
                                      );
                                    } else {
                                      Navigator.pop(bottomSheetContext);

                                      if (previousRecipeIds.isNotEmpty) {
                                        // Already exploring a variation: replace current variation to avoid endless stack
                                        Navigator.pushReplacement(
                                          rootContext,
                                          MaterialPageRoute(
                                            settings: RouteSettings(name: 'recipe_${linkedRecipe.id}'),
                                            builder: (_) => RecipeDetailScreen(
                                              recipe: linkedRecipe,
                                              matchedIngredients: matchedIngredients,
                                              missingIngredients: const [],
                                              previousRecipeIds: previousRecipeIds,
                                              historyService: _historyService,
                                              shoppingListService: _shoppingListService,
                                            ),
                                          ),
                                        );
                                      } else {
                                        // First variation from the initial recipe: push with route name
                                        Navigator.push(
                                          rootContext,
                                          MaterialPageRoute(
                                            settings: RouteSettings(name: 'recipe_${linkedRecipe.id}'),
                                            builder: (_) => RecipeDetailScreen(
                                              recipe: linkedRecipe,
                                              matchedIngredients: matchedIngredients,
                                              missingIngredients: const [],
                                              previousRecipeIds: [recipe.id],
                                              historyService: _historyService,
                                              shoppingListService: _shoppingListService,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          variation.title,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                  if (variation.description != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      variation.description!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (variation.swappedIngredients.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: variation.swappedIngredients.map((item) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIngredientsSection(
    BuildContext context, {
    required List<RecipeIngredient> matched,
    required List<RecipeIngredient> missing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ingredientes requeridos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${matched.length}/${widget.recipe.ingredients.length} listos',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (matched.isNotEmpty) ...[
          _buildSubSectionTitle(
            context,
            title: 'Tienes en casa (${matched.length})',
            color: colorScheme.primary,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 8),
          ...matched.map((ing) => _buildIngredientRow(context, ing, isAvailable: true)),
          const SizedBox(height: 16),
        ],
        if (missing.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: _buildSubSectionTitle(
                  context,
                  title: 'Ingredientes adicionales necesarios (${missing.length})',
                  color: colorScheme.error,
                  icon: Icons.add_shopping_cart,
                ),
              ),
              if (missing.any(
                (i) => !_shoppingListNormalizedNames.contains(i.normalizedName),
              ))
                TextButton.icon(
                  onPressed: () => _addAllMissingToShoppingList(missing),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: AppSvgIcon(
                    assetName: 'shopping_cart',
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  label: const Text('Agregar todos'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...missing.map((ing) => _buildIngredientRow(context, ing, isAvailable: false)),
        ],
        if (missing.isEmpty && matched.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.thumb_up_alt_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¡Excelente! Tienes todos los ingredientes necesarios para preparar este platillo.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubSectionTitle(
    BuildContext context, {
    required String title,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientRow(
    BuildContext context,
    RecipeIngredient ingredient, {
    required bool isAvailable,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inShoppingList =
        !isAvailable && _shoppingListNormalizedNames.contains(ingredient.normalizedName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAvailable
              ? colorScheme.surface
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAvailable
                ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isAvailable ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: isAvailable ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ingredient.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isAvailable ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Flexible(
              child: Text(
                ingredient.displayAmount,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isAvailable) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: inShoppingList
                    ? 'En lista de compras'
                    : 'Agregar a lista de compras',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: AppSvgIcon(
                  assetName: inShoppingList ? 'check' : 'shopping_cart',
                  size: 18,
                  color: colorScheme.primary,
                ),
                onPressed: () => _addMissingToShoppingList(ingredient),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipe = widget.recipe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instrucciones de preparación',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...recipe.instructions.asMap().entries.map((entry) {
          final stepIndex = entry.key + 1;
          final stepText = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$stepIndex',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      stepText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

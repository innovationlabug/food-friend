import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../data/external_recipe_service.dart';
import '../data/recipe_search_service.dart';
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
  });

  /// The list of ingredient names selected by the user.
  final List<String> selectedIngredientNames;

  /// Optional injected search service for local matching.
  final RecipeSearchService? searchService;

  /// Optional injected external service for API queries and fallback coordination.
  final ExternalRecipeService? externalService;

  /// Helper static method for easy navigation.
  static Future<void> navigate(
    BuildContext context, {
    required List<String> selectedIngredientNames,
    RecipeSearchService? searchService,
    ExternalRecipeService? externalService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeSuggestionsScreen(
          selectedIngredientNames: selectedIngredientNames,
          searchService: searchService,
          externalService: externalService,
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

  bool _isLoading = true;
  RecipeDiscoveryResponse? _discoveryResponse;
  List<RecipeSearchResult> _results = [];
  bool _showingAllRecipes = false;

  @override
  void initState() {
    super.initState();
    _searchService = widget.searchService ?? RecipeSearchService();
    _externalService = widget.externalService ?? ExternalRecipeService();
    _performDiscovery();
  }

  Future<void> _performDiscovery() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _externalService.discoverRecipes(
      selectedIngredients: widget.selectedIngredientNames,
      localSearchService: _searchService,
    );

    if (mounted) {
      setState(() {
        _discoveryResponse = response;
        _results = response.results;
        _isLoading = false;
        _showingAllRecipes = false;
      });
    }
  }

  void _showAllLocalRecipes() {
    final all = _searchService.getAllRecipes().map((r) {
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
    });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_discoveryResponse?.isFallback == true && !_showingAllRecipes) ...[
          _buildFallbackNotice(context),
          const SizedBox(height: 12),
        ],
        _buildHeaderBanner(context),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final result = _results[index];
              return _buildRecipeCard(context, result);
            },
          ),
        ),
      ],
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

  Widget _buildHeaderBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final count = _results.length;
    final ingredientCount = widget.selectedIngredientNames.length;

    String bannerTitle = '$count receta(s) disponible(s)';
    if (_showingAllRecipes) {
      bannerTitle = 'Catálogo de recetas ($count)';
    } else if (_discoveryResponse?.isExternal == true) {
      bannerTitle = '$count receta(s) en línea';
    } else if (_discoveryResponse?.isFallback == true) {
      bannerTitle = '$count receta(s) sugerida(s)';
    }

    return Container(
      padding: const EdgeInsets.all(14),
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
              builder: (_) => RecipeDetailScreen.fromResult(result: result),
            ),
          );
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


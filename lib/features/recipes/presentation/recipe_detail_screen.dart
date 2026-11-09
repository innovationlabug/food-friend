import 'package:flutter/material.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/app_svg_icon.dart';
import '../domain/recipe.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_search_result.dart';

/// Detailed view for a single recipe.
/// Displays title, required ingredients (highlighting available vs. missing items),
/// and step-by-step preparation instructions in Spanish.
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.matchedIngredients = const [],
    this.missingIngredients = const [],
  });

  /// Factory constructor when navigating with a [RecipeSearchResult].
  factory RecipeDetailScreen.fromResult({
    Key? key,
    required RecipeSearchResult result,
  }) {
    return RecipeDetailScreen(
      key: key,
      recipe: result.recipe,
      matchedIngredients: result.matchedIngredients,
      missingIngredients: result.missingIngredients,
    );
  }

  final Recipe recipe;
  final List<RecipeIngredient> matchedIngredients;
  final List<RecipeIngredient> missingIngredients;

  @override
  Widget build(BuildContext context) {
    // Determine missing items if not explicitly provided
    final matchedSet = matchedIngredients.map((i) => i.normalizedName).toSet();
    final effectiveMatched = matchedIngredients.isNotEmpty
        ? matchedIngredients
        : recipe.ingredients.where((i) => matchedSet.contains(i.normalizedName)).toList();
    final effectiveMissing = missingIngredients.isNotEmpty
        ? missingIngredients
        : recipe.ingredients.where((i) => !matchedSet.contains(i.normalizedName)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
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
            Text(
              '${recipe.ingredients.length} ingredientes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 1. Ingredients the user already has
        if (matched.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                AppSvgIcon(
                  assetName: 'check',
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tienes en casa (${matched.length})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...matched.map((ing) => _buildIngredientCard(
                context,
                ingredient: ing,
                isAvailable: true,
              )),
          const SizedBox(height: 12),
        ],

        // 2. Additional ingredients needed
        if (missing.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                AppSvgIcon(
                  assetName: 'shopping_cart',
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ingredientes adicionales necesarios (${missing.length})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          ...missing.map((ing) => _buildIngredientCard(
                context,
                ingredient: ing,
                isAvailable: false,
              )),
        ],

        // 3. If user has all ingredients
        if (missing.isEmpty && matched.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                AppSvgIcon(
                  assetName: 'check',
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Excelente! Tienes todos los ingredientes necesarios para preparar este platillo.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
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

  Widget _buildIngredientCard(
    BuildContext context, {
    required RecipeIngredient ingredient,
    required bool isAvailable,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isAvailable
          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isAvailable
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isAvailable
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: AppSvgIcon(
                assetName: isAvailable ? 'check' : 'shopping_cart',
                size: 16,
                color: isAvailable ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ingredient.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              ingredient.displayAmount,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

import 'package:flutter/material.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/utils/string_normalizer.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../domain/shopping_suggestion.dart';

/// Displays actionable Spanish shopping suggestions derived from favorite,
/// liked, frequently cooked, and health-goal/nutrition-aligned recipes.
class SmartShoppingSuggestionsSection extends StatelessWidget {
  const SmartShoppingSuggestionsSection({
    super.key,
    required this.suggestions,
    required this.onAddIngredient,
  });

  /// Ranked suggestions to present to the user.
  final List<ShoppingSuggestion> suggestions;

  /// Callback triggered when the user taps to add a suggested missing ingredient.
  final ValueChanged<String> onAddIngredient;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

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
                'Sugerencias para tu lista',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Te faltan pocos ingredientes para preparar estas recetas.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (!isDesktop)
          for (int i = 0; i < suggestions.length; i++) ...[
            _buildSuggestionCard(context, suggestions[i]),
            if (i < suggestions.length - 1) const SizedBox(height: 10),
          ]
        else
          for (int i = 0; i < suggestions.length; i += 2) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildSuggestionCard(context, suggestions[i]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < suggestions.length
                        ? _buildSuggestionCard(context, suggestions[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            if (i + 2 < suggestions.length) const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    ShoppingSuggestion suggestion,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final (String iconName, Color containerColor, Color iconColor) =
        _iconStyle(colorScheme, suggestion);

    return Card(
      key: ValueKey('shopping_suggestion_${suggestion.recipe.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppSvgIcon(
                    assetName: iconName,
                    size: 18,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestion.missingIngredients.map((ingredient) {
                final normalizedIngredient =
                    StringNormalizer.normalize(ingredient);
                return Tooltip(
                  message: 'Agregar $ingredient a tu lista de compras',
                  child: OutlinedButton.icon(
                    key: ValueKey(
                      'add_suggestion_${suggestion.recipe.id}_$normalizedIngredient',
                    ),
                    onPressed: () => onAddIngredient(ingredient),
                    icon: AppSvgIcon(
                      assetName: 'plus',
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'Agregar $ingredient',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  (String, Color, Color) _iconStyle(
    ColorScheme colorScheme,
    ShoppingSuggestion suggestion,
  ) {
    return switch (suggestion.source) {
      ShoppingSuggestionSource.favorite => (
          'heart',
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      ShoppingSuggestionSource.liked => (
          'thumb_up',
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      ShoppingSuggestionSource.frequentlyCooked => (
          'restaurant',
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
      ShoppingSuggestionSource.healthGoal => (
          suggestion.matchedGoal?.iconName ?? 'nutrition',
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      ShoppingSuggestionSource.nutritionTip => (
          'nutrition',
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
    };
  }
}

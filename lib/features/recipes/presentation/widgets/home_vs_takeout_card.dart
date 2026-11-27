import 'package:flutter/material.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../pricing/domain/recipe_comparison.dart';

/// Clutter-free Material 3 card displaying the GTQ cost-per-serving estimate
/// and nutritional quality comparison between cooking at home and ordering
/// equivalent takeout/delivery food.
class HomeVsTakeoutCard extends StatelessWidget {
  const HomeVsTakeoutCard({
    super.key,
    required this.comparison,
  });

  final RecipeHomeVsTakeoutComparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final servingsLabel = comparison.servings == 1
        ? '1 porción'
        : '${comparison.servings} porciones';

    return Container(
      key: const ValueKey('recipe_home_vs_takeout_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSvgIcon(
                assetName: 'savings',
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'En casa vs. pedir comida',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En casa ($servingsLabel)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${comparison.formattedHomePerServing} / porción',
                      key: const ValueKey('home_cost_per_serving_text'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total estimado: ${comparison.formattedHomeTotal}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comparison.takeoutReferenceLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '~${comparison.formattedTakeoutPerServing} / porción',
                      key: const ValueKey('takeout_cost_per_serving_text'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comparison.hasSavings) ...[
            const SizedBox(height: 10),
            Text(
              'Ahorras aprox. ${comparison.formattedSavingsPerServing} por porción (${comparison.savingsPercent}% menos)',
              key: const ValueKey('home_savings_summary_text'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
          if (comparison.nutritionHighlights.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Calidad nutricional en casa',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            for (int i = 0; i < comparison.nutritionHighlights.length; i++) ...[
              Text(
                '• ${comparison.nutritionHighlights[i]}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (i < comparison.nutritionHighlights.length - 1)
                const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }
}

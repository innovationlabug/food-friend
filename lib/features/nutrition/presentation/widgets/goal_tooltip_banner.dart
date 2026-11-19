import 'package:flutter/material.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../domain/recipe_goal_match.dart';

/// Displays an inline Spanish nutritional reasoning callout wrapped in an
/// interactive tap-to-expand [Tooltip] for goal-aligned recipes.
class GoalTooltipBanner extends StatelessWidget {
  const GoalTooltipBanner({
    super.key,
    required this.tooltipKey,
    required this.goalMatch,
  });

  /// Deterministic widget key used for interactive tooltip testing.
  final Key tooltipKey;

  /// Evaluated goal alignment and Spanish explanations.
  final RecipeGoalMatch goalMatch;

  @override
  Widget build(BuildContext context) {
    final primaryReason = goalMatch.primaryReason;
    if (!goalMatch.hasMatch || primaryReason == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      key: tooltipKey,
      message: goalMatch.combinedTooltipMessage,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSvgIcon(
              assetName: 'nutrition',
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                primaryReason,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            if (goalMatch.reasons.length > 1) ...[
              const SizedBox(width: 6),
              AppSvgIcon(
                assetName: 'info',
                size: 14,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

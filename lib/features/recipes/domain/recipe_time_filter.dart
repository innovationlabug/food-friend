import 'recipe.dart';

/// Filter options for recipes based on total cooking time
/// (`prepTimeMinutes + cookTimeMinutes`).
enum RecipeTimeFilter {
  all(null, 'Todos'),
  upTo20(20, '≤ 20 min'),
  upTo40(40, '≤ 40 min'),
  upTo60(60, '≤ 60 min');

  const RecipeTimeFilter(this.maxMinutes, this.label);

  /// Maximum allowed total minutes, or `null` when no time limit applies.
  final int? maxMinutes;

  /// Spanish display label for UI filter chips and banners.
  final String label;

  /// Returns whether [recipe] satisfies this time limit.
  ///
  /// When [maxMinutes] is `null` ([RecipeTimeFilter.all]), every recipe matches
  /// regardless of whether time metadata is present. When a limit is active,
  /// recipes without a known `totalTimeMinutes` are excluded and recipes with
  /// `totalTimeMinutes <= maxMinutes` are included.
  bool matches(Recipe recipe) {
    final limit = maxMinutes;
    if (limit == null) return true;
    final total = recipe.totalTimeMinutes;
    if (total == null) return false;
    return total <= limit;
  }
}

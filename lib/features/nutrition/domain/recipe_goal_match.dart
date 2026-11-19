import 'health_goal.dart';

/// Concise Spanish explanation linking a recipe (and optionally a key ingredient)
/// to one of the user's active [HealthGoal]s.
class GoalTooltipReason {
  const GoalTooltipReason({
    required this.goal,
    required this.message,
    this.highlightedIngredient,
  });

  /// The health goal supported by this reasoning.
  final HealthGoal goal;

  /// Short, specific Spanish tooltip sentence.
  final String message;

  /// Optional ingredient name that drives this nutritional benefit.
  final String? highlightedIngredient;
}

/// Deterministic evaluation of how well a recipe aligns with the user's active health goals.
class RecipeGoalMatch {
  const RecipeGoalMatch({
    required this.matchedGoals,
    required this.reasons,
    required this.alignmentScore,
    this.penaltyScore = 0.0,
  });

  /// Empty match used when no health goals are active or none match the recipe.
  static const RecipeGoalMatch empty = RecipeGoalMatch(
    matchedGoals: <HealthGoal>{},
    reasons: <GoalTooltipReason>[],
    alignmentScore: 0.0,
  );

  /// Subset of active health goals satisfied by this recipe.
  final Set<HealthGoal> matchedGoals;

  /// Ordered Spanish nutritional explanations for matched goals.
  final List<GoalTooltipReason> reasons;

  /// Positive ranking boost earned from matched goals.
  final double alignmentScore;

  /// Ranking penalty applied when the recipe contains ingredients conflicting with active goals.
  final double penaltyScore;

  /// Net ranking adjustment contributed by active health goals.
  double get netScore => alignmentScore - penaltyScore;

  /// Whether at least one active health goal matches with an explanation.
  bool get hasMatch => matchedGoals.isNotEmpty && reasons.isNotEmpty;

  /// Primary Spanish reasoning displayed inline on recipe cards.
  String? get primaryReason => reasons.isEmpty ? null : reasons.first.message;

  /// Combined Spanish reasoning displayed inside interactive tooltips.
  String get combinedTooltipMessage => reasons.map((r) => r.message).join(' • ');
}

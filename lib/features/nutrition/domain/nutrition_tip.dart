import '../../recipes/domain/recipe.dart';
import 'health_goal.dart';
import 'nutrition_metadata.dart';
import 'recipe_goal_match.dart';

/// Categorization of deterministic nutrition advice generated from recipe history
/// and the user's selected [HealthGoal]s.
enum NutritionTipCategory {
  /// Warning triggered when recent cooked meals frequently contain processed meats.
  healthAlert,

  /// Dynamic recommendation tailored to an active user [HealthGoal].
  goalGuidance,

  /// Micronutrient recommendation listing fruits/vegetables rich in a missing vitamin.
  vitaminSuggestion,

  /// Complementary plant protein recommendation (e.g., grains + legumes).
  proteinPairing,
}

/// Structured Spanish nutrition tip emitted by [NutritionService].
class NutritionTip {
  const NutritionTip({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    this.nutrient,
    this.goal,
    this.recommendedIngredients = const <String>[],
  });

  /// Stable identifier for rendering lists and deduplication.
  final String id;

  /// Heuristic category controlling visual icon and grouping.
  final NutritionTipCategory category;

  /// Short Spanish headline for the tip.
  final String title;

  /// Clear, actionable Spanish explanation tailored to the user's goals and meals.
  final String message;

  /// Optional missing micronutrient associated with a [vitaminSuggestion].
  final TrackedNutrient? nutrient;

  /// Optional active health goal associated with a [goalGuidance] tip.
  final HealthGoal? goal;

  /// Specific Spanish catalog ingredients the user can add to their shopping list.
  final List<String> recommendedIngredients;
}

/// Aggregated deterministic evaluation of the user's cooked recipe history
/// and active [HealthGoal]s.
class NutritionReport {
  const NutritionReport({
    required this.hasCookingHistory,
    required this.totalCookedMeals,
    required this.recentMealsEvaluated,
    required this.processedMeatMealsLast7Days,
    required this.processedMeatMealsRecent,
    required this.coveredNutrients,
    required this.missingNutrients,
    required this.tips,
    this.activeGoals = const <HealthGoal>{},
    this.recommendedGoalRecipes =
        const <({Recipe recipe, RecipeGoalMatch goalMatch})>[],
  });

  /// Whether at least one cooked meal exists in [RecipeHistoryService].
  final bool hasCookingHistory;

  /// Total logged cooked meal events across history.
  final int totalCookedMeals;

  /// Number of recent cooked meal events included in the sliding heuristic window.
  final int recentMealsEvaluated;

  /// Number of cooked meals containing processed meats within the last 7 days.
  final int processedMeatMealsLast7Days;

  /// Number of cooked meals containing processed meats in the recent evaluation window.
  final int processedMeatMealsRecent;

  /// Tracked vitamins/micronutrients present in recent cooked meals.
  final Set<TrackedNutrient> coveredNutrients;

  /// Tracked vitamins/micronutrients absent from recent cooked meals.
  final Set<TrackedNutrient> missingNutrients;

  /// Ordered list of active Spanish nutrition tips for presentation.
  final List<NutritionTip> tips;

  /// Currently active user-selected health goals.
  final Set<HealthGoal> activeGoals;

  /// Top local/known recipes aligned with [activeGoals] and their Spanish tooltips.
  final List<({Recipe recipe, RecipeGoalMatch goalMatch})> recommendedGoalRecipes;
}

import 'nutrition_metadata.dart';

/// Categorization of deterministic nutrition advice generated from recipe history.
enum NutritionTipCategory {
  /// Warning triggered when recent cooked meals frequently contain processed meats.
  healthAlert,

  /// Micronutrient recommendation listing fruits/vegetables rich in a missing vitamin.
  vitaminSuggestion,

  /// Complementary plant protein recommendation (e.g., grains + legumes).
  proteinPairing,

  /// Foundational healthy eating guidance shown when cooking history is still empty.
  foundational,
}

/// Structured Spanish nutrition tip emitted by [NutritionService].
class NutritionTip {
  const NutritionTip({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    this.nutrient,
    this.recommendedIngredients = const <String>[],
  });

  /// Stable identifier for rendering lists and deduplication.
  final String id;

  /// Heuristic category controlling visual icon and grouping.
  final NutritionTipCategory category;

  /// Short Spanish headline for the tip.
  final String title;

  /// Clear, actionable Spanish explanation tailored to the user's meals.
  final String message;

  /// Optional missing micronutrient associated with a [vitaminSuggestion].
  final TrackedNutrient? nutrient;

  /// Specific Spanish catalog ingredients the user can add to their shopping list.
  final List<String> recommendedIngredients;
}

/// Aggregated deterministic evaluation of the user's cooked recipe history.
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
}


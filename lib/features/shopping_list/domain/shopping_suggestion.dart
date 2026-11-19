import '../../nutrition/domain/health_goal.dart';
import '../../nutrition/domain/nutrition_metadata.dart';
import '../../recipes/domain/recipe.dart';

/// Origin category explaining why a [ShoppingSuggestion] is surfaced to the user.
enum ShoppingSuggestionSource {
  favorite,
  liked,
  frequentlyCooked,
  healthGoal,
  nutritionTip,
}

/// Represents an actionable suggestion in `"Por comprar"` recommending 1 to 2
/// missing ingredients that unlock an almost-ready favorite, liked, frequently
/// cooked, health-goal, or nutrient-enriching recipe.
class ShoppingSuggestion {
  const ShoppingSuggestion({
    required this.recipe,
    required this.missingIngredients,
    required this.availableIngredientCount,
    required this.totalIngredientCount,
    required this.source,
    required this.message,
    this.matchedGoal,
    this.missingNutrient,
    this.timesCooked = 0,
    this.relevanceScore = 0.0,
  });

  /// Target recipe unlocked by purchasing [missingIngredients].
  final Recipe recipe;

  /// One or two missing ingredient names (in Spanish) not yet in `"Por comprar"`.
  final List<String> missingIngredients;

  /// Number of [recipe] ingredients already available in `"Mis ingredientes"`.
  final int availableIngredientCount;

  /// Total number of ingredients required by [recipe].
  final int totalIngredientCount;

  /// Classification driving ranking, icon selection, and Spanish phrasing.
  final ShoppingSuggestionSource source;

  /// Actionable Spanish sentence shown to the user.
  final String message;

  /// Active health goal satisfied when [source] is [ShoppingSuggestionSource.healthGoal].
  final HealthGoal? matchedGoal;

  /// Missing micronutrient addressed when [source] is [ShoppingSuggestionSource.nutritionTip].
  final TrackedNutrient? missingNutrient;

  /// Number of times [recipe] has been cooked in history.
  final int timesCooked;

  /// Deterministic alignment score used for ordering nutrition/goal suggestions.
  final double relevanceScore;

  /// Whether this suggestion originates from user preferences or cooking frequency.
  bool get isHistoryOrFavorite => switch (source) {
        ShoppingSuggestionSource.favorite ||
        ShoppingSuggestionSource.liked ||
        ShoppingSuggestionSource.frequentlyCooked =>
          true,
        ShoppingSuggestionSource.healthGoal ||
        ShoppingSuggestionSource.nutritionTip =>
          false,
      };

  /// Whether this suggestion originates from active health goals or nutrition tips.
  bool get isNutritionOrGoal => !isHistoryOrFavorite;

  /// Ratio of recipe ingredients currently available at home (`0.0` to `1.0`).
  double get pantryCoverage =>
      totalIngredientCount == 0 ? 0.0 : availableIngredientCount / totalIngredientCount;
}

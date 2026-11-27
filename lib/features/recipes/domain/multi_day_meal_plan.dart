import '../../nutrition/domain/health_goal.dart';
import '../../nutrition/domain/recipe_goal_match.dart';
import 'recipe.dart';
import 'recipe_ingredient.dart';
import 'recipe_variation.dart';

/// Represents one scheduled day inside a [MultiDayMealPlan].
class MealPlanDay {
  const MealPlanDay({
    required this.dayNumber,
    required this.recipe,
    this.baseRecipe,
    this.variation,
    this.matchedPantryIngredients = const [],
    this.missingIngredients = const [],
    this.sharedIngredientsWithPreviousDays = const [],
    this.goalMatch = RecipeGoalMatch.empty,
  });

  /// 1-based day index within the plan (1..N).
  final int dayNumber;

  /// The scheduled recipe for this day.
  final Recipe recipe;

  /// Optional anchor recipe from an earlier day when [recipe] was selected
  /// as a culinary variation of [baseRecipe].
  final Recipe? baseRecipe;

  /// Variation metadata linking [baseRecipe] to [recipe], if applicable.
  final RecipeVariation? variation;

  /// Recipe ingredients available in the user's pantry / selected ingredients.
  final List<RecipeIngredient> matchedPantryIngredients;

  /// Recipe ingredients currently missing from the user's pantry.
  final List<RecipeIngredient> missingIngredients;

  /// Display names of ingredients shared with earlier days in the plan.
  final List<String> sharedIngredientsWithPreviousDays;

  /// Deterministic health-goal alignment and Spanish tooltip reasoning.
  final RecipeGoalMatch goalMatch;

  /// Spanish day title (e.g., "Día 1").
  String get dayLabel => 'Día $dayNumber';

  /// Whether this day's recipe is scheduled as a variation of an earlier dish.
  bool get isVariation => variation != null && baseRecipe != null;

  /// Total ingredients required by [recipe].
  int get totalIngredients => recipe.ingredients.length;

  /// Number of ingredients available in the pantry.
  int get matchedCount => matchedPantryIngredients.length;

  /// Whether all ingredients for this day are already available at home.
  bool get hasAllIngredients =>
      missingIngredients.isEmpty && totalIngredients > 0;
}

/// Complete deterministic multi-day cooking and variation plan generated
/// locally for 2 to 7 days.
class MultiDayMealPlan {
  const MultiDayMealPlan({
    required this.daysCount,
    required this.days,
    this.sharedCoreIngredients = const [],
    this.consolidatedMissingIngredients = const [],
    this.activeHealthGoals = const <HealthGoal>{},
    this.selectedCategory,
    this.maxTotalTimeMinutes,
  });

  /// Requested number of cooking days (2..7).
  final int daysCount;

  /// Ordered day-by-day meal schedule (`Día 1` .. `Día N`).
  final List<MealPlanDay> days;

  /// Ingredients shared across 2 or more days of the generated plan.
  final List<String> sharedCoreIngredients;

  /// Deduplicated missing ingredients aggregated across all planned days.
  final List<RecipeIngredient> consolidatedMissingIngredients;

  /// Health goals applied when ranking and explaining the plan.
  final Set<HealthGoal> activeHealthGoals;

  /// Optional meal category filter applied to the plan.
  final String? selectedCategory;

  /// Optional maximum cooking time filter applied to the plan.
  final int? maxTotalTimeMinutes;

  /// Whether the plan contains at least one scheduled day.
  bool get isNotEmpty => days.isNotEmpty;

  /// Whether the plan has no scheduled days.
  bool get isEmpty => days.isEmpty;

  /// Number of unique missing ingredients across the whole plan.
  int get totalMissingCount => consolidatedMissingIngredients.length;

  /// Total number of variation-linked days in the plan.
  int get variationDaysCount => days.where((d) => d.isVariation).length;
}

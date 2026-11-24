import '../../nutrition/domain/recipe_goal_match.dart';
import 'ingredient_replacement.dart';
import 'recipe.dart';
import 'recipe_ingredient.dart';

/// Encapsulates the evaluation of a recipe against a user's selected ingredients,
/// tracking matched ingredients, missing ingredients, availability-based and
/// health-goal ingredient replacements, match percentages, and deterministic
/// health-goal alignment.
class RecipeSearchResult {
  const RecipeSearchResult({
    required this.recipe,
    required this.matchedIngredients,
    required this.missingIngredients,
    this.goalMatch = RecipeGoalMatch.empty,
    this.availabilityReplacements = const [],
    this.healthGoalReplacements = const [],
  });

  /// The evaluated recipe.
  final Recipe recipe;

  /// List of recipe ingredients that directly match the user's selected ingredients.
  final List<RecipeIngredient> matchedIngredients;

  /// List of recipe ingredients that the user is currently missing directly.
  final List<RecipeIngredient> missingIngredients;

  /// Deterministic health-goal alignment and Spanish tooltip reasoning.
  final RecipeGoalMatch goalMatch;

  /// Compatible pantry ingredients that can replace missing recipe ingredients.
  final List<AvailabilityReplacement> availabilityReplacements;

  /// Healthier ingredient alternatives aligned with active health goals.
  final List<HealthGoalReplacement> healthGoalReplacements;

  /// Number of directly matched ingredients.
  int get matchCount => matchedIngredients.length;

  /// Total number of ingredients required by the recipe.
  int get totalIngredients => recipe.ingredients.length;

  /// Number of ingredients covered either directly or via an available substitute.
  int get effectiveMatchCount => matchCount + availabilityReplacements.length;

  /// Fraction of recipe ingredients fulfilled directly by the user's selection (0.0 to 1.0).
  double get matchPercentage {
    if (totalIngredients == 0) return 0.0;
    return matchCount / totalIngredients;
  }

  /// Fraction of recipe ingredients fulfilled directly or via available swaps (0.0 to 1.0).
  double get effectiveMatchPercentage {
    if (totalIngredients == 0) return 0.0;
    return effectiveMatchCount / totalIngredients;
  }

  /// Percentage value rounded to nearest integer (0 to 100).
  int get matchPercentageInt => (matchPercentage * 100).round();

  /// Effective percentage including substitutions rounded to nearest integer (0 to 100).
  int get effectiveMatchPercentageInt =>
      (effectiveMatchPercentage * 100).round();

  /// Whether the user has all ingredients required for this recipe directly.
  bool get hasAllIngredients =>
      missingIngredients.isEmpty && totalIngredients > 0;

  /// Whether at least one missing ingredient can be replaced with an available item.
  bool get hasAvailabilityReplacements => availabilityReplacements.isNotEmpty;

  /// Whether at least one healthier ingredient swap matches active health goals.
  bool get hasHealthGoalReplacements => healthGoalReplacements.isNotEmpty;

  /// Whether every missing ingredient is covered by an available pantry replacement.
  bool get isCookableWithReplacements =>
      missingIngredients.isNotEmpty &&
      availabilityReplacements.length >= missingIngredients.length;

  /// Whether the recipe can be cooked right away (directly or with swaps).
  bool get canCookNow => hasAllIngredients || isCookableWithReplacements;

  /// Missing ingredients that do not have an available pantry replacement.
  List<RecipeIngredient> get trulyMissingIngredients {
    if (availabilityReplacements.isEmpty) return missingIngredients;
    final covered = availabilityReplacements
        .map((r) => r.missingIngredient.normalizedName)
        .toSet();
    return missingIngredients
        .where((ing) => !covered.contains(ing.normalizedName))
        .toList();
  }

  /// Whether this recipe is a partial match.
  bool get isPartialMatch => matchCount > 0 && missingIngredients.isNotEmpty;

  @override
  String toString() =>
      'RecipeSearchResult("${recipe.title}": $matchCount/$totalIngredients matched ($matchPercentageInt%))';
}

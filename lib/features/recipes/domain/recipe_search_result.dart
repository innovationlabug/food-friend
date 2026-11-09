import 'recipe.dart';
import 'recipe_ingredient.dart';

/// Encapsulates the evaluation of a recipe against a user's selected ingredients,
/// tracking matched ingredients, missing ingredients, and match percentages.
class RecipeSearchResult {
  const RecipeSearchResult({
    required this.recipe,
    required this.matchedIngredients,
    required this.missingIngredients,
  });

  /// The evaluated recipe.
  final Recipe recipe;

  /// List of recipe ingredients that match the user's selected ingredients.
  final List<RecipeIngredient> matchedIngredients;

  /// List of recipe ingredients that the user is currently missing.
  final List<RecipeIngredient> missingIngredients;

  /// Number of matched ingredients.
  int get matchCount => matchedIngredients.length;

  /// Total number of ingredients required by the recipe.
  int get totalIngredients => recipe.ingredients.length;

  /// Fraction of recipe ingredients fulfilled by the user's selection (0.0 to 1.0).
  double get matchPercentage {
    if (totalIngredients == 0) return 0.0;
    return matchCount / totalIngredients;
  }

  /// Percentage value rounded to nearest integer (0 to 100).
  int get matchPercentageInt => (matchPercentage * 100).round();

  /// Whether the user has all ingredients required for this recipe.
  bool get hasAllIngredients => missingIngredients.isEmpty && totalIngredients > 0;

  /// Whether this recipe is a partial match.
  bool get isPartialMatch => matchCount > 0 && missingIngredients.isNotEmpty;

  @override
  String toString() =>
      'RecipeSearchResult("${recipe.title}": $matchCount/$totalIngredients matched ($matchPercentageInt%))';
}

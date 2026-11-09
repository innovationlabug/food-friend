import '../../../core/utils/string_normalizer.dart';
import '../domain/recipe.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_search_result.dart';
import 'local_recipe_dataset.dart';

/// Service responsible for querying, matching, and ranking recipes
/// against a set of user-selected ingredient names.
class RecipeSearchService {
  RecipeSearchService({LocalRecipeDataset? dataset})
      : _dataset = dataset ?? LocalRecipeDataset.instance;

  final LocalRecipeDataset _dataset;

  /// Retrieves all preloaded recipes in the local dataset.
  List<Recipe> getAllRecipes() => _dataset.recipes;

  /// Retrieves a recipe by its unique identifier.
  Recipe? getRecipeById(String id) {
    try {
      return _dataset.recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Searches recipes against a list of user-selected ingredient names,
  /// ranking matching recipes by match count and match percentage.
  ///
  /// [selectedIngredientNames]: The list of ingredient names provided by the user.
  /// [recipePool]: Optional subset of recipes to search against (defaults to all local recipes).
  /// [minMatchCount]: Minimum number of matching ingredients required for inclusion (default: 1).
  List<RecipeSearchResult> searchRecipes({
    required List<String> selectedIngredientNames,
    List<Recipe>? recipePool,
    int minMatchCount = 1,
  }) {
    final pool = recipePool ?? _dataset.recipes;

    if (selectedIngredientNames.isEmpty) {
      if (minMatchCount == 0) {
        return pool.map((r) {
          return RecipeSearchResult(
            recipe: r,
            matchedIngredients: const [],
            missingIngredients: List.of(r.ingredients),
          );
        }).toList();
      }
      return const [];
    }

    final normalizedUserIngredients = selectedIngredientNames
        .map(StringNormalizer.normalize)
        .where((name) => name.isNotEmpty)
        .toSet();

    final results = <RecipeSearchResult>[];

    for (final recipe in pool) {
      final matched = <RecipeIngredient>[];
      final missing = <RecipeIngredient>[];

      for (final recipeIng in recipe.ingredients) {
        final matches = _matchesAnyUserIngredient(
          recipeIng,
          normalizedUserIngredients,
        );

        if (matches) {
          matched.add(recipeIng);
        } else {
          missing.add(recipeIng);
        }
      }

      if (matched.length >= minMatchCount) {
        results.add(
          RecipeSearchResult(
            recipe: recipe,
            matchedIngredients: matched,
            missingIngredients: missing,
          ),
        );
      }
    }

    // Rank results:
    // 1. Higher matchCount first (most ingredients the user already has)
    // 2. Higher matchPercentage first (fewer missing items relative to recipe size)
    // 3. Alphabetical title for stability
    results.sort((a, b) {
      final countCompare = b.matchCount.compareTo(a.matchCount);
      if (countCompare != 0) return countCompare;

      final pctCompare = b.matchPercentage.compareTo(a.matchPercentage);
      if (pctCompare != 0) return pctCompare;

      return a.recipe.title.compareTo(b.recipe.title);
    });

    return results;
  }

  /// Finds the closest partial matches from the local dataset for fallback scenarios.
  /// Always returns at least partial matches if any overlap exists, up to [limit].
  List<RecipeSearchResult> findClosestPartialMatches(
    List<String> selectedIngredientNames, {
    int limit = 5,
  }) {
    final results = searchRecipes(
      selectedIngredientNames: selectedIngredientNames,
      minMatchCount: 1,
    );

    if (results.isEmpty) {
      // If zero overlap, return top diverse recipes from local pool
      return _dataset.recipes.take(limit).map((r) {
        return RecipeSearchResult(
          recipe: r,
          matchedIngredients: const [],
          missingIngredients: List.of(r.ingredients),
        );
      }).toList();
    }

    return results.take(limit).toList();
  }

  /// Determines if a recipe ingredient matches any user ingredient
  /// using exact normalized equality or mutual sub-phrase containment.
  bool _matchesAnyUserIngredient(
    RecipeIngredient recipeIngredient,
    Set<String> normalizedUserIngredients,
  ) {
    final recipeNorm = recipeIngredient.normalizedName;

    for (final userNorm in normalizedUserIngredients) {
      if (isIngredientMatch(userNorm, recipeNorm)) {
        return true;
      }
    }
    return false;
  }

  /// Static helper for comparing two normalized ingredient strings.
  static bool isIngredientMatch(String userNorm, String recipeNorm) {
    if (userNorm == recipeNorm) return true;

    // Sub-phrase matching (e.g. "pollo" in "pechuga de pollo" or "posta de res" in "carne de res")
    if (userNorm.contains(recipeNorm) || recipeNorm.contains(userNorm)) {
      return true;
    }

    // Common culinary synonym bridges in Guatemalan Spanish
    final isPoultry = (userNorm.contains('pollo') || userNorm.contains('pechuga')) &&
        (recipeNorm.contains('pollo') || recipeNorm.contains('pechuga'));
    if (isPoultry) return true;

    final isBeef = (userNorm.contains('res') || userNorm.contains('carne molida') || userNorm.contains('posta')) &&
        (recipeNorm.contains('res') || recipeNorm.contains('carne molida') || recipeNorm.contains('posta'));
    if (isBeef) return true;

    final isFish = (userNorm.contains('pescado') || userNorm.contains('filete')) &&
        (recipeNorm.contains('pescado') || recipeNorm.contains('filete'));
    if (isFish) return true;

    final isEgg = (userNorm.contains('huevo') || userNorm.contains('huevos')) &&
        (recipeNorm.contains('huevo') || recipeNorm.contains('huevos'));
    if (isEgg) return true;

    final isEggplant = (userNorm.contains('berenjena') || userNorm.contains('aubergine') || userNorm.contains('eggplant')) &&
        (recipeNorm.contains('berenjena') || recipeNorm.contains('aubergine') || recipeNorm.contains('eggplant'));
    if (isEggplant) return true;

    final isCassava = (userNorm.contains('yuca') || userNorm.contains('cassava') || userNorm.contains('mandioca')) &&
        (recipeNorm.contains('yuca') || recipeNorm.contains('cassava') || recipeNorm.contains('mandioca'));
    if (isCassava) return true;

    final isSweetPotato = (userNorm.contains('camote') || userNorm.contains('batata') || userNorm.contains('sweet potato')) &&
        (recipeNorm.contains('camote') || recipeNorm.contains('batata') || recipeNorm.contains('sweet potato'));
    if (isSweetPotato) return true;

    final isBeetroot = (userNorm.contains('remolacha') || userNorm.contains('betabel') || userNorm.contains('beetroot')) &&
        (recipeNorm.contains('remolacha') || recipeNorm.contains('betabel') || recipeNorm.contains('beetroot'));
    if (isBeetroot) return true;

    final isChickpea = (userNorm.contains('garbanzo') || userNorm.contains('garbanzos') || userNorm.contains('chickpea')) &&
        (recipeNorm.contains('garbanzo') || recipeNorm.contains('garbanzos') || recipeNorm.contains('chickpea'));
    if (isChickpea) return true;

    final isTuna = (userNorm.contains('atun') || userNorm.contains('tuna')) &&
        (recipeNorm.contains('atun') || recipeNorm.contains('tuna'));
    if (isTuna) return true;

    final isPork = (userNorm.contains('cerdo') || userNorm.contains('pork')) &&
        (recipeNorm.contains('cerdo') || recipeNorm.contains('pork'));
    if (isPork) return true;

    return false;
  }
}

import '../../../core/utils/string_normalizer.dart';
import '../domain/recipe.dart';
import '../domain/recipe_history_record.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_preference.dart';
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
  /// [history]: Optional map of user recipe history records, used to filter out `Nunca` recipes.
  List<RecipeSearchResult> searchRecipes({
    required List<String> selectedIngredientNames,
    List<Recipe>? recipePool,
    int minMatchCount = 1,
    Map<String, RecipeHistoryRecord>? history,
  }) {
    final rawPool = recipePool ?? _dataset.recipes;
    final pool = rawPool.where((recipe) {
      if (history != null && history.containsKey(recipe.id)) {
        if (history[recipe.id]?.preference == RecipePreference.never) {
          return false;
        }
      }
      return true;
    }).toList();

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

    // Rank results based on preference marks, cooking recency/variety, and match count/percentage
    results.sort((a, b) {
      final recA = history?[a.recipe.id];
      final recB = history?[b.recipe.id];

      final prefA = recA?.preference ?? RecipePreference.none;
      final prefB = recB?.preference ?? RecipePreference.none;

      // 1. Disliked recipes (No me gustó) appear at the very end as a last option
      final isDislikedA = prefA == RecipePreference.disliked;
      final isDislikedB = prefB == RecipePreference.disliked;
      if (isDislikedA != isDislikedB) {
        return isDislikedA ? 1 : -1;
      }

      // 2. Active recipes are ranked by composite score (matches + preference boost + variety balance)
      final scoreA = calculateScore(a, recA);
      final scoreB = calculateScore(b, recB);
      final scoreCompare = scoreB.compareTo(scoreA);
      if (scoreCompare != 0) return scoreCompare;

      // 3. Alphabetical title for stability
      return a.recipe.title.compareTo(b.recipe.title);
    });

    return results;
  }

  /// Computes a composite ranking score for a recipe based on:
  /// - Ingredient match count and percentage
  /// - User preference boost (Favorita: +12, Me gustó: +6)
  /// - Recency balance to encourage meal variety (recently cooked penalties: -4 for today, -2 for this week)
  static double calculateScore(
    RecipeSearchResult result,
    RecipeHistoryRecord? record, {
    DateTime? now,
  }) {
    double score = (result.matchCount * 10.0) + (result.matchPercentage * 5.0);

    final pref = record?.preference ?? RecipePreference.none;
    switch (pref) {
      case RecipePreference.favorite:
        score += 12.0;
        break;
      case RecipePreference.liked:
        score += 6.0;
        break;
      case RecipePreference.disliked:
        score -= 1000.0;
        break;
      case RecipePreference.never:
        score -= 10000.0;
        break;
      case RecipePreference.none:
        break;
    }

    if (record != null && record.cookedDates.isNotEmpty) {
      final currentDate = now ?? DateTime.now();
      if (record.isCookedToday(now: currentDate)) {
        score -= 4.0; // Cooked today: encourage variety
      } else {
        final last = record.lastCookedDate;
        if (last != null && currentDate.difference(last).inDays < 7) {
          score -= 2.0; // Cooked recently this week
        }
      }
      // Slight dampener for high-frequency repetition
      score -= (record.timesCooked * 0.2);
    }

    return score;
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

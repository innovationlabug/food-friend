import '../../../core/utils/string_normalizer.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../nutrition/data/health_goal_evaluator.dart';
import '../../nutrition/domain/health_goal.dart';
import '../domain/recipe.dart';
import '../domain/recipe_history_record.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_preference.dart';
import '../domain/recipe_search_result.dart';
import 'ingredient_replacement_service.dart';
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
  /// [maxTotalTimeMinutes]: Optional maximum total time (`prepTimeMinutes + cookTimeMinutes`) in minutes.
  /// [activeHealthGoals]: Optional active user health goals used to prioritize and explain recipes.
  List<RecipeSearchResult> searchRecipes({
    required List<String> selectedIngredientNames,
    List<Recipe>? recipePool,
    int minMatchCount = 1,
    Map<String, RecipeHistoryRecord>? history,
    int? maxTotalTimeMinutes,
    Set<HealthGoal> activeHealthGoals = const <HealthGoal>{},
  }) {
    final rawPool = recipePool ?? _dataset.recipes;
    final pool = rawPool.where((recipe) {
      if (history != null && history.containsKey(recipe.id)) {
        if (history[recipe.id]?.preference == RecipePreference.never) {
          return false;
        }
      }
      if (maxTotalTimeMinutes != null) {
        final total = recipe.totalTimeMinutes;
        if (total == null || total > maxTotalTimeMinutes) {
          return false;
        }
      }
      return true;
    }).toList();

    if (selectedIngredientNames.isEmpty) {
      if (minMatchCount == 0) {
        final emptySearchResults = pool.map((r) {
          return RecipeSearchResult(
            recipe: r,
            matchedIngredients: const [],
            missingIngredients: List.of(r.ingredients),
            goalMatch: HealthGoalEvaluator.evaluateRecipe(r, activeHealthGoals),
            healthGoalReplacements:
                IngredientReplacementService.findHealthGoalReplacements(
              recipe: r,
              activeHealthGoals: activeHealthGoals,
            ),
          );
        }).toList();
        if (activeHealthGoals.isNotEmpty) {
          _sortResults(
            emptySearchResults,
            history: history,
            activeHealthGoals: activeHealthGoals,
          );
        }
        return emptySearchResults;
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

      final availabilityReplacements =
          IngredientReplacementService.findAvailabilityReplacements(
        missingIngredients: missing,
        availableIngredientNames: selectedIngredientNames,
      );
      final effectiveMatchCount =
          matched.length + availabilityReplacements.length;

      if (effectiveMatchCount >= minMatchCount) {
        results.add(
          RecipeSearchResult(
            recipe: recipe,
            matchedIngredients: matched,
            missingIngredients: missing,
            goalMatch: HealthGoalEvaluator.evaluateRecipe(
              recipe,
              activeHealthGoals,
            ),
            availabilityReplacements: availabilityReplacements,
            healthGoalReplacements:
                IngredientReplacementService.findHealthGoalReplacements(
              recipe: recipe,
              activeHealthGoals: activeHealthGoals,
              availableIngredientNames: selectedIngredientNames,
            ),
          ),
        );
      }
    }

    // Rank results based on preference marks, cooking recency/variety, health goals, and match count/percentage
    _sortResults(
      results,
      history: history,
      activeHealthGoals: activeHealthGoals,
    );

    return results;
  }

  void _sortResults(
    List<RecipeSearchResult> results, {
    Map<String, RecipeHistoryRecord>? history,
    Set<HealthGoal> activeHealthGoals = const <HealthGoal>{},
  }) {
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

      // 2. Active recipes are ranked by composite score (matches + preference boost + goal alignment + variety balance)
      final scoreA = calculateScore(
        a,
        recA,
        activeHealthGoals: activeHealthGoals,
      );
      final scoreB = calculateScore(
        b,
        recB,
        activeHealthGoals: activeHealthGoals,
      );
      final scoreCompare = scoreB.compareTo(scoreA);
      if (scoreCompare != 0) return scoreCompare;

      // 3. Alphabetical title for stability
      return a.recipe.title.compareTo(b.recipe.title);
    });
  }

  /// Computes a composite ranking score for a recipe based on:
  /// - Direct ingredient match count and percentage
  /// - Availability-based replacement coverage (plus readiness bonus when all missing items are substitutable)
  /// - Health-goal alignment net score (positive boost minus conflict penalty)
  /// - User preference boost (Favorita: +12, Me gustó: +6)
  /// - Recency balance to encourage meal variety (recently cooked penalties: -4 for today, -2 for this week)
  static double calculateScore(
    RecipeSearchResult result,
    RecipeHistoryRecord? record, {
    DateTime? now,
    Set<HealthGoal> activeHealthGoals = const <HealthGoal>{},
  }) {
    double score = (result.matchCount * 10.0) + (result.matchPercentage * 5.0);
    if (result.hasAvailabilityReplacements) {
      score += result.availabilityReplacements.length * 6.0;
      if (result.isCookableWithReplacements) {
        score += 4.0;
      }
    }

    final effectiveGoalMatch =
        (result.goalMatch.hasMatch || result.goalMatch.penaltyScore > 0)
            ? result.goalMatch
            : (activeHealthGoals.isEmpty
                ? result.goalMatch
                : HealthGoalEvaluator.evaluateRecipe(
                    result.recipe,
                    activeHealthGoals,
                  ));
    score += effectiveGoalMatch.netScore;

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
    Set<HealthGoal> activeHealthGoals = const <HealthGoal>{},
  }) {
    final results = searchRecipes(
      selectedIngredientNames: selectedIngredientNames,
      minMatchCount: 1,
      activeHealthGoals: activeHealthGoals,
    );

    if (results.isEmpty) {
      // If zero overlap, return top diverse recipes from local pool (goal-prioritized when active)
      final allZeroMatch = _dataset.recipes.map((r) {
        return RecipeSearchResult(
          recipe: r,
          matchedIngredients: const [],
          missingIngredients: List.of(r.ingredients),
          goalMatch: HealthGoalEvaluator.evaluateRecipe(r, activeHealthGoals),
          healthGoalReplacements:
              IngredientReplacementService.findHealthGoalReplacements(
            recipe: r,
            activeHealthGoals: activeHealthGoals,
            availableIngredientNames: selectedIngredientNames,
          ),
        );
      }).toList();
      if (activeHealthGoals.isNotEmpty) {
        _sortResults(allZeroMatch, activeHealthGoals: activeHealthGoals);
      }
      return allZeroMatch.take(limit).toList();
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

  /// Finds all pantry [Ingredient] items currently in `"Mis ingredientes"`
  /// that match at least one required ingredient of [recipe] using the standard
  /// normalized, sub-phrase, and culinary synonym rules.
  ///
  /// Each matching pantry ingredient is returned at most once, preserving pantry order.
  static List<Ingredient> findMatchingPantryIngredients(
    Recipe recipe,
    List<Ingredient> pantryIngredients,
  ) {
    if (recipe.ingredients.isEmpty || pantryIngredients.isEmpty) {
      return const [];
    }

    final recipeNormalizedNames = recipe.ingredients
        .map((ing) => ing.normalizedName)
        .where((name) => name.isNotEmpty)
        .toList();
    if (recipeNormalizedNames.isEmpty) {
      return const [];
    }

    final matched = <Ingredient>[];
    for (final pantryItem in pantryIngredients) {
      final pantryNorm = StringNormalizer.normalize(pantryItem.name);
      if (pantryNorm.isEmpty) continue;
      final isUsed = recipeNormalizedNames.any(
        (recipeNorm) => isIngredientMatch(pantryNorm, recipeNorm),
      );
      if (isUsed) {
        matched.add(pantryItem);
      }
    }
    return matched;
  }

  /// Static helper for comparing two normalized ingredient strings.
  static bool isIngredientMatch(String userNorm, String recipeNorm) {
    if (userNorm == recipeNorm) return true;

    // Sub-phrase matching on token boundaries (e.g. "pollo" matches "pechuga de pollo"
    // without falsely matching "repollo morado", and "res" matches "lomo de res"
    // without matching "fresa" or "queso fresco")
    if (_containsWordOrPhrase(userNorm, recipeNorm) ||
        _containsWordOrPhrase(recipeNorm, userNorm)) {
      return true;
    }

    // Common culinary synonym bridges in Guatemalan Spanish
    final isPoultry =
        (_containsWordOrPhrase(userNorm, 'pollo') ||
            _containsWordOrPhrase(userNorm, 'pechuga')) &&
        (_containsWordOrPhrase(recipeNorm, 'pollo') ||
            _containsWordOrPhrase(recipeNorm, 'pechuga'));
    if (isPoultry) return true;

    final isBeef =
        (_containsWordOrPhrase(userNorm, 'res') ||
            _containsWordOrPhrase(userNorm, 'carne molida') ||
            _containsWordOrPhrase(userNorm, 'posta')) &&
        (_containsWordOrPhrase(recipeNorm, 'res') ||
            _containsWordOrPhrase(recipeNorm, 'carne molida') ||
            _containsWordOrPhrase(recipeNorm, 'posta'));
    if (isBeef) return true;

    final isFish =
        (_containsWordOrPhrase(userNorm, 'pescado') ||
            _containsWordOrPhrase(userNorm, 'filete')) &&
        (_containsWordOrPhrase(recipeNorm, 'pescado') ||
            _containsWordOrPhrase(recipeNorm, 'filete'));
    if (isFish) return true;

    final isEgg =
        (_containsWordOrPhrase(userNorm, 'huevo') ||
            _containsWordOrPhrase(userNorm, 'huevos')) &&
        (_containsWordOrPhrase(recipeNorm, 'huevo') ||
            _containsWordOrPhrase(recipeNorm, 'huevos'));
    if (isEgg) return true;

    final isEggplant =
        (_containsWordOrPhrase(userNorm, 'berenjena') ||
            _containsWordOrPhrase(userNorm, 'aubergine') ||
            _containsWordOrPhrase(userNorm, 'eggplant')) &&
        (_containsWordOrPhrase(recipeNorm, 'berenjena') ||
            _containsWordOrPhrase(recipeNorm, 'aubergine') ||
            _containsWordOrPhrase(recipeNorm, 'eggplant'));
    if (isEggplant) return true;

    final isCassava =
        (_containsWordOrPhrase(userNorm, 'yuca') ||
            _containsWordOrPhrase(userNorm, 'cassava') ||
            _containsWordOrPhrase(userNorm, 'mandioca')) &&
        (_containsWordOrPhrase(recipeNorm, 'yuca') ||
            _containsWordOrPhrase(recipeNorm, 'cassava') ||
            _containsWordOrPhrase(recipeNorm, 'mandioca'));
    if (isCassava) return true;

    final isSweetPotato =
        (_containsWordOrPhrase(userNorm, 'camote') ||
            _containsWordOrPhrase(userNorm, 'batata') ||
            _containsWordOrPhrase(userNorm, 'sweet potato')) &&
        (_containsWordOrPhrase(recipeNorm, 'camote') ||
            _containsWordOrPhrase(recipeNorm, 'batata') ||
            _containsWordOrPhrase(recipeNorm, 'sweet potato'));
    if (isSweetPotato) return true;

    final isBeetroot =
        (_containsWordOrPhrase(userNorm, 'remolacha') ||
            _containsWordOrPhrase(userNorm, 'betabel') ||
            _containsWordOrPhrase(userNorm, 'beetroot')) &&
        (_containsWordOrPhrase(recipeNorm, 'remolacha') ||
            _containsWordOrPhrase(recipeNorm, 'betabel') ||
            _containsWordOrPhrase(recipeNorm, 'beetroot'));
    if (isBeetroot) return true;

    final isChickpea =
        (_containsWordOrPhrase(userNorm, 'garbanzo') ||
            _containsWordOrPhrase(userNorm, 'garbanzos') ||
            _containsWordOrPhrase(userNorm, 'chickpea')) &&
        (_containsWordOrPhrase(recipeNorm, 'garbanzo') ||
            _containsWordOrPhrase(recipeNorm, 'garbanzos') ||
            _containsWordOrPhrase(recipeNorm, 'chickpea'));
    if (isChickpea) return true;

    final isTuna =
        (_containsWordOrPhrase(userNorm, 'atun') ||
            _containsWordOrPhrase(userNorm, 'tuna')) &&
        (_containsWordOrPhrase(recipeNorm, 'atun') ||
            _containsWordOrPhrase(recipeNorm, 'tuna'));
    if (isTuna) return true;

    final isPork =
        (_containsWordOrPhrase(userNorm, 'cerdo') ||
            _containsWordOrPhrase(userNorm, 'pork')) &&
        (_containsWordOrPhrase(recipeNorm, 'cerdo') ||
            _containsWordOrPhrase(recipeNorm, 'pork'));
    if (isPork) return true;

    return false;
  }

  /// Checks whether [haystack] contains [needle] on token boundaries
  /// (supporting optional Spanish plural suffix `-s` or `-es`).
  static bool _containsWordOrPhrase(String haystack, String needle) {
    if (needle.isEmpty || haystack.isEmpty) return false;
    final escaped = RegExp.escape(needle);
    final pattern = RegExp('(?:^|[^a-z0-9])$escaped(?:e?s)?(?:\$|[^a-z0-9])');
    return pattern.hasMatch(haystack);
  }
}

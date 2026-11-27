import '../../../core/utils/string_normalizer.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../nutrition/data/health_goal_evaluator.dart';
import '../../nutrition/data/health_goal_storage_service.dart';
import '../../nutrition/domain/health_goal.dart';
import '../../nutrition/domain/recipe_goal_match.dart';
import '../domain/multi_day_meal_plan.dart';
import '../domain/recipe.dart';
import '../domain/recipe_history_record.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_preference.dart';
import '../domain/recipe_variation.dart';
import 'local_recipe_dataset.dart';
import 'recipe_history_service.dart';
import 'recipe_search_service.dart';

/// Deterministic, offline-capable planner that builds a 2 to 7 day cooking plan
/// prioritizing shared pantry ingredients, rotating recipes and culinary
/// variations without consecutive repetition, and aggregating missing items.
class MultiDayPlannerService {
  MultiDayPlannerService({
    LocalRecipeDataset? dataset,
    IngredientStorageService? ingredientStorageService,
    RecipeHistoryService? historyService,
    HealthGoalStorageService? healthGoalStorageService,
  })  : _dataset = dataset ?? LocalRecipeDataset.instance,
        _ingredientStorageService =
            ingredientStorageService ?? IngredientStorageService(),
        _historyService = historyService ??
            RecipeHistoryService(
              ingredientStorageService:
                  ingredientStorageService ?? IngredientStorageService(),
            ),
        _healthGoalStorageService =
            healthGoalStorageService ?? HealthGoalStorageService();

  static const int minDays = 2;
  static const int maxDays = 7;
  static const List<int> supportedDayCounts = <int>[2, 3, 4, 5, 6, 7];

  final LocalRecipeDataset _dataset;
  final IngredientStorageService _ingredientStorageService;
  final RecipeHistoryService _historyService;
  final HealthGoalStorageService _healthGoalStorageService;

  /// Loads persisted pantry, history, and health goals, then generates a plan.
  Future<MultiDayMealPlan> loadAndGeneratePlan({
    required int daysCount,
    List<String>? overrideIngredientNames,
    String? categoryFilter,
    int? maxTotalTimeMinutes,
  }) async {
    final results = await Future.wait<dynamic>([
      _ingredientStorageService.getIngredients(),
      _historyService.getHistory(),
      _healthGoalStorageService.getSelectedGoals(),
    ]);

    final pantry = results[0] as List<dynamic>;
    final history = results[1] as Map<String, RecipeHistoryRecord>;
    final activeGoals = results[2] as Set<HealthGoal>;

    final availableNames = overrideIngredientNames ??
        pantry.map((item) => item.name as String).toList();

    return generatePlan(
      daysCount: daysCount,
      availableIngredientNames: availableNames,
      history: history,
      activeHealthGoals: activeGoals,
      categoryFilter: categoryFilter,
      maxTotalTimeMinutes: maxTotalTimeMinutes,
    );
  }

  /// Generates a deterministic [MultiDayMealPlan] for [daysCount] (`2..7`)
  /// using only on-device data and zero LLM calls.
  MultiDayMealPlan generatePlan({
    required int daysCount,
    required List<String> availableIngredientNames,
    List<Recipe>? recipePool,
    Map<String, RecipeHistoryRecord> history = const <String, RecipeHistoryRecord>{},
    Set<HealthGoal> activeHealthGoals = const <HealthGoal>{},
    String? categoryFilter,
    int? maxTotalTimeMinutes,
  }) {
    final clampedDays = daysCount.clamp(minDays, maxDays);
    final rawPool = recipePool ?? _dataset.recipes;

    final normalizedPantry = availableIngredientNames
        .map(StringNormalizer.normalize)
        .where((name) => name.isNotEmpty)
        .toSet();

    final candidates = <_EvaluatedCandidate>[];
    final seenIds = <String>{};

    for (final recipe in rawPool) {
      if (!seenIds.add(recipe.id)) continue;
      if (recipe.ingredients.isEmpty) continue;

      final record = history[recipe.id];
      final pref = record?.preference ?? RecipePreference.none;
      if (pref == RecipePreference.never) continue;

      if (categoryFilter != null &&
          categoryFilter != 'Todos' &&
          !_matchesCategory(recipe, categoryFilter)) {
        continue;
      }

      if (maxTotalTimeMinutes != null) {
        final total = recipe.totalTimeMinutes;
        if (total == null || total > maxTotalTimeMinutes) continue;
      }

      final matched = <RecipeIngredient>[];
      final missing = <RecipeIngredient>[];
      for (final ing in recipe.ingredients) {
        final ingNorm = ing.normalizedName;
        final isMatched = ingNorm.isNotEmpty &&
            normalizedPantry.any(
              (pantryNorm) =>
                  RecipeSearchService.isIngredientMatch(pantryNorm, ingNorm),
            );
        if (isMatched) {
          matched.add(ing);
        } else {
          missing.add(ing);
        }
      }

      final goalMatch = HealthGoalEvaluator.evaluateRecipe(
        recipe,
        activeHealthGoals,
      );

      candidates.add(
        _EvaluatedCandidate(
          recipe: recipe,
          matched: matched,
          missing: missing,
          goalMatch: goalMatch,
          preference: pref,
        ),
      );
    }

    if (candidates.isEmpty) {
      return MultiDayMealPlan(
        daysCount: clampedDays,
        days: const [],
        activeHealthGoals: activeHealthGoals,
        selectedCategory: categoryFilter,
        maxTotalTimeMinutes: maxTotalTimeMinutes,
      );
    }

    final plannedDays = <MealPlanDay>[];
    final usedRecipeIds = <String>{};
    final priorIngredientNorms = <String>[];

    for (int dayNum = 1; dayNum <= clampedDays; dayNum++) {
      final prevDay = plannedDays.isEmpty ? null : plannedDays.last;
      final hasUnusedNonDisliked = candidates.any(
        (c) =>
            !usedRecipeIds.contains(c.recipe.id) &&
            c.preference != RecipePreference.disliked,
      );
      final hasAnyUnused = candidates.any(
        (c) => !usedRecipeIds.contains(c.recipe.id),
      );

      _ScoredSelection? bestSelection;

      for (final candidate in candidates) {
        // Hard non-consecutive rule whenever more than 1 recipe is available.
        if (prevDay != null &&
            candidates.length > 1 &&
            candidate.recipe.id == prevDay.recipe.id) {
          continue;
        }

        double score = _baseCandidateScore(candidate);

        // Avoid repeating recipes across the plan while fresh candidates exist.
        if (usedRecipeIds.contains(candidate.recipe.id)) {
          if (hasUnusedNonDisliked || hasAnyUnused) {
            score -= 500.0;
          }
        }

        // Encourage starting with a recipe that has rich linked variations.
        if (dayNum == 1 && candidate.recipe.hasVariations) {
          score += 2.0;
        }

        Recipe? anchorRecipe;
        RecipeVariation? matchedVariation;
        final sharedNames = <String>[];
        final seenSharedNorms = <String>{};

        if (prevDay != null) {
          // Check direct variation from the previous day first, then earlier days.
          final directVar = _findVariationLink(
            anchor: prevDay.recipe,
            candidateId: candidate.recipe.id,
          );
          if (directVar != null) {
            anchorRecipe = prevDay.recipe;
            matchedVariation = directVar;
            score += 14.0;
          } else {
            for (int idx = plannedDays.length - 1; idx >= 0; idx--) {
              final earlier = plannedDays[idx];
              final link = _findVariationLink(
                anchor: earlier.recipe,
                candidateId: candidate.recipe.id,
              );
              if (link != null) {
                anchorRecipe = earlier.recipe;
                matchedVariation = link;
                score += 9.0;
                break;
              }
              if (earlier.baseRecipe != null) {
                final baseLink = _findVariationLink(
                  anchor: earlier.baseRecipe!,
                  candidateId: candidate.recipe.id,
                );
                if (baseLink != null) {
                  anchorRecipe = earlier.baseRecipe;
                  matchedVariation = baseLink;
                  score += 8.0;
                  break;
                }
              }
            }
          }

          // Score ingredient reuse with earlier days (prioritizing pantry items).
          for (final ing in candidate.recipe.ingredients) {
            final ingNorm = ing.normalizedName;
            if (ingNorm.isEmpty) continue;
            final sharesWithEarlier = priorIngredientNorms.any(
              (priorNorm) =>
                  RecipeSearchService.isIngredientMatch(priorNorm, ingNorm),
            );
            if (!sharesWithEarlier) continue;

            final isInPantry = candidate.matched.any(
              (m) => m.normalizedName == ingNorm,
            );
            score += isInPantry ? 6.0 : 3.5;

            if (seenSharedNorms.add(ingNorm)) {
              sharedNames.add(ing.name);
            }
          }
        }

        final selection = _ScoredSelection(
          candidate: candidate,
          score: score,
          baseRecipe: anchorRecipe,
          variation: matchedVariation,
          sharedIngredientNames: sharedNames,
        );

        if (bestSelection == null ||
            selection.score > bestSelection.score ||
            (selection.score == bestSelection.score &&
                selection.candidate.recipe.title
                        .compareTo(bestSelection.candidate.recipe.title) <
                    0)) {
          bestSelection = selection;
        }
      }

      if (bestSelection == null) break;

      final chosen = bestSelection.candidate;
      usedRecipeIds.add(chosen.recipe.id);
      for (final ing in chosen.recipe.ingredients) {
        if (ing.normalizedName.isNotEmpty) {
          priorIngredientNorms.add(ing.normalizedName);
        }
      }

      plannedDays.add(
        MealPlanDay(
          dayNumber: dayNum,
          recipe: chosen.recipe,
          baseRecipe: bestSelection.baseRecipe,
          variation: bestSelection.variation,
          matchedPantryIngredients: chosen.matched,
          missingIngredients: chosen.missing,
          sharedIngredientsWithPreviousDays: bestSelection.sharedIngredientNames,
          goalMatch: chosen.goalMatch,
        ),
      );
    }

    final sharedCore = _computeSharedCoreIngredients(
      plannedDays,
      normalizedPantry: normalizedPantry,
    );
    final consolidatedMissing = _consolidateMissingIngredients(plannedDays);

    return MultiDayMealPlan(
      daysCount: clampedDays,
      days: plannedDays,
      sharedCoreIngredients: sharedCore,
      consolidatedMissingIngredients: consolidatedMissing,
      activeHealthGoals: activeHealthGoals,
      selectedCategory: categoryFilter,
      maxTotalTimeMinutes: maxTotalTimeMinutes,
    );
  }

  static double _baseCandidateScore(_EvaluatedCandidate candidate) {
    final total = candidate.recipe.ingredients.length;
    final matchRatio = total == 0 ? 0.0 : candidate.matched.length / total;
    double score = (candidate.matched.length * 10.0) + (matchRatio * 6.0);
    score += candidate.goalMatch.netScore;

    switch (candidate.preference) {
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

    return score;
  }

  static RecipeVariation? _findVariationLink({
    required Recipe anchor,
    required String candidateId,
  }) {
    for (final variation in anchor.variations) {
      if (variation.recipeId == candidateId) {
        return variation;
      }
    }
    return null;
  }

  static bool _matchesCategory(Recipe recipe, String category) {
    final rCat = recipe.category?.trim().toLowerCase();
    if (rCat == null) return false;
    final fCat = category.trim().toLowerCase();
    return rCat == fCat || rCat.contains(fCat) || fCat.contains(rCat);
  }

  static List<String> _computeSharedCoreIngredients(
    List<MealPlanDay> days, {
    required Set<String> normalizedPantry,
  }) {
    if (days.length < 2) return const [];

    final groups = <_SharedIngredientStat>[];

    for (final day in days) {
      final seenInDay = <String>{};
      for (final ing in day.recipe.ingredients) {
        final ingNorm = ing.normalizedName;
        if (ingNorm.isEmpty) continue;
        if (seenInDay.any(
          (seen) => RecipeSearchService.isIngredientMatch(seen, ingNorm),
        )) {
          continue;
        }
        seenInDay.add(ingNorm);

        final existingIndex = groups.indexWhere(
          (g) => RecipeSearchService.isIngredientMatch(g.normalizedName, ingNorm),
        );
        final inPantry = normalizedPantry.any(
          (p) => RecipeSearchService.isIngredientMatch(p, ingNorm),
        );
        if (existingIndex >= 0) {
          groups[existingIndex].dayCount += 1;
          groups[existingIndex].inPantry =
              groups[existingIndex].inPantry || inPantry;
        } else {
          groups.add(
            _SharedIngredientStat(
              displayName: ing.name,
              normalizedName: ingNorm,
              dayCount: 1,
              inPantry: inPantry,
            ),
          );
        }
      }
    }

    final shared = groups.where((g) => g.dayCount >= 2).toList()
      ..sort((a, b) {
        if (a.inPantry != b.inPantry) return a.inPantry ? -1 : 1;
        final countCmp = b.dayCount.compareTo(a.dayCount);
        if (countCmp != 0) return countCmp;
        return a.displayName.compareTo(b.displayName);
      });

    return shared.map((g) => g.displayName).toList();
  }

  static List<RecipeIngredient> _consolidateMissingIngredients(
    List<MealPlanDay> days,
  ) {
    final consolidated = <RecipeIngredient>[];
    for (final day in days) {
      for (final ing in day.missingIngredients) {
        final ingNorm = ing.normalizedName;
        if (ingNorm.isEmpty) continue;
        final alreadyIncluded = consolidated.any(
          (existing) => RecipeSearchService.isIngredientMatch(
            existing.normalizedName,
            ingNorm,
          ),
        );
        if (!alreadyIncluded) {
          consolidated.add(ing);
        }
      }
    }
    return consolidated;
  }
}

class _EvaluatedCandidate {
  const _EvaluatedCandidate({
    required this.recipe,
    required this.matched,
    required this.missing,
    required this.goalMatch,
    required this.preference,
  });

  final Recipe recipe;
  final List<RecipeIngredient> matched;
  final List<RecipeIngredient> missing;
  final RecipeGoalMatch goalMatch;
  final RecipePreference preference;
}

class _ScoredSelection {
  const _ScoredSelection({
    required this.candidate,
    required this.score,
    this.baseRecipe,
    this.variation,
    this.sharedIngredientNames = const [],
  });

  final _EvaluatedCandidate candidate;
  final double score;
  final Recipe? baseRecipe;
  final RecipeVariation? variation;
  final List<String> sharedIngredientNames;
}

class _SharedIngredientStat {
  _SharedIngredientStat({
    required this.displayName,
    required this.normalizedName,
    required this.dayCount,
    required this.inPantry,
  });

  final String displayName;
  final String normalizedName;
  int dayCount;
  bool inPantry;
}

import '../../../core/utils/string_normalizer.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../../ingredients/domain/ingredient.dart';
import '../../nutrition/data/health_goal_evaluator.dart';
import '../../nutrition/data/health_goal_storage_service.dart';
import '../../nutrition/data/nutrition_catalog.dart';
import '../../nutrition/data/nutrition_service.dart';
import '../../nutrition/domain/health_goal.dart';
import '../../nutrition/domain/nutrition_metadata.dart';
import '../../nutrition/domain/nutrition_tip.dart';
import '../../recipes/data/local_recipe_dataset.dart';
import '../../recipes/data/recipe_history_service.dart';
import '../../recipes/data/recipe_search_service.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_history_record.dart';
import '../../recipes/domain/recipe_ingredient.dart';
import '../../recipes/domain/recipe_preference.dart';
import '../domain/shopping_suggestion.dart';
import 'shopping_list_storage_service.dart';

/// Immutable snapshot of recipe, history, health-goal, and nutrition state
/// used to recompute shopping suggestions locally without repeated disk reads.
class ShoppingSuggestionsContext {
  const ShoppingSuggestionsContext({
    required this.recipes,
    required this.history,
    required this.activeHealthGoals,
    required this.nutritionReport,
  });

  final List<Recipe> recipes;
  final Map<String, RecipeHistoryRecord> history;
  final Set<HealthGoal> activeHealthGoals;
  final NutritionReport nutritionReport;
}

/// Deterministic gap-analysis engine that surfaces "almost-ready" recipes in
/// `"Por comprar"` based on user favorites, liked/frequent recipes, active
/// health goals, and nutrition gaps — running 100% locally with zero LLM calls.
class ShoppingSuggestionService {
  ShoppingSuggestionService({
    IngredientStorageService? ingredientStorageService,
    ShoppingListStorageService? shoppingListService,
    RecipeHistoryService? historyService,
    HealthGoalStorageService? healthGoalStorageService,
    NutritionService? nutritionService,
  })  : _ingredientStorageService =
            ingredientStorageService ?? IngredientStorageService(),
        _shoppingListService = shoppingListService ??
            ShoppingListStorageService(
              pantryStorageService:
                  ingredientStorageService ?? IngredientStorageService(),
            ),
        _historyService = historyService ??
            RecipeHistoryService(
              ingredientStorageService:
                  ingredientStorageService ?? IngredientStorageService(),
            ),
        _healthGoalStorageService =
            healthGoalStorageService ?? HealthGoalStorageService(),
        _nutritionService = nutritionService ??
            NutritionService(
              historyService: historyService ??
                  RecipeHistoryService(
                    ingredientStorageService:
                        ingredientStorageService ?? IngredientStorageService(),
                  ),
              healthGoalStorageService:
                  healthGoalStorageService ?? HealthGoalStorageService(),
            );

  final IngredientStorageService _ingredientStorageService;
  final ShoppingListStorageService _shoppingListService;
  final RecipeHistoryService _historyService;
  final HealthGoalStorageService _healthGoalStorageService;
  final NutritionService _nutritionService;

  /// Maximum number of missing pantry ingredients for a recipe to qualify.
  static const int defaultMaxMissingIngredients = 2;

  /// Maximum total suggestions returned to keep the shopping screen uncluttered.
  static const int defaultMaxSuggestions = 6;

  /// Minimum logged cooks required to treat an unmarked recipe as frequent.
  static const int frequentCookThreshold = 2;

  /// Loads recipe pool, history, active health goals, and nutrition report.
  Future<ShoppingSuggestionsContext> loadContext() async {
    final results = await Future.wait<dynamic>([
      _historyService.getAllKnownRecipes(),
      _historyService.getHistory(),
      _healthGoalStorageService.getSelectedGoals(),
      _nutritionService.generateReport(),
    ]);

    return ShoppingSuggestionsContext(
      recipes: results[0] as List<Recipe>,
      history: results[1] as Map<String, RecipeHistoryRecord>,
      activeHealthGoals: results[2] as Set<HealthGoal>,
      nutritionReport: results[3] as NutritionReport,
    );
  }

  /// Loads persisted pantry, shopping list, and context data, returning ranked
  /// [ShoppingSuggestion]s.
  Future<List<ShoppingSuggestion>> loadSuggestions({
    int maxMissingIngredients = defaultMaxMissingIngredients,
    int maxSuggestions = defaultMaxSuggestions,
  }) async {
    final results = await Future.wait<dynamic>([
      _ingredientStorageService.getIngredients(),
      _shoppingListService.getIngredients(),
      loadContext(),
    ]);

    final pantry = results[0] as List<Ingredient>;
    final shoppingList = results[1] as List<Ingredient>;
    final context = results[2] as ShoppingSuggestionsContext;

    return generateSuggestions(
      pantryIngredients: pantry,
      shoppingListIngredients: shoppingList,
      recipes: context.recipes,
      history: context.history,
      activeHealthGoals: context.activeHealthGoals,
      nutritionReport: context.nutritionReport,
      maxMissingIngredients: maxMissingIngredients,
      maxSuggestions: maxSuggestions,
    );
  }

  /// Pure deterministic gap evaluation across pantry, `"Por comprar"`, history,
  /// active health goals, and nutrition tips.
  List<ShoppingSuggestion> generateSuggestions({
    required List<Ingredient> pantryIngredients,
    required List<Ingredient> shoppingListIngredients,
    List<Recipe>? recipes,
    Map<String, RecipeHistoryRecord> history = const <String, RecipeHistoryRecord>{},
    Set<HealthGoal> activeHealthGoals = const <HealthGoal>{},
    NutritionReport? nutritionReport,
    int maxMissingIngredients = defaultMaxMissingIngredients,
    int maxSuggestions = defaultMaxSuggestions,
  }) {
    if (pantryIngredients.isEmpty ||
        maxMissingIngredients <= 0 ||
        maxSuggestions <= 0) {
      return const <ShoppingSuggestion>[];
    }

    final pantryNorms = pantryIngredients
        .map((item) => StringNormalizer.normalize(item.name))
        .where((name) => name.isNotEmpty)
        .toList();
    if (pantryNorms.isEmpty) {
      return const <ShoppingSuggestion>[];
    }

    final shoppingNorms = shoppingListIngredients
        .map((item) => StringNormalizer.normalize(item.name))
        .where((name) => name.isNotEmpty)
        .toList();

    final recipePool = recipes ?? LocalRecipeDataset.instance.recipes;
    final seenRecipeIds = <String>{};
    final historyCandidates = <ShoppingSuggestion>[];
    final nutritionCandidates = <ShoppingSuggestion>[];

    for (final recipe in recipePool) {
      if (!seenRecipeIds.add(recipe.id)) continue;
      if (recipe.ingredients.length < 2) continue;

      final record = history[recipe.id];
      final preference = record?.preference ?? RecipePreference.none;
      if (preference == RecipePreference.never ||
          preference == RecipePreference.disliked) {
        continue;
      }

      int availableCount = 0;
      final missingFromPantry = <RecipeIngredient>[];

      for (final recipeIng in recipe.ingredients) {
        final recipeNorm = recipeIng.normalizedName;
        if (recipeNorm.isEmpty) continue;
        final isAvailable = pantryNorms.any(
          (pantryNorm) => RecipeSearchService.isIngredientMatch(
            pantryNorm,
            recipeNorm,
          ),
        );
        if (isAvailable) {
          availableCount++;
        } else {
          missingFromPantry.add(recipeIng);
        }
      }

      if (availableCount < 1 ||
          missingFromPantry.isEmpty ||
          missingFromPantry.length > maxMissingIngredients ||
          availableCount < missingFromPantry.length) {
        continue;
      }

      final unlistedMissing = <RecipeIngredient>[];
      final seenMissingNorms = <String>{};
      for (final missingIng in missingFromPantry) {
        final missingNorm = missingIng.normalizedName;
        if (missingNorm.isEmpty || !seenMissingNorms.add(missingNorm)) {
          continue;
        }
        final alreadyInShoppingList = shoppingNorms.any(
          (shopNorm) => RecipeSearchService.isIngredientMatch(
            shopNorm,
            missingNorm,
          ),
        );
        if (!alreadyInShoppingList) {
          unlistedMissing.add(missingIng);
        }
      }

      if (unlistedMissing.isEmpty) {
        continue;
      }

      final missingNames = unlistedMissing.map((i) => i.name).toList();
      final timesCooked = record?.timesCooked ?? 0;

      // Classify with precedence: Favorites/Liked/Frequent before Goals/Nutrition
      // so every recipe appears at most once across buckets.
      final ShoppingSuggestionSource? historySource;
      if (preference == RecipePreference.favorite) {
        historySource = ShoppingSuggestionSource.favorite;
      } else if (preference == RecipePreference.liked) {
        historySource = ShoppingSuggestionSource.liked;
      } else if (timesCooked >= frequentCookThreshold) {
        historySource = ShoppingSuggestionSource.frequentlyCooked;
      } else {
        historySource = null;
      }

      if (historySource != null) {
        historyCandidates.add(
          ShoppingSuggestion(
            recipe: recipe,
            missingIngredients: missingNames,
            availableIngredientCount: availableCount,
            totalIngredientCount: recipe.ingredients.length,
            source: historySource,
            message: buildMessage(
              recipe: recipe,
              missingIngredients: missingNames,
              source: historySource,
            ),
            timesCooked: timesCooked,
          ),
        );
        continue;
      }

      if (activeHealthGoals.isNotEmpty) {
        final goalMatch = HealthGoalEvaluator.evaluateRecipe(
          recipe,
          activeHealthGoals,
        );
        if (goalMatch.hasMatch && goalMatch.penaltyScore == 0) {
          final matchedGoal = goalMatch.reasons.first.goal;
          final relevance =
              goalMatch.netScore + (goalMatch.matchedGoals.length * 4.0);
          nutritionCandidates.add(
            ShoppingSuggestion(
              recipe: recipe,
              missingIngredients: missingNames,
              availableIngredientCount: availableCount,
              totalIngredientCount: recipe.ingredients.length,
              source: ShoppingSuggestionSource.healthGoal,
              matchedGoal: matchedGoal,
              message: buildMessage(
                recipe: recipe,
                missingIngredients: missingNames,
                source: ShoppingSuggestionSource.healthGoal,
                matchedGoal: matchedGoal,
              ),
              timesCooked: timesCooked,
              relevanceScore: relevance,
            ),
          );
          continue;
        }
      }

      if (nutritionReport != null &&
          nutritionReport.hasCookingHistory &&
          nutritionReport.missingNutrients.isNotEmpty) {
        final hasProcessedMeat = recipe.ingredients.any(
          (ing) =>
              NutritionCatalog.evaluateIngredient(ing.name).isProcessedMeat,
        );
        if (hasProcessedMeat) continue;

        final suppliedNutrients = <TrackedNutrient>{};
        for (final missingName in missingNames) {
          suppliedNutrients.addAll(
            NutritionCatalog.evaluateIngredient(missingName).nutrients,
          );
        }

        TrackedNutrient? matchedNutrient;
        int matchedNutrientCount = 0;
        for (final nutrient in TrackedNutrient.values) {
          if (nutritionReport.missingNutrients.contains(nutrient) &&
              suppliedNutrients.contains(nutrient)) {
            matchedNutrient ??= nutrient;
            matchedNutrientCount++;
          }
        }

        if (matchedNutrient != null) {
          nutritionCandidates.add(
            ShoppingSuggestion(
              recipe: recipe,
              missingIngredients: missingNames,
              availableIngredientCount: availableCount,
              totalIngredientCount: recipe.ingredients.length,
              source: ShoppingSuggestionSource.nutritionTip,
              missingNutrient: matchedNutrient,
              message: buildMessage(
                recipe: recipe,
                missingIngredients: missingNames,
                source: ShoppingSuggestionSource.nutritionTip,
                missingNutrient: matchedNutrient,
              ),
              timesCooked: timesCooked,
              relevanceScore: matchedNutrientCount.toDouble(),
            ),
          );
        }
      }
    }

    historyCandidates.sort(_compareHistoryCandidates);
    nutritionCandidates.sort(_compareNutritionCandidates);

    return _combineBalanced(
      historyCandidates,
      nutritionCandidates,
      maxSuggestions,
    );
  }

  /// Formats a list of ingredient names naturally in Spanish (`A`, `A y B`).
  static String formatIngredientsList(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} y ${items[1]}';
    return '${items.take(items.length - 1).join(', ')} y ${items.last}';
  }

  /// Formats the actionable Spanish recommendation text for a [ShoppingSuggestion].
  static String buildMessage({
    required Recipe recipe,
    required List<String> missingIngredients,
    required ShoppingSuggestionSource source,
    HealthGoal? matchedGoal,
    TrackedNutrient? missingNutrient,
  }) {
    final itemsText = formatIngredientsList(missingIngredients);
    return switch (source) {
      ShoppingSuggestionSource.favorite =>
        'Si compras $itemsText puedes cocinar ${recipe.title} de tus recetas favoritas',
      ShoppingSuggestionSource.liked =>
        'Si compras $itemsText puedes cocinar ${recipe.title} de las recetas que te gustaron',
      ShoppingSuggestionSource.frequentlyCooked =>
        'Si compras $itemsText puedes cocinar ${recipe.title} de tus recetas frecuentes',
      ShoppingSuggestionSource.healthGoal =>
        'Si compras $itemsText puedes preparar ${recipe.title} para tu meta de '
            '${matchedGoal?.shoppingGoalPhrase ?? 'alimentación saludable'}',
      ShoppingSuggestionSource.nutritionTip =>
        'Si compras $itemsText puedes preparar ${recipe.title} para reforzar tu aporte de '
            '${missingNutrient?.label ?? 'vitaminas'}',
    };
  }

  static int _historySourcePriority(ShoppingSuggestionSource source) {
    return switch (source) {
      ShoppingSuggestionSource.favorite => 3,
      ShoppingSuggestionSource.liked => 2,
      ShoppingSuggestionSource.frequentlyCooked => 1,
      _ => 0,
    };
  }

  static int _nutritionSourcePriority(ShoppingSuggestionSource source) {
    return switch (source) {
      ShoppingSuggestionSource.healthGoal => 2,
      ShoppingSuggestionSource.nutritionTip => 1,
      _ => 0,
    };
  }

  static int _compareHistoryCandidates(
    ShoppingSuggestion a,
    ShoppingSuggestion b,
  ) {
    final missingCmp =
        a.missingIngredients.length.compareTo(b.missingIngredients.length);
    if (missingCmp != 0) return missingCmp;

    final sourceCmp = _historySourcePriority(b.source)
        .compareTo(_historySourcePriority(a.source));
    if (sourceCmp != 0) return sourceCmp;

    final cookedCmp = b.timesCooked.compareTo(a.timesCooked);
    if (cookedCmp != 0) return cookedCmp;

    final coverageCmp = b.pantryCoverage.compareTo(a.pantryCoverage);
    if (coverageCmp != 0) return coverageCmp;

    return a.recipe.title.compareTo(b.recipe.title);
  }

  static int _compareNutritionCandidates(
    ShoppingSuggestion a,
    ShoppingSuggestion b,
  ) {
    final missingCmp =
        a.missingIngredients.length.compareTo(b.missingIngredients.length);
    if (missingCmp != 0) return missingCmp;

    final sourceCmp = _nutritionSourcePriority(b.source)
        .compareTo(_nutritionSourcePriority(a.source));
    if (sourceCmp != 0) return sourceCmp;

    final scoreCmp = b.relevanceScore.compareTo(a.relevanceScore);
    if (scoreCmp != 0) return scoreCmp;

    final coverageCmp = b.pantryCoverage.compareTo(a.pantryCoverage);
    if (coverageCmp != 0) return coverageCmp;

    return a.recipe.title.compareTo(b.recipe.title);
  }

  static List<ShoppingSuggestion> _combineBalanced(
    List<ShoppingSuggestion> historyCandidates,
    List<ShoppingSuggestion> nutritionCandidates,
    int maxSuggestions,
  ) {
    final historyQuota = (maxSuggestions + 1) ~/ 2;
    final nutritionQuota = maxSuggestions ~/ 2;

    final selectedHistory =
        historyCandidates.take(historyQuota).toList();
    final selectedNutrition =
        nutritionCandidates.take(nutritionQuota).toList();

    int remaining =
        maxSuggestions - selectedHistory.length - selectedNutrition.length;

    if (remaining > 0 && historyCandidates.length > selectedHistory.length) {
      final extraHistory = historyCandidates
          .skip(selectedHistory.length)
          .take(remaining)
          .toList();
      selectedHistory.addAll(extraHistory);
      remaining -= extraHistory.length;
    }

    if (remaining > 0 && nutritionCandidates.length > selectedNutrition.length) {
      final extraNutrition = nutritionCandidates
          .skip(selectedNutrition.length)
          .take(remaining)
          .toList();
      selectedNutrition.addAll(extraNutrition);
    }

    return <ShoppingSuggestion>[
      ...selectedHistory,
      ...selectedNutrition,
    ];
  }
}

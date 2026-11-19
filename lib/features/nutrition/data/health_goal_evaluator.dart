import '../../../core/utils/string_normalizer.dart';
import '../domain/health_goal.dart';
import '../domain/nutrition_metadata.dart';
import '../domain/recipe_goal_match.dart';
import '../../recipes/domain/recipe.dart';
import 'nutrition_catalog.dart';

/// Deterministic health-goal alignment and Spanish tooltip generator.
/// Runs 100% locally on device with zero external LLM calls.
class HealthGoalEvaluator {
  HealthGoalEvaluator._();

  static const List<String> _proteinPriorityKeywords = <String>[
    'pechuga de pollo',
    'filete de pescado',
    'filete de tilapia',
    'filete de robalo',
    'salmon',
    'pollo',
    'posta de res',
    'lomo',
    'carne de res',
    'carne molida',
    'huevo',
    'lentejas',
    'frijoles',
    'garbanzos',
    'requeson',
    'yogur griego',
    'queso de capas',
  ];

  static const List<String> _lowCaloriePriorityKeywords = <String>[
    'guisquil',
    'perulero',
    'brocoli',
    'espinaca',
    'pepino',
    'zanahoria',
    'ejote',
    'rabano',
    'lechuga',
    'champinones',
    'coliflor',
    'berenjena',
    'filete de pescado',
    'pechuga de pollo',
    'tomate',
    'manzana',
  ];

  static const List<String> _lowSodiumAromaticKeywords = <String>[
    'limon',
    'cilantro',
    'hierbabuena',
    'epazote',
    'curry',
    'ajo',
    'perejil',
    'oregano',
  ];

  static const List<String> _fiberPriorityKeywords = <String>[
    'espinaca',
    'brocoli',
    'lentejas',
    'frijoles',
    'garbanzos',
    'zanahoria',
    'guisquil',
    'aguacate',
    'chile pimiento',
    'ejote',
    'tomate',
    'naranja',
    'manzana',
    'avena',
  ];

  /// Evaluates how well [recipe] aligns with [activeGoals] and produces specific
  /// Spanish tooltips and net ranking scores.
  static RecipeGoalMatch evaluateRecipe(
    Recipe recipe,
    Set<HealthGoal> activeGoals,
  ) {
    if (activeGoals.isEmpty) {
      return RecipeGoalMatch.empty;
    }

    final profiles = recipe.ingredients
        .map((ing) => NutritionCatalog.evaluateIngredient(ing.name))
        .toList();

    final hasProcessedMeat = profiles.any((p) => p.isProcessedMeat);
    final hasHighSodium = profiles.any((p) => p.isHighSodiumOrProcessed);
    final hasCalorieDense = profiles.any((p) => p.isCalorieDense) ||
        recipe.nutritionAttributes.contains(NutritionalAttribute.calorieDense);

    final nonProcessedProteinProfiles = profiles
        .where((p) => p.isHighProtein && !p.isProcessedMeat)
        .toList();
    final lowCalorieProfiles = profiles
        .where((p) => p.isLowCalorieDensity && !p.isCalorieDense)
        .toList();
    final fiberVitaminProfiles = profiles
        .where((p) => p.isHighFiberOrVitamins || p.nutrients.isNotEmpty)
        .toList();
    final lowSodiumWholeProfiles = profiles
        .where((p) => p.isLowSodiumWholeFood && !p.isHighSodiumOrProcessed)
        .toList();

    final matchedGoals = <HealthGoal>{};
    final reasons = <GoalTooltipReason>[];
    double positiveScore = 0.0;
    double penaltyScore = 0.0;
    int matchedCount = 0;

    void addMatch({
      required HealthGoal goal,
      required String message,
      String? highlightedIngredient,
      required double baseScore,
    }) {
      matchedGoals.add(goal);
      reasons.add(
        GoalTooltipReason(
          goal: goal,
          message: message,
          highlightedIngredient: highlightedIngredient,
        ),
      );
      // Apply mild diminishing returns after the first matched goal so multi-goal
      // alignment boosts priority without overpowering ingredient availability.
      final multiplier = matchedCount == 0 ? 1.0 : 0.75;
      positiveScore += baseScore * multiplier;
      matchedCount++;
    }

    for (final goal in HealthGoal.values) {
      if (!activeGoals.contains(goal)) continue;

      switch (goal) {
        case HealthGoal.gainMuscle:
          final recipeTaggedProtein = recipe.nutritionAttributes
              .contains(NutritionalAttribute.highProtein);
          final hasGoodProtein =
              nonProcessedProteinProfiles.isNotEmpty ||
                  (recipeTaggedProtein && !hasProcessedMeat);
          if (hasGoodProtein) {
            final bestProfile = _pickBestProfile(
              nonProcessedProteinProfiles,
              _proteinPriorityKeywords,
            );
            final reasonText = bestProfile != null
                ? NutritionCatalog.reasonFor(bestProfile, goal)
                : null;
            final message = reasonText ??
                'Este platillo aporta buenas fuentes de proteína para tu objetivo';
            final cleanProteinCount = nonProcessedProteinProfiles
                .where((p) => !p.isCalorieDense && !p.isHighSodiumOrProcessed)
                .length;
            final bonus = cleanProteinCount >= 2 ? 1.5 : 0.0;
            addMatch(
              goal: goal,
              message: message,
              highlightedIngredient: bestProfile?.canonicalName,
              baseScore: 8.0 + bonus,
            );
          }
          break;

        case HealthGoal.loseWeight:
          if (hasCalorieDense || hasProcessedMeat) {
            penaltyScore += 4.0;
            break;
          }
          final recipeTaggedLight = recipe.nutritionAttributes
              .contains(NutritionalAttribute.lowCalorieDensity);
          if (recipeTaggedLight || lowCalorieProfiles.isNotEmpty) {
            final bestProfile = _pickBestProfile(
              lowCalorieProfiles,
              _lowCaloriePriorityKeywords,
            );
            final reasonText = bestProfile != null
                ? NutritionCatalog.reasonFor(bestProfile, goal)
                : null;
            final message = reasonText ??
                'Platillo ligero con ingredientes bajos en densidad calórica';
            final bonus = lowCalorieProfiles.length >= 2 ? 1.5 : 0.0;
            addMatch(
              goal: goal,
              message: message,
              highlightedIngredient: bestProfile?.canonicalName,
              baseScore: 8.0 + bonus,
            );
          }
          break;

        case HealthGoal.reduceSodiumAndProcessed:
          if (hasHighSodium) {
            penaltyScore += hasProcessedMeat ? 8.0 : 5.0;
            break;
          }
          final recipeTaggedWhole = recipe.nutritionAttributes
              .contains(NutritionalAttribute.lowSodiumWholeFood);
          if (recipeTaggedWhole || lowSodiumWholeProfiles.isNotEmpty) {
            final bestProfile = _pickBestProfile(
              lowSodiumWholeProfiles,
              _lowSodiumAromaticKeywords,
            );
            final reasonText = bestProfile != null
                ? NutritionCatalog.reasonFor(bestProfile, goal)
                : null;
            final message = reasonText ??
                'Preparado con ingredientes frescos y naturales sin embutidos ni exceso de sodio';
            addMatch(
              goal: goal,
              message: message,
              highlightedIngredient: bestProfile?.canonicalName,
              baseScore: 7.5,
            );
          }
          break;

        case HealthGoal.increaseVitaminsAndFiber:
          final recipeTaggedFiber = recipe.nutritionAttributes
              .contains(NutritionalAttribute.highFiberOrVitamins);
          if (recipeTaggedFiber || fiberVitaminProfiles.isNotEmpty) {
            final bestProfile = _pickBestFiberProfile(fiberVitaminProfiles);
            final reasonText = bestProfile != null
                ? NutritionCatalog.reasonFor(bestProfile, goal)
                : null;
            final message = reasonText ??
                'Aporta variedad de vegetales y fibra natural para tu alimentación';
            final bonus = fiberVitaminProfiles.length >= 2 ? 1.5 : 0.0;
            addMatch(
              goal: goal,
              message: message,
              highlightedIngredient: bestProfile?.canonicalName,
              baseScore: 7.5 + bonus,
            );
          }
          break;
      }
    }

    return RecipeGoalMatch(
      matchedGoals: matchedGoals,
      reasons: reasons,
      alignmentScore: positiveScore,
      penaltyScore: penaltyScore,
    );
  }

  /// Filters and orders [recipes] matching at least one goal in [activeGoals].
  static List<({Recipe recipe, RecipeGoalMatch goalMatch})> rankRecipesForGoals(
    List<Recipe> recipes,
    Set<HealthGoal> activeGoals, {
    int? limit,
  }) {
    if (activeGoals.isEmpty || recipes.isEmpty) {
      return const [];
    }

    final matched = <({Recipe recipe, RecipeGoalMatch goalMatch})>[];
    for (final recipe in recipes) {
      final goalMatch = evaluateRecipe(recipe, activeGoals);
      if (goalMatch.hasMatch) {
        matched.add((recipe: recipe, goalMatch: goalMatch));
      }
    }

    matched.sort((a, b) {
      final goalCountCompare = b.goalMatch.matchedGoals.length
          .compareTo(a.goalMatch.matchedGoals.length);
      if (goalCountCompare != 0) return goalCountCompare;

      final scoreCompare =
          b.goalMatch.netScore.compareTo(a.goalMatch.netScore);
      if (scoreCompare != 0) return scoreCompare;

      return a.recipe.title.compareTo(b.recipe.title);
    });

    if (limit != null && matched.length > limit) {
      return matched.sublist(0, limit);
    }
    return matched;
  }

  static IngredientNutritionProfile? _pickBestProfile(
    List<IngredientNutritionProfile> candidates,
    List<String> priorityKeywords,
  ) {
    if (candidates.isEmpty) return null;

    int bestScore = -1;
    IngredientNutritionProfile best = candidates.first;

    for (final candidate in candidates) {
      final normalized = StringNormalizer.normalize(candidate.canonicalName);
      int priorityScore = 0;
      for (int i = 0; i < priorityKeywords.length; i++) {
        if (normalized.contains(priorityKeywords[i])) {
          priorityScore = priorityKeywords.length - i;
          break;
        }
      }
      if (priorityScore > bestScore) {
        bestScore = priorityScore;
        best = candidate;
      }
    }
    return best;
  }

  static IngredientNutritionProfile? _pickBestFiberProfile(
    List<IngredientNutritionProfile> candidates,
  ) {
    if (candidates.isEmpty) return null;

    int bestScore = -1;
    IngredientNutritionProfile best = candidates.first;

    for (final candidate in candidates) {
      final normalized = StringNormalizer.normalize(candidate.canonicalName);
      int priorityScore = candidate.nutrients.length * 4;
      for (int i = 0; i < _fiberPriorityKeywords.length; i++) {
        if (normalized.contains(_fiberPriorityKeywords[i])) {
          priorityScore += _fiberPriorityKeywords.length - i;
          break;
        }
      }
      if (priorityScore > bestScore) {
        bestScore = priorityScore;
        best = candidate;
      }
    }
    return best;
  }
}

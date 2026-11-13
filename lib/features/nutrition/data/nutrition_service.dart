import '../../recipes/data/recipe_history_service.dart';
import '../../recipes/domain/recipe.dart';
import '../domain/nutrition_metadata.dart';
import '../domain/nutrition_tip.dart';
import 'nutrition_catalog.dart';

/// Deterministic nutrition heuristics engine evaluating the user's logged
/// recipe cooking history ([RecipeHistoryService]) without external LLM calls.
class NutritionService {
  NutritionService({RecipeHistoryService? historyService})
      : _historyService = historyService ?? RecipeHistoryService();

  final RecipeHistoryService _historyService;

  /// Maximum number of recent cooked meal events analyzed in the sliding window.
  static const int recentMealWindowSize = 10;

  /// Loads persisted recipe cooking history and produces a structured [NutritionReport].
  Future<NutritionReport> generateReport({DateTime? now}) async {
    final referenceNow = now ?? DateTime.now();
    final history = await _historyService.getHistory();
    final knownRecipes = await _historyService.getAllKnownRecipes();
    final recipesById = <String, Recipe>{
      for (final recipe in knownRecipes) recipe.id: recipe,
    };

    final cookedEvents = <({Recipe recipe, DateTime cookedAt})>[];
    for (final record in history.values) {
      if (record.timesCooked <= 0 && record.cookedDates.isEmpty) {
        continue;
      }

      final recipe = recipesById[record.recipeId] ?? record.cachedRecipe;
      if (recipe == null) {
        continue;
      }

      if (record.cookedDates.isNotEmpty) {
        for (final date in record.cookedDates) {
          cookedEvents.add((recipe: recipe, cookedAt: date));
        }
      } else {
        for (int i = 0; i < record.timesCooked; i++) {
          cookedEvents.add((recipe: recipe, cookedAt: referenceNow));
        }
      }
    }

    return evaluateCookedMeals(cookedEvents, now: referenceNow);
  }

  /// Pure deterministic evaluation of cooked meal events across all three rules:
  /// 1. Processed / cured meat health alert
  /// 2. Missing tracked vitamins & recommended catalog fruits/vegetables
  /// 3. Unpaired plant grain / legume incomplete protein detection
  NutritionReport evaluateCookedMeals(
    List<({Recipe recipe, DateTime cookedAt})> cookedMeals, {
    DateTime? now,
  }) {
    if (cookedMeals.isEmpty) {
      return NutritionReport(
        hasCookingHistory: false,
        totalCookedMeals: 0,
        recentMealsEvaluated: 0,
        processedMeatMealsLast7Days: 0,
        processedMeatMealsRecent: 0,
        coveredNutrients: const <TrackedNutrient>{},
        missingNutrients: Set<TrackedNutrient>.from(TrackedNutrient.values),
        tips: _buildFoundationalTips(),
      );
    }

    final referenceNow = now ?? DateTime.now();
    final sortedMeals = List<({Recipe recipe, DateTime cookedAt})>.from(cookedMeals)
      ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));

    final recentMeals = sortedMeals.take(recentMealWindowSize).toList();
    final sevenDaysAgo = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    ).subtract(const Duration(days: 7));

    int processedMeatMealsLast7Days = 0;
    int processedMeatMealsRecent = 0;
    final detectedProcessedMeats = <String>{};
    final coveredNutrients = <TrackedNutrient>{};

    bool hasUnpairedGrainMeal = false;
    bool hasUnpairedLegumeMeal = false;
    final unpairedGrainNames = <String>{};
    final unpairedLegumeNames = <String>{};

    for (final event in sortedMeals) {
      final mealDate = DateTime(
        event.cookedAt.year,
        event.cookedAt.month,
        event.cookedAt.day,
      );
      if (!mealDate.isBefore(sevenDaysAgo) && _recipeContainsProcessedMeat(event.recipe)) {
        processedMeatMealsLast7Days++;
      }
    }

    for (final event in recentMeals) {
      bool mealHasProcessedMeat = false;
      bool mealHasGrain = false;
      bool mealHasLegume = false;
      bool mealHasCompleteAnimal = false;
      final mealGrains = <String>[];
      final mealLegumes = <String>[];

      for (final ingredient in event.recipe.ingredients) {
        final profile = NutritionCatalog.evaluateIngredient(ingredient.name);

        if (profile.isProcessedMeat) {
          mealHasProcessedMeat = true;
          detectedProcessedMeats.add(profile.canonicalName);
        }

        coveredNutrients.addAll(profile.nutrients);

        switch (profile.proteinGroup) {
          case ProteinGroup.plantGrain:
            mealHasGrain = true;
            mealGrains.add(profile.canonicalName);
          case ProteinGroup.plantLegumeOrSeed:
            mealHasLegume = true;
            mealLegumes.add(profile.canonicalName);
          case ProteinGroup.completeAnimal:
            mealHasCompleteAnimal = true;
          case ProteinGroup.none:
            break;
        }
      }

      if (mealHasProcessedMeat) {
        processedMeatMealsRecent++;
      }

      if (mealHasGrain && !mealHasLegume && !mealHasCompleteAnimal) {
        hasUnpairedGrainMeal = true;
        unpairedGrainNames.addAll(mealGrains);
      }
      if (mealHasLegume && !mealHasGrain && !mealHasCompleteAnimal) {
        hasUnpairedLegumeMeal = true;
        unpairedLegumeNames.addAll(mealLegumes);
      }
    }

    final tips = <NutritionTip>[];

    // Rule 1: Processed meats threshold (>= 2 in last 7 days OR >= 30% of recent meals)
    final double recentProcessedRatio =
        recentMeals.isEmpty ? 0.0 : processedMeatMealsRecent / recentMeals.length;
    if (processedMeatMealsLast7Days >= 2 || recentProcessedRatio >= 0.30) {
      final meatExamples = detectedProcessedMeats.take(3).join(', ');
      tips.add(
        NutritionTip(
          id: 'alert_processed_meats',
          category: NutritionTipCategory.healthAlert,
          title: 'Modera el consumo de carnes procesadas',
          message:
              'Tus comidas recientes incluyen con frecuencia embutidos o carnes curadas '
              '($meatExamples). Reducir su frecuencia y alternarlas con pollo fresco, '
              'pescado, huevo o frijoles ayuda a cuidar tu salud cardiovascular a largo plazo.',
        ),
      );
    }

    // Rule 3: Incomplete plant protein pairing recommendation
    if (hasUnpairedGrainMeal || hasUnpairedLegumeMeal) {
      final recommendedComplements = <String>[
        if (hasUnpairedGrainMeal) ...<String>['Frijoles negros', 'Lentejas'],
        if (hasUnpairedLegumeMeal) ...<String>['Arroz blanco', 'Masa de maíz'],
      ];
      final sourceExamples = <String>[
        ...unpairedGrainNames.take(2),
        ...unpairedLegumeNames.take(2),
      ].join(', ');

      tips.add(
        NutritionTip(
          id: 'tip_protein_pairing',
          category: NutritionTipCategory.proteinPairing,
          title: 'Combina granos y legumbres para lograr proteína completa',
          message:
              'Registraste recetas con proteína vegetal individual ($sourceExamples). '
              'Al combinar cereales como arroz o maíz con legumbres como frijoles o lentejas '
              '(por ejemplo, Arroz con Frijoles) obtienes todos los aminoácidos esenciales '
              'de una proteína completa.',
          recommendedIngredients: recommendedComplements,
        ),
      );
    }

    // Rule 2: Missing vitamins & micronutrient recommendations
    final missingNutrients = TrackedNutrient.values
        .where((nutrient) => !coveredNutrients.contains(nutrient))
        .toSet();

    for (final nutrient in TrackedNutrient.values) {
      if (!missingNutrients.contains(nutrient)) continue;
      final sources =
          NutritionCatalog.recommendedSources[nutrient] ?? const <String>[];
      final sampleSources = sources.take(3).toList();
      final sourceText = sampleSources.join(', ');

      tips.add(
        NutritionTip(
          id: 'vitamin_${nutrient.name}',
          category: NutritionTipCategory.vitaminSuggestion,
          title: 'Refuerza tu aporte de ${nutrient.label}',
          message:
              'Tus recetas recientes no incluyen fuentes destacadas de ${nutrient.label}. '
              'Intenta sumar ingredientes frescos como $sourceText a tus próximas compras.',
          nutrient: nutrient,
          recommendedIngredients: sampleSources,
        ),
      );
    }

    return NutritionReport(
      hasCookingHistory: true,
      totalCookedMeals: cookedMeals.length,
      recentMealsEvaluated: recentMeals.length,
      processedMeatMealsLast7Days: processedMeatMealsLast7Days,
      processedMeatMealsRecent: processedMeatMealsRecent,
      coveredNutrients: coveredNutrients,
      missingNutrients: missingNutrients,
      tips: tips,
    );
  }

  bool _recipeContainsProcessedMeat(Recipe recipe) {
    return recipe.ingredients.any(
      (ingredient) =>
          NutritionCatalog.evaluateIngredient(ingredient.name).isProcessedMeat,
    );
  }

  List<NutritionTip> _buildFoundationalTips() {
    return const <NutritionTip>[
      NutritionTip(
        id: 'foundational_protein_pairing',
        category: NutritionTipCategory.foundational,
        title: 'Proteína completa combinando arroz y frijoles',
        message:
            'Unir cereales como arroz o tortillas de maíz con legumbres como frijoles negros '
            'o lentejas aporta todos los aminoácidos esenciales sin necesidad de carne.',
        recommendedIngredients: <String>['Arroz blanco', 'Frijoles negros'],
      ),
      NutritionTip(
        id: 'foundational_vitamins',
        category: NutritionTipCategory.foundational,
        title: 'Variedad diaria de frutas y verduras',
        message:
            'Incluir vegetales verdes como espinaca o brócoli junto con cítricos como naranja '
            'o limón mejora el aporte de Vitamina C, Vitamina K y la absorción de Hierro.',
        recommendedIngredients: <String>['Espinaca', 'Naranja', 'Zanahoria'],
      ),
    ];
  }
}


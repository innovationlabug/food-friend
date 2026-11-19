import '../../recipes/data/local_recipe_dataset.dart';
import '../../recipes/data/recipe_history_service.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_preference.dart';
import '../domain/health_goal.dart';
import '../domain/nutrition_metadata.dart';
import '../domain/nutrition_tip.dart';
import '../domain/recipe_goal_match.dart';
import 'health_goal_evaluator.dart';
import 'health_goal_storage_service.dart';
import 'nutrition_catalog.dart';

/// Deterministic nutrition heuristics engine evaluating the user's selected
/// [HealthGoal]s and logged recipe cooking history ([RecipeHistoryService])
/// without external LLM calls.
class NutritionService {
  NutritionService({
    RecipeHistoryService? historyService,
    HealthGoalStorageService? healthGoalStorageService,
  })  : _historyService = historyService ?? RecipeHistoryService(),
        _healthGoalStorageService =
            healthGoalStorageService ?? HealthGoalStorageService();

  final RecipeHistoryService _historyService;
  final HealthGoalStorageService _healthGoalStorageService;

  /// Maximum number of recent cooked meal events analyzed in the sliding window.
  static const int recentMealWindowSize = 10;

  /// Loads persisted health goals and recipe cooking history to produce a
  /// structured [NutritionReport].
  Future<NutritionReport> generateReport({DateTime? now}) async {
    final referenceNow = now ?? DateTime.now();
    final results = await Future.wait<dynamic>([
      _historyService.getHistory(),
      _historyService.getAllKnownRecipes(),
      _healthGoalStorageService.getSelectedGoals(),
    ]);
    final history = results[0] as Map<String, dynamic>;
    final knownRecipes = results[1] as List<Recipe>;
    final activeGoals = results[2] as Set<HealthGoal>;

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

    final eligibleRecipes = knownRecipes
        .where((r) => history[r.id]?.preference != RecipePreference.never)
        .toList();

    return evaluateCookedMeals(
      cookedEvents,
      activeGoals: activeGoals,
      candidateRecipes: eligibleRecipes,
      now: referenceNow,
    );
  }

  /// Pure deterministic evaluation of cooked meal events and [activeGoals]:
  /// 1. Processed / cured meat health alert
  /// 2. Dynamic goal-oriented recommendations replacing generic static tips
  /// 3. Unpaired plant grain / legume incomplete protein detection
  /// 4. Missing tracked vitamins & recommended catalog fruits/vegetables
  NutritionReport evaluateCookedMeals(
    List<({Recipe recipe, DateTime cookedAt})> cookedMeals, {
    Set<HealthGoal> activeGoals = const <HealthGoal>{},
    List<Recipe>? candidateRecipes,
    DateTime? now,
  }) {
    final orderedGoals = <HealthGoal>{
      for (final goal in HealthGoal.values)
        if (activeGoals.contains(goal)) goal,
    };

    final recipePool = candidateRecipes ?? LocalRecipeDataset.instance.recipes;
    final recommendedGoalRecipes = orderedGoals.isEmpty
        ? const <({Recipe recipe, RecipeGoalMatch goalMatch})>[]
        : HealthGoalEvaluator.rankRecipesForGoals(
            recipePool,
            orderedGoals,
            limit: 4,
          );

    if (cookedMeals.isEmpty) {
      return NutritionReport(
        hasCookingHistory: false,
        totalCookedMeals: 0,
        recentMealsEvaluated: 0,
        processedMeatMealsLast7Days: 0,
        processedMeatMealsRecent: 0,
        coveredNutrients: const <TrackedNutrient>{},
        missingNutrients: Set<TrackedNutrient>.from(TrackedNutrient.values),
        tips: _buildEmptyHistoryGoalTips(orderedGoals),
        activeGoals: orderedGoals,
        recommendedGoalRecipes: recommendedGoalRecipes,
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
    int calorieDenseMealsRecent = 0;
    int proteinMealsRecent = 0;
    int highSodiumMealsRecent = 0;
    final detectedProcessedMeats = <String>{};
    final highSodiumNonMeatItems = <String>{};
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
      bool mealHasHighSodium = false;
      bool mealHasCalorieDense = event.recipe.nutritionAttributes
          .contains(NutritionalAttribute.calorieDense);
      bool mealHasProtein = false;
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
        } else if (profile.isHighSodiumOrProcessed) {
          highSodiumNonMeatItems.add(profile.canonicalName);
        }

        if (profile.isHighSodiumOrProcessed) {
          mealHasHighSodium = true;
        }
        if (profile.isCalorieDense) {
          mealHasCalorieDense = true;
        }
        if (profile.isHighProtein && !profile.isProcessedMeat) {
          mealHasProtein = true;
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
      if (mealHasHighSodium) {
        highSodiumMealsRecent++;
      }
      if (mealHasCalorieDense) {
        calorieDenseMealsRecent++;
      }
      if (mealHasProtein) {
        proteinMealsRecent++;
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
    final bool hasProcessedMeatAlert =
        processedMeatMealsLast7Days >= 2 || recentProcessedRatio >= 0.30;
    if (hasProcessedMeatAlert) {
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

    final missingNutrients = TrackedNutrient.values
        .where((nutrient) => !coveredNutrients.contains(nutrient))
        .toSet();

    // Goal-driven dynamic tips tailored to active goals and cooking history
    if (orderedGoals.isNotEmpty) {
      tips.addAll(
        _buildHistoryGoalTips(
          activeGoals: orderedGoals,
          recentCount: recentMeals.length,
          calorieDenseMealsRecent: calorieDenseMealsRecent,
          proteinMealsRecent: proteinMealsRecent,
          highSodiumMealsRecent: highSodiumMealsRecent,
          highSodiumNonMeatItems: highSodiumNonMeatItems,
          hasProcessedMeatAlert: hasProcessedMeatAlert,
          missingNutrients: missingNutrients,
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
      activeGoals: orderedGoals,
      recommendedGoalRecipes: recommendedGoalRecipes,
    );
  }

  bool _recipeContainsProcessedMeat(Recipe recipe) {
    return recipe.ingredients.any(
      (ingredient) =>
          NutritionCatalog.evaluateIngredient(ingredient.name).isProcessedMeat,
    );
  }

  List<NutritionTip> _buildEmptyHistoryGoalTips(Set<HealthGoal> activeGoals) {
    if (activeGoals.isEmpty) {
      return const <NutritionTip>[];
    }

    return activeGoals.map((goal) {
      final sources =
          (NutritionCatalog.recommendedSourcesForGoal[goal] ?? const <String>[])
              .take(3)
              .toList();
      final sourceText = sources.join(', ');

      return switch (goal) {
        HealthGoal.loseWeight => NutritionTip(
            id: 'goal_guidance_${goal.storageKey}',
            category: NutritionTipCategory.goalGuidance,
            goal: goal,
            title: 'Prioriza platillos ligeros y saciantes',
            message:
                'Para tu meta de bajar calorías, elige preparaciones al vapor, asadas o ensaladas frescas con $sourceText.',
            recommendedIngredients: sources,
          ),
        HealthGoal.gainMuscle => NutritionTip(
            id: 'goal_guidance_${goal.storageKey}',
            category: NutritionTipCategory.goalGuidance,
            goal: goal,
            title: 'Incluye proteína completa en tus comidas',
            message:
                'Para apoyar tu meta de ganar masa muscular, incorpora fuentes de proteína como $sourceText en tus platos diarios.',
            recommendedIngredients: sources,
          ),
        HealthGoal.reduceSodiumAndProcessed => NutritionTip(
            id: 'goal_guidance_${goal.storageKey}',
            category: NutritionTipCategory.goalGuidance,
            goal: goal,
            title: 'Condimenta con ingredientes naturales',
            message:
                'Para reducir sodio y alimentos procesados, sustituye embutidos y consomés por condimentos frescos como $sourceText.',
            recommendedIngredients: sources,
          ),
        HealthGoal.increaseVitaminsAndFiber => NutritionTip(
            id: 'goal_guidance_${goal.storageKey}',
            category: NutritionTipCategory.goalGuidance,
            goal: goal,
            title: 'Suma más vegetales, frutas y legumbres',
            message:
                'Para aumentar vitaminas y fibra en tu dieta, procura incluir $sourceText en tus preparaciones diarias.',
            recommendedIngredients: sources,
          ),
      };
    }).toList();
  }

  List<NutritionTip> _buildHistoryGoalTips({
    required Set<HealthGoal> activeGoals,
    required int recentCount,
    required int calorieDenseMealsRecent,
    required int proteinMealsRecent,
    required int highSodiumMealsRecent,
    required Set<String> highSodiumNonMeatItems,
    required bool hasProcessedMeatAlert,
    required Set<TrackedNutrient> missingNutrients,
  }) {
    final tips = <NutritionTip>[];

    for (final goal in activeGoals) {
      final sources =
          (NutritionCatalog.recommendedSourcesForGoal[goal] ?? const <String>[])
              .take(3)
              .toList();
      final sourceText = sources.join(', ');

      switch (goal) {
        case HealthGoal.loseWeight:
          if (calorieDenseMealsRecent >= 1) {
            final mealPhrase = calorieDenseMealsRecent == 1
                ? '1 comida reciente incluye'
                : '$calorieDenseMealsRecent comidas recientes incluyen';
            tips.add(
              NutritionTip(
                id: 'goal_guidance_${goal.storageKey}',
                category: NutritionTipCategory.goalGuidance,
                goal: goal,
                title: 'Aligera tus recetas recientes',
                message:
                    '$mealPhrase ingredientes altos en calorías (como crema, mantequilla o embutidos). Prefiere preparaciones ligeras con $sourceText.',
                recommendedIngredients: sources,
              ),
            );
          } else {
            tips.add(
              NutritionTip(
                id: 'goal_guidance_${goal.storageKey}',
                category: NutritionTipCategory.goalGuidance,
                goal: goal,
                title: 'Buen ritmo en platos bajos en calorías',
                message:
                    'Tus comidas recientes se mantienen ligeras para tu meta de bajar calorías. Puedes variar con $sourceText.',
                recommendedIngredients: sources,
              ),
            );
          }
          break;

        case HealthGoal.gainMuscle:
          if (proteinMealsRecent < recentCount) {
            tips.add(
              NutritionTip(
                id: 'goal_guidance_${goal.storageKey}',
                category: NutritionTipCategory.goalGuidance,
                goal: goal,
                title: 'Refuerza la proteína en cada comida',
                message:
                    'Solo $proteinMealsRecent de tus últimas $recentCount comidas aportan buena proteína. Agrega $sourceText para alcanzar tu meta muscular.',
                recommendedIngredients: sources,
              ),
            );
          } else {
            tips.add(
              NutritionTip(
                id: 'goal_guidance_${goal.storageKey}',
                category: NutritionTipCategory.goalGuidance,
                goal: goal,
                title: 'Excelente constancia proteica',
                message:
                    'Todas tus comidas recientes ($recentCount) incluyen buenas fuentes de proteína. Mantén la variedad alternando con $sourceText.',
                recommendedIngredients: sources,
              ),
            );
          }
          break;

        case HealthGoal.reduceSodiumAndProcessed:
          if (highSodiumMealsRecent > 0) {
            final String detail;
            if (highSodiumNonMeatItems.isNotEmpty) {
              final items = highSodiumNonMeatItems.take(2).join(', ');
              detail =
                  'Además de evitar embutidos, modera ingredientes altos en sodio como $items. Sazona naturalmente con $sourceText.';
            } else if (!hasProcessedMeatAlert) {
              detail =
                  'Detectamos ingredientes altos en sodio o procesados en tus comidas recientes. Sustitúyelos por opciones naturales con $sourceText.';
            } else {
              detail =
                  'Para reforzar tu meta sin sodio añadido, apóyate en hierbas y cítricos frescos como $sourceText en lugar de embutidos.';
            }
            tips.add(
              NutritionTip(
                id: 'goal_guidance_${goal.storageKey}',
                category: NutritionTipCategory.goalGuidance,
                goal: goal,
                title: 'Controla el sodio en tus preparaciones',
                message: detail,
                recommendedIngredients: sources,
              ),
            );
          } else {
            tips.add(
              NutritionTip(
                id: 'goal_guidance_${goal.storageKey}',
                category: NutritionTipCategory.goalGuidance,
                goal: goal,
                title: 'Alimentación natural y baja en sodio',
                message:
                    'Tus comidas recientes están libres de embutidos y excesos de sodio. Sigue sazonando con $sourceText.',
                recommendedIngredients: sources,
              ),
            );
          }
          break;

        case HealthGoal.increaseVitaminsAndFiber:
          if (missingNutrients.isNotEmpty) {
            final missingText =
                missingNutrients.take(2).map((n) => n.label).join(' y ');
            tips.add(
              NutritionTip(
                id: 'goal_guidance_${goal.storageKey}',
                category: NutritionTipCategory.goalGuidance,
                goal: goal,
                title: 'Impulsa vitaminas y fibra faltantes',
                message:
                    'Para completar tu meta de vitaminas y fibra, suma fuentes ricas en $missingText como $sourceText.',
                recommendedIngredients: sources,
              ),
            );
          } else {
            tips.add(
              NutritionTip(
                id: 'goal_guidance_${goal.storageKey}',
                category: NutritionTipCategory.goalGuidance,
                goal: goal,
                title: 'Gran variedad de vitaminas y fibra',
                message:
                    'Has cubierto todas las vitaminas clave en tus comidas recientes. Mantén la variedad con $sourceText.',
                recommendedIngredients: sources,
              ),
            );
          }
          break;
      }
    }

    return tips;
  }
}

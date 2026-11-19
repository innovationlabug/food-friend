import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/data/ingredient_catalog.dart';
import 'package:food_friend/features/nutrition/data/health_goal_evaluator.dart';
import 'package:food_friend/features/nutrition/data/health_goal_storage_service.dart';
import 'package:food_friend/features/nutrition/data/nutrition_catalog.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/nutrition/domain/nutrition_metadata.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:shared_preferences/shared_preferences.dart';

Recipe _makeCustomRecipe(
  String id,
  String title,
  List<String> ingredientNames, {
  Set<NutritionalAttribute> attributes = const <NutritionalAttribute>{},
}) {
  return Recipe(
    id: id,
    title: title,
    ingredients: ingredientNames
        .map((n) => RecipeIngredient(name: n, displayAmount: '1 porción'))
        .toList(),
    instructions: const <String>['Preparar.'],
    nutritionAttributes: attributes,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FEAT-2: HealthGoalStorageService local persistence', () {
    test('defaults to empty set and persists selected goals across instances',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage1 = HealthGoalStorageService(preferences: prefs);

      expect(await storage1.getSelectedGoals(), isEmpty);

      final saved = await storage1.saveSelectedGoals({
        HealthGoal.increaseVitaminsAndFiber,
        HealthGoal.gainMuscle,
      });
      // Ordered consistently according to HealthGoal.values
      expect(
        saved.toList(),
        equals([
          HealthGoal.gainMuscle,
          HealthGoal.increaseVitaminsAndFiber,
        ]),
      );

      final storage2 = HealthGoalStorageService(preferences: prefs);
      final reloaded = await storage2.getSelectedGoals();
      expect(
        reloaded,
        equals({
          HealthGoal.gainMuscle,
          HealthGoal.increaseVitaminsAndFiber,
        }),
      );
    });

    test('toggleGoal adds and removes goals and clearGoals resets state',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = HealthGoalStorageService(preferences: prefs);

      final afterFirst = await storage.toggleGoal(HealthGoal.loseWeight);
      expect(afterFirst, equals({HealthGoal.loseWeight}));

      final afterSecond =
          await storage.toggleGoal(HealthGoal.reduceSodiumAndProcessed);
      expect(
        afterSecond,
        equals({
          HealthGoal.loseWeight,
          HealthGoal.reduceSodiumAndProcessed,
        }),
      );

      final afterToggleOff = await storage.toggleGoal(HealthGoal.loseWeight);
      expect(afterToggleOff, equals({HealthGoal.reduceSodiumAndProcessed}));

      await storage.clearGoals();
      expect(await storage.getSelectedGoals(), isEmpty);
    });

    test('ignores unknown or corrupted persisted goal keys gracefully',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(HealthGoalStorageService.storageKey, [
        'invalid_goal_key',
        HealthGoal.gainMuscle.storageKey,
        'legacy_removed_goal',
      ]);

      final storage = HealthGoalStorageService(preferences: prefs);
      expect(
        await storage.getSelectedGoals(),
        equals({HealthGoal.gainMuscle}),
      );
    });
  });

  group('FEAT-2: NutritionCatalog structured attributes & goal sources', () {
    test(
        'every recommendedSourcesForGoal ingredient resolves to an exact IngredientCatalog entry',
        () {
      final allCatalogNames = IngredientCatalog.instance.allIngredients.toSet();

      for (final goal in HealthGoal.values) {
        final sources = NutritionCatalog.recommendedSourcesForGoal[goal];
        expect(sources, isNotNull);
        expect(sources, isNotEmpty);
        for (final source in sources!) {
          expect(
            allCatalogNames.contains(source),
            isTrue,
            reason:
                '$source for ${goal.label} must exist in IngredientCatalog',
          );
        }
      }
    });

    test('classifies high-protein, low-calorie, fiber, whole-food, and conflicting items',
        () {
      final chicken = NutritionCatalog.evaluateIngredient('Pechuga de pollo');
      expect(chicken.isHighProtein, isTrue);
      expect(chicken.isLowCalorieDensity, isTrue);
      expect(chicken.isLowSodiumWholeFood, isTrue);
      expect(chicken.isHighSodiumOrProcessed, isFalse);

      final guisquil = NutritionCatalog.evaluateIngredient('Güisquil');
      expect(guisquil.isLowCalorieDensity, isTrue);
      expect(guisquil.isHighFiberOrVitamins, isTrue);
      expect(guisquil.isCalorieDense, isFalse);

      final crema = NutritionCatalog.evaluateIngredient('Crema pura');
      expect(crema.isCalorieDense, isTrue);

      final parmesan = NutritionCatalog.evaluateIngredient('Queso parmesano');
      expect(parmesan.isHighProtein, isTrue);
      expect(parmesan.isHighSodiumOrProcessed, isTrue);

      final chorizo = NutritionCatalog.evaluateIngredient('Chorizo colorado');
      expect(chorizo.isProcessedMeat, isTrue);
      expect(chorizo.isHighSodiumOrProcessed, isTrue);
      expect(chorizo.isCalorieDense, isTrue);
    });
  });

  group('FEAT-2: HealthGoalEvaluator deterministic matching & tooltips', () {
    test('matches gainMuscle with specific Spanish protein tooltip and excludes non-protein salads',
        () {
      final dataset = LocalRecipeDataset.instance;
      final polloPlancha = dataset.getRecipeById('pollo_plancha_vegetales')!;
      final ensalada = dataset.getRecipeById('ensalada_aguacate_tomate')!;

      final chickenMatch = HealthGoalEvaluator.evaluateRecipe(
        polloPlancha,
        {HealthGoal.gainMuscle},
      );
      expect(chickenMatch.hasMatch, isTrue);
      expect(chickenMatch.matchedGoals, contains(HealthGoal.gainMuscle));
      expect(
        chickenMatch.primaryReason,
        equals('La pechuga de pollo es una excelente fuente de proteína'),
      );
      expect(chickenMatch.netScore, greaterThan(0));

      final saladMatch = HealthGoalEvaluator.evaluateRecipe(
        ensalada,
        {HealthGoal.gainMuscle},
      );
      expect(saladMatch.hasMatch, isFalse);
      expect(saladMatch.primaryReason, isNull);
    });

    test('matches loseWeight for light recipes and penalizes calorie-dense recipes',
        () {
      final dataset = LocalRecipeDataset.instance;
      final caldo = dataset.getRecipeById('caldo_pollo_verduras')!;
      final pastaGouda = dataset.getRecipeById('pasta_gouda_espinaca')!;

      final lightMatch = HealthGoalEvaluator.evaluateRecipe(
        caldo,
        {HealthGoal.loseWeight},
      );
      expect(lightMatch.hasMatch, isTrue);
      expect(
        lightMatch.primaryReason,
        equals('El güisquil contiene pocas calorías y aporta fibra'),
      );
      expect(lightMatch.netScore, greaterThan(0));

      final heavyMatch = HealthGoalEvaluator.evaluateRecipe(
        pastaGouda,
        {HealthGoal.loseWeight},
      );
      expect(heavyMatch.hasMatch, isFalse);
      expect(heavyMatch.penaltyScore, greaterThan(0));
      expect(heavyMatch.netScore, lessThan(0));
    });

    test('matches reduceSodiumAndProcessed for whole-food dishes and penalizes processed/high-sodium dishes',
        () {
      final dataset = LocalRecipeDataset.instance;
      final pescado = dataset.getRecipeById('pescado_limon_cilantro')!;
      final pechugaParmesano =
          dataset.getRecipeById('pechuga_parmesano_tomate')!;
      final processedDish = _makeCustomRecipe(
        'proc_meal',
        'Huevos con salchicha',
        ['Salchicha', 'Huevo'],
      );

      final pescadoMatch = HealthGoalEvaluator.evaluateRecipe(
        pescado,
        {HealthGoal.reduceSodiumAndProcessed},
      );
      expect(pescadoMatch.hasMatch, isTrue);
      expect(
        pescadoMatch.primaryReason,
        equals('El limón realza el sabor de forma natural sin agregar sodio'),
      );

      final parmesanMatch = HealthGoalEvaluator.evaluateRecipe(
        pechugaParmesano,
        {HealthGoal.reduceSodiumAndProcessed},
      );
      expect(parmesanMatch.hasMatch, isFalse);
      expect(parmesanMatch.netScore, lessThan(0));

      final procMatch = HealthGoalEvaluator.evaluateRecipe(
        processedDish,
        {HealthGoal.reduceSodiumAndProcessed},
      );
      expect(procMatch.hasMatch, isFalse);
      expect(procMatch.penaltyScore, greaterThanOrEqualTo(8.0));
    });

    test('matches increaseVitaminsAndFiber and generates multi-goal combined tooltips',
        () {
      final dataset = LocalRecipeDataset.instance;
      final sopaLentejas = dataset.getRecipeById('sopa_lentejas_espinaca')!;

      final multiMatch = HealthGoalEvaluator.evaluateRecipe(
        sopaLentejas,
        {
          HealthGoal.gainMuscle,
          HealthGoal.increaseVitaminsAndFiber,
        },
      );

      expect(multiMatch.hasMatch, isTrue);
      expect(
        multiMatch.matchedGoals,
        equals({
          HealthGoal.gainMuscle,
          HealthGoal.increaseVitaminsAndFiber,
        }),
      );
      expect(multiMatch.reasons.length, equals(2));
      expect(multiMatch.combinedTooltipMessage, contains('•'));
      expect(multiMatch.combinedTooltipMessage, contains('lentejas'));
      expect(multiMatch.combinedTooltipMessage, contains('espinaca'));
    });

    test('evaluates unannotated external recipes deterministically via ingredient fallback',
        () {
      final externalRecipe = _makeCustomRecipe(
        'ext_fish_salad',
        'Filete de tilapia con brócoli y limón',
        ['Filete de tilapia', 'Brócoli', 'Limón'],
      );

      final match = HealthGoalEvaluator.evaluateRecipe(
        externalRecipe,
        {
          HealthGoal.loseWeight,
          HealthGoal.gainMuscle,
          HealthGoal.reduceSodiumAndProcessed,
          HealthGoal.increaseVitaminsAndFiber,
        },
      );

      expect(match.hasMatch, isTrue);
      expect(match.matchedGoals.length, equals(4));
      expect(match.reasons.length, equals(4));
      for (final reason in match.reasons) {
        expect(reason.message.trim(), isNotEmpty);
      }
    });
  });
}

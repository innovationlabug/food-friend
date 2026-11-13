import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_catalog.dart';
import 'package:food_friend/features/nutrition/data/nutrition_catalog.dart';
import 'package:food_friend/features/nutrition/data/nutrition_service.dart';
import 'package:food_friend/features/nutrition/domain/nutrition_metadata.dart';
import 'package:food_friend/features/nutrition/domain/nutrition_tip.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';

Recipe _makeRecipe(String id, String title, List<String> ingredientNames) {
  return Recipe(
    id: id,
    title: title,
    ingredients: ingredientNames
        .map((name) => RecipeIngredient(name: name, displayAmount: '1 porción'))
        .toList(),
    instructions: const <String>['Paso 1'],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('US-9.1: NutritionCatalog metadata tags', () {
    test('flags expected processed and cured meats', () {
      const expectedProcessed = <String>[
        'Salchicha',
        'Jamón',
        'Jamón de pavo',
        'Chorizo',
        'Chorizo colorado',
        'Longaniza',
        'Longaniza guatemalteca',
        'Tocino',
        'Mortadela',
        'Salami',
      ];

      for (final name in expectedProcessed) {
        final profile = NutritionCatalog.evaluateIngredient(name);
        expect(profile.isProcessedMeat, isTrue, reason: '$name should be flagged');
      }

      expect(NutritionCatalog.evaluateIngredient('Pechuga de pollo').isProcessedMeat, isFalse);
      expect(NutritionCatalog.evaluateIngredient('Frijoles negros').isProcessedMeat, isFalse);
    });

    test('distinguishes plant grains from plant legumes and complete animal proteins', () {
      expect(
        NutritionCatalog.evaluateIngredient('Arroz blanco').proteinGroup,
        equals(ProteinGroup.plantGrain),
      );
      expect(
        NutritionCatalog.evaluateIngredient('Tortillas de maíz').proteinGroup,
        equals(ProteinGroup.plantGrain),
      );
      expect(
        NutritionCatalog.evaluateIngredient('Avena').proteinGroup,
        equals(ProteinGroup.plantGrain),
      );
      expect(
        NutritionCatalog.evaluateIngredient('Frijoles negros').proteinGroup,
        equals(ProteinGroup.plantLegumeOrSeed),
      );
      expect(
        NutritionCatalog.evaluateIngredient('Lentejas').proteinGroup,
        equals(ProteinGroup.plantLegumeOrSeed),
      );
      expect(
        NutritionCatalog.evaluateIngredient('Pollo').proteinGroup,
        equals(ProteinGroup.completeAnimal),
      );
    });

    test('every recommended vitamin food source resolves to an exact IngredientCatalog entry', () {
      final allCatalogNames = IngredientCatalog.instance.allIngredients.toSet();

      for (final entry in NutritionCatalog.recommendedSources.entries) {
        expect(entry.value, isNotEmpty);
        for (final source in entry.value) {
          expect(
            allCatalogNames.contains(source),
            isTrue,
            reason: '$source for ${entry.key.label} must exist in IngredientCatalog',
          );
        }
      }
    });
  });

  group('US-9.1: Deterministic NutritionService heuristics', () {
    final service = NutritionService();
    final now = DateTime(2026, 11, 13, 12, 0);

    test('returns foundational Spanish tips when cooking history is empty', () {
      final report = service.evaluateCookedMeals(const [], now: now);

      expect(report.hasCookingHistory, isFalse);
      expect(report.totalCookedMeals, equals(0));
      expect(report.tips, isNotEmpty);
      expect(
        report.tips.every((t) => t.category == NutritionTipCategory.foundational),
        isTrue,
      );
    });

    test('Rule 1: triggers processed meat alert at >= 2 meals in 7 days or >= 30% recent ratio',
        () {
      // Case A: 2 meals with processed meat in last 7 days among 8 meals (25% ratio, >=2 in 7d)
      final eightMealsWithTwoProcessed = <({Recipe recipe, DateTime cookedAt})>[
        (
          recipe: _makeRecipe('p1', 'Desayuno con salchicha', ['Salchicha', 'Huevo']),
          cookedAt: now.subtract(const Duration(days: 1)),
        ),
        (
          recipe: _makeRecipe('p2', 'Arroz con chorizo', ['Chorizo colorado', 'Arroz blanco']),
          cookedAt: now.subtract(const Duration(days: 3)),
        ),
        for (int i = 0; i < 6; i++)
          (
            recipe: _makeRecipe('h$i', 'Pollo guisado', ['Pollo', 'Tomate', 'Espinaca']),
            cookedAt: now.subtract(const Duration(days: 4)),
          ),
      ];
      final reportA = service.evaluateCookedMeals(eightMealsWithTwoProcessed, now: now);
      expect(reportA.processedMeatMealsLast7Days, equals(2));
      expect(
        reportA.tips.any((t) => t.category == NutritionTipCategory.healthAlert),
        isTrue,
      );

      // Case B: 1 processed meat meal 12 days ago out of 3 meals total (33% >= 30% recent ratio)
      final threeMealsOneOldProcessed = <({Recipe recipe, DateTime cookedAt})>[
        (
          recipe: _makeRecipe('old_p', 'Sándwich de mortadela', ['Mortadela']),
          cookedAt: now.subtract(const Duration(days: 12)),
        ),
        (
          recipe: _makeRecipe('c1', 'Pollo con brócoli', ['Pollo', 'Brócoli']),
          cookedAt: now.subtract(const Duration(days: 2)),
        ),
        (
          recipe: _makeRecipe('c2', 'Huevos con espinaca', ['Huevo', 'Espinaca']),
          cookedAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      final reportB = service.evaluateCookedMeals(threeMealsOneOldProcessed, now: now);
      expect(reportB.processedMeatMealsLast7Days, equals(0));
      expect(reportB.processedMeatMealsRecent, equals(1));
      expect(
        reportB.tips.any((t) => t.category == NutritionTipCategory.healthAlert),
        isTrue,
      );

      // Case C: 1 processed meat meal out of 5 meals (20% < 30%, < 2 in 7d) -> no alert
      final fiveMealsOneProcessed = <({Recipe recipe, DateTime cookedAt})>[
        (
          recipe: _makeRecipe('p_single', 'Huevos con jamón', ['Jamón', 'Huevo']),
          cookedAt: now.subtract(const Duration(days: 2)),
        ),
        for (int i = 0; i < 4; i++)
          (
            recipe: _makeRecipe('healthy$i', 'Caldo nutritivo', ['Pollo', 'Zanahoria']),
            cookedAt: now.subtract(const Duration(days: 1)),
          ),
      ];
      final reportC = service.evaluateCookedMeals(fiveMealsOneProcessed, now: now);
      expect(
        reportC.tips.any((t) => t.category == NutritionTipCategory.healthAlert),
        isFalse,
      );
    });

    test('Rule 2: detects missing vitamins and suggests specific catalog fruits/vegetables', () {
      // Pollo + Tomate + Naranja covers Vitamin A, Vitamin C, Potassium -> Iron & Vitamin K missing
      final meals = <({Recipe recipe, DateTime cookedAt})>[
        (
          recipe: _makeRecipe('m1', 'Ensalada cítrica', ['Pollo', 'Tomate', 'Naranja']),
          cookedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final report = service.evaluateCookedMeals(meals, now: now);
      expect(report.coveredNutrients, contains(TrackedNutrient.vitaminA));
      expect(report.coveredNutrients, contains(TrackedNutrient.vitaminC));
      expect(report.coveredNutrients, contains(TrackedNutrient.potassium));
      expect(report.missingNutrients, containsAll([TrackedNutrient.vitaminKFolate, TrackedNutrient.iron]));

      final vitaminTips = report.tips
          .where((t) => t.category == NutritionTipCategory.vitaminSuggestion)
          .toList();
      expect(vitaminTips.length, equals(2));
      for (final tip in vitaminTips) {
        expect(tip.recommendedIngredients, isNotEmpty);
      }

      // Covering all 5 nutrients leaves 0 missing vitamin tips
      final completeMeals = <({Recipe recipe, DateTime cookedAt})>[
        (
          recipe: _makeRecipe('all', 'Plato completo', ['Espinaca', 'Naranja', 'Tomate']),
          cookedAt: now,
        ),
      ];
      final fullReport = service.evaluateCookedMeals(completeMeals, now: now);
      expect(fullReport.missingNutrients, isEmpty);
      expect(
        fullReport.tips.where((t) => t.category == NutritionTipCategory.vitaminSuggestion),
        isEmpty,
      );
    });

    test('Rule 3: recommends grain + legume pairing only when plant proteins are unpaired', () {
      // Unpaired grain (Arroz blanco + Tomate, no beans/meat)
      final unpairedGrainReport = service.evaluateCookedMeals([
        (
          recipe: _makeRecipe('g1', 'Arroz rojo sencillo', ['Arroz blanco', 'Tomate']),
          cookedAt: now,
        ),
      ], now: now);
      final grainTips = unpairedGrainReport.tips
          .where((t) => t.category == NutritionTipCategory.proteinPairing)
          .toList();
      expect(grainTips.length, equals(1));
      expect(grainTips.first.recommendedIngredients, contains('Frijoles negros'));

      // Unpaired legume (Frijoles negros + Cebolla, no grain/meat)
      final unpairedLegumeReport = service.evaluateCookedMeals([
        (
          recipe: _makeRecipe('l1', 'Frijoles parados', ['Frijoles negros', 'Cebolla blanca']),
          cookedAt: now,
        ),
      ], now: now);
      final legumeTips = unpairedLegumeReport.tips
          .where((t) => t.category == NutritionTipCategory.proteinPairing)
          .toList();
      expect(legumeTips.length, equals(1));
      expect(legumeTips.first.recommendedIngredients, contains('Arroz blanco'));

      // Paired Arroz blanco + Frijoles negros in the same meal -> no incomplete protein tip
      final pairedReport = service.evaluateCookedMeals([
        (
          recipe: _makeRecipe('p', 'Casamiento', ['Arroz blanco', 'Frijoles negros']),
          cookedAt: now,
        ),
      ], now: now);
      expect(
        pairedReport.tips.where((t) => t.category == NutritionTipCategory.proteinPairing),
        isEmpty,
      );

      // Grain paired with complete animal protein -> no incomplete protein tip
      final animalPairedReport = service.evaluateCookedMeals([
        (
          recipe: _makeRecipe('ap', 'Arroz con pollo', ['Arroz blanco', 'Pechuga de pollo']),
          cookedAt: now,
        ),
      ], now: now);
      expect(
        animalPairedReport.tips.where((t) => t.category == NutritionTipCategory.proteinPairing),
        isEmpty,
      );
    });

    test('generateReport reads cooked history from RecipeHistoryService persistence', () async {
      final prefs = await SharedPreferences.getInstance();
      final historyService = RecipeHistoryService(preferences: prefs);
      final nutritionService = NutritionService(historyService: historyService);

      await historyService.recordCooked(
        _makeRecipe('ext_1', 'Desayuno rápido', ['Salchicha', 'Tortillas de maíz']),
        cookedAt: now.subtract(const Duration(days: 1)),
      );
      await historyService.recordCooked(
        _makeRecipe('ext_2', 'Refacción con arroz', ['Arroz blanco']),
        cookedAt: now,
      );

      final report = await nutritionService.generateReport(now: now);
      expect(report.hasCookingHistory, isTrue);
      expect(report.totalCookedMeals, equals(2));
      expect(
        report.tips.any((t) => t.category == NutritionTipCategory.healthAlert),
        isTrue,
      );
      expect(
        report.tips.any((t) => t.category == NutritionTipCategory.proteinPairing),
        isTrue,
      );
      expect(
        report.tips.any((t) => t.category == NutritionTipCategory.vitaminSuggestion),
        isTrue,
      );
    });
  });
}

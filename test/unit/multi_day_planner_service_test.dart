import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/nutrition/domain/nutrition_metadata.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/data/multi_day_planner_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_history_record.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/recipes/domain/recipe_variation.dart';

void main() {
  group('FEAT-9: MultiDayPlannerService', () {
    late MultiDayPlannerService service;

    setUp(() {
      service = MultiDayPlannerService();
    });

    test('generates 2 to 7 day plans with clamped boundaries and no consecutive repeats', () {
      for (final requestedDays in [1, 2, 3, 5, 7, 10]) {
        final plan = service.generatePlan(
          daysCount: requestedDays,
          availableIngredientNames: const [
            'Pollo',
            'Tomate',
            'Cebolla blanca',
            'Ajo',
            'Güisquil',
          ],
        );

        final expectedDays = requestedDays.clamp(2, 7);
        expect(plan.daysCount, equals(expectedDays));
        expect(plan.days.length, equals(expectedDays));

        for (int i = 0; i < plan.days.length; i++) {
          expect(plan.days[i].dayNumber, equals(i + 1));
          expect(plan.days[i].dayLabel, equals('Día ${i + 1}'));
          if (i > 0) {
            expect(
              plan.days[i].recipe.id,
              isNot(equals(plan.days[i - 1].recipe.id)),
              reason: 'Consecutive days must never repeat the same recipe',
            );
          }
        }
      }
    });

    test('alternates without consecutive repetition even when pool has only 2 recipes', () {
      const twoRecipePool = <Recipe>[
        Recipe(
          id: 'r_a',
          title: 'Receta A',
          category: 'Almuerzo',
          ingredients: [RecipeIngredient(name: 'Pollo', displayAmount: '1 lb')],
          instructions: ['Cocinar A'],
        ),
        Recipe(
          id: 'r_b',
          title: 'Receta B',
          category: 'Almuerzo',
          ingredients: [RecipeIngredient(name: 'Pollo', displayAmount: '1 lb')],
          instructions: ['Cocinar B'],
        ),
      ];

      final plan = service.generatePlan(
        daysCount: 5,
        availableIngredientNames: const ['Pollo'],
        recipePool: twoRecipePool,
      );

      expect(plan.days.length, equals(5));
      for (int i = 1; i < plan.days.length; i++) {
        expect(plan.days[i].recipe.id, isNot(equals(plan.days[i - 1].recipe.id)));
      }
    });

    test('prioritizes shared pantry ingredients and links recipe variations across days', () {
      const customPool = <Recipe>[
        Recipe(
          id: 'base_pollo',
          title: 'Pollo Guisado Base',
          category: 'Almuerzo',
          ingredients: [
            RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
            RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
            RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1 unidad'),
          ],
          instructions: ['Preparar pollo guisado.'],
          variations: [
            RecipeVariation(
              recipeId: 'var_pollo_caldo',
              title: 'Caldo de Pollo',
              description: 'Misma base en caldo ligero.',
              swappedIngredients: ['Güisquil'],
            ),
          ],
        ),
        Recipe(
          id: 'var_pollo_caldo',
          title: 'Caldo Ligero de Pollo',
          category: 'Almuerzo',
          ingredients: [
            RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
            RecipeIngredient(name: 'Cebolla blanca', displayAmount: '1 unidad'),
            RecipeIngredient(name: 'Güisquil', displayAmount: '1 unidad'),
          ],
          instructions: ['Hervir en caldo.'],
        ),
        Recipe(
          id: 'pescado_aislado',
          title: 'Pescado Aislado',
          category: 'Almuerzo',
          ingredients: [
            RecipeIngredient(name: 'Pescado', displayAmount: '1 lb'),
            RecipeIngredient(name: 'Limón', displayAmount: '2 unidades'),
          ],
          instructions: ['Asar pescado.'],
        ),
      ];

      final plan = service.generatePlan(
        daysCount: 2,
        availableIngredientNames: const ['Pollo', 'Tomate', 'Cebolla blanca'],
        recipePool: customPool,
      );

      expect(plan.days.length, equals(2));
      expect(plan.days[0].recipe.id, equals('base_pollo'));
      expect(plan.days[1].recipe.id, equals('var_pollo_caldo'));
      expect(plan.days[1].isVariation, isTrue);
      expect(plan.days[1].baseRecipe?.id, equals('base_pollo'));
      expect(plan.days[1].sharedIngredientsWithPreviousDays, containsAll(['Pollo', 'Cebolla blanca']));
      expect(plan.sharedCoreIngredients, containsAll(['Pollo', 'Cebolla blanca']));
    });

    test('excludes Nunca recipes, defers Disliked recipes, and prioritizes Favorite & health goals', () {
      const pool = <Recipe>[
        Recipe(
          id: 'never_dish',
          title: 'Pollo Oculto',
          category: 'Almuerzo',
          ingredients: [
            RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
            RecipeIngredient(name: 'Güisquil', displayAmount: '1 unidad'),
          ],
          instructions: ['Cocinar'],
          nutritionAttributes: {NutritionalAttribute.highProtein},
        ),
        Recipe(
          id: 'fav_dish',
          title: 'Pollo Favorito',
          category: 'Almuerzo',
          ingredients: [
            RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
            RecipeIngredient(name: 'Zanahoria', displayAmount: '1 unidad'),
          ],
          instructions: ['Cocinar'],
          nutritionAttributes: {
            NutritionalAttribute.highProtein,
            NutritionalAttribute.lowCalorieDensity,
          },
        ),
        Recipe(
          id: 'disliked_dish',
          title: 'Pollo No Gustó',
          category: 'Almuerzo',
          ingredients: [
            RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
          ],
          instructions: ['Cocinar'],
        ),
        Recipe(
          id: 'goal_dish',
          title: 'Ensalada Proteica de Pollo y Güisquil',
          category: 'Almuerzo',
          ingredients: [
            RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
            RecipeIngredient(name: 'Güisquil', displayAmount: '1 unidad'),
          ],
          instructions: ['Cocinar'],
          nutritionAttributes: {
            NutritionalAttribute.highProtein,
            NutritionalAttribute.lowCalorieDensity,
          },
        ),
      ];

      final history = <String, RecipeHistoryRecord>{
        'never_dish': const RecipeHistoryRecord(
          recipeId: 'never_dish',
          preference: RecipePreference.never,
        ),
        'fav_dish': const RecipeHistoryRecord(
          recipeId: 'fav_dish',
          preference: RecipePreference.favorite,
        ),
        'disliked_dish': const RecipeHistoryRecord(
          recipeId: 'disliked_dish',
          preference: RecipePreference.disliked,
        ),
      };

      final plan = service.generatePlan(
        daysCount: 2,
        availableIngredientNames: const ['Pechuga de pollo', 'Güisquil'],
        recipePool: pool,
        history: history,
        activeHealthGoals: const {HealthGoal.gainMuscle, HealthGoal.loseWeight},
      );

      final selectedIds = plan.days.map((d) => d.recipe.id).toList();
      expect(selectedIds, isNot(contains('never_dish')));
      expect(selectedIds, isNot(contains('disliked_dish')));
      expect(selectedIds, containsAll(['fav_dish', 'goal_dish']));
      expect(plan.days.any((d) => d.goalMatch.hasMatch), isTrue);
    });

    test('aggregates and deduplicates missing ingredients across the entire multi-day plan', () {
      const pool = <Recipe>[
        Recipe(
          id: 'day1',
          title: 'Plato 1',
          ingredients: [
            RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
            RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
            RecipeIngredient(name: 'Cilantro', displayAmount: '1 manojo'),
          ],
          instructions: ['Paso 1'],
        ),
        Recipe(
          id: 'day2',
          title: 'Plato 2',
          ingredients: [
            RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
            RecipeIngredient(name: 'tomate', displayAmount: '3 unidades'),
            RecipeIngredient(name: 'Huevo', displayAmount: '2 unidades'),
          ],
          instructions: ['Paso 2'],
        ),
        Recipe(
          id: 'day3',
          title: 'Plato 3',
          ingredients: [
            RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
            RecipeIngredient(name: 'Huevos', displayAmount: '2 unidades'),
            RecipeIngredient(name: 'Limón', displayAmount: '1 unidad'),
          ],
          instructions: ['Paso 3'],
        ),
      ];

      final plan = service.generatePlan(
        daysCount: 3,
        availableIngredientNames: const ['Pollo'],
        recipePool: pool,
      );

      final missingNames =
          plan.consolidatedMissingIngredients.map((i) => i.name.toLowerCase()).toList();
      expect(missingNames, isNot(contains('pollo')));
      expect(missingNames.where((n) => n == 'tomate').length, equals(1));
      expect(missingNames.where((n) => n.startsWith('huevo')).length, equals(1));
      expect(missingNames, contains('cilantro'));
      expect(missingNames, contains('limón'));
    });

    test('filters by category and cooking time deterministically using LocalRecipeDataset', () {
      final firstRun = service.generatePlan(
        daysCount: 4,
        availableIngredientNames: const ['Huevo', 'Tomate', 'Avena en hojuelas'],
        categoryFilter: 'Desayuno',
        maxTotalTimeMinutes: 40,
      );
      final secondRun = service.generatePlan(
        daysCount: 4,
        availableIngredientNames: const ['Huevo', 'Tomate', 'Avena en hojuelas'],
        categoryFilter: 'Desayuno',
        maxTotalTimeMinutes: 40,
      );

      expect(firstRun.days.length, equals(4));
      expect(
        firstRun.days.map((d) => d.recipe.id).toList(),
        equals(secondRun.days.map((d) => d.recipe.id).toList()),
      );
      for (final day in firstRun.days) {
        expect(day.recipe.category, equals('Desayuno'));
        expect(day.recipe.totalTimeMinutes, lessThanOrEqualTo(40));
      }
      expect(LocalRecipeDataset.instance.recipes, isNotEmpty);
    });
  });
}

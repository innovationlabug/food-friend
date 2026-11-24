import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/recipes/data/ingredient_replacement_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';

void main() {
  group('FEAT-4: IngredientReplacementService - Availability Substitutions', () {
    test('detects aceite vegetal as substitute for aceite de oliva', () {
      final replacements =
          IngredientReplacementService.findAvailabilityReplacements(
        missingIngredients: const [
          RecipeIngredient(name: 'Aceite de oliva', displayAmount: '1 cda'),
        ],
        availableIngredientNames: const ['Tomate', 'Aceite vegetal'],
      );

      expect(replacements.length, 1);
      expect(replacements.first.missingIngredient.name, 'Aceite de oliva');
      expect(replacements.first.availableIngredientName, 'Aceite vegetal');
      expect(
        replacements.first.message,
        'Puedes usar Aceite vegetal en lugar de Aceite de oliva',
      );
    });

    test('detects queso de capas as substitute for queso mozzarella', () {
      final replacements =
          IngredientReplacementService.findAvailabilityReplacements(
        missingIngredients: const [
          RecipeIngredient(name: 'Queso mozzarella', displayAmount: '4 oz'),
        ],
        availableIngredientNames: const ['Queso de capas'],
      );

      expect(replacements.length, 1);
      expect(
        replacements.first.message,
        'Puedes usar Queso de capas en lugar de Queso mozzarella',
      );
    });

    test('detects yogur natural for crema pura and arroz integral for arroz blanco',
        () {
      final replacements =
          IngredientReplacementService.findAvailabilityReplacements(
        missingIngredients: const [
          RecipeIngredient(name: 'Crema pura', displayAmount: '1/2 taza'),
          RecipeIngredient(name: 'Arroz blanco', displayAmount: '1 taza'),
        ],
        availableIngredientNames: const ['Yogur natural', 'Arroz integral'],
      );

      expect(replacements.length, 2);
      expect(
        replacements[0].message,
        'Puedes usar Yogur natural en lugar de Crema pura',
      );
      expect(
        replacements[1].message,
        'Puedes usar Arroz integral en lugar de Arroz blanco',
      );
    });

    test('handles Spanish accents and partial preparation descriptors', () {
      final replacements =
          IngredientReplacementService.findAvailabilityReplacements(
        missingIngredients: const [
          RecipeIngredient(
            name: 'Queso mozzarella rallado',
            displayAmount: '1 taza',
          ),
          RecipeIngredient(name: 'Güisquil', displayAmount: '1 unidad'),
        ],
        availableIngredientNames: const ['queso de capas', 'perulero'],
      );

      expect(replacements.length, 2);
      expect(replacements[0].availableIngredientName, 'queso de capas');
      expect(replacements[1].availableIngredientName, 'perulero');
    });

    test('returns empty list when inputs are empty or no logical substitute exists',
        () {
      expect(
        IngredientReplacementService.findAvailabilityReplacements(
          missingIngredients: const [],
          availableIngredientNames: const ['Aceite vegetal'],
        ),
        isEmpty,
      );
      expect(
        IngredientReplacementService.findAvailabilityReplacements(
          missingIngredients: const [
            RecipeIngredient(name: 'Canela en polvo', displayAmount: '1 cdta'),
          ],
          availableIngredientNames: const ['Tomate', 'Ajo'],
        ),
        isEmpty,
      );
    });
  });

  group('FEAT-4: IngredientReplacementService - Health-Goal Replacements', () {
    const richRecipe = Recipe(
      id: 'rich_test',
      title: 'Arroz con Crema y Salchicha',
      ingredients: [
        RecipeIngredient(name: 'Arroz blanco', displayAmount: '1 taza'),
        RecipeIngredient(name: 'Crema pura', displayAmount: '1/2 taza'),
        RecipeIngredient(name: 'Salchicha', displayAmount: '4 unidades'),
        RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
      ],
      instructions: ['Cocinar todo.'],
    );

    test('returns empty list when no health goals are active', () {
      final swaps = IngredientReplacementService.findHealthGoalReplacements(
        recipe: richRecipe,
        activeHealthGoals: const <HealthGoal>{},
      );
      expect(swaps, isEmpty);
    });

    test('suggests yogur natural / aguacate for crema pura under loseWeight', () {
      final swaps = IngredientReplacementService.findHealthGoalReplacements(
        recipe: richRecipe,
        activeHealthGoals: const {HealthGoal.loseWeight},
        availableIngredientNames: const ['Yogur natural'],
      );

      final cremaSwap = swaps.firstWhere(
        (s) => s.targetIngredient.name == 'Crema pura',
      );
      expect(cremaSwap.healthierAlternatives, contains('Yogur natural'));
      expect(cremaSwap.healthierAlternatives, contains('Aguacate'));
      expect(cremaSwap.message, 'Cambia Crema pura por Yogur natural o Aguacate');
      expect(cremaSwap.availableAlternativesInPantry, equals(['Yogur natural']));
    });

    test('suggests arroz integral for arroz blanco under increaseVitaminsAndFiber',
        () {
      final swaps = IngredientReplacementService.findHealthGoalReplacements(
        recipe: richRecipe,
        activeHealthGoals: const {HealthGoal.increaseVitaminsAndFiber},
      );

      expect(swaps.length, 1);
      expect(swaps.first.targetIngredient.name, 'Arroz blanco');
      expect(swaps.first.healthierAlternatives, equals(['Arroz integral']));
      expect(swaps.first.message, 'Cambia Arroz blanco por Arroz integral');
    });

    test(
        'suggests pechuga de pollo, huevo, or frijoles negros for processed meats under reduceSodiumAndProcessed',
        () {
      final swaps = IngredientReplacementService.findHealthGoalReplacements(
        recipe: richRecipe,
        activeHealthGoals: const {HealthGoal.reduceSodiumAndProcessed},
      );

      final salchichaSwap = swaps.firstWhere(
        (s) => s.targetIngredient.name == 'Salchicha',
      );
      expect(
        salchichaSwap.healthierAlternatives,
        equals(['Pechuga de pollo', 'Huevo', 'Frijoles negros']),
      );
      expect(
        salchichaSwap.message,
        'Cambia Salchicha por Pechuga de pollo, Huevo o Frijoles negros',
      );
    });
  });
}

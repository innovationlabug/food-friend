import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_search_result.dart';

void main() {
  group('US-4.1: Recipe & RecipeIngredient Models', () {
    test('RecipeIngredient serializes to and from JSON accurately', () {
      const ingredient = RecipeIngredient(
        name: 'Güisquil',
        displayAmount: '1 unidad pelado y en cubos',
      );

      final json = ingredient.toJson();
      expect(json['name'], equals('Güisquil'));
      expect(json['displayAmount'], equals('1 unidad pelado y en cubos'));

      final fromJson = RecipeIngredient.fromJson(json);
      expect(fromJson.name, equals('Güisquil'));
      expect(fromJson.displayAmount, equals('1 unidad pelado y en cubos'));
      expect(fromJson.normalizedName, equals('guisquil'));
      expect(fromJson, equals(ingredient));
    });

    test('Recipe serializes to and from JSON accurately with metadata', () {
      const recipe = Recipe(
        id: 'caldo_pollo_test',
        title: 'Caldo de Pollo',
        description: 'Delicioso caldo tradicional',
        category: 'Sopas y Caldos',
        difficulty: 'Fácil',
        prepTimeMinutes: 15,
        cookTimeMinutes: 35,
        servings: 4,
        source: 'local',
        ingredients: [
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
          RecipeIngredient(name: 'Papa', displayAmount: '2 unidades'),
        ],
        instructions: [
          'Hervir agua en una olla grande.',
          'Agregar el pollo y cocinar por 20 minutos.',
        ],
      );

      final json = recipe.toJson();
      expect(json['id'], equals('caldo_pollo_test'));
      expect(json['title'], equals('Caldo de Pollo'));
      expect(json['description'], equals('Delicioso caldo tradicional'));
      expect(json['category'], equals('Sopas y Caldos'));
      expect(json['prepTimeMinutes'], equals(15));
      expect(json['cookTimeMinutes'], equals(35));
      expect(json['servings'], equals(4));
      expect(json['source'], equals('local'));

      final fromJson = Recipe.fromJson(json);
      expect(fromJson.id, equals(recipe.id));
      expect(fromJson.title, equals(recipe.title));
      expect(fromJson.ingredients.length, equals(2));
      expect(fromJson.instructions.length, equals(2));
      expect(fromJson.totalTimeMinutes, equals(50));
      expect(fromJson, equals(recipe));
    });

    test('RecipeSearchResult calculates match counts and percentages correctly', () {
      const recipe = Recipe(
        id: 'r1',
        title: 'Ensalada',
        ingredients: [
          RecipeIngredient(name: 'Tomate', displayAmount: '2'),
          RecipeIngredient(name: 'Aguacate', displayAmount: '1'),
          RecipeIngredient(name: 'Pepino', displayAmount: '1'),
          RecipeIngredient(name: 'Limón', displayAmount: '1'),
        ],
        instructions: ['Mezclar todo.'],
      );

      final result = RecipeSearchResult(
        recipe: recipe,
        matchedIngredients: const [
          RecipeIngredient(name: 'Tomate', displayAmount: '2'),
          RecipeIngredient(name: 'Aguacate', displayAmount: '1'),
        ],
        missingIngredients: const [
          RecipeIngredient(name: 'Pepino', displayAmount: '1'),
          RecipeIngredient(name: 'Limón', displayAmount: '1'),
        ],
      );

      expect(result.matchCount, equals(2));
      expect(result.totalIngredients, equals(4));
      expect(result.matchPercentage, closeTo(0.5, 0.001));
      expect(result.matchPercentageInt, equals(50));
      expect(result.hasAllIngredients, isFalse);
      expect(result.isPartialMatch, isTrue);
    });

    test('RecipeSearchResult indicates full match when missing is empty', () {
      const recipe = Recipe(
        id: 'r2',
        title: 'Frijoles',
        ingredients: [
          RecipeIngredient(name: 'Frijoles negros', displayAmount: '1 lb'),
        ],
        instructions: ['Cocinar.'],
      );

      final result = RecipeSearchResult(
        recipe: recipe,
        matchedIngredients: const [
          RecipeIngredient(name: 'Frijoles negros', displayAmount: '1 lb'),
        ],
        missingIngredients: const [],
      );

      expect(result.hasAllIngredients, isTrue);
      expect(result.isPartialMatch, isFalse);
      expect(result.matchPercentageInt, equals(100));
    });
  });

  group('US-4.1: Local Recipe Dataset Verification', () {
    test('Dataset contains varied, healthy recipes suited to Guatemalan kitchens', () {
      final dataset = LocalRecipeDataset.instance;
      expect(dataset.recipes.length, greaterThanOrEqualTo(10));

      final ids = <String>{};
      for (final r in dataset.recipes) {
        expect(r.id, isNotEmpty);
        expect(ids.add(r.id), isTrue, reason: 'Recipe id ${r.id} must be unique');
        expect(r.title, isNotEmpty);
        expect(r.ingredients.length, greaterThanOrEqualTo(2));
        expect(r.instructions.length, greaterThanOrEqualTo(2));
        expect(r.category, isNotNull);

        for (final ing in r.ingredients) {
          expect(ing.name, isNotEmpty);
          expect(ing.displayAmount, isNotEmpty);
        }
      }
    });

    test('Dataset includes traditional Guatemalan dishes with authentic ingredients', () {
      final dataset = LocalRecipeDataset.instance;
      final titles = dataset.recipes.map((r) => r.title.toLowerCase()).toList();

      expect(titles.any((t) => t.contains('pepián') || t.contains('pepian')), isTrue);
      expect(titles.any((t) => t.contains('hilachas')), isTrue);
      expect(titles.any((t) => t.contains('caldo de pollo')), isTrue);
      expect(titles.any((t) => t.contains('frijoles negros')), isTrue);
      expect(titles.any((t) => t.contains('salpicón') || t.contains('salpicon')), isTrue);
    });
  });
}

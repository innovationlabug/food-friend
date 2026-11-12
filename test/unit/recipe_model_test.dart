import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/data/ingredient_catalog.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_search_result.dart';
import 'package:food_friend/features/recipes/domain/recipe_variation.dart';

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

  group('US-6.1: Expanded Local Recipe Dataset & Pre-Defined Recipe Variations Model', () {
    test('RecipeVariation serializes and deserializes accurately', () {
      const variation = RecipeVariation(
        recipeId: 'pollo_curry_crema',
        title: 'Pechuga al Curry Cremoso con Maní',
        description: 'Salsa suave de curry con crema y maní tostado.',
        swappedIngredients: ['Curry', 'Crema pura', 'Maní'],
      );

      final json = variation.toJson();
      expect(json['recipeId'], equals('pollo_curry_crema'));
      expect(json['title'], equals('Pechuga al Curry Cremoso con Maní'));
      expect(json['description'], equals('Salsa suave de curry con crema y maní tostado.'));
      expect(json['swappedIngredients'], equals(['Curry', 'Crema pura', 'Maní']));

      final fromJson = RecipeVariation.fromJson(json);
      expect(fromJson.recipeId, equals(variation.recipeId));
      expect(fromJson.title, equals(variation.title));
      expect(fromJson.description, equals(variation.description));
      expect(fromJson.swappedIngredients, equals(variation.swappedIngredients));
      expect(fromJson, equals(variation));
    });

    test('Recipe serializes and deserializes variations and variationIds', () {
      const recipe = Recipe(
        id: 'pollo_test',
        title: 'Pollo Test',
        ingredients: [
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
        ],
        instructions: ['Cocinar'],
        variations: [
          RecipeVariation(
            recipeId: 'pollo_var_1',
            title: 'Pollo al Curry',
            description: 'Con curry',
            swappedIngredients: ['Curry'],
          ),
        ],
      );

      expect(recipe.hasVariations, isTrue);
      expect(recipe.variationIds, equals(['pollo_var_1']));

      final json = recipe.toJson();
      expect(json['variations'], isNotNull);
      expect(json['variationIds'], equals(['pollo_var_1']));

      final deserialized = Recipe.fromJson(json);
      expect(deserialized.hasVariations, isTrue);
      expect(deserialized.variations.length, equals(1));
      expect(deserialized.variations.first.recipeId, equals('pollo_var_1'));
      expect(deserialized.variations.first.title, equals('Pollo al Curry'));
      expect(deserialized.variationIds, equals(['pollo_var_1']));
    });

    test('LocalRecipeDataset contains recipes using newly added staples (nueces, maní, queso gouda, queso parmesano, curry)', () {
      final dataset = LocalRecipeDataset.instance;
      final allRecipeIngredients = dataset.recipes
          .expand((r) => r.ingredients)
          .map((i) => i.name.toLowerCase())
          .toSet();

      expect(allRecipeIngredients.contains('nueces'), isTrue, reason: 'Dataset should include Nueces');
      expect(allRecipeIngredients.contains('maní'), isTrue, reason: 'Dataset should include Maní');
      expect(allRecipeIngredients.contains('queso gouda'), isTrue, reason: 'Dataset should include Queso gouda');
      expect(allRecipeIngredients.contains('queso parmesano'), isTrue, reason: 'Dataset should include Queso parmesano');
      expect(allRecipeIngredients.contains('curry'), isTrue, reason: 'Dataset should include Curry');
    });

    test('Multiple recipes include sensible pre-defined variations linking to valid recipes', () {
      final dataset = LocalRecipeDataset.instance;
      final recipesWithVariations = dataset.recipes.where((r) => r.hasVariations).toList();

      expect(recipesWithVariations.length, greaterThanOrEqualTo(5),
          reason: 'Expected at least 5 recipes with pre-defined variations');

      final allRecipeIds = dataset.recipes.map((r) => r.id).toSet();

      for (final recipe in recipesWithVariations) {
        for (final variation in recipe.variations) {
          expect(variation.recipeId, isNotEmpty);
          expect(variation.title, isNotEmpty);
          expect(allRecipeIds.contains(variation.recipeId), isTrue,
              reason: 'Variation ID "${variation.recipeId}" on recipe "${recipe.id}" must exist in LocalRecipeDataset');

          // Check that LocalRecipeDataset.getVariationsFor(recipe) resolves the linked recipes cleanly
          final resolvedVariations = dataset.getVariationsFor(recipe);
          expect(resolvedVariations.any((r) => r.id == variation.recipeId), isTrue);
        }
      }
    });

    test('Every recipe ingredient maps cleanly to IngredientCatalog', () {
      final dataset = LocalRecipeDataset.instance;
      final catalog = IngredientCatalog.instance;

      for (final recipe in dataset.recipes) {
        for (final ingredient in recipe.ingredients) {
          final closest = catalog.getClosestMatch(ingredient.name);
          expect(
            closest,
            isNotNull,
            reason: 'Ingredient "${ingredient.name}" in recipe "${recipe.title}" should map to catalog',
          );
        }
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/data/recipe_search_service.dart';

void main() {
  group('US-4.1: RecipeSearchService Matching and Ranking', () {
    late RecipeSearchService service;

    setUp(() {
      service = RecipeSearchService();
    });

    test('Returns empty list when user provides empty ingredient list with minMatchCount >= 1', () {
      final results = service.searchRecipes(
        selectedIngredientNames: [],
        minMatchCount: 1,
      );
      expect(results, isEmpty);
    });

    test('Searches by single ingredient and finds relevant recipes', () {
      final results = service.searchRecipes(
        selectedIngredientNames: ['Pollo'],
      );

      expect(results, isNotEmpty);
      for (final res in results) {
        expect(res.matchCount, greaterThanOrEqualTo(1));
        final matchedNames = res.matchedIngredients.map((i) => i.name.toLowerCase()).toList();
        expect(
          matchedNames.any((n) => n.contains('pollo') || n.contains('pechuga')),
          isTrue,
        );
      }
    });

    test('Handles accent-insensitive and case-insensitive matching', () {
      final resultsWithAccents = service.searchRecipes(
        selectedIngredientNames: ['Güisquil', 'Limón'],
      );
      final resultsWithoutAccents = service.searchRecipes(
        selectedIngredientNames: ['guisquil', 'limon'],
      );

      expect(resultsWithAccents.length, equals(resultsWithoutAccents.length));
      expect(
        resultsWithAccents.map((r) => r.recipe.id).toSet(),
        equals(resultsWithoutAccents.map((r) => r.recipe.id).toSet()),
      );
    });

    test('Ranks recipes by match count descending and match percentage descending', () {
      // User has ingredients for Ensalada Chapina: Aguacate, Tomate, Pepino, Limón
      final results = service.searchRecipes(
        selectedIngredientNames: ['Aguacate', 'Tomate', 'Pepino', 'Limón'],
      );

      expect(results, isNotEmpty);

      // Verify descending sort by match count
      for (var i = 0; i < results.length - 1; i++) {
        final current = results[i];
        final next = results[i + 1];

        if (current.matchCount == next.matchCount) {
          expect(
            current.matchPercentage,
            greaterThanOrEqualTo(next.matchPercentage),
            reason: 'Equal matchCount should tie-break on matchPercentage descending',
          );
        } else {
          expect(
            current.matchCount,
            greaterThan(next.matchCount),
            reason: 'Earlier results should have greater or equal matchCount',
          );
        }
      }

      // Check top result has high match count and is a relevant dish
      final topResult = results.first;
      expect(topResult.matchCount, greaterThanOrEqualTo(3));
      expect(
        topResult.recipe.title.contains('Ceviche') ||
            topResult.recipe.title.contains('Ensalada') ||
            topResult.recipe.title.contains('Aguacate'),
        isTrue,
      );
    });

    test('Correctly populates matchedIngredients and missingIngredients lists', () {
      final results = service.searchRecipes(
        selectedIngredientNames: ['Pechuga de pollo', 'Papa'],
      );

      expect(results, isNotEmpty);
      final caldoResult = results.firstWhere((r) => r.recipe.id == 'caldo_pollo_verduras');

      expect(caldoResult.matchedIngredients.map((i) => i.name), contains('Pechuga de pollo'));
      expect(caldoResult.matchedIngredients.map((i) => i.name), contains('Papa'));
      expect(caldoResult.missingIngredients.map((i) => i.name), contains('Güisquil'));
      expect(caldoResult.missingIngredients.map((i) => i.name), contains('Zanahoria'));
      expect(
        caldoResult.matchedIngredients.length + caldoResult.missingIngredients.length,
        equals(caldoResult.recipe.ingredients.length),
      );
    });

    test('findClosestPartialMatches returns fallback recipes even with low match count', () {
      final fallbacks = service.findClosestPartialMatches(
        ['IngredienteDesconocidoXYZ'],
        limit: 3,
      );

      expect(fallbacks.length, equals(3));
      for (final fb in fallbacks) {
        expect(fb.recipe.title, isNotEmpty);
      }
    });

    test('getAllRecipes returns all recipes from dataset', () {
      final all = service.getAllRecipes();
      expect(all.length, equals(LocalRecipeDataset.instance.recipes.length));
    });

    test('getRecipeById returns recipe if found, or null if missing', () {
      final recipe = service.getRecipeById('pepian_pollo');
      expect(recipe, isNotNull);
      expect(recipe!.title, contains('Pepián'));

      final nonExistent = service.getRecipeById('non_existent_id');
      expect(nonExistent, isNull);
    });
  });
}

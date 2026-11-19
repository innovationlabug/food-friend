import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/nutrition/domain/nutrition_metadata.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/data/recipe_search_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_history_record.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/recipes/domain/recipe_time_filter.dart';

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

    test('isIngredientMatch bridges Spanish and English synonyms for catalog items', () {
      expect(RecipeSearchService.isIngredientMatch('berenjena', 'aubergine'), isTrue);
      expect(RecipeSearchService.isIngredientMatch('berenjena', 'eggplant'), isTrue);
      expect(RecipeSearchService.isIngredientMatch('yuca', 'cassava'), isTrue);
      expect(RecipeSearchService.isIngredientMatch('yuca', 'mandioca'), isTrue);
      expect(RecipeSearchService.isIngredientMatch('camote', 'sweet potato'), isTrue);
      expect(RecipeSearchService.isIngredientMatch('remolacha', 'beetroot'), isTrue);
      expect(RecipeSearchService.isIngredientMatch('garbanzos', 'chickpea'), isTrue);
      expect(RecipeSearchService.isIngredientMatch('atun', 'tuna'), isTrue);
    });
  });

  group('US-7.3: Preference- & History-Aware Recipe Suggestion Ranking', () {
    late RecipeSearchService service;

    const recipeFav = Recipe(
      id: 'rec_fav',
      title: 'A - Receta Favorita',
      ingredients: [
        RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
        RecipeIngredient(name: 'Arroz', displayAmount: '1 taza'),
      ],
      instructions: ['Cocinar.'],
    );

    const recipeLiked = Recipe(
      id: 'rec_liked',
      title: 'B - Receta Me Gustó',
      ingredients: [
        RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
        RecipeIngredient(name: 'Arroz', displayAmount: '1 taza'),
      ],
      instructions: ['Cocinar.'],
    );

    const recipeUnmarked = Recipe(
      id: 'rec_unmarked',
      title: 'C - Receta Sin Marcar',
      ingredients: [
        RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
        RecipeIngredient(name: 'Arroz', displayAmount: '1 taza'),
      ],
      instructions: ['Cocinar.'],
    );

    const recipeDisliked = Recipe(
      id: 'rec_disliked',
      title: 'D - Receta No Me Gustó',
      ingredients: [
        RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
        RecipeIngredient(name: 'Arroz', displayAmount: '1 taza'),
        RecipeIngredient(name: 'Tomate', displayAmount: '1 unidad'),
      ],
      instructions: ['Cocinar.'],
    );

    const recipeNever = Recipe(
      id: 'rec_never',
      title: 'E - Receta Nunca',
      ingredients: [
        RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
        RecipeIngredient(name: 'Arroz', displayAmount: '1 taza'),
      ],
      instructions: ['Cocinar.'],
    );

    setUp(() {
      service = RecipeSearchService();
    });

    test('strictly filters out recipes marked as Nunca (never)', () {
      final pool = [recipeFav, recipeNever];
      final history = {
        recipeNever.id: const RecipeHistoryRecord(
          recipeId: 'rec_never',
          preference: RecipePreference.never,
        ),
      };

      final results = service.searchRecipes(
        selectedIngredientNames: ['Pollo', 'Arroz'],
        recipePool: pool,
        history: history,
      );

      expect(results.length, 1);
      expect(results.first.recipe.id, 'rec_fav');
      expect(results.any((r) => r.recipe.id == 'rec_never'), isFalse);
    });

    test('ranks active recipes ahead of disliked recipes even when disliked has more matches', () {
      // recipeDisliked has 3 matches; recipeUnmarked has 2 matches
      final pool = [recipeDisliked, recipeUnmarked];
      final history = {
        recipeDisliked.id: const RecipeHistoryRecord(
          recipeId: 'rec_disliked',
          preference: RecipePreference.disliked,
        ),
      };

      final results = service.searchRecipes(
        selectedIngredientNames: ['Pollo', 'Arroz', 'Tomate'],
        recipePool: pool,
        history: history,
      );

      expect(results.length, 2);
      expect(results.first.recipe.id, 'rec_unmarked');
      expect(results.last.recipe.id, 'rec_disliked');
    });

    test('exact ordering: Favorita > Me gustó > Sin marcar > No me gustó with equal matches', () {
      final pool = [recipeDisliked, recipeUnmarked, recipeLiked, recipeFav, recipeNever];
      final history = {
        recipeFav.id: const RecipeHistoryRecord(
          recipeId: 'rec_fav',
          preference: RecipePreference.favorite,
        ),
        recipeLiked.id: const RecipeHistoryRecord(
          recipeId: 'rec_liked',
          preference: RecipePreference.liked,
        ),
        recipeDisliked.id: const RecipeHistoryRecord(
          recipeId: 'rec_disliked',
          preference: RecipePreference.disliked,
        ),
        recipeNever.id: const RecipeHistoryRecord(
          recipeId: 'rec_never',
          preference: RecipePreference.never,
        ),
      };

      final results = service.searchRecipes(
        selectedIngredientNames: ['Pollo', 'Arroz'],
        recipePool: pool,
        history: history,
      );

      // Verify never is excluded
      expect(results.length, 4);

      // Verify exact order
      expect(results[0].recipe.id, 'rec_fav');
      expect(results[1].recipe.id, 'rec_liked');
      expect(results[2].recipe.id, 'rec_unmarked');
      expect(results[3].recipe.id, 'rec_disliked');
    });

    test('variety balance balances recently cooked recipes to encourage variety', () {
      final today = DateTime(2026, 11, 11, 12, 0);

      const recipeFavCookedToday = Recipe(
        id: 'rec_fav_cooked_today',
        title: 'Favorita Cocinada Hoy',
        ingredients: [
          RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
        ],
        instructions: ['Cocinar.'],
      );

      const recipeFavFresh = Recipe(
        id: 'rec_fav_fresh',
        title: 'Favorita No Cocinada Recientemente',
        ingredients: [
          RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
        ],
        instructions: ['Cocinar.'],
      );

      final pool = [recipeFavCookedToday, recipeFavFresh];
      final history = {
        recipeFavCookedToday.id: RecipeHistoryRecord(
          recipeId: 'rec_fav_cooked_today',
          preference: RecipePreference.favorite,
          timesCooked: 1,
          cookedDates: [today],
        ),
        recipeFavFresh.id: const RecipeHistoryRecord(
          recipeId: 'rec_fav_fresh',
          preference: RecipePreference.favorite,
          timesCooked: 0,
        ),
      };

      final results = service.searchRecipes(
        selectedIngredientNames: ['Pollo'],
        recipePool: pool,
        history: history,
      );

      expect(results.length, 2);
      expect(results[0].recipe.id, 'rec_fav_fresh');
      expect(results[1].recipe.id, 'rec_fav_cooked_today');
    });
  });

  group('FEAT-1: Total Cooking Time Filter & Pantry Ingredient Matching', () {
    const quickRecipe = Recipe(
      id: 'rec_quick',
      title: 'Ensalada Rápida',
      prepTimeMinutes: 10,
      cookTimeMinutes: 10, // total 20
      ingredients: [RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades')],
      instructions: ['Mezclar.'],
    );

    const mediumRecipe = Recipe(
      id: 'rec_medium',
      title: 'Salteado Medio',
      prepTimeMinutes: 15,
      cookTimeMinutes: 25, // total 40
      ingredients: [RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades')],
      instructions: ['Saltear.'],
    );

    const hourRecipe = Recipe(
      id: 'rec_hour',
      title: 'Caldo Tradicional',
      prepTimeMinutes: 20,
      cookTimeMinutes: 40, // total 60
      ingredients: [RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades')],
      instructions: ['Hervir.'],
    );

    const slowRecipe = Recipe(
      id: 'rec_slow',
      title: 'Guiso Lento',
      prepTimeMinutes: 25,
      cookTimeMinutes: 45, // total 70
      ingredients: [RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades')],
      instructions: ['Cocer lentamente.'],
    );

    const noTimeRecipe = Recipe(
      id: 'rec_no_time',
      title: 'Receta sin tiempo',
      ingredients: [RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades')],
      instructions: ['Preparar.'],
    );

    test('RecipeTimeFilter matches totalTimeMinutes accurately at boundaries', () {
      // Todos includes everything including null time
      expect(RecipeTimeFilter.all.matches(quickRecipe), isTrue);
      expect(RecipeTimeFilter.all.matches(slowRecipe), isTrue);
      expect(RecipeTimeFilter.all.matches(noTimeRecipe), isTrue);

      // <= 20 min
      expect(RecipeTimeFilter.upTo20.matches(quickRecipe), isTrue);
      expect(RecipeTimeFilter.upTo20.matches(mediumRecipe), isFalse);
      expect(RecipeTimeFilter.upTo20.matches(noTimeRecipe), isFalse);

      // <= 40 min
      expect(RecipeTimeFilter.upTo40.matches(quickRecipe), isTrue);
      expect(RecipeTimeFilter.upTo40.matches(mediumRecipe), isTrue);
      expect(RecipeTimeFilter.upTo40.matches(hourRecipe), isFalse);

      // <= 60 min
      expect(RecipeTimeFilter.upTo60.matches(quickRecipe), isTrue);
      expect(RecipeTimeFilter.upTo60.matches(mediumRecipe), isTrue);
      expect(RecipeTimeFilter.upTo60.matches(hourRecipe), isTrue);
      expect(RecipeTimeFilter.upTo60.matches(slowRecipe), isFalse);
      expect(RecipeTimeFilter.upTo60.matches(noTimeRecipe), isFalse);
    });

    test('RecipeSearchService.searchRecipes filters by maxTotalTimeMinutes', () {
      final service = RecipeSearchService();
      final pool = [quickRecipe, mediumRecipe, hourRecipe, slowRecipe, noTimeRecipe];

      final upTo20 = service.searchRecipes(
        selectedIngredientNames: ['Tomate'],
        recipePool: pool,
        maxTotalTimeMinutes: 20,
      );
      expect(upTo20.map((r) => r.recipe.id), equals(['rec_quick']));

      final upTo40 = service.searchRecipes(
        selectedIngredientNames: ['Tomate'],
        recipePool: pool,
        maxTotalTimeMinutes: 40,
      );
      expect(
        upTo40.map((r) => r.recipe.id).toSet(),
        equals({'rec_quick', 'rec_medium'}),
      );

      final upTo60 = service.searchRecipes(
        selectedIngredientNames: ['Tomate'],
        recipePool: pool,
        maxTotalTimeMinutes: 60,
      );
      expect(
        upTo60.map((r) => r.recipe.id).toSet(),
        equals({'rec_quick', 'rec_medium', 'rec_hour'}),
      );
    });

    test('findMatchingPantryIngredients returns matching pantry items without duplicates', () {
      const recipe = Recipe(
        id: 'rec_pantry_match',
        title: 'Pollo con Huevo y Tomate',
        ingredients: [
          RecipeIngredient(name: 'Pollo', displayAmount: '1 lb'),
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1/2 lb'),
          RecipeIngredient(name: 'Huevo', displayAmount: '2 unidades'),
          RecipeIngredient(name: 'Tomate', displayAmount: '3 unidades'),
        ],
        instructions: ['Cocinar.'],
      );

      const pantry = [
        Ingredient(name: 'Pechuga de pollo'),
        Ingredient(name: 'Huevos'),
        Ingredient(name: 'Zanahoria'),
        Ingredient(name: 'Tomate'),
      ];

      final matched = RecipeSearchService.findMatchingPantryIngredients(
        recipe,
        pantry,
      );

      expect(
        matched.map((i) => i.name),
        equals(['Pechuga de pollo', 'Huevos', 'Tomate']),
      );
    });
  });

  group('FEAT-2: Health-Goal Recipe Prioritization & Deterministic Tooltips', () {
    const lightProteinRecipe = Recipe(
      id: 'light_chicken',
      title: 'Pechuga con Güisquil',
      nutritionAttributes: {
        NutritionalAttribute.highProtein,
        NutritionalAttribute.lowCalorieDensity,
        NutritionalAttribute.lowSodiumWholeFood,
      },
      ingredients: [
        RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
        RecipeIngredient(name: 'Güisquil', displayAmount: '1 unidad'),
      ],
      instructions: ['Cocinar al vapor.'],
    );

    const creamyRecipe = Recipe(
      id: 'creamy_chicken',
      title: 'Pollo en Crema y Mantequilla',
      nutritionAttributes: {
        NutritionalAttribute.highProtein,
        NutritionalAttribute.calorieDense,
      },
      ingredients: [
        RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
        RecipeIngredient(name: 'Crema pura', displayAmount: '1 taza'),
        RecipeIngredient(name: 'Mantequilla', displayAmount: '2 cdas'),
      ],
      instructions: ['Cocinar en crema.'],
    );

    const hiddenLightRecipe = Recipe(
      id: 'never_light',
      title: 'Ensalada Oculta',
      nutritionAttributes: {
        NutritionalAttribute.lowCalorieDensity,
        NutritionalAttribute.lowSodiumWholeFood,
      },
      ingredients: [
        RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
      ],
      instructions: ['Servir.'],
    );

    const dislikedLightRecipe = Recipe(
      id: 'disliked_light',
      title: 'Caldo No Me Gustó',
      nutritionAttributes: {
        NutritionalAttribute.lowCalorieDensity,
        NutritionalAttribute.highProtein,
        NutritionalAttribute.lowSodiumWholeFood,
      },
      ingredients: [
        RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
        RecipeIngredient(name: 'Güisquil', displayAmount: '1 unidad'),
      ],
      instructions: ['Hervir.'],
    );

    test('prioritizes recipes aligned with active health goals and attaches Spanish tooltips',
        () {
      final service = RecipeSearchService();
      final results = service.searchRecipes(
        selectedIngredientNames: ['Pechuga de pollo', 'Crema pura'],
        recipePool: const [creamyRecipe, lightProteinRecipe],
        activeHealthGoals: {HealthGoal.loseWeight},
      );

      // Even though creamyRecipe has 2 matching ingredients (Pechuga + Crema) vs 1,
      // loseWeight boosts lightProteinRecipe (+9.5) and penalizes creamyRecipe (-4.0).
      expect(results.first.recipe.id, equals('light_chicken'));
      expect(results.first.goalMatch.hasMatch, isTrue);
      expect(
        results.first.goalMatch.primaryReason,
        equals('El güisquil contiene pocas calorías y aporta fibra'),
      );

      expect(results.last.recipe.id, equals('creamy_chicken'));
      expect(results.last.goalMatch.hasMatch, isFalse);
    });

    test('ranks multi-goal matches ahead of single-goal matches when ingredients tie',
        () {
      final service = RecipeSearchService();
      const singleGoalOnly = Recipe(
        id: 'single_goal',
        title: 'Arroz con Pollo',
        ingredients: [
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
          RecipeIngredient(name: 'Arroz blanco', displayAmount: '1 taza'),
        ],
        instructions: ['Cocinar.'],
      );
      const multiGoal = Recipe(
        id: 'multi_goal',
        title: 'Pollo con Espinaca',
        ingredients: [
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
          RecipeIngredient(name: 'Espinaca', displayAmount: '1 taza'),
        ],
        instructions: ['Saltear.'],
      );

      final results = service.searchRecipes(
        selectedIngredientNames: ['Pechuga de pollo'],
        recipePool: const [singleGoalOnly, multiGoal],
        activeHealthGoals: {
          HealthGoal.gainMuscle,
          HealthGoal.increaseVitaminsAndFiber,
        },
      );

      expect(results.first.recipe.id, equals('multi_goal'));
      expect(results.first.goalMatch.matchedGoals.length, equals(2));
      expect(results.first.goalMatch.reasons.length, equals(2));
    });

    test('still excludes Nunca and keeps No me gustó at the bottom even when aligned with goals',
        () {
      final service = RecipeSearchService();
      final history = {
        hiddenLightRecipe.id: const RecipeHistoryRecord(
          recipeId: 'never_light',
          preference: RecipePreference.never,
        ),
        dislikedLightRecipe.id: const RecipeHistoryRecord(
          recipeId: 'disliked_light',
          preference: RecipePreference.disliked,
        ),
      };

      final results = service.searchRecipes(
        selectedIngredientNames: ['Pechuga de pollo', 'Güisquil'],
        recipePool: const [
          dislikedLightRecipe,
          hiddenLightRecipe,
          creamyRecipe,
        ],
        history: history,
        activeHealthGoals: {HealthGoal.loseWeight, HealthGoal.gainMuscle},
      );

      expect(results.any((r) => r.recipe.id == 'never_light'), isFalse);
      expect(results.first.recipe.id, equals('creamy_chicken'));
      expect(results.last.recipe.id, equals('disliked_light'));
    });
  });
}

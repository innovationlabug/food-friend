import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/nutrition/data/health_goal_storage_service.dart';
import 'package:food_friend/features/nutrition/data/nutrition_service.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/nutrition/domain/nutrition_metadata.dart';
import 'package:food_friend/features/nutrition/domain/nutrition_tip.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_history_record.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:food_friend/features/shopping_list/data/shopping_suggestion_service.dart';
import 'package:food_friend/features/shopping_list/domain/shopping_suggestion.dart';

Recipe _makeRecipe(
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

List<Ingredient> _pantry(List<String> names) =>
    names.map((n) => Ingredient(name: n)).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ShoppingSuggestionService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = ShoppingSuggestionService();
  });

  group('FEAT-3: ShoppingSuggestionService deterministic gap engine', () {
    test('returns empty list when pantry is empty or no history/goals exist',
        () {
      final recipe = _makeRecipe(
        'r1',
        'Ensalada Fresca',
        ['Aguacate', 'Tomate', 'Limón'],
      );

      expect(
        service.generateSuggestions(
          pantryIngredients: const [],
          shoppingListIngredients: const [],
          recipes: [recipe],
          history: {
            'r1': const RecipeHistoryRecord(
              recipeId: 'r1',
              preference: RecipePreference.favorite,
            ),
          },
        ),
        isEmpty,
      );

      expect(
        service.generateSuggestions(
          pantryIngredients: _pantry(['Aguacate', 'Tomate']),
          shoppingListIngredients: const [],
          recipes: [recipe],
        ),
        isEmpty,
      );
    });

    test('surfaces favorite recipe missing 1 ingredient with exact Spanish text',
        () {
      final recipe = _makeRecipe(
        'fav_1',
        'Ensalada Chapina',
        ['Aguacate', 'Tomate', 'Pepino', 'Limón'],
      );

      final results = service.generateSuggestions(
        pantryIngredients: _pantry(['Aguacate', 'Tomate', 'Pepino']),
        shoppingListIngredients: const [],
        recipes: [recipe],
        history: const {
          'fav_1': RecipeHistoryRecord(
            recipeId: 'fav_1',
            preference: RecipePreference.favorite,
          ),
        },
      );

      expect(results, hasLength(1));
      final suggestion = results.first;
      expect(suggestion.source, equals(ShoppingSuggestionSource.favorite));
      expect(suggestion.missingIngredients, equals(['Limón']));
      expect(suggestion.availableIngredientCount, equals(3));
      expect(suggestion.totalIngredientCount, equals(4));
      expect(
        suggestion.message,
        equals(
          'Si compras Limón puedes cocinar Ensalada Chapina de tus recetas favoritas',
        ),
      );
    });

    test('surfaces favorite recipe missing 2 ingredients joined with "y"', () {
      final recipe = _makeRecipe(
        'fav_2',
        'Sopa de Lentejas',
        ['Lentejas', 'Espinaca', 'Zanahoria', 'Tomate', 'Cebolla blanca'],
      );

      final results = service.generateSuggestions(
        pantryIngredients: _pantry(['Lentejas', 'Tomate', 'Cebolla blanca']),
        shoppingListIngredients: const [],
        recipes: [recipe],
        history: const {
          'fav_2': RecipeHistoryRecord(
            recipeId: 'fav_2',
            preference: RecipePreference.favorite,
          ),
        },
      );

      expect(results, hasLength(1));
      expect(results.first.missingIngredients, equals(['Espinaca', 'Zanahoria']));
      expect(
        results.first.message,
        equals(
          'Si compras Espinaca y Zanahoria puedes cocinar Sopa de Lentejas de tus recetas favoritas',
        ),
      );
    });

    test(
        'includes liked and frequently cooked (timesCooked >= 2) while excluding 1-cook, disliked, and never recipes',
        () {
      final liked = _makeRecipe('r_liked', 'Omelet Verde', ['Huevo', 'Espinaca', 'Queso de capas']);
      final frequent = _makeRecipe('r_freq', 'Frijoles con Queso', ['Frijoles negros', 'Cebolla blanca', 'Queso de capas']);
      final singleCook = _makeRecipe('r_once', 'Arroz Sencillo', ['Arroz blanco', 'Cebolla blanca', 'Tomate']);
      final disliked = _makeRecipe('r_disliked', 'Pasta Crema', ['Pasta', 'Crema pura', 'Ajo']);
      final never = _makeRecipe('r_never', 'Salchicha Frita', ['Salchicha', 'Tomate', 'Cebolla blanca']);

      final results = service.generateSuggestions(
        pantryIngredients: _pantry([
          'Huevo',
          'Espinaca',
          'Frijoles negros',
          'Cebolla blanca',
          'Arroz blanco',
          'Pasta',
          'Salchicha',
          'Tomate',
        ]),
        shoppingListIngredients: const [],
        recipes: [liked, frequent, singleCook, disliked, never],
        history: const {
          'r_liked': RecipeHistoryRecord(
            recipeId: 'r_liked',
            preference: RecipePreference.liked,
          ),
          'r_freq': RecipeHistoryRecord(
            recipeId: 'r_freq',
            timesCooked: 2,
          ),
          'r_once': RecipeHistoryRecord(
            recipeId: 'r_once',
            timesCooked: 1,
          ),
          'r_disliked': RecipeHistoryRecord(
            recipeId: 'r_disliked',
            preference: RecipePreference.disliked,
            timesCooked: 3,
          ),
          'r_never': RecipeHistoryRecord(
            recipeId: 'r_never',
            preference: RecipePreference.never,
            timesCooked: 5,
          ),
        },
      );

      expect(results.map((s) => s.recipe.id), equals(['r_liked', 'r_freq']));
      expect(results[0].source, equals(ShoppingSuggestionSource.liked));
      expect(
        results[0].message,
        equals(
          'Si compras Queso de capas puedes cocinar Omelet Verde de las recetas que te gustaron',
        ),
      );
      expect(results[1].source, equals(ShoppingSuggestionSource.frequentlyCooked));
      expect(
        results[1].message,
        equals(
          'Si compras Queso de capas puedes cocinar Frijoles con Queso de tus recetas frecuentes',
        ),
      );
    });

    test(
        'enforces gap boundaries (max 2 missing and availableCount >= missingCount)',
        () {
      final missingThree = _makeRecipe(
        'r_three',
        'Receta Grande',
        ['Pollo', 'Tomate', 'Papa', 'Zanahoria', 'Ejote', 'Cilantro'],
      );
      final lowCoverage = _makeRecipe(
        'r_low',
        'Tres Ingredientes',
        ['Pollo', 'Limón', 'Ajo'],
      );
      final halfCoverage = _makeRecipe(
        'r_half',
        'Dos Ingredientes',
        ['Huevo', 'Espinaca'],
      );

      final results = service.generateSuggestions(
        pantryIngredients: _pantry(['Pollo', 'Tomate', 'Papa', 'Huevo']),
        shoppingListIngredients: const [],
        recipes: [missingThree, lowCoverage, halfCoverage],
        history: const {
          'r_three': RecipeHistoryRecord(
            recipeId: 'r_three',
            preference: RecipePreference.favorite,
          ),
          'r_low': RecipeHistoryRecord(
            recipeId: 'r_low',
            preference: RecipePreference.favorite,
          ),
          'r_half': RecipeHistoryRecord(
            recipeId: 'r_half',
            preference: RecipePreference.favorite,
          ),
        },
      );

      expect(results.map((s) => s.recipe.id), equals(['r_half']));
      expect(results.first.missingIngredients, equals(['Espinaca']));
    });

    test(
        'filters out missing ingredients already in Por comprar using normalized and synonym matching',
        () {
      final recipe = _makeRecipe(
        'r_shop',
        'Pollo con Limón y Ajo',
        ['Pechuga de pollo', 'Limón', 'Ajo', 'Zanahoria'],
      );
      const history = {
        'r_shop': RecipeHistoryRecord(
          recipeId: 'r_shop',
          preference: RecipePreference.favorite,
        ),
      };

      // Pantry has 2/4 (Ajo, Zanahoria), missing Pechuga de pollo + Limón.
      // Shopping list already has 'limon' (case/accent variant).
      final partialQueued = service.generateSuggestions(
        pantryIngredients: _pantry(['Ajo', 'Zanahoria']),
        shoppingListIngredients: _pantry(['limon']),
        recipes: [recipe],
        history: history,
      );

      expect(partialQueued, hasLength(1));
      expect(partialQueued.first.missingIngredients, equals(['Pechuga de pollo']));

      // Now shopping list also has 'Pollo' (culinary synonym for Pechuga de pollo).
      final allQueued = service.generateSuggestions(
        pantryIngredients: _pantry(['Ajo', 'Zanahoria']),
        shoppingListIngredients: _pantry(['limon', 'Pollo']),
        recipes: [recipe],
        history: history,
      );

      expect(allQueued, isEmpty);
    });

    test(
        'generates health-goal suggestions and excludes penalized recipes for active goals',
        () {
      final lightChicken = _makeRecipe(
        'light_chicken',
        'Pechuga con Güisquil',
        ['Pechuga de pollo', 'Güisquil', 'Limón'],
        attributes: {
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
        },
      );
      final creamyPasta = _makeRecipe(
        'creamy_pasta',
        'Pasta con Crema y Tocino',
        ['Pasta', 'Crema pura', 'Tocino'],
        attributes: {
          NutritionalAttribute.calorieDense,
          NutritionalAttribute.highSodiumOrProcessed,
        },
      );

      final loseWeightResults = service.generateSuggestions(
        pantryIngredients: _pantry(['Pechuga de pollo', 'Güisquil', 'Pasta', 'Crema pura']),
        shoppingListIngredients: const [],
        recipes: [lightChicken, creamyPasta],
        activeHealthGoals: {HealthGoal.loseWeight},
      );

      expect(loseWeightResults, hasLength(1));
      expect(loseWeightResults.first.recipe.id, equals('light_chicken'));
      expect(loseWeightResults.first.source, equals(ShoppingSuggestionSource.healthGoal));
      expect(loseWeightResults.first.matchedGoal, equals(HealthGoal.loseWeight));
      expect(
        loseWeightResults.first.message,
        equals(
          'Si compras Limón puedes preparar Pechuga con Güisquil para tu meta de bajar calorías',
        ),
      );

      final muscleResults = service.generateSuggestions(
        pantryIngredients: _pantry(['Pechuga de pollo', 'Güisquil']),
        shoppingListIngredients: const [],
        recipes: [lightChicken],
        activeHealthGoals: {HealthGoal.gainMuscle},
      );
      expect(
        muscleResults.first.message,
        contains('para tu meta de ganar masa muscular'),
      );

      final sodiumResults = service.generateSuggestions(
        pantryIngredients: _pantry(['Pechuga de pollo', 'Güisquil']),
        shoppingListIngredients: const [],
        recipes: [lightChicken],
        activeHealthGoals: {HealthGoal.reduceSodiumAndProcessed},
      );
      expect(
        sodiumResults.first.message,
        contains('para tu meta de reducir sodio'),
      );

      final fiberResults = service.generateSuggestions(
        pantryIngredients: _pantry(['Pechuga de pollo', 'Güisquil']),
        shoppingListIngredients: const [],
        recipes: [lightChicken],
        activeHealthGoals: {HealthGoal.increaseVitaminsAndFiber},
      );
      expect(
        fiberResults.first.message,
        contains('para tu meta de aumentar vitaminas y fibra'),
      );
    });

    test(
        'generates nutrition-tip suggestions when missing nutrients are supplied by missing ingredient',
        () {
      final carrotSoup = _makeRecipe(
        'carrot_soup',
        'Crema Ligera de Zanahoria',
        ['Papa', 'Cebolla blanca', 'Zanahoria'],
      );
      final processedDish = _makeRecipe(
        'proc_dish',
        'Chorizo con Zanahoria',
        ['Chorizo', 'Cebolla blanca', 'Zanahoria'],
      );

      const report = NutritionReport(
        hasCookingHistory: true,
        totalCookedMeals: 2,
        recentMealsEvaluated: 2,
        processedMeatMealsLast7Days: 0,
        processedMeatMealsRecent: 0,
        coveredNutrients: {TrackedNutrient.potassium},
        missingNutrients: {TrackedNutrient.vitaminA},
        tips: [],
      );

      final results = service.generateSuggestions(
        pantryIngredients: _pantry(['Papa', 'Cebolla blanca', 'Chorizo']),
        shoppingListIngredients: const [],
        recipes: [carrotSoup, processedDish],
        nutritionReport: report,
      );

      expect(results, hasLength(1));
      expect(results.first.recipe.id, equals('carrot_soup'));
      expect(results.first.source, equals(ShoppingSuggestionSource.nutritionTip));
      expect(results.first.missingNutrient, equals(TrackedNutrient.vitaminA));
      expect(
        results.first.message,
        equals(
          'Si compras Zanahoria puedes preparar Crema Ligera de Zanahoria para reforzar tu aporte de Vitamina A',
        ),
      );
    });

    test(
        'deduplicates favorite+goal recipes, ranks 1 missing before 2 missing, and enforces balanced cap',
        () {
      final favTwoMissing = _makeRecipe(
        'fav_two',
        'Favorita Dos Faltantes',
        ['Pollo', 'Tomate', 'Cebolla blanca', 'Limón'],
        attributes: {NutritionalAttribute.highProtein},
      );
      final likedOneMissing = _makeRecipe(
        'liked_one',
        'Gustada Un Faltante',
        ['Pollo', 'Tomate', 'Ajo'],
      );
      final goalOne = _makeRecipe(
        'goal_1',
        'Meta Uno',
        ['Pollo', 'Güisquil', 'Zanahoria'],
        attributes: {NutritionalAttribute.highProtein},
      );
      final goalTwo = _makeRecipe(
        'goal_2',
        'Meta Dos',
        ['Pollo', 'Güisquil', 'Espinaca'],
        attributes: {NutritionalAttribute.highProtein},
      );
      final goalThree = _makeRecipe(
        'goal_3',
        'Meta Tres',
        ['Pollo', 'Güisquil', 'Brócoli'],
        attributes: {NutritionalAttribute.highProtein},
      );
      final goalFour = _makeRecipe(
        'goal_4',
        'Meta Cuatro',
        ['Pollo', 'Güisquil', 'Chile pimiento'],
        attributes: {NutritionalAttribute.highProtein},
      );

      final results = service.generateSuggestions(
        pantryIngredients: _pantry(['Pollo', 'Tomate', 'Güisquil']),
        shoppingListIngredients: const [],
        recipes: [favTwoMissing, likedOneMissing, goalOne, goalTwo, goalThree, goalFour],
        history: const {
          'fav_two': RecipeHistoryRecord(
            recipeId: 'fav_two',
            preference: RecipePreference.favorite,
          ),
          'liked_one': RecipeHistoryRecord(
            recipeId: 'liked_one',
            preference: RecipePreference.liked,
          ),
        },
        activeHealthGoals: {HealthGoal.gainMuscle},
        maxSuggestions: 4,
      );

      // Balanced cap of 4 -> 2 history + 2 goal, with liked_one (1 missing) before fav_two (2 missing)
      // and fav_two NOT duplicated in the goal bucket.
      expect(results, hasLength(4));
      final ids = results.map((s) => s.recipe.id).toList();
      expect(ids.toSet(), hasLength(4));
      expect(ids.sublist(0, 2), equals(['liked_one', 'fav_two']));
      expect(results[2].source, equals(ShoppingSuggestionSource.healthGoal));
      expect(results[3].source, equals(ShoppingSuggestionSource.healthGoal));
    });

    test('loadSuggestions reads persisted pantry, shopping list, history (including cached custom recipe), and health goals',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );
      final history = RecipeHistoryService(ingredientStorageService: pantry);
      final goalStorage = HealthGoalStorageService(preferences: prefs);
      final nutrition = NutritionService(
        historyService: history,
        healthGoalStorageService: goalStorage,
      );

      await pantry.saveIngredients([
        const Ingredient(name: 'Aguacate'),
        const Ingredient(name: 'Tomate'),
        const Ingredient(name: 'Pepino'),
        const Ingredient(name: 'Cebolla morada'),
        const Ingredient(name: 'Cilantro'),
        const Ingredient(name: 'Limón'),
      ]);

      // Local recipe ensalada_aguacate_tomate has 7 ingredients -> only missing Aceite de oliva!
      final localSalad = LocalRecipeDataset.instance
          .getRecipeById('ensalada_aguacate_tomate')!;
      await history.setPreference(
        localSalad.id,
        RecipePreference.favorite,
      );

      // Custom cached external recipe missing 1 ingredient
      final customRecipe = _makeRecipe(
        'custom_bowl',
        'Tazón Personalizado',
        ['Aguacate', 'Tomate', 'Quinoa'],
      );
      await history.setPreference(
        customRecipe.id,
        RecipePreference.liked,
        recipe: customRecipe,
      );

      await goalStorage.saveSelectedGoals({HealthGoal.loseWeight});

      final wiredService = ShoppingSuggestionService(
        ingredientStorageService: pantry,
        shoppingListService: shopping,
        historyService: history,
        healthGoalStorageService: goalStorage,
        nutritionService: nutrition,
      );

      final loaded = await wiredService.loadSuggestions();
      final ids = loaded.map((s) => s.recipe.id).toList();
      expect(ids, contains('ensalada_aguacate_tomate'));
      expect(ids, contains('custom_bowl'));

      final saladSuggestion = loaded.firstWhere(
        (s) => s.recipe.id == 'ensalada_aguacate_tomate',
      );
      expect(saladSuggestion.missingIngredients, equals(['Aceite de oliva']));
      expect(
        saladSuggestion.message,
        equals(
          'Si compras Aceite de oliva puedes cocinar Ensalada Chapina de Aguacate y Tomate de tus recetas favoritas',
        ),
      );
    });
  });
}

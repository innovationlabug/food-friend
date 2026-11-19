import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/data/recipe_search_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_history_record.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testRecipe = Recipe(
    id: 'test_pollo_history',
    title: 'Pollo con Verduras Test',
    description: 'Pollo sazonado con verduras',
    ingredients: [
      RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
      RecipeIngredient(name: 'Zanahoria', displayAmount: '2 unidades'),
    ],
    instructions: ['Cocinar todo junto.'],
  );

  group('US-7.1: RecipeHistoryRecord Model & Idempotency', () {
    test('initializes with default zero timesCooked and empty dates', () {
      const record = RecipeHistoryRecord(recipeId: 'rec_1');
      expect(record.recipeId, 'rec_1');
      expect(record.timesCooked, 0);
      expect(record.cookedDates, isEmpty);
      expect(record.preference, RecipePreference.none);
      expect(record.isCookedToday(), isFalse);
      expect(record.lastCookedDate, isNull);
    });

    test('markCooked increments timesCooked and registers date', () {
      final now = DateTime(2026, 11, 11, 12, 0);
      const record = RecipeHistoryRecord(recipeId: 'rec_1');
      final updated = record.markCooked(cookedAt: now);

      expect(updated.timesCooked, 1);
      expect(updated.cookedDates.length, 1);
      expect(updated.isCookedOn(now), isTrue);
      expect(updated.isCookedToday(now: now), isTrue);
      expect(updated.lastCookedDate, now);
    });

    test('markCooked prevents same-day duplicates (daily idempotency)', () {
      final morning = DateTime(2026, 11, 11, 8, 30);
      final evening = DateTime(2026, 11, 11, 19, 45);

      const record = RecipeHistoryRecord(recipeId: 'rec_1');
      final firstCook = record.markCooked(cookedAt: morning);
      expect(firstCook.timesCooked, 1);

      // Same calendar day, second tap
      final secondCook = firstCook.markCooked(cookedAt: evening);
      expect(secondCook.timesCooked, 1);
      expect(secondCook.cookedDates.length, 1);
    });

    test('markCooked increments on different calendar days', () {
      final day1 = DateTime(2026, 11, 11, 12, 0);
      final day2 = DateTime(2026, 11, 12, 13, 0);

      const record = RecipeHistoryRecord(recipeId: 'rec_1');
      final firstCook = record.markCooked(cookedAt: day1);
      final secondCook = firstCook.markCooked(cookedAt: day2);

      expect(secondCook.timesCooked, 2);
      expect(secondCook.cookedDates.length, 2);
    });

    test('serializes and deserializes cleanly via toJson and fromJson', () {
      final date = DateTime(2026, 11, 11, 10, 0);
      final record = RecipeHistoryRecord(
        recipeId: 'rec_json',
        timesCooked: 3,
        cookedDates: [date],
        preference: RecipePreference.favorite,
        cachedRecipe: testRecipe,
      );

      final json = record.toJson();
      final restored = RecipeHistoryRecord.fromJson(json);

      expect(restored.recipeId, 'rec_json');
      expect(restored.timesCooked, 3);
      expect(restored.cookedDates.length, 1);
      expect(restored.preference, RecipePreference.favorite);
      expect(restored.cachedRecipe?.title, testRecipe.title);
    });
  });

  group('US-7.1: RecipeHistoryService Integration', () {
    late SharedPreferences prefs;
    late IngredientStorageService ingredientStorage;
    late RecipeHistoryService historyService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      ingredientStorage = IngredientStorageService(preferences: prefs);
      historyService = RecipeHistoryService(
        preferences: prefs,
        ingredientStorageService: ingredientStorage,
      );
    });

    test('records recipe cooking, increments timesCooked, and persists', () async {
      final today = DateTime(2026, 11, 11, 14, 0);
      final initialRecord = await historyService.getRecord(testRecipe.id);
      expect(initialRecord.timesCooked, 0);

      final updatedRecord = await historyService.recordCooked(
        testRecipe,
        cookedAt: today,
      );

      expect(updatedRecord.timesCooked, 1);
      expect(updatedRecord.isCookedOn(today), isTrue);

      final reloaded = await historyService.getRecord(testRecipe.id);
      expect(reloaded.timesCooked, 1);
      expect(reloaded.isCookedOn(today), isTrue);
    });

    test('daily idempotency prevents multiple counts on same day', () async {
      final morning = DateTime(2026, 11, 11, 9, 0);
      final evening = DateTime(2026, 11, 11, 20, 0);

      final first = await historyService.recordCooked(testRecipe, cookedAt: morning);
      expect(first.timesCooked, 1);

      final second = await historyService.recordCooked(testRecipe, cookedAt: evening);
      expect(second.timesCooked, 1);

      final reloaded = await historyService.getRecord(testRecipe.id);
      expect(reloaded.timesCooked, 1);
    });

    test('increments timesUsed on matching pantry ingredients when cooked', () async {
      // Add pantry ingredient
      await ingredientStorage.addIngredient(
        const Ingredient(name: 'Pechuga de pollo', timesUsed: 0),
      );

      final today = DateTime(2026, 11, 11, 12, 0);
      await historyService.recordCooked(testRecipe, cookedAt: today);

      final ingredients = await ingredientStorage.getIngredients();
      final pollo = ingredients.firstWhere((i) => i.name == 'Pechuga de pollo');

      expect(pollo.timesUsed, 1);
      expect(pollo.lastUsed, isNotNull);
    });

    test('increments timesUsed on synonym/sub-phrase pantry matches and respects daily idempotency', () async {
      await ingredientStorage.saveIngredients([
        const Ingredient(name: 'Pollo', timesUsed: 0),
        const Ingredient(name: 'Huevos', timesUsed: 1),
        const Ingredient(name: 'Aguacate', timesUsed: 0),
      ]);

      const synonymRecipe = Recipe(
        id: 'test_synonym_usage',
        title: 'Pollo con Huevo Test',
        ingredients: [
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
          RecipeIngredient(name: 'Huevo', displayAmount: '2 unidades'),
        ],
        instructions: ['Cocinar.'],
      );

      final morning = DateTime(2026, 11, 19, 9, 0);
      final evening = DateTime(2026, 11, 19, 20, 0);

      await historyService.recordCooked(synonymRecipe, cookedAt: morning);
      // Same-day repeat must not increment timesUsed or change lastUsed
      await historyService.recordCooked(synonymRecipe, cookedAt: evening);

      final updated = await ingredientStorage.getIngredients();
      final pollo = updated.firstWhere((i) => i.name == 'Pollo');
      final huevos = updated.firstWhere((i) => i.name == 'Huevos');
      final aguacate = updated.firstWhere((i) => i.name == 'Aguacate');

      expect(pollo.timesUsed, 1);
      expect(pollo.lastUsed, morning);
      expect(huevos.timesUsed, 2);
      expect(huevos.lastUsed, morning);
      expect(aguacate.timesUsed, 0);
      expect(aguacate.lastUsed, isNull);
    });

    test('applyPantryDepletion deducts items and optionally moves them to shopping list preserving usage stats', () async {
      final shoppingService = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: ingredientStorage,
      );
      final usedAt = DateTime(2026, 11, 19, 12, 30);

      await ingredientStorage.saveIngredients([
        Ingredient(name: 'Pechuga de pollo', timesUsed: 2, lastUsed: usedAt),
        Ingredient(name: 'Zanahoria', timesUsed: 1, lastUsed: usedAt),
        const Ingredient(name: 'Papa', timesUsed: 0),
      ]);

      final pantryBefore = await ingredientStorage.getIngredients();
      final chicken = pantryBefore.firstWhere((i) => i.name == 'Pechuga de pollo');

      // Deduct and add to Por comprar
      final resultWithBuy = await historyService.applyPantryDepletion(
        depletedIngredients: [chicken],
        addToShoppingList: true,
        shoppingListService: shoppingService,
      );

      expect(
        resultWithBuy.pantry.map((i) => i.name),
        equals(['Zanahoria', 'Papa']),
      );
      expect(resultWithBuy.shoppingList.length, 1);
      expect(resultWithBuy.shoppingList.first.name, 'Pechuga de pollo');
      expect(resultWithBuy.shoppingList.first.timesUsed, 2);
      expect(resultWithBuy.shoppingList.first.lastUsed, usedAt);

      // Deduct Zanahoria without adding to Por comprar
      final carrot = resultWithBuy.pantry.firstWhere((i) => i.name == 'Zanahoria');
      final resultRemoveOnly = await historyService.applyPantryDepletion(
        depletedIngredients: [carrot],
        addToShoppingList: false,
        shoppingListService: shoppingService,
      );

      expect(resultRemoveOnly.pantry.map((i) => i.name), equals(['Papa']));
      expect(
        resultRemoveOnly.shoppingList.map((i) => i.name),
        equals(['Pechuga de pollo']),
      );
    });

    test('getAllKnownRecipes includes local recipes and cached external recipes', () async {
      const externalRecipe = Recipe(
        id: 'external_curry_ai',
        title: 'Curry Especial con Maní AI',
        ingredients: [],
        instructions: [],
      );

      await historyService.recordCooked(externalRecipe);

      final all = await historyService.getAllKnownRecipes();
      expect(all.length, greaterThan(LocalRecipeDataset.instance.recipes.length));
      expect(all.any((r) => r.id == externalRecipe.id), isTrue);
    });
  });

  group('US-7.2: Recipe Preference Marks & Exclusion', () {
    late SharedPreferences prefs;
    late RecipeHistoryService historyService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      historyService = RecipeHistoryService(preferences: prefs);
    });

    test('saves and toggles all four preference marks', () async {
      // 1. Set to favorite
      var rec = await historyService.setPreference(
        testRecipe.id,
        RecipePreference.favorite,
      );
      expect(rec.preference, RecipePreference.favorite);

      // 2. Set to liked
      rec = await historyService.setPreference(
        testRecipe.id,
        RecipePreference.liked,
      );
      expect(rec.preference, RecipePreference.liked);

      // 3. Set to disliked
      rec = await historyService.setPreference(
        testRecipe.id,
        RecipePreference.disliked,
      );
      expect(rec.preference, RecipePreference.disliked);

      // 4. Set to never
      rec = await historyService.setPreference(
        testRecipe.id,
        RecipePreference.never,
      );
      expect(rec.preference, RecipePreference.never);

      // 5. Toggle back to none
      rec = await historyService.setPreference(
        testRecipe.id,
        RecipePreference.none,
      );
      expect(rec.preference, RecipePreference.none);
    });

    test('RecipeSearchService excludes recipes marked as Nunca (never)', () async {
      final searchService = RecipeSearchService();

      // Ensure testRecipe matches 'Pechuga de pollo' normally
      final normalResults = searchService.searchRecipes(
        selectedIngredientNames: ['Pechuga de pollo'],
        recipePool: [testRecipe],
      );
      expect(normalResults.length, 1);

      // Mark testRecipe as never
      final historyMap = {
        testRecipe.id: RecipeHistoryRecord(
          recipeId: testRecipe.id,
          preference: RecipePreference.never,
        ),
      };

      // Search with history containing 'never'
      final filteredResults = searchService.searchRecipes(
        selectedIngredientNames: ['Pechuga de pollo'],
        recipePool: [testRecipe],
        history: historyMap,
      );

      // Must be completely excluded
      expect(filteredResults, isEmpty);
    });
  });
}

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

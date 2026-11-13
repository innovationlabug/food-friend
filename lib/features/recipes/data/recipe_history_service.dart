import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ingredients/data/ingredient_storage_service.dart';
import '../domain/recipe.dart';
import '../domain/recipe_history_record.dart';
import '../domain/recipe_preference.dart';
import 'local_recipe_dataset.dart';

/// Local persistence service tracking recipe cooking history, timestamps,
/// and user preferences (Favorita, Me gustó, No me gustó, Nunca).
/// Backed by SharedPreferences (localStorage on Web, SharedPreferences on Android).
class RecipeHistoryService {
  RecipeHistoryService({
    SharedPreferences? preferences,
    IngredientStorageService? ingredientStorageService,
  })  : _preferences = preferences,
        _ingredientStorageService =
            ingredientStorageService ?? IngredientStorageService(preferences: preferences);

  SharedPreferences? _preferences;
  final IngredientStorageService _ingredientStorageService;

  static const String storageKey = 'food_friend_recipe_history';

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  /// Retrieves all persisted recipe history records mapped by recipeId.
  Future<Map<String, RecipeHistoryRecord>> getHistory() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(storageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return <String, RecipeHistoryRecord>{};
    }

    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return <String, RecipeHistoryRecord>{};
      }

      final result = <String, RecipeHistoryRecord>{};
      decoded.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          result[key] = RecipeHistoryRecord.fromJson(value);
        }
      });
      return result;
    } catch (_) {
      return <String, RecipeHistoryRecord>{};
    }
  }

  /// Retrieves the history record for a specific [recipeId].
  /// If no record exists, returns a new record with default zero values.
  Future<RecipeHistoryRecord> getRecord(String recipeId) async {
    final history = await getHistory();
    return history[recipeId] ?? RecipeHistoryRecord(recipeId: recipeId);
  }

  /// Checks if a recipe was already cooked today.
  Future<bool> isCookedToday(String recipeId, {DateTime? now}) async {
    final record = await getRecord(recipeId);
    return record.isCookedToday(now: now);
  }

  /// Records that [recipe] was cooked on [cookedAt] (defaults to DateTime.now()).
  ///
  /// Sanity Check / Same-Day Idempotency:
  /// If the recipe has already been logged as cooked on this calendar day,
  /// it registers only once for that day. `timesCooked` is not incremented again.
  ///
  /// Matching available pantry ingredients have their [timesUsed] counter
  /// incremented and [lastUsed] timestamp updated.
  Future<RecipeHistoryRecord> recordCooked(
    Recipe recipe, {
    DateTime? cookedAt,
  }) async {
    final date = cookedAt ?? DateTime.now();
    final history = await getHistory();
    final existing = history[recipe.id] ?? RecipeHistoryRecord(recipeId: recipe.id);

    // Same-day idempotency check
    if (existing.isCookedOn(date)) {
      return existing;
    }

    // Check if recipe is from LocalRecipeDataset; if not, cache it for management view
    final isLocal = LocalRecipeDataset.instance.recipes.any((r) => r.id == recipe.id);
    final updatedRecord = existing.markCooked(cookedAt: date).copyWith(
          cachedRecipe: isLocal ? null : (existing.cachedRecipe ?? recipe),
        );

    history[recipe.id] = updatedRecord;
    await _saveHistory(history);

    // Update timesUsed and lastUsed on matching home ingredients
    for (final ingredient in recipe.ingredients) {
      await _ingredientStorageService.recordIngredientUsage(
        ingredient.name,
        usedAt: date,
      );
    }

    return updatedRecord;
  }

  /// Sets or updates the preference mark for [recipeId].
  Future<RecipeHistoryRecord> setPreference(
    String recipeId,
    RecipePreference preference, {
    Recipe? recipe,
  }) async {
    final history = await getHistory();
    final existing = history[recipeId] ?? RecipeHistoryRecord(recipeId: recipeId);

    final isLocal = LocalRecipeDataset.instance.recipes.any((r) => r.id == recipeId);
    final updated = existing.copyWith(
      preference: preference,
      cachedRecipe: isLocal ? null : (existing.cachedRecipe ?? recipe),
    );

    history[recipeId] = updated;
    await _saveHistory(history);
    return updated;
  }

  /// Retrieves all known recipes: local dataset recipes plus any cached external recipes.
  Future<List<Recipe>> getAllKnownRecipes() async {
    final history = await getHistory();
    final recipesMap = <String, Recipe>{};

    for (final local in LocalRecipeDataset.instance.recipes) {
      recipesMap[local.id] = local;
    }

    for (final record in history.values) {
      if (record.cachedRecipe != null && !recipesMap.containsKey(record.recipeId)) {
        recipesMap[record.recipeId] = record.cachedRecipe!;
      }
    }

    return recipesMap.values.toList();
  }

  /// Clears all stored recipe history.
  Future<void> clearHistory() async {
    final prefs = await _prefs;
    await prefs.remove(storageKey);
  }

  Future<void> _saveHistory(Map<String, RecipeHistoryRecord> history) async {
    final prefs = await _prefs;
    final map = <String, dynamic>{};
    history.forEach((key, record) {
      map[key] = record.toJson();
    });
    await prefs.setString(storageKey, jsonEncode(map));
  }
}

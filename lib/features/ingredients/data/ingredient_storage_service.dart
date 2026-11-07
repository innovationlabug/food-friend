import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/string_normalizer.dart';
import '../domain/ingredient.dart';

/// Local persistence service for ingredients on Flutter Web and Android.
/// Backed by SharedPreferences (localStorage on Web, SharedPreferences on Android).
class IngredientStorageService {
  IngredientStorageService({SharedPreferences? preferences}) {
    _preferences = preferences;
  }

  SharedPreferences? _preferences;

  static const String storageKey = 'food_friend_ingredients';

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  /// Retrieves the persisted list of ingredients.
  /// Returns an empty list if no ingredients have been saved yet.
  Future<List<Ingredient>> getIngredients() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(storageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return <Ingredient>[];
    }

    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! List) return <Ingredient>[];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Ingredient.fromJson)
          .toList();
    } catch (_) {
      // In case of corrupt or outdated data format, return empty list gracefully
      return <Ingredient>[];
    }
  }

  /// Persists the list of ingredients to local storage, ensuring duplicates are consolidated.
  Future<void> saveIngredients(List<Ingredient> ingredients) async {
    final prefs = await _prefs;
    final consolidated = consolidateList(ingredients);
    final jsonList = consolidated.map((item) => item.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(jsonList));
  }

  /// Adds a new ingredient to local storage.
  /// If an ingredient with the same normalized name already exists,
  /// it consolidates quantities, brands, and expiration dates cleanly.
  Future<List<Ingredient>> addIngredient(Ingredient newIngredient) async {
    final currentList = await getIngredients();
    final updatedList = <Ingredient>[];
    bool merged = false;

    for (final existing in currentList) {
      if (!merged &&
          StringNormalizer.areEquivalent(existing.name, newIngredient.name)) {
        updatedList.add(_mergeIngredients(existing, newIngredient));
        merged = true;
      } else {
        updatedList.add(existing);
      }
    }

    if (!merged) {
      updatedList.add(newIngredient);
    }

    await saveIngredients(updatedList);
    return updatedList;
  }

  /// Removes an ingredient by name (case- and accent-insensitive).
  Future<List<Ingredient>> removeIngredient(String name) async {
    final currentList = await getIngredients();
    final updatedList = currentList
        .where(
            (item) => !StringNormalizer.areEquivalent(item.name, name))
        .toList();

    await saveIngredients(updatedList);
    return updatedList;
  }

  /// Clears all stored ingredients.
  Future<void> clearIngredients() async {
    final prefs = await _prefs;
    await prefs.remove(storageKey);
  }

  /// Consolidates a list of ingredients so that any items with equivalent
  /// names are merged into a single entry without duplicates.
  List<Ingredient> consolidateList(List<Ingredient> ingredients) {
    final map = <String, Ingredient>{};

    for (final item in ingredients) {
      final key = StringNormalizer.normalize(item.name);
      if (map.containsKey(key)) {
        map[key] = _mergeIngredients(map[key]!, item);
      } else {
        map[key] = item;
      }
    }

    return map.values.toList();
  }

  /// Merges two matching ingredients, consolidating amounts if units match.
  Ingredient _mergeIngredients(Ingredient base, Ingredient incoming) {
    double? resolvedAmount;
    final resolvedUnit = incoming.amountUnit ?? base.amountUnit;

    if (base.amountValue != null &&
        incoming.amountValue != null &&
        base.amountUnit == incoming.amountUnit) {
      // Sum amounts when units match
      resolvedAmount = base.amountValue! + incoming.amountValue!;
    } else {
      resolvedAmount = incoming.amountValue ?? base.amountValue;
    }

    // Resolve earliest expiration date if both provided
    DateTime? resolvedDate;
    if (base.expirationDate != null && incoming.expirationDate != null) {
      resolvedDate = base.expirationDate!.isBefore(incoming.expirationDate!)
          ? base.expirationDate
          : incoming.expirationDate;
    } else {
      resolvedDate = incoming.expirationDate ?? base.expirationDate;
    }

    return Ingredient(
      name: base.name, // Retain primary existing name casing
      brand: incoming.brand ?? base.brand,
      amountValue: resolvedAmount,
      amountUnit: resolvedUnit,
      expirationDate: resolvedDate,
      isBestBefore: incoming.isBestBefore ?? base.isBestBefore,
    );
  }
}

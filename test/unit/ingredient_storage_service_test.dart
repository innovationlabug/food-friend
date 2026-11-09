import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/amount_unit.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IngredientStorageService storageService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storageService = IngredientStorageService();
  });

  group('IngredientStorageService - Basic CRUD', () {
    test('returns empty list when storage is empty', () async {
      final ingredients = await storageService.getIngredients();
      expect(ingredients, isEmpty);
    });

    test('saves and retrieves ingredients correctly', () async {
      final initial = [
        const Ingredient(name: 'Arroz', amountValue: 1.0, amountUnit: AmountUnit.pounds),
        const Ingredient(name: 'Frijol', amountValue: 2.0, amountUnit: AmountUnit.pounds),
      ];

      await storageService.saveIngredients(initial);
      final retrieved = await storageService.getIngredients();

      expect(retrieved.length, equals(2));
      expect(retrieved[0].name, equals('Arroz'));
      expect(retrieved[1].name, equals('Frijol'));
    });

    test('removes an ingredient by name (case- and accent-insensitive)', () async {
      await storageService.saveIngredients([
        const Ingredient(name: 'Limón'),
        const Ingredient(name: 'Cebolla'),
      ]);

      // Remove with unaccented lowercase name
      final afterRemove = await storageService.removeIngredient('limon');

      expect(afterRemove.length, equals(1));
      expect(afterRemove.first.name, equals('Cebolla'));

      final retrieved = await storageService.getIngredients();
      expect(retrieved.length, equals(1));
      expect(retrieved.first.name, equals('Cebolla'));
    });

    test('clears all ingredients from storage', () async {
      await storageService.saveIngredients([
        const Ingredient(name: 'Aceite'),
      ]);

      await storageService.clearIngredients();
      final retrieved = await storageService.getIngredients();
      expect(retrieved, isEmpty);
    });
  });

  group('IngredientStorageService - Duplicate Handling & Consolidation', () {
    test('adds new unique ingredient to empty and populated list', () async {
      final firstAdd = await storageService.addIngredient(
        const Ingredient(name: 'Zanahoria', amountValue: 3, amountUnit: AmountUnit.units),
      );
      expect(firstAdd.length, equals(1));

      final secondAdd = await storageService.addIngredient(
        const Ingredient(name: 'Papa', amountValue: 5, amountUnit: AmountUnit.units),
      );
      expect(secondAdd.length, equals(2));
    });

    test('consolidates duplicates with case differences (e.g. Pollo vs pollo)', () async {
      await storageService.addIngredient(
        const Ingredient(name: 'Pollo', amountValue: 500, amountUnit: AmountUnit.grams),
      );

      final updated = await storageService.addIngredient(
        const Ingredient(name: 'pollo', amountValue: 300, amountUnit: AmountUnit.grams),
      );

      // Should not create a second entry, but consolidate amount
      expect(updated.length, equals(1));
      expect(updated.first.amountValue, equals(800.0));
      expect(updated.first.amountUnit, equals(AmountUnit.grams));
    });

    test('consolidates duplicates with accent differences (e.g. Limón vs limon)', () async {
      await storageService.addIngredient(
        const Ingredient(name: 'Limón', amountValue: 4, amountUnit: AmountUnit.units),
      );

      final updated = await storageService.addIngredient(
        const Ingredient(name: 'limon', amountValue: 2, amountUnit: AmountUnit.units),
      );

      expect(updated.length, equals(1));
      expect(updated.first.name, equals('Limón'));
      expect(updated.first.amountValue, equals(6.0));
    });

    test('consolidates brand information if new item specifies brand', () async {
      await storageService.addIngredient(
        const Ingredient(name: 'Crema'),
      );

      final updated = await storageService.addIngredient(
        const Ingredient(name: 'crema', brand: 'Trebolac'),
      );

      expect(updated.length, equals(1));
      expect(updated.first.brand, equals('Trebolac'));
    });

    test('consolidates earliest expiration date when both provide dates', () async {
      final earlierDate = DateTime(2026, 11, 15);
      final laterDate = DateTime(2026, 11, 28);

      await storageService.addIngredient(
        Ingredient(name: 'Yogurt', expirationDate: laterDate),
      );

      final updated = await storageService.addIngredient(
        Ingredient(name: 'yogurt', expirationDate: earlierDate, isBestBefore: true),
      );

      expect(updated.length, equals(1));
      expect(updated.first.expirationDate, equals(earlierDate));
      expect(updated.first.isBestBefore, isTrue);
    });

    test('consolidateList merges multiple duplicate entries from raw list', () {
      final rawList = [
        const Ingredient(name: 'Tomate', amountValue: 2, amountUnit: AmountUnit.units),
        const Ingredient(name: 'Cebolla', amountValue: 1, amountUnit: AmountUnit.units),
        const Ingredient(name: 'tomate', amountValue: 3, amountUnit: AmountUnit.units),
        const Ingredient(name: 'TOMATE', amountValue: 1, amountUnit: AmountUnit.units),
      ];

      final consolidated = storageService.consolidateList(rawList);

      expect(consolidated.length, equals(2));
      final tomato = consolidated.firstWhere((i) => i.name.toLowerCase() == 'tomate');
      expect(tomato.amountValue, equals(6.0));
      expect(tomato.amountUnit, equals(AmountUnit.units));
    });

    test('consolidates timesUsed (sum) and lastUsed (latest date)', () async {
      final earlier = DateTime(2026, 11, 1);
      final later = DateTime(2026, 11, 8);

      await storageService.addIngredient(
        Ingredient(name: 'Ajo', timesUsed: 3, lastUsed: earlier),
      );

      final updated = await storageService.addIngredient(
        Ingredient(name: 'ajo', timesUsed: 2, lastUsed: later),
      );

      expect(updated.length, equals(1));
      expect(updated.first.timesUsed, equals(5));
      expect(updated.first.lastUsed, equals(later));
    });

    test('recordIngredientUsage increments timesUsed and updates lastUsed', () async {
      await storageService.addIngredient(
        const Ingredient(name: 'Cilantro'),
      );

      final usageDate = DateTime(2026, 11, 9, 14, 0);
      final updated = await storageService.recordIngredientUsage('cilantro', usedAt: usageDate);

      expect(updated.length, equals(1));
      expect(updated.first.timesUsed, equals(1));
      expect(updated.first.lastUsed, equals(usageDate));

      final retrieved = await storageService.getIngredients();
      expect(retrieved.first.timesUsed, equals(1));
      expect(retrieved.first.lastUsed, equals(usageDate));
    });
  });
}


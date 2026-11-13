import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/amount_unit.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('US-8.1: ShoppingListStorageService independent persistence & consolidation', () {
    test('maintains Lista de Compras completely separate from Mis Ingredientes', () async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );

      await pantry.addIngredient(const Ingredient(name: 'Pollo'));
      await shopping.addIngredient(const Ingredient(name: 'Tomate'));
      await shopping.addIngredient(const Ingredient(name: 'Cebolla'));

      final pantryItems = await pantry.getIngredients();
      final shoppingItems = await shopping.getIngredients();

      expect(pantryItems.map((e) => e.name), equals(['Pollo']));
      expect(shoppingItems.map((e) => e.name), equals(['Tomate', 'Cebolla']));
    });

    test('clearing shopping list does not alter available pantry ingredients', () async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );

      await pantry.addIngredient(const Ingredient(name: 'Arroz blanco'));
      await shopping.addIngredient(const Ingredient(name: 'Frijoles negros'));

      await shopping.clearIngredients();

      expect(await shopping.getIngredients(), isEmpty);
      expect((await pantry.getIngredients()).map((e) => e.name), equals(['Arroz blanco']));
    });

    test('consolidates duplicate items added to shopping list case- and accent-insensitively',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final shopping = ShoppingListStorageService(preferences: prefs);

      await shopping.addIngredient(
        const Ingredient(name: 'Limón', amountValue: 2, amountUnit: AmountUnit.units),
      );
      await shopping.addIngredient(
        const Ingredient(name: 'limon', amountValue: 3, amountUnit: AmountUnit.units),
      );
      await shopping.addIngredient(const Ingredient(name: 'Tomate'));
      await shopping.addIngredient(const Ingredient(name: 'tomate'));

      final items = await shopping.getIngredients();
      expect(items.length, equals(2));
      expect(items[0].name, equals('Limón'));
      expect(items[0].amountValue, equals(5.0));
      expect(items[1].name, equals('Tomate'));
      expect(await shopping.containsIngredient('LIMON'), isTrue);
      expect(await shopping.containsIngredient('Aguacate'), isFalse);
    });
  });

  group('US-8.2: ShoppingListStorageService markAsBought & dismissItem', () {
    test('markAsBought transfers item from shopping list to Mis Ingredientes and consolidates',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );

      await pantry.addIngredient(
        const Ingredient(name: 'Tomate', amountValue: 2, amountUnit: AmountUnit.units),
      );
      await shopping.addIngredient(
        const Ingredient(name: 'tomate', amountValue: 3, amountUnit: AmountUnit.units),
      );
      await shopping.addIngredient(const Ingredient(name: 'Aguacate'));

      final result = await shopping.markAsBought('Tomate');

      expect(result.shoppingList.map((e) => e.name), equals(['Aguacate']));
      expect(result.availableIngredients.length, equals(1));
      expect(result.availableIngredients[0].name, equals('Tomate'));
      expect(result.availableIngredients[0].amountValue, equals(5.0));

      // Verify persisted state
      expect((await shopping.getIngredients()).map((e) => e.name), equals(['Aguacate']));
      expect((await pantry.getIngredients()).first.amountValue, equals(5.0));
    });

    test('dismissItem removes item from shopping list without adding it to Mis Ingredientes',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );

      await shopping.addIngredient(const Ingredient(name: 'Chorizo'));
      await shopping.addIngredient(const Ingredient(name: 'Cebolla blanca'));

      final remaining = await shopping.dismissItem('chorizo');

      expect(remaining.map((e) => e.name), equals(['Cebolla blanca']));
      expect(await pantry.getIngredients(), isEmpty);
    });
  });
}


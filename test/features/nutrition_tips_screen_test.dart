import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/nutrition/data/nutrition_service.dart';
import 'package:food_friend/features/nutrition/presentation/nutrition_tips_screen.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';

Recipe _recipe(String id, String title, List<String> ingredients) {
  return Recipe(
    id: id,
    title: title,
    ingredients: ingredients
        .map((n) => RecipeIngredient(name: n, displayAmount: '1 porción'))
        .toList(),
    instructions: const <String>['Paso 1'],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('US-9.2: NutritionTipsScreen UI & Shopping List Integration', () {
    testWidgets('shows encouraging empty history message and foundational tips when no meals are cooked',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final historyService = RecipeHistoryService(preferences: prefs);
      final nutritionService = NutritionService(historyService: historyService);
      final shoppingService = ShoppingListStorageService(preferences: prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: NutritionTipsScreen(
            nutritionService: nutritionService,
            historyService: historyService,
            shoppingListService: shoppingService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consejos de Nutrición'), findsOneWidget);
      expect(find.text('Aún no has registrado recetas cocinadas'), findsOneWidget);
      expect(find.textContaining('Lo cociné'), findsOneWidget);
      expect(find.text('Proteína completa combinando arroz y frijoles'), findsOneWidget);
      expect(find.text('Variedad diaria de frutas y verduras'), findsOneWidget);
      expect(find.text('Asistente de nutrición'), findsNothing);
    });

    testWidgets(
        'renders health alert, protein pairing, and vitamin suggestions and adds recommended ingredient to Lista de Compras',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );
      final history = RecipeHistoryService(
        preferences: prefs,
        ingredientStorageService: pantry,
      );
      final nutrition = NutritionService(historyService: history);

      await history.recordCooked(
        _recipe('m1', 'Huevos con salchicha', ['Salchicha', 'Huevo']),
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      await history.recordCooked(
        _recipe('m2', 'Arroz blanco sencillo', ['Arroz blanco', 'Cebolla blanca']),
        cookedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NutritionTipsScreen(
            nutritionService: nutrition,
            historyService: history,
            shoppingListService: shopping,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Health alert rendered
      expect(find.text('Modera el consumo de carnes procesadas'), findsOneWidget);

      // 2. Protein pairing rendered
      expect(
        find.text('Combina granos y legumbres para lograr proteína completa'),
        findsOneWidget,
      );

      // 3. Vitamin suggestion rendered (scroll if needed on compact viewport)
      final vitA = find.text('Refuerza tu aporte de Vitamina A');
      await tester.scrollUntilVisible(vitA, 200);
      await tester.pumpAndSettle();
      expect(vitA, findsOneWidget);

      // 4. Tap to add recommended vitamin source ('Zanahoria') to Lista de Compras
      final addCarrotBtn = find.widgetWithText(OutlinedButton, 'Agregar Zanahoria').first;
      await tester.ensureVisible(addCarrotBtn);
      await tester.pumpAndSettle();
      await tester.tap(addCarrotBtn);
      await tester.pumpAndSettle();

      expect(find.text('"Zanahoria" agregado a tu lista de compras'), findsOneWidget);
      expect(find.text('Zanahoria (en lista)'), findsAtLeastNWidgets(1));

      // Persisted in Lista de Compras and NOT in Mis Ingredientes
      final shoppingItems = await shopping.getIngredients();
      expect(shoppingItems.map((i) => i.name), contains('Zanahoria'));
      expect(await pantry.getIngredients(), isEmpty);
    });
  });
}


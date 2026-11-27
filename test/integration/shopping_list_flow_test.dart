import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/core/settings/settings_controller.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/nutrition/data/health_goal_storage_service.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:food_friend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      SettingsController.hasCompletedModeSelectionKey: true,
    });
    SettingsController.instance.resetToDefaults();
  });

  testWidgets(
      'E2E Flow US-8.1: Clean state -> Home -> Lista de Compras -> Add via search, closest match, categories, and RecipeDetailScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // 1. Navigate to Lista de compras from HomeScreen
    final buyListBtn = find.text('Lista de compras').first;
    await tester.ensureVisible(buyListBtn);
    await tester.pumpAndSettle();
    await tester.tap(buyListBtn);
    await tester.pumpAndSettle();

    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

    // 2. Open AddIngredientScreen in shopping list mode
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar a lista de compras'));
    await tester.pumpAndSettle();

    expect(find.text('Agregar a lista de compras'), findsOneWidget);
    expect(find.text('Foto'), findsNothing);

    // 3. Add via search suggestion
    final searchField = find.widgetWithText(TextFormField, 'Nombre del ingrediente');
    await tester.enterText(searchField, 'aguacate');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aguacate'));
    await tester.pumpAndSettle();

    // 4. Add via closest match fallback ('tomte' -> 'Tomate')
    await tester.enterText(searchField, 'tomte');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // 5. Add via category browser
    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frutas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cítricos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limón'));
    await tester.pumpAndSettle();

    // 6. Return to shopping list
    await tester.tap(find.text('Ver lista'));
    await tester.pumpAndSettle();

    expect(find.text('Por comprar (3)'), findsOneWidget);
    expect(find.text('Aguacate'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Limón'), findsOneWidget);

    // 7. Verify available ingredients list ("Mis ingredientes") remains completely empty
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    expect(await pantry.getIngredients(), isEmpty);
    expect((await shopping.getIngredients()).length, equals(3));

    // Switch to Mis ingredientes tab and verify empty state
    await tester.tap(find.text('Mis ingredientes'));
    await tester.pumpAndSettle();
    expect(find.text('No tienes ingredientes guardados'), findsOneWidget);
  });

  testWidgets(
      'E2E Flow US-8.2: Comprado transfers ingredient to Mis ingredientes and unlocks recipe suggestions while Descartar removes completely',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    await pantry.addIngredient(const Ingredient(name: 'Tomate'));
    await shopping.addIngredients([
      const Ingredient(name: 'Aguacate'),
      const Ingredient(name: 'Mortadela'),
    ]);

    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // 1. Navigate to Lista de compras
    final buyListBtn = find.text('Lista de compras').first;
    await tester.ensureVisible(buyListBtn);
    await tester.pumpAndSettle();
    await tester.tap(buyListBtn);
    await tester.pumpAndSettle();

    expect(find.text('Por comprar (2)'), findsOneWidget);
    expect(find.text('Aguacate'), findsOneWidget);
    expect(find.text('Mortadela'), findsOneWidget);

    // 2. Tap Comprado on Aguacate
    await tester.tap(find.byTooltip('Marcar como comprado').first);
    await tester.pumpAndSettle();
    expect(find.text('"Aguacate" movido a Mis ingredientes'), findsOneWidget);
    expect(find.text('Por comprar (1)'), findsOneWidget);

    // 3. Tap Descartar on Mortadela
    await tester.tap(find.byTooltip('Descartar de la lista').first);
    await tester.pumpAndSettle();
    expect(find.text('"Mortadela" descartado de la lista de compras'), findsOneWidget);
    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

    // 4. Switch to Mis ingredientes and verify Aguacate is selectable for recipe generation
    await tester.tap(find.text('Mis ingredientes'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredientes disponibles (2)'), findsOneWidget);
    expect(find.text('Aguacate'), findsOneWidget);
    expect(find.text('Mortadela'), findsNothing);
    expect(find.text('Buscar recetas'), findsOneWidget);

    // 5. Generate recipes using Tomate + newly bought Aguacate
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar recetas'));
    await tester.pumpAndSettle();
    expect(find.text('Recetas sugeridas'), findsOneWidget);
  });

  testWidgets(
      'E2E Flow FEAT-3: Home -> Lista de compras -> smart suggestions from favorites and health goals -> one-tap add and Comprado refresh',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    final history = RecipeHistoryService(ingredientStorageService: pantry);
    final goalStorage = HealthGoalStorageService();

    await pantry.saveIngredients([
      const Ingredient(name: 'Frijoles negros'),
      const Ingredient(name: 'Cebolla blanca'),
      const Ingredient(name: 'Ajo'),
      const Ingredient(name: 'Brócoli'),
      const Ingredient(name: 'Zanahoria'),
      const Ingredient(name: 'Chile pimiento'),
      const Ingredient(name: 'Curry'),
      const Ingredient(name: 'Aceite vegetal'),
    ]);
    await history.setPreference(
      'frijoles_parados_queso',
      RecipePreference.favorite,
    );
    await goalStorage.saveSelectedGoals({HealthGoal.loseWeight});

    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // 1. Navigate to Lista de compras from HomeScreen
    final buyListBtn = find.text('Lista de compras').first;
    await tester.ensureVisible(buyListBtn);
    await tester.pumpAndSettle();
    await tester.tap(buyListBtn);
    await tester.pumpAndSettle();

    expect(find.text('Sugerencias para tu lista'), findsOneWidget);
    expect(
      find.text(
        'Si compras Epazote y Queso de capas puedes cocinar Frijoles Negros Parados con Epazote y Queso de tus recetas favoritas',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Si compras Maní puedes preparar Salteado de Verduras al Curry con Maní para tu meta de bajar calorías',
      ),
      findsOneWidget,
    );

    // 2. Add Epazote in one tap and verify Por comprar + suggestion update
    final addEpazote = find.byKey(
      const ValueKey('add_suggestion_frijoles_parados_queso_epazote'),
    );
    await tester.ensureVisible(addEpazote);
    await tester.pumpAndSettle();
    await tester.tap(addEpazote);
    await tester.pumpAndSettle();

    expect(find.text('Por comprar (1)'), findsOneWidget);
    expect(find.text('Epazote'), findsOneWidget);
    expect(
      find.text(
        'Si compras Queso de capas puedes cocinar Frijoles Negros Parados con Epazote y Queso de tus recetas favoritas',
      ),
      findsOneWidget,
    );

    // 3. Add Maní in one tap and verify health-goal suggestion disappears
    final addMani = find.byKey(
      const ValueKey('add_suggestion_salteado_verduras_curry_mani'),
    );
    await tester.ensureVisible(addMani);
    await tester.pumpAndSettle();
    await tester.tap(addMani);
    await tester.pumpAndSettle();

    expect(find.text('Por comprar (2)'), findsOneWidget);
    expect(find.text('Maní'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('shopping_suggestion_salteado_verduras_curry')),
      findsNothing,
    );

    // Verify persistence with no duplicates
    final queued = await shopping.getIngredients();
    expect(queued.map((i) => i.name), equals(['Epazote', 'Maní']));

    // 4. Mark Epazote as Comprado -> moves to pantry and keeps suggestions accurate
    await tester.tap(find.byTooltip('Marcar como comprado').first);
    await tester.pumpAndSettle();

    expect(find.text('Por comprar (1)'), findsOneWidget);
    expect((await pantry.getIngredients()).map((i) => i.name), contains('Epazote'));
    expect(
      find.text(
        'Si compras Queso de capas puedes cocinar Frijoles Negros Parados con Epazote y Queso de tus recetas favoritas',
      ),
      findsOneWidget,
    );
  });
}

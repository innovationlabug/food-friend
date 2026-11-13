import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:food_friend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'E2E Flow US-8.1: Clean state -> Home -> Lista de Compras -> Add via search, closest match, categories, and RecipeDetailScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // 1. Navigate to Lista de compras from HomeScreen
    final buyListBtn = find.text('Ir a lista de compras').first;
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
    final buyListBtn = find.text('Ir a lista de compras').first;
    await tester.ensureVisible(buyListBtn);
    await tester.pumpAndSettle();
    await tester.tap(buyListBtn);
    await tester.pumpAndSettle();

    expect(find.text('Por comprar (2)'), findsOneWidget);
    expect(find.text('Aguacate'), findsOneWidget);
    expect(find.text('Mortadela'), findsOneWidget);

    // 2. Tap Comprado on Aguacate
    await tester.tap(find.text('Comprado').first);
    await tester.pumpAndSettle();
    expect(find.text('"Aguacate" movido a Mis ingredientes'), findsOneWidget);
    expect(find.text('Por comprar (1)'), findsOneWidget);

    // 3. Tap Descartar on Mortadela
    await tester.tap(find.text('Descartar').first);
    await tester.pumpAndSettle();
    expect(find.text('"Mortadela" descartado de la lista de compras'), findsOneWidget);
    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

    // 4. Switch to Mis ingredientes and verify Aguacate is selectable for recipe generation
    await tester.tap(find.text('Mis ingredientes'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredientes disponibles (2)'), findsOneWidget);
    expect(find.text('Aguacate'), findsOneWidget);
    expect(find.text('Mortadela'), findsNothing);
    expect(find.text('Buscar recetas (2)'), findsOneWidget);

    // 5. Generate recipes using Tomate + newly bought Aguacate
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar recetas (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Recetas sugeridas'), findsOneWidget);
  });
}

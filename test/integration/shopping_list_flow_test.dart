import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
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
}

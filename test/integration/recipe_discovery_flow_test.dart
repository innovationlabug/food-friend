import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_suggestions_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:food_friend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('E2E Full Flow US-4.2: Clean state -> Add ingredients -> Select -> Discover Recipes -> Recipe Detail',
      (WidgetTester tester) async {
    // 1. Launch entire app
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // Verify home screen is rendered in Spanish
    expect(find.text('Bienvenido a Food Friend'), findsOneWidget);
    expect(find.text('Ir a lista de compras'), findsAtLeastNWidgets(1));

    // 2. Navigate to Shopping List screen
    await tester.tap(find.text('Ir a lista de compras').first);
    await tester.pumpAndSettle();

    expect(find.text('Lista de compras'), findsOneWidget);

    // Clean session state using "Borrar todos los ingredientes" routine
    final clearButton = find.byTooltip('Borrar todos los ingredientes');
    if (clearButton.evaluate().isNotEmpty) {
      await tester.tap(clearButton);
      await tester.pumpAndSettle();
      final confirmBtn = find.text('Borrar todo');
      if (confirmBtn.evaluate().isNotEmpty) {
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();
      }
    }

    // Verify clean empty state
    expect(find.text('No tienes ingredientes guardados'), findsOneWidget);

    // 3. Navigate through ingredient input flow to add test ingredients
    // Ingredient 1: "Pechuga de pollo" via search suggestion
    final addBtn = find.widgetWithText(FilledButton, 'Agregar ingrediente');
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    final searchInput = find.widgetWithText(TextFormField, 'Nombre del ingrediente *');
    await tester.enterText(searchInput, 'pechuga');
    await tester.pumpAndSettle();

    final suggestion1 = find.text('Pechuga de pollo');
    expect(suggestion1, findsOneWidget);
    await tester.tap(suggestion1);
    await tester.pumpAndSettle();

    // Ingredient 2: "Papa" via text field + Guardar button
    await tester.enterText(searchInput, 'Papa');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // Ingredient 3: "Güisquil" via search suggestion
    await tester.enterText(searchInput, 'guisquil');
    await tester.pumpAndSettle();
    final suggestion3 = find.text('Güisquil');
    expect(suggestion3, findsOneWidget);
    await tester.tap(suggestion3);
    await tester.pumpAndSettle();

    // Return to Shopping List and dismiss any snackbars
    final returnBtn = find.text('Ver lista');
    expect(returnBtn, findsOneWidget);
    await tester.tap(returnBtn);
    await tester.pumpAndSettle();

    // Clear any queued SnackBars from ingredient additions that might obscure bottom buttons
    final shoppingListElement = tester.element(find.byType(ShoppingListScreen));
    ScaffoldMessenger.of(shoppingListElement).clearSnackBars();
    await tester.pumpAndSettle();

    // 4. Verify test ingredients appear correctly in the list
    expect(find.text('Ingredientes disponibles (3)'), findsOneWidget);
    expect(find.text('Pechuga de pollo'), findsOneWidget);
    expect(find.text('Papa'), findsOneWidget);
    expect(find.text('Güisquil'), findsOneWidget);

    // 5. Test ingredient selection & quick actions
    expect(find.text('Buscar recetas (3)'), findsOneWidget);

    // Deselect all
    await tester.tap(find.text('Deseleccionar todos'));
    await tester.pumpAndSettle();
    expect(find.text('Buscar recetas (3)'), findsNothing);

    // Select all again
    await tester.tap(find.text('Seleccionar todos'));
    await tester.pumpAndSettle();
    expect(find.text('Buscar recetas (3)'), findsOneWidget);

    // 6. Tap "Buscar recetas (3)" to search/generate recipes
    final searchRecipesBtn = find.widgetWithText(FilledButton, 'Buscar recetas (3)');
    expect(searchRecipesBtn, findsOneWidget);
    await tester.tap(searchRecipesBtn);
    await tester.pumpAndSettle();

    // 7. Verify RecipeSuggestionsScreen
    expect(find.byType(RecipeSuggestionsScreen), findsOneWidget);
    expect(find.text('Recetas sugeridas'), findsOneWidget);
    expect(find.textContaining('receta(s) disponible(s)'), findsOneWidget);

    // Find and verify "Caldo de Pollo con Verduras Frescas" card
    final caldoCard = find.text('Caldo de Pollo con Verduras Frescas');
    expect(caldoCard, findsOneWidget);

    // 8. Open RecipeDetailScreen
    await tester.tap(caldoCard);
    await tester.pumpAndSettle();

    // 9. Verify RecipeDetailScreen details
    expect(find.byType(RecipeDetailScreen), findsOneWidget);
    expect(find.text('Caldo de Pollo con Verduras Frescas'), findsAtLeastNWidgets(1));
    expect(find.text('Ingredientes requeridos'), findsOneWidget);
    expect(find.text('Tienes en casa (3)'), findsOneWidget);
    expect(find.text('Pechuga de pollo'), findsOneWidget);
    expect(find.text('Güisquil'), findsOneWidget);
    expect(find.text('Papa'), findsOneWidget);
    expect(find.text('Ingredientes adicionales necesarios (5)'), findsOneWidget);
    expect(find.text('Instrucciones de preparación'), findsOneWidget);

    // 10. Navigate back to suggestions, then back to shopping list
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeSuggestionsScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Lista de compras'), findsOneWidget);
  });
}

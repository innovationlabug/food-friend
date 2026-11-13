import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/recipes/data/external_recipe_service.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_management_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_suggestions_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:food_friend/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
    expect(find.text('Ir a ingredientes disponibles'), findsAtLeastNWidgets(1));

    // 2. Navigate to Shopping List screen
    await tester.tap(find.text('Ir a ingredientes disponibles').first);
    await tester.pumpAndSettle();

    expect(find.text('Ingredientes disponibles'), findsOneWidget);

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

    final searchInput = find.widgetWithText(TextFormField, 'Nombre del ingrediente');
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
    expect(find.text('Ingredientes disponibles'), findsOneWidget);
  });

  testWidgets('E2E Flow US-4.3: Combination berenjena + yuca queries external API and displays matching online recipes',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        '{"success": true, "count": 2, "recipes": ['
        '{"id": "ext_berenjena_1", "title": "Berenjena a la plancha con hummus", "description": "Receta tradicional adaptada (Turquía)", "category": "Vegetariano", "prepTimeMinutes": 15, "cookTimeMinutes": 30, "servings": 4, "difficulty": "Fácil", "source": "external", "ingredients": [{"name": "Berenjena", "displayAmount": "2 unidades"}, {"name": "Aceite de oliva", "displayAmount": "2 cdas"}, {"name": "Hummus", "displayAmount": "200g"}], "instructions": ["Cortar la berenjena en rodajas.", "Asar a la plancha con aceite de oliva.", "Servir con hummus."] },'
        '{"id": "ext_yuca_1", "title": "Pastel de Yuca", "description": "Receta tradicional adaptada (Internacional)", "category": "Postre", "prepTimeMinutes": 20, "cookTimeMinutes": 45, "servings": 6, "difficulty": "Fácil", "source": "external", "ingredients": [{"name": "Yuca", "displayAmount": "2 lbs"}, {"name": "Leche de coco", "displayAmount": "1 lata"}, {"name": "Azúcar", "displayAmount": "1 taza"}], "instructions": ["Rallar la yuca finamente.", "Mezclar con leche de coco y azúcar.", "Hornear a 180°C."] }'
        ']}',
        200,
      );
    });

    final externalService = ExternalRecipeService(
      client: mockClient,
      proxyBaseUrl: 'https://test/api/recipes',
    );

    // Launch with ShoppingListScreen directly for clean isolation
    await tester.pumpWidget(
      MaterialApp(
        home: ShoppingListScreen(
          externalRecipeService: externalService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Add "Berenjena"
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar ingrediente'));
    await tester.pumpAndSettle();

    final searchInput = find.widgetWithText(TextFormField, 'Nombre del ingrediente');
    await tester.enterText(searchInput, 'berenjena');
    await tester.pumpAndSettle();

    final berenjenaSuggestion = find.text('Berenjena');
    expect(berenjenaSuggestion, findsOneWidget);
    await tester.tap(berenjenaSuggestion);
    await tester.pumpAndSettle();

    // 2. Add "Yuca"
    await tester.enterText(searchInput, 'yuca');
    await tester.pumpAndSettle();

    final yucaSuggestion = find.text('Yuca');
    expect(yucaSuggestion, findsOneWidget);
    await tester.tap(yucaSuggestion);
    await tester.pumpAndSettle();

    // 3. Return to shopping list
    await tester.tap(find.text('Ver lista'));
    await tester.pumpAndSettle();

    final shoppingListElement = tester.element(find.byType(ShoppingListScreen));
    ScaffoldMessenger.of(shoppingListElement).clearSnackBars();
    await tester.pumpAndSettle();

    // Verify both ingredients appear
    expect(find.text('Ingredientes disponibles (2)'), findsOneWidget);
    expect(find.text('Berenjena'), findsOneWidget);
    expect(find.text('Yuca'), findsOneWidget);

    // 4. Tap "Buscar recetas (2)"
    final searchBtn = find.widgetWithText(FilledButton, 'Buscar recetas (2)');
    expect(searchBtn, findsOneWidget);
    await tester.tap(searchBtn);
    await tester.pumpAndSettle();

    // 5. Verify RecipeSuggestionsScreen displays online recipes
    expect(find.byType(RecipeSuggestionsScreen), findsOneWidget);
    expect(find.text('2 receta(s) en línea'), findsOneWidget);
    expect(find.text('Con base en 2 ingrediente(s) seleccionado(s)'), findsOneWidget);

    // Both recipes rendered with matching ingredient indicators
    expect(find.text('Berenjena a la plancha con hummus'), findsOneWidget);
    expect(find.textContaining('Tienes: Berenjena'), findsOneWidget);
    expect(find.text('Pastel de Yuca'), findsOneWidget);
    expect(find.textContaining('Tienes: Yuca'), findsOneWidget);

    // 6. Navigate to detail screen for "Pastel de Yuca"
    await tester.tap(find.text('Pastel de Yuca'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeDetailScreen), findsOneWidget);
    expect(find.text('Pastel de Yuca'), findsAtLeastNWidgets(1));
    expect(find.text('Postre'), findsOneWidget);
    expect(find.text('Tienes en casa (1)'), findsOneWidget);
    expect(find.text('Yuca'), findsOneWidget);
    expect(find.text('Ingredientes adicionales necesarios (2)'), findsOneWidget);
    expect(find.text('Leche de coco'), findsOneWidget);
    expect(find.text('Azúcar'), findsOneWidget);

    // Navigate back
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeSuggestionsScreen), findsOneWidget);
  });

  testWidgets(
      'E2E Flow Phase 7: Clean state -> Cook log ("Lo cociné") -> Idempotency -> Preference toggle -> Gestión de Recetas restore',
      (WidgetTester tester) async {
    // 1. Launch app
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // 2. Navigate to Gestión de recetas from HomeScreen
    final manageBtn = find.text('Gestionar recetas');
    expect(manageBtn, findsOneWidget);
    await tester.ensureVisible(manageBtn);
    await tester.pumpAndSettle();
    await tester.tap(manageBtn);
    await tester.pumpAndSettle();

    // 3. Verify RecipeManagementScreen and filter tabs
    expect(find.byType(RecipeManagementScreen), findsOneWidget);
    expect(find.text('Gestión de Recetas'), findsOneWidget);
    expect(find.textContaining('Todas'), findsOneWidget);
    expect(find.textContaining('Favoritas (0)'), findsOneWidget);
    expect(find.textContaining('Cocinadas (0)'), findsOneWidget);
    expect(find.textContaining('Ocultas (0)'), findsOneWidget);

    // 4. Open recipe detail for "Pepián de Pollo Tradicional"
    final pepianCard = find.text('Pepián de Pollo Tradicional');
    expect(pepianCard, findsOneWidget);
    await tester.tap(pepianCard);
    await tester.pumpAndSettle();

    expect(find.byType(RecipeDetailScreen), findsOneWidget);

    // 5. Test "Lo cociné" button first tap
    final cookedBtn = find.text('Lo cociné');
    expect(cookedBtn, findsOneWidget);
    await tester.tap(cookedBtn);
    await tester.pumpAndSettle();

    expect(find.text('¡Receta registrada como cocinada!'), findsOneWidget);
    expect(find.text('Cocinada hoy (1 vez)'), findsOneWidget);

    // 6. Test same-day idempotency check
    await tester.tap(find.text('Cocinada hoy (1 vez)'));
    await tester.pumpAndSettle();
    expect(find.text('Esta receta ya fue registrada como cocinada hoy.'), findsOneWidget);

    // 7. Hide recipe via "Ocultar" button
    final ocultarBtn = find.text('Ocultar');
    expect(ocultarBtn, findsOneWidget);
    await tester.tap(ocultarBtn);
    await tester.pumpAndSettle();
    expect(find.text('Oculta'), findsOneWidget);
    expect(find.text('Receta oculta de sugerencias'), findsOneWidget);

    // 8. Pop back to RecipeManagementScreen
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeManagementScreen), findsOneWidget);
    expect(find.textContaining('Cocinadas (1)'), findsOneWidget);
    expect(find.textContaining('Ocultas (1)'), findsOneWidget);

    // 9. Filter by "Ocultas"
    await tester.tap(find.textContaining('Ocultas ('));
    await tester.pumpAndSettle();

    expect(find.text('Pepián de Pollo Tradicional'), findsOneWidget);

    // 10. Restore from "Oculta" directly from the management card
    final cardOcultaChip = find.descendant(
      of: find.byType(Card),
      matching: find.text('Oculta'),
    );
    expect(cardOcultaChip, findsOneWidget);
    await tester.tap(cardOcultaChip);
    await tester.pumpAndSettle();

    expect(find.text('Receta restablecida para sugerencias'), findsOneWidget);
    expect(find.text('No tienes recetas ocultas.'), findsOneWidget);

    // 11. Navigate back to HomeScreen
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a Food Friend'), findsOneWidget);
  });
}

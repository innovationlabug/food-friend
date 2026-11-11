import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/recipes/data/external_recipe_service.dart';
import 'package:food_friend/features/recipes/data/recipe_search_service.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_suggestions_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({
    required List<String> selectedIngredients,
    RecipeSearchService? searchService,
    ExternalRecipeService? externalService,
  }) {
    return MaterialApp(
      home: RecipeSuggestionsScreen(
        selectedIngredientNames: selectedIngredients,
        searchService: searchService,
        externalService: externalService,
      ),
    );
  }

  group('US-4.2: RecipeSuggestionsScreen & ShoppingListScreen Selection', () {
    testWidgets('displays matching recipes in a clean responsive list',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        selectedIngredients: ['Pechuga de pollo', 'Güisquil', 'Papa'],
      ));
      await tester.pumpAndSettle();

      // Verify title & banner
      expect(find.text('Recetas sugeridas'), findsOneWidget);
      expect(find.textContaining('receta(s) disponible(s)'), findsOneWidget);
      expect(find.text('Con base en 3 ingrediente(s) seleccionado(s)'), findsOneWidget);

      // Verify recipe cards are displayed
      expect(find.text('Caldo de Pollo con Verduras Frescas'), findsOneWidget);
      expect(find.textContaining('Tienes 3 de 8 ingredientes'), findsOneWidget);
    });

    testWidgets('tapping a recipe card navigates to RecipeDetailScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        selectedIngredients: ['Aguacate', 'Tomate', 'Pepino'],
      ));
      await tester.pumpAndSettle();

      // Find recipe card and tap it
      final recipeCard = find.text('Ensalada Chapina de Aguacate y Tomate');
      expect(recipeCard, findsOneWidget);
      await tester.tap(recipeCard);
      await tester.pumpAndSettle();

      // Verify navigation to RecipeDetailScreen
      expect(find.byType(RecipeDetailScreen), findsOneWidget);
      expect(find.text('Ingredientes requeridos'), findsOneWidget);
      expect(find.text('Instrucciones de preparación'), findsOneWidget);
    });

    testWidgets('shows clean empty state when no matching recipes are found and allows viewing all',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        selectedIngredients: [],
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('No se encontraron recetas con los ingredientes seleccionados'),
        findsOneWidget,
      );
      expect(find.text('Ver todas las recetas'), findsOneWidget);

      // Tap button to view all local recipes
      await tester.tap(find.text('Ver todas las recetas'));
      await tester.pumpAndSettle();

      // Verify catalog list is loaded
      expect(find.textContaining('Catálogo de recetas'), findsOneWidget);
      expect(find.text('Arroz con Pollo y Verduras Casero'), findsOneWidget);
    });

    testWidgets('ShoppingListScreen allows selecting/deselecting ingredients and searching recipes',
        (WidgetTester tester) async {
      final storage = IngredientStorageService();
      await storage.saveIngredients([
        const Ingredient(name: 'Tomate'),
        const Ingredient(name: 'Aguacate'),
        const Ingredient(name: 'Pepino'),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListScreen(storageService: storage),
        ),
      );
      await tester.pumpAndSettle();

      // Verify ingredients rendered with default selection
      expect(find.text('Ingredientes disponibles (3)'), findsOneWidget);
      expect(find.text('Tomate'), findsOneWidget);
      expect(find.text('Aguacate'), findsOneWidget);
      expect(find.text('Pepino'), findsOneWidget);

      // Verify search recipes button
      expect(find.text('Buscar recetas (3)'), findsOneWidget);

      // Quick action: tap "Deseleccionar todos"
      await tester.tap(find.text('Deseleccionar todos'));
      await tester.pumpAndSettle();

      // Button should disappear when 0 items selected
      expect(find.text('Buscar recetas (3)'), findsNothing);
      expect(find.text('Seleccionar todos'), findsOneWidget);

      // Tap single checkbox to re-select Tomate
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(3));
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Now 1 item is selected
      expect(find.text('Buscar recetas (1)'), findsOneWidget);

      // Tap "Buscar recetas (1)" to navigate to suggestions
      await tester.tap(find.text('Buscar recetas (1)'));
      await tester.pumpAndSettle();

      // Verify navigation to RecipeSuggestionsScreen
      expect(find.byType(RecipeSuggestionsScreen), findsOneWidget);
      expect(find.text('Recetas sugeridas'), findsOneWidget);
    });
  });

  group('US-4.3: External Recipe API & Graceful Fallback UI', () {
    testWidgets('displays fallback notice and local partial suggestions when offline',
        (WidgetTester tester) async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('Sin conexión');
      });

      final externalService = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/recipes',
      );

      await tester.pumpWidget(createTestWidget(
        selectedIngredients: ['IngredienteInexistente999'],
        externalService: externalService,
      ));
      await tester.pumpAndSettle();

      // Verify fallback message notice is displayed
      expect(find.textContaining('recetario externo o te encuentras sin conexión'), findsOneWidget);
      expect(find.textContaining('receta(s) sugerida(s)'), findsOneWidget);

      // Verify partial local matches are shown
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays external recipe results when returned from external API',
        (WidgetTester tester) async {
      final mockClient = MockClient((_) async {
        return http.Response(
          '{"success": true, "count": 1, "recipes": ['
          '{"id": "ext_1", "title": "Guiso Internacional de Pollo", "source": "external", "ingredients": [{"name": "curry", "displayAmount": "1 cda"}], "instructions": ["Cocinar todo."]}]}',
          200,
        );
      });

      final externalService = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/recipes',
      );

      await tester.pumpWidget(createTestWidget(
        selectedIngredients: ['berenjena'],
        externalService: externalService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Guiso Internacional de Pollo'), findsOneWidget);
      expect(find.textContaining('receta(s) en línea'), findsOneWidget);
    });

    testWidgets('displays external recipe results for berenjena + yuca with matching highlights',
        (WidgetTester tester) async {
      final mockClient = MockClient((_) async {
        return http.Response(
          '{"success": true, "count": 2, "recipes": ['
          '{"id": "ext_berenjena", "title": "Berenjena a la plancha con hummus", "source": "external", "ingredients": [{"name": "Berenjena", "displayAmount": "2 unidades"}, {"name": "Aceite de oliva", "displayAmount": "2 cdas"}], "instructions": ["Asar berenjenas."] },'
          '{"id": "ext_yuca", "title": "Pastel de Yuca", "source": "external", "ingredients": [{"name": "Yuca", "displayAmount": "2 lbs"}, {"name": "Leche de coco", "displayAmount": "1 lata"}], "instructions": ["Hornear pastel."] }'
          ']}',
          200,
        );
      });

      final externalService = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/recipes',
      );

      await tester.pumpWidget(createTestWidget(
        selectedIngredients: ['Berenjena', 'Yuca'],
        externalService: externalService,
      ));
      await tester.pumpAndSettle();

      // Banner shows 2 online recipes
      expect(find.text('2 receta(s) en línea'), findsOneWidget);
      expect(find.text('Con base en 2 ingrediente(s) seleccionado(s)'), findsOneWidget);

      // Recipe cards
      expect(find.text('Berenjena a la plancha con hummus'), findsOneWidget);
      expect(find.text('Pastel de Yuca'), findsOneWidget);

      // Ingredient match highlights
      expect(find.textContaining('Tienes: Berenjena'), findsOneWidget);
      expect(find.textContaining('Tienes: Yuca'), findsOneWidget);
    });

    testWidgets('displays meal category filter chips and filters recipes by meal type',
        (WidgetTester tester) async {
      final mockClient = MockClient((_) async {
        return http.Response(
          '{"success": true, "count": 2, "recipes": ['
          '{"id": "ext_desayuno", "title": "Pancake de Berenjena", "category": "Desayuno", "source": "external", "ingredients": [{"name": "Berenjena", "displayAmount": "1 taza"}], "instructions": ["Mezclar y cocinar."] },'
          '{"id": "ext_almuerzo", "title": "Guiso de Yuca", "category": "Almuerzo", "source": "external", "ingredients": [{"name": "Yuca", "displayAmount": "1 lb"}], "instructions": ["Cocinar yuca."] }'
          ']}',
          200,
        );
      });

      final externalService = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/recipes',
      );

      await tester.pumpWidget(createTestWidget(
        selectedIngredients: ['Berenjena', 'Yuca'],
        externalService: externalService,
      ));
      await tester.pumpAndSettle();

      // Verify filter chips exist
      expect(find.byType(ChoiceChip), findsWidgets);
      expect(
        find.descendant(of: find.byType(ChoiceChip), matching: find.textContaining('Todos')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(ChoiceChip), matching: find.textContaining('Desayuno')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(ChoiceChip), matching: find.textContaining('Almuerzo')),
        findsOneWidget,
      );

      // Initially both Pancake de Berenjena and Guiso de Yuca are visible
      expect(find.text('Pancake de Berenjena'), findsOneWidget);
      expect(find.text('Guiso de Yuca'), findsOneWidget);

      // Tap on 'Desayuno' filter chip
      final desayunoChip = find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.textContaining('Desayuno'),
      );
      await tester.tap(desayunoChip);
      await tester.pumpAndSettle();

      // Now only Pancake de Berenjena is visible, Guiso de Yuca is filtered out
      expect(find.text('Pancake de Berenjena'), findsOneWidget);
      expect(find.text('Guiso de Yuca'), findsNothing);

      // Tap on 'Almuerzo' filter chip
      final almuerzoChip = find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.textContaining('Almuerzo'),
      );
      await tester.tap(almuerzoChip);
      await tester.pumpAndSettle();

      // Now Guiso de Yuca is visible, Pancake de Berenjena is filtered out
      expect(find.text('Guiso de Yuca'), findsOneWidget);
      expect(find.text('Pancake de Berenjena'), findsNothing);

      // Tap on 'Todos' to clear filter
      final todosChip = find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.textContaining('Todos'),
      );
      await tester.tap(todosChip);
      await tester.pumpAndSettle();

      expect(find.text('Pancake de Berenjena'), findsOneWidget);
      expect(find.text('Guiso de Yuca'), findsOneWidget);
    });

    testWidgets('shows empty filtered state when category has zero matches and resets to all',
        (WidgetTester tester) async {
      final mockClient = MockClient((_) async {
        return http.Response(
          '{"success": true, "count": 1, "recipes": ['
          '{"id": "ext_almuerzo", "title": "Guiso de Yuca", "category": "Almuerzo", "source": "external", "ingredients": [{"name": "Yuca", "displayAmount": "1 lb"}], "instructions": ["Cocinar yuca."] }'
          ']}',
          200,
        );
      });

      final externalService = ExternalRecipeService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/recipes',
      );

      await tester.pumpWidget(createTestWidget(
        selectedIngredients: ['Yuca'],
        externalService: externalService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Guiso de Yuca'), findsOneWidget);

      // Tap on 'Cena' filter (0 dinner recipes returned)
      final cenaChip = find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.textContaining('Cena'),
      );
      await tester.tap(cenaChip);
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('Sin recetas de tipo "Cena"'), findsOneWidget);
      expect(find.text('Mostrar todas las recetas'), findsOneWidget);

      // Tap button to restore all recipes
      await tester.tap(find.text('Mostrar todas las recetas'));
      await tester.pumpAndSettle();

      expect(find.text('Guiso de Yuca'), findsOneWidget);
    });
  });
}

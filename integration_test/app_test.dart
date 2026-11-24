import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/amount_unit.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/nutrition/data/health_goal_storage_service.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_suggestions_screen.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:food_friend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E integration test: launches app shell and verifies Spanish navigation',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify root shell headers and cards render in Spanish
    expect(find.text('Food Friend'), findsOneWidget);
    expect(find.text('Bienvenido a Food Friend'), findsOneWidget);
    expect(find.text('Ingredientes disponibles'), findsOneWidget);
    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
    expect(find.text('Gestión de recetas'), findsOneWidget);
  });

  testWidgets('E2E integration test: verifies ingredient persistence and deduplication service',
      (WidgetTester tester) async {
    final storageService = IngredientStorageService();
    await storageService.clearIngredients();

    // Add ingredient
    await storageService.addIngredient(
      const Ingredient(name: 'Tomate', amountValue: 3, amountUnit: AmountUnit.units),
    );

    // Consolidate duplicate with case/accent variation
    final consolidated = await storageService.addIngredient(
      const Ingredient(name: 'tomate', amountValue: 2, amountUnit: AmountUnit.units),
    );

    expect(consolidated.length, equals(1));
    expect(consolidated.first.amountValue, equals(5.0));

    // Verify persistent retrieval
    final retrieved = await storageService.getIngredients();
    expect(retrieved.length, equals(1));
    expect(retrieved.first.name, equals('Tomate'));
    expect(retrieved.first.amountValue, equals(5.0));

    // Cleanup
    await storageService.clearIngredients();
  });

  testWidgets('E2E integration test: navigates to shopping list and manages ingredients through UI',
      (WidgetTester tester) async {
    final storage = IngredientStorageService();
    await storage.clearIngredients();

    app.main();
    await tester.pumpAndSettle();

    // Navigate to Available Ingredients screen
    final navButton = find.text('Ingredientes disponibles').first;
    await tester.tap(navButton);
    await tester.pumpAndSettle();

    // Verify on Available Ingredients screen
    expect(find.text('Ingredientes disponibles'), findsOneWidget);
    expect(find.text('No tienes ingredientes guardados'), findsOneWidget);

    // Open add ingredient dialog
    final addBtn = find.widgetWithText(FilledButton, 'Agregar ingrediente');
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Fill in ingredient name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del ingrediente'),
      'Frijoles colorados',
    );

    // Save ingredient
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // Tap Ver lista to return to shopping list
    await tester.tap(find.text('Ver lista'));
    await tester.pumpAndSettle();

    // Verify item displayed in list
    expect(find.text('Frijoles colorados'), findsOneWidget);
    expect(find.text('Ingredientes disponibles (1)'), findsOneWidget);

    // Remove ingredient
    final deleteButton = find.byTooltip('Eliminar ingrediente');
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify empty state is restored
    expect(find.text('Frijoles colorados'), findsNothing);
    expect(find.text('No tienes ingredientes guardados'), findsOneWidget);

    // Cleanup
    await storage.clearIngredients();
  });

  testWidgets('E2E integration test: discovers matching recipes and opens recipe detail',
      (WidgetTester tester) async {
    final storage = IngredientStorageService();
    await storage.clearIngredients();

    // Add ingredients for salad: Aguacate, Tomate, Pepino
    await storage.addIngredient(const Ingredient(name: 'Aguacate'));
    await storage.addIngredient(const Ingredient(name: 'Tomate'));
    await storage.addIngredient(const Ingredient(name: 'Pepino'));

    app.main();
    await tester.pumpAndSettle();

    // Navigate to Available Ingredients screen
    await tester.tap(find.text('Ingredientes disponibles').first);
    await tester.pumpAndSettle();

    expect(find.text('Ingredientes disponibles (3)'), findsOneWidget);
    expect(find.text('Buscar recetas'), findsOneWidget);

    // Tap Buscar recetas
    await tester.tap(find.text('Buscar recetas'));
    await tester.pumpAndSettle();

    // Verify suggestions screen
    expect(find.text('Recetas sugeridas'), findsOneWidget);
    final ensaladaCard = find.text('Ensalada Chapina de Aguacate y Tomate');
    expect(ensaladaCard, findsOneWidget);

    // Tap card to open detail
    await tester.tap(ensaladaCard);
    await tester.pumpAndSettle();

    // Verify recipe detail screen
    expect(find.text('Ensalada Chapina de Aguacate y Tomate'), findsAtLeastNWidgets(1));
    expect(find.text('Ingredientes requeridos'), findsOneWidget);
    expect(find.text('Tienes en casa (3)'), findsOneWidget);
    expect(find.text('Instrucciones de preparación'), findsOneWidget);

    // Cleanup
    await storage.clearIngredients();
  });

  testWidgets('E2E integration test: verifies photo and receipt scanner navigation from Add Ingredient',
      (WidgetTester tester) async {
    final storage = IngredientStorageService();
    await storage.clearIngredients();

    app.main();
    await tester.pumpAndSettle();

    // Navigate to Add Ingredients screen
    final addIngredientsBtn = find.text('Agregar ingredientes').first;
    await tester.ensureVisible(addIngredientsBtn);
    await tester.pumpAndSettle();
    await tester.tap(addIngredientsBtn);
    await tester.pumpAndSettle();

    expect(find.text('Agregar ingrediente'), findsOneWidget);
    expect(find.text('Foto'), findsOneWidget);

    // Switch to Foto tab
    await tester.tap(find.text('Foto'));
    await tester.pumpAndSettle();

    expect(find.text('Escanear refrigerador'), findsAtLeastNWidgets(1));
    expect(find.text('Escanear recibo'), findsAtLeastNWidgets(1));

    // Tap Refrigerador button
    final fridgeBtn = find.widgetWithText(FilledButton, 'Escanear refrigerador');
    await tester.ensureVisible(fridgeBtn);
    await tester.pumpAndSettle();
    await tester.tap(fridgeBtn);
    await tester.pumpAndSettle();
    expect(find.text('Escanear refrigerador'), findsAtLeastNWidgets(1));
    expect(find.text('Detectar ingredientes por foto'), findsOneWidget);

    // Go back
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Tap Recibo button
    final receiptBtn = find.widgetWithText(FilledButton, 'Escanear recibo');
    await tester.ensureVisible(receiptBtn);
    await tester.pumpAndSettle();
    await tester.tap(receiptBtn);
    await tester.pumpAndSettle();
    expect(find.text('Escanear recibo'), findsAtLeastNWidgets(1));
    expect(find.text('Extraer alimentos de factura / ticket'), findsOneWidget);

    // Go back
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Cleanup
    await storage.clearIngredients();
  });

  testWidgets('E2E integration test US-8.1: adds items to Lista de compras independently from Mis ingredientes',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    await pantry.clearIngredients();
    await shopping.clearIngredients();

    app.main();
    await tester.pumpAndSettle();

    // Navigate to Lista de compras
    final buyListBtn = find.text('Lista de compras').first;
    await tester.ensureVisible(buyListBtn);
    await tester.pumpAndSettle();
    await tester.tap(buyListBtn);
    await tester.pumpAndSettle();

    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

    // Add ingredient via search suggestion
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar a lista de compras'));
    await tester.pumpAndSettle();

    final searchField = find.widgetWithText(TextFormField, 'Nombre del ingrediente');
    await tester.enterText(searchField, 'aguacate');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aguacate'));
    await tester.pumpAndSettle();

    // Return to Lista de compras
    await tester.tap(find.text('Ver lista'));
    await tester.pumpAndSettle();

    expect(find.text('Por comprar (1)'), findsOneWidget);
    expect(find.text('Aguacate'), findsOneWidget);
    expect(await pantry.getIngredients(), isEmpty);

    // Cleanup
    await pantry.clearIngredients();
    await shopping.clearIngredients();
  });

  testWidgets(
      'E2E integration test US-8.2: marks shopping item Comprado to generate recipes and Descartar removes completely',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    await pantry.clearIngredients();
    await shopping.clearIngredients();

    app.main();
    await tester.pumpAndSettle();

    // Navigate to Lista de compras and add Tomate and Salchicha via UI
    final buyListBtn = find.text('Lista de compras').first;
    await tester.ensureVisible(buyListBtn);
    await tester.pumpAndSettle();
    await tester.tap(buyListBtn);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Agregar a lista de compras'));
    await tester.pumpAndSettle();

    final searchField = find.widgetWithText(TextFormField, 'Nombre del ingrediente');
    await tester.enterText(searchField, 'tomate');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    await tester.enterText(searchField, 'salchicha');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salchicha'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver lista'));
    await tester.pumpAndSettle();

    expect(find.text('Por comprar (2)'), findsOneWidget);

    // Mark Tomate as Comprado
    await tester.tap(find.byTooltip('Marcar como comprado').first);
    await tester.pumpAndSettle();
    expect(find.text('"Tomate" movido a Mis ingredientes'), findsOneWidget);

    // Dismiss Salchicha
    await tester.tap(find.byTooltip('Descartar de la lista').first);
    await tester.pumpAndSettle();
    expect(find.text('"Salchicha" descartado de la lista de compras'), findsOneWidget);
    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

    // Switch to Mis ingredientes and verify Tomate is ready for Buscar recetas
    await tester.tap(find.text('Mis ingredientes'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredientes disponibles (1)'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Buscar recetas'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar recetas'));
    await tester.pumpAndSettle();
    expect(find.text('Recetas sugeridas'), findsOneWidget);

    // Cleanup
    await pantry.clearIngredients();
    await shopping.clearIngredients();
  });

  testWidgets(
      'E2E integration test US-9.2: displays nutrition tips from cooked history and adds recommended ingredient to Lista de compras',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    final history = RecipeHistoryService(ingredientStorageService: pantry);
    final goalStorage = HealthGoalStorageService();
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await history.clearHistory();
    await goalStorage.clearGoals();

    app.main();
    await tester.pumpAndSettle();

    // Open Consejos de Nutrición with empty history
    final tipsBtn = find.text('Consejos de Nutrición');
    await tester.ensureVisible(tipsBtn);
    await tester.pumpAndSettle();
    await tester.tap(tipsBtn);
    await tester.pumpAndSettle();

    expect(find.text('Tus metas de salud'), findsOneWidget);
    expect(find.text('Personaliza tu nutrición'), findsOneWidget);
    expect(find.text('Ganar masa muscular / Más proteína'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Record cooked meals triggering health alert, protein pairing, and vitamin suggestions
    await history.recordCooked(
      const Recipe(
        id: 'app_test_proc',
        title: 'Chorizo con huevo',
        ingredients: [
          RecipeIngredient(name: 'Chorizo', displayAmount: '1 unidad'),
          RecipeIngredient(name: 'Huevo', displayAmount: '2 unidades'),
        ],
        instructions: ['Cocinar'],
      ),
      cookedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    await history.recordCooked(
      const Recipe(
        id: 'app_test_rice',
        title: 'Arroz blanco sencillo',
        ingredients: [
          RecipeIngredient(name: 'Arroz blanco', displayAmount: '1 taza'),
        ],
        instructions: ['Hervir'],
      ),
      cookedAt: DateTime.now(),
    );

    await tester.ensureVisible(tipsBtn);
    await tester.pumpAndSettle();
    await tester.tap(tipsBtn);
    await tester.pumpAndSettle();

    final alertTitle = find.text('Modera el consumo de carnes procesadas');
    await tester.scrollUntilVisible(alertTitle, 250);
    await tester.pumpAndSettle();
    expect(alertTitle, findsOneWidget);

    final proteinTitle =
        find.text('Combina granos y legumbres para lograr proteína completa');
    await tester.scrollUntilVisible(proteinTitle, 250);
    await tester.pumpAndSettle();
    expect(proteinTitle, findsOneWidget);

    final vitA = find.text('Refuerza tu aporte de Vitamina A');
    await tester.scrollUntilVisible(vitA, 250);
    await tester.pumpAndSettle();
    expect(vitA, findsOneWidget);

    final addCarrot = find.widgetWithText(OutlinedButton, 'Agregar Zanahoria').first;
    await tester.ensureVisible(addCarrot);
    await tester.pumpAndSettle();
    await tester.tap(addCarrot);
    await tester.pumpAndSettle();

    expect(find.text('"Zanahoria" agregado a tu lista de compras'), findsOneWidget);
    expect((await shopping.getIngredients()).map((i) => i.name), contains('Zanahoria'));

    // Cleanup
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await history.clearHistory();
  });

  testWidgets(
      'E2E integration test FEAT-1: filters recipes by total time + category, deducts depleted items on "Lo cociné", and syncs Por comprar',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    final history = RecipeHistoryService(ingredientStorageService: pantry);
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await history.clearHistory();

    await pantry.saveIngredients([
      const Ingredient(name: 'Aguacate'),
      const Ingredient(name: 'Tomate'),
      const Ingredient(name: 'Pepino'),
      const Ingredient(name: 'Pollo'),
      const Ingredient(name: 'Papa'),
    ]);

    app.main();
    await tester.pumpAndSettle();

    // Navigate to Available Ingredients and start recipe discovery
    await tester.tap(find.text('Ingredientes disponibles').first);
    await tester.pumpAndSettle();
    expect(find.text('Ingredientes disponibles (5)'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Buscar recetas'));
    await tester.pumpAndSettle();
    expect(find.text('Recetas sugeridas'), findsOneWidget);

    // Apply <= 20 min total time filter alongside Ensaladas category
    await tester.tap(find.text('≤ 20 min'));
    await tester.pumpAndSettle();
    expect(find.text('Ensalada Chapina de Aguacate y Tomate'), findsOneWidget);
    expect(find.text('Pepián de Pollo Tradicional'), findsNothing);

    final ensaladasChip = find.descendant(
      of: find.byType(ChoiceChip),
      matching: find.textContaining('Ensaladas'),
    );
    await tester.ensureVisible(ensaladasChip);
    await tester.pumpAndSettle();
    await tester.tap(ensaladasChip);
    await tester.pumpAndSettle();
    expect(find.text('Ensalada Chapina de Aguacate y Tomate'), findsOneWidget);

    // Open recipe detail and tap "Lo cociné"
    await tester.tap(find.text('Ensalada Chapina de Aguacate y Tomate'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lo cociné'));
    await tester.pumpAndSettle();

    // Quick depletion sheet opens with matching pantry ingredients
    expect(find.text('¿Qué se te acabó?'), findsOneWidget);
    final sheet = find.byType(BottomSheet);
    await tester.tap(find.descendant(of: sheet, matching: find.text('Aguacate')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quitar y pasar a Lista de compras (1)'));
    await tester.pumpAndSettle();

    expect(
      find.text('Receta cocinada. "Aguacate" pasó a Lista de compras.'),
      findsOneWidget,
    );

    // Verify daily idempotency on repeat tap
    await tester.tap(find.text('Cocinada hoy (1 vez)'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué se te acabó?'), findsNothing);

    // Verify storage state (deduction + Por comprar + timesUsed/lastUsed)
    final remainingPantry = await pantry.getIngredients();
    expect(remainingPantry.map((i) => i.name), isNot(contains('Aguacate')));
    final tomate = remainingPantry.firstWhere((i) => i.name == 'Tomate');
    expect(tomate.timesUsed, equals(1));
    expect(tomate.lastUsed, isNotNull);

    final shoppingItems = await shopping.getIngredients();
    expect(shoppingItems.map((i) => i.name), contains('Aguacate'));

    // Navigate back through suggestions to shopping list and confirm UI sync
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Con base en 4 ingredientes seleccionados'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Ingredientes disponibles (4)'), findsOneWidget);

    await tester.tap(find.text('Por comprar'));
    await tester.pumpAndSettle();
    expect(find.text('Por comprar (1)'), findsOneWidget);
    expect(find.text('Aguacate'), findsOneWidget);

    // Cleanup
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await history.clearHistory();
  });

  testWidgets(
      'E2E integration test FEAT-2: selects and persists health goals, prioritizes aligned recipes, and displays Spanish nutritional tooltips',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    final history = RecipeHistoryService(ingredientStorageService: pantry);
    final goalStorage = HealthGoalStorageService();
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await history.clearHistory();
    await goalStorage.clearGoals();

    await pantry.saveIngredients([
      const Ingredient(name: 'Pechuga de pollo'),
      const Ingredient(name: 'Güisquil'),
      const Ingredient(name: 'Zanahoria'),
      const Ingredient(name: 'Crema pura'),
    ]);

    app.main();
    await tester.pumpAndSettle();

    // 1. Open Consejos de Nutrición and select goals
    final tipsBtn = find.text('Consejos de Nutrición');
    await tester.ensureVisible(tipsBtn);
    await tester.pumpAndSettle();
    await tester.tap(tipsBtn);
    await tester.pumpAndSettle();

    final loseWeightTile = find.byKey(
      ValueKey('health_goal_${HealthGoal.loseWeight.storageKey}'),
    );
    final gainMuscleTile = find.byKey(
      ValueKey('health_goal_${HealthGoal.gainMuscle.storageKey}'),
    );
    await tester.ensureVisible(loseWeightTile);
    await tester.pumpAndSettle();
    await tester.tap(loseWeightTile);
    await tester.pumpAndSettle();

    await tester.ensureVisible(gainMuscleTile);
    await tester.pumpAndSettle();
    await tester.tap(gainMuscleTile);
    await tester.pumpAndSettle();

    expect(
      await goalStorage.getSelectedGoals(),
      equals({HealthGoal.loseWeight, HealthGoal.gainMuscle}),
    );

    // 2. Open recipe suggestions from goal screen and verify ranking + tooltips
    final seeAllBtn =
        find.widgetWithText(OutlinedButton, 'Ver todas en recetas sugeridas');
    await tester.scrollUntilVisible(seeAllBtn, 250);
    await tester.pumpAndSettle();
    await tester.tap(seeAllBtn);
    await tester.pumpAndSettle();

    expect(
      find.text('Metas activas: Bajar calorías, Más proteína'),
      findsOneWidget,
    );

    final lightDish = find.text('Pechuga a la Plancha con Verduras al Vapor');
    final creamyDish = find.text('Pechuga al Curry Cremoso con Maní');
    expect(lightDish, findsOneWidget);

    final tooltipFinder = find.byKey(
      const ValueKey('goal_tooltip_pollo_plancha_vegetales'),
    );
    expect(tooltipFinder, findsOneWidget);
    expect(
      tester.widget<Tooltip>(tooltipFinder).message,
      contains('La pechuga de pollo es una excelente fuente de proteína'),
    );

    if (creamyDish.evaluate().isNotEmpty) {
      expect(
        tester.getRect(lightDish).top,
        lessThan(tester.getRect(creamyDish).top),
      );
    } else {
      final listScrollable = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        creamyDish,
        200,
        scrollable: listScrollable,
      );
      await tester.pumpAndSettle();
      expect(creamyDish, findsOneWidget);
      await tester.scrollUntilVisible(
        lightDish,
        -200,
        scrollable: listScrollable,
      );
      await tester.pumpAndSettle();
    }

    // 3. Open recipe detail and confirm Spanish alignment card renders
    await tester.tap(lightDish);
    await tester.pumpAndSettle();

    expect(find.text('Alineado con tus metas de salud'), findsOneWidget);
    expect(
      find.text('El güisquil contiene pocas calorías y aporta fibra'),
      findsOneWidget,
    );
    expect(
      find.text('La pechuga de pollo es una excelente fuente de proteína'),
      findsOneWidget,
    );

    // Cleanup
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await history.clearHistory();
    await goalStorage.clearGoals();
  });

  testWidgets(
      'E2E integration test FEAT-3: surfaces favorite and health-goal shopping suggestions, adds missing items in one tap, and updates suggestions',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    final history = RecipeHistoryService(ingredientStorageService: pantry);
    final goalStorage = HealthGoalStorageService();
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await history.clearHistory();
    await goalStorage.clearGoals();

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

    app.main();
    await tester.pumpAndSettle();

    // Navigate to Lista de compras
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

    // One-tap add Epazote -> Por comprar updates and favorite suggestion narrows to Queso de capas
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

    // One-tap add Queso de capas -> favorite suggestion disappears while health-goal remains
    final addQueso = find.byKey(
      const ValueKey('add_suggestion_frijoles_parados_queso_queso de capas'),
    );
    await tester.ensureVisible(addQueso);
    await tester.pumpAndSettle();
    await tester.tap(addQueso);
    await tester.pumpAndSettle();

    expect(find.text('Por comprar (2)'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('shopping_suggestion_frijoles_parados_queso')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('shopping_suggestion_salteado_verduras_curry')),
      findsOneWidget,
    );

    final queued = await shopping.getIngredients();
    expect(queued.map((i) => i.name), equals(['Epazote', 'Queso de capas']));

    // Cleanup
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await history.clearHistory();
    await goalStorage.clearGoals();
  });

  testWidgets(
      'E2E integration test FEAT-5: detects matched supermarket deals in GTQ, shows sales banner on Home & Por comprar, and adds deal item to Por comprar',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    await pantry.clearIngredients();
    await shopping.clearIngredients();

    await pantry.saveIngredients([
      const Ingredient(name: 'Pollo', timesUsed: 4),
    ]);
    await shopping.saveIngredients([
      const Ingredient(name: 'Aceite de oliva'),
    ]);

    app.main();
    await tester.pumpAndSettle();

    // HomeScreen shows compact Spanish sales alert banner for matched items
    expect(find.byKey(const ValueKey('sales_alert_banner')), findsOneWidget);
    expect(find.text('Ver ofertas'), findsOneWidget);

    // Open SupermarketDealsScreen from the banner
    await tester.tap(find.text('Ver ofertas'));
    await tester.pumpAndSettle();

    expect(find.text('Ofertas del supermercado'), findsOneWidget);
    expect(find.text('Milanesa Pollo Rey'), findsOneWidget);
    expect(find.text('Q 17.55'), findsOneWidget);
    expect(find.text('Q 23.45'), findsOneWidget);

    // Add matched frequent ingredient (Pollo) to Por comprar
    await tester.tap(
      find.widgetWithText(FilledButton, 'Agregar a lista de compras').first,
    );
    await tester.pumpAndSettle();

    final updatedList = await shopping.getIngredients();
    expect(
      updatedList.any((item) => item.name.toLowerCase() == 'pollo'),
      isTrue,
    );

    // Cleanup
    await pantry.clearIngredients();
    await shopping.clearIngredients();
  });

  testWidgets(
      'E2E integration test FEAT-4: availability replacements make recipes cookable and health-goal swaps appear in RecipeDetailScreen',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    final shopping = ShoppingListStorageService(pantryStorageService: pantry);
    final goalStorage = HealthGoalStorageService();
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await goalStorage.clearGoals();

    // User has Ensalada Chapina ingredients except Aceite de oliva (has Aceite vegetal),
    // plus Pechuga de pollo, Arroz integral, and Yogur natural for health-goal swaps.
    await pantry.saveIngredients(const [
      Ingredient(name: 'Aguacate'),
      Ingredient(name: 'Tomate'),
      Ingredient(name: 'Pepino'),
      Ingredient(name: 'Cebolla morada'),
      Ingredient(name: 'Cilantro'),
      Ingredient(name: 'Limón'),
      Ingredient(name: 'Aceite vegetal'),
      Ingredient(name: 'Pechuga de pollo'),
      Ingredient(name: 'Arroz integral'),
    ]);
    await goalStorage.saveSelectedGoals({HealthGoal.increaseVitaminsAndFiber});

    app.main();
    await tester.pumpAndSettle();

    // Navigate to Ingredientes disponibles -> Buscar recetas
    await tester.tap(find.text('Ingredientes disponibles').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Buscar recetas'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeSuggestionsScreen), findsOneWidget);

    // Filter to Ensaladas to isolate Ensalada Chapina de Aguacate y Tomate
    final ensaladasChip = find.descendant(
      of: find.byType(ChoiceChip),
      matching: find.textContaining('Ensaladas'),
    );
    await tester.ensureVisible(ensaladasChip);
    await tester.tap(ensaladasChip);
    await tester.pumpAndSettle();

    expect(find.text('Ensalada Chapina de Aguacate y Tomate'), findsOneWidget);
    expect(
      find.text('Puedes usar Aceite vegetal en lugar de Aceite de oliva'),
      findsOneWidget,
    );
    expect(
      find.text('¡Lista para cocinar con este cambio!'),
      findsOneWidget,
    );

    // Open Ensalada Chapina detail screen and verify replacement guidance
    await tester.tap(find.text('Ensalada Chapina de Aguacate y Tomate'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeDetailScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('detail_cookable_with_replacements_banner')),
      findsOneWidget,
    );
    expect(
      find.text('Puedes usar Aceite vegetal en lugar de Aceite de oliva'),
      findsOneWidget,
    );

    // Return to suggestions and verify Arroz con Pollo shows health-goal swap (Arroz blanco -> Arroz integral)
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    final almuerzoChip = find.descendant(
      of: find.byType(ChoiceChip),
      matching: find.textContaining('Almuerzo'),
    );
    await tester.ensureVisible(almuerzoChip);
    await tester.tap(almuerzoChip);
    await tester.pumpAndSettle();

    final arrozConPollo = find.text('Arroz con Pollo y Verduras Casero');
    await tester.scrollUntilVisible(
      arrozConPollo,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(arrozConPollo);
    await tester.pumpAndSettle();
    await tester.tap(arrozConPollo);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('detail_health_goal_replacements_card')),
      findsOneWidget,
    );
    expect(
      find.text('Cambia Arroz blanco por Arroz integral'),
      findsOneWidget,
    );
    expect(
      find.text('Disponible en tu despensa: Arroz integral'),
      findsOneWidget,
    );

    // Cleanup
    await pantry.clearIngredients();
    await shopping.clearIngredients();
    await goalStorage.clearGoals();
  });
}

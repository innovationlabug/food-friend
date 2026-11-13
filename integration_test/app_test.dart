import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/amount_unit.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
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
    final navButton = find.text('Ir a ingredientes disponibles').first;
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
    await tester.tap(find.text('Ir a ingredientes disponibles').first);
    await tester.pumpAndSettle();

    expect(find.text('Ingredientes disponibles (3)'), findsOneWidget);
    expect(find.text('Buscar recetas (3)'), findsOneWidget);

    // Tap Buscar recetas
    await tester.tap(find.text('Buscar recetas (3)'));
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
    final addIngredientsBtn = find.text('Añadir ingredientes').first;
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
    final buyListBtn = find.text('Ir a lista de compras').first;
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
    final buyListBtn = find.text('Ir a lista de compras').first;
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
    await tester.tap(find.text('Comprado').first);
    await tester.pumpAndSettle();
    expect(find.text('"Tomate" movido a Mis ingredientes'), findsOneWidget);

    // Dismiss Salchicha
    await tester.tap(find.text('Descartar').first);
    await tester.pumpAndSettle();
    expect(find.text('"Salchicha" descartado de la lista de compras'), findsOneWidget);
    expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

    // Switch to Mis ingredientes and verify Tomate is ready for Buscar recetas
    await tester.tap(find.text('Mis ingredientes'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredientes disponibles (1)'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Buscar recetas (1)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar recetas (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Recetas sugeridas'), findsOneWidget);

    // Cleanup
    await pantry.clearIngredients();
    await shopping.clearIngredients();
  });
}

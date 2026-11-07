import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/amount_unit.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
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
    expect(find.text('Lista de compras'), findsAtLeastNWidgets(1));
    expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
    expect(find.text('Asistente de nutrición'), findsOneWidget);
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

    // Navigate to Shopping List screen
    final navButton = find.text('Ir a lista de compras').first;
    await tester.tap(navButton);
    await tester.pumpAndSettle();

    // Verify on Shopping List
    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('No tienes ingredientes guardados'), findsOneWidget);

    // Open add ingredient dialog
    final addBtn = find.widgetWithText(FilledButton, 'Agregar ingrediente');
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Fill in ingredient name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del ingrediente *'),
      'Frijol colorado',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cantidad'),
      '2',
    );

    // Save ingredient
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // Verify item displayed in list
    expect(find.text('Frijol colorado'), findsOneWidget);
    expect(find.text('Ingredientes disponibles (1)'), findsOneWidget);

    // Remove ingredient
    final deleteButton = find.byTooltip('Eliminar ingrediente');
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify empty state is restored
    expect(find.text('Frijol colorado'), findsNothing);
    expect(find.text('No tienes ingredientes guardados'), findsOneWidget);

    // Cleanup
    await storage.clearIngredients();
  });
}

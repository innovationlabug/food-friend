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
    expect(find.text('Lista de compras'), findsOneWidget);
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
}

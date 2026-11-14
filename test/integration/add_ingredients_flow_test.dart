import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('E2E Full Flow: Cleans state, adds ingredients via search, closest-match, and category browsing',
      (WidgetTester tester) async {
    // 1. Launch entire app
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // Verify home screen is rendered in Spanish
    expect(find.text('Bienvenido a Food Friend'), findsOneWidget);
    expect(find.text('Ingredientes disponibles'), findsAtLeastNWidgets(1));

    // 2. Navigate to Shopping List screen
    await tester.tap(find.text('Ingredientes disponibles').first);
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

    // 3. Flow US-2.2: Add ingredient via text search with auto-suggestions
    final addBtn = find.widgetWithText(FilledButton, 'Agregar ingrediente');
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    expect(find.text('Agregar ingrediente'), findsOneWidget);
    expect(find.text('Nombre del ingrediente'), findsOneWidget);

    // Type query
    final searchInput = find.widgetWithText(TextFormField, 'Nombre del ingrediente');
    await tester.enterText(searchInput, 'pechuga');
    await tester.pumpAndSettle();

    // Tap suggestion
    final suggestion = find.text('Pechuga de pollo');
    expect(suggestion, findsOneWidget);
    await tester.ensureVisible(suggestion);
    await tester.pumpAndSettle();
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    // Verify user STAYS on Add Ingredient screen
    expect(find.text('Agregar ingrediente'), findsOneWidget);

    // 4. Flow US-2.2: Add ingredient via closest match fallback without leaving screen
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del ingrediente'),
      'tomte',
    );
    await tester.pumpAndSettle();

    // Tap Guardar
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // Verify still on Add Ingredient screen
    expect(find.text('Agregar ingrediente'), findsOneWidget);

    // 5. Flow US-2.3: Add ingredient via Category Browsing without leaving screen
    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();

    // Step 1: Tap Level 1 category
    await tester.tap(find.text('Granos, Cereales y Harinas'));
    await tester.pumpAndSettle();

    // Step 2: Tap Level 2 subcategory
    await tester.tap(find.text('Frijoles'));
    await tester.pumpAndSettle();

    // Step 3: Tap Level 3 leaf ingredient
    final frijolLeaf = find.text('Frijoles negros');
    expect(frijolLeaf, findsOneWidget);
    await tester.tap(frijolLeaf);
    await tester.pumpAndSettle();

    // Still on screen! Tap "Ver lista" to return to shopping list
    await tester.tap(find.text('Ver lista'));
    await tester.pumpAndSettle();

    // 6. Verify shopping list now has all 3 ingredients
    expect(find.text('Pechuga de pollo'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Frijoles negros'), findsOneWidget);
    expect(find.text('Ingredientes disponibles (3)'), findsOneWidget);
    expect(find.text('Ingredientes disponibles (3)'), findsOneWidget);

    // 7. Verify clean session state routine can clear all data with confirmation
    await tester.tap(find.byTooltip('Borrar todos los ingredientes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar todo'));
    await tester.pumpAndSettle();

    expect(find.text('No tienes ingredientes guardados'), findsOneWidget);
    expect(find.text('Pechuga de pollo'), findsNothing);
  });

  testWidgets('E2E Flow US-5.2: Adds user-tested staples (Queso gouda, Nueces, Curry) via search and categories',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // Navigate to Ingredientes disponibles
    await tester.tap(find.text('Ingredientes disponibles').first);
    await tester.pumpAndSettle();

    // Clean session state
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

    // Tap Agregar ingrediente
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar ingrediente'));
    await tester.pumpAndSettle();

    final searchInput = find.widgetWithText(TextFormField, 'Nombre del ingrediente');

    // 1. Search for 'nuez' (synonym) and add 'Nueces'
    await tester.enterText(searchInput, 'nuez');
    await tester.pumpAndSettle();
    final nuecesSuggestion = find.text('Nueces');
    expect(nuecesSuggestion, findsOneWidget);
    await tester.tap(nuecesSuggestion);
    await tester.pumpAndSettle();

    // 2. Search for 'gouda' and add 'Queso gouda'
    await tester.enterText(searchInput, 'gouda');
    await tester.pumpAndSettle();
    final goudaSuggestion = find.text('Queso gouda');
    expect(goudaSuggestion, findsOneWidget);
    await tester.tap(goudaSuggestion);
    await tester.pumpAndSettle();

    // 3. Search for 'curry en polvo' (synonym) and add 'Curry'
    await tester.enterText(searchInput, 'curry en polvo');
    await tester.pumpAndSettle();
    final currySuggestion = find.text('Curry');
    expect(currySuggestion, findsOneWidget);
    await tester.tap(currySuggestion);
    await tester.pumpAndSettle();

    // Tap "Ver lista"
    await tester.tap(find.text('Ver lista'));
    await tester.pumpAndSettle();

    // Verify all 3 newly added staples are displayed in the list
    expect(find.text('Nueces'), findsOneWidget);
    expect(find.text('Queso gouda'), findsOneWidget);
    expect(find.text('Curry'), findsOneWidget);
    expect(find.text('Ingredientes disponibles (3)'), findsAtLeastNWidgets(1));

    // Clean up
    await tester.tap(find.byTooltip('Borrar todos los ingredientes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar todo'));
    await tester.pumpAndSettle();
  });
}


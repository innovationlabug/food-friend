import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:food_friend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'E2E Flow US-9.2: Clean state -> Empty state foundational tips -> Cooked history triggers all 3 tip categories -> Add vitamin food to Lista de Compras',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // 1. Open Consejos de Nutrición from HomeScreen when cooking history is empty
    final openTipsBtn = find.text('Ver consejos de nutrición');
    await tester.ensureVisible(openTipsBtn);
    await tester.pumpAndSettle();
    await tester.tap(openTipsBtn);
    await tester.pumpAndSettle();

    expect(find.text('Aún no has registrado recetas cocinadas'), findsOneWidget);
    expect(find.textContaining('Lo cociné'), findsOneWidget);
    expect(find.text('Proteína completa combinando arroz y frijoles'), findsOneWidget);

    // 2. Navigate back and simulate logging cooked meals via RecipeHistoryService
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    final historyService = RecipeHistoryService();
    await historyService.recordCooked(
      const Recipe(
        id: 'cooked_proc_1',
        title: 'Desayuno con chorizo',
        ingredients: [
          RecipeIngredient(name: 'Chorizo colorado', displayAmount: '2 unidades'),
          RecipeIngredient(name: 'Huevo', displayAmount: '2 unidades'),
        ],
        instructions: ['Cocinar chorizo con huevo'],
      ),
      cookedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    await historyService.recordCooked(
      const Recipe(
        id: 'cooked_grain_2',
        title: 'Arroz blanco sencillo',
        ingredients: [
          RecipeIngredient(name: 'Arroz blanco', displayAmount: '1 taza'),
        ],
        instructions: ['Hervir arroz'],
      ),
      cookedAt: DateTime.now(),
    );

    // 3. Re-open Consejos de Nutrición to verify all three heuristic categories render
    await tester.ensureVisible(openTipsBtn);
    await tester.pumpAndSettle();
    await tester.tap(openTipsBtn);
    await tester.pumpAndSettle();

    expect(find.text('Resumen de tu alimentación'), findsOneWidget);
    expect(find.text('Modera el consumo de carnes procesadas'), findsOneWidget);
    expect(
      find.text('Combina granos y legumbres para lograr proteína completa'),
      findsOneWidget,
    );

    // Scroll to Vitamina C suggestion and tap "Agregar Naranja"
    final vitCSuggestion = find.text('Refuerza tu aporte de Vitamina C');
    await tester.scrollUntilVisible(vitCSuggestion, 250);
    await tester.pumpAndSettle();
    expect(vitCSuggestion, findsOneWidget);

    final addOrangeBtn = find.widgetWithText(OutlinedButton, 'Agregar Naranja').first;
    await tester.ensureVisible(addOrangeBtn);
    await tester.pumpAndSettle();
    await tester.tap(addOrangeBtn);
    await tester.pumpAndSettle();

    expect(find.text('"Naranja" agregado a tu lista de compras'), findsOneWidget);
    expect(find.text('Naranja (en lista)'), findsAtLeastNWidgets(1));

    // 4. Open Lista de Compras via top bar icon and verify Naranja is persisted under Por comprar
    await tester.tap(find.byTooltip('Ver lista de compras'));
    await tester.pumpAndSettle();

    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('Por comprar (1)'), findsOneWidget);
    expect(find.text('Naranja'), findsOneWidget);

    final shopping = ShoppingListStorageService();
    expect((await shopping.getIngredients()).map((e) => e.name), equals(['Naranja']));
  });
}


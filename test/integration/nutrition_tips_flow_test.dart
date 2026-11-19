import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/nutrition/data/health_goal_storage_service.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_suggestions_screen.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:food_friend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'E2E Flow US-9.2: Clean state -> Empty goal prompt -> Cooked history triggers all 3 tip categories -> Add vitamin food to Lista de Compras',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // 1. Open Consejos de Nutrición from HomeScreen when cooking history is empty
    final openTipsBtn = find.text('Consejos de Nutrición');
    await tester.ensureVisible(openTipsBtn);
    await tester.pumpAndSettle();
    await tester.tap(openTipsBtn);
    await tester.pumpAndSettle();

    expect(find.text('Tus metas de salud'), findsOneWidget);
    expect(find.text('Personaliza tu nutrición'), findsOneWidget);
    expect(find.textContaining('Lo cociné'), findsOneWidget);
    expect(find.text('Proteína completa combinando arroz y frijoles'), findsNothing);

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
    final alertTitle = find.text('Modera el consumo de carnes procesadas');
    await tester.scrollUntilVisible(alertTitle, 250);
    await tester.pumpAndSettle();
    expect(alertTitle, findsOneWidget);

    final proteinTitle =
        find.text('Combina granos y legumbres para lograr proteína completa');
    await tester.scrollUntilVisible(proteinTitle, 250);
    await tester.pumpAndSettle();
    expect(proteinTitle, findsOneWidget);

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

  testWidgets(
      'E2E Flow FEAT-2: Select health goals -> persist -> dynamic guidance & goal-driven recipe ranking with tooltips',
      (WidgetTester tester) async {
    final pantry = IngredientStorageService();
    await pantry.saveIngredients([
      const Ingredient(name: 'Pechuga de pollo'),
      const Ingredient(name: 'Güisquil'),
      const Ingredient(name: 'Zanahoria'),
      const Ingredient(name: 'Crema pura'),
    ]);

    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    // 1. Open Consejos de Nutrición and select two health goals
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

    // Verify local persistence
    final goalStorage = HealthGoalStorageService();
    expect(
      await goalStorage.getSelectedGoals(),
      equals({HealthGoal.loseWeight, HealthGoal.gainMuscle}),
    );

    // 2. Navigate directly to recipe suggestions aligned with goals
    final seeAllSuggestionsBtn =
        find.widgetWithText(OutlinedButton, 'Ver todas en recetas sugeridas');
    await tester.scrollUntilVisible(seeAllSuggestionsBtn, 250);
    await tester.pumpAndSettle();
    await tester.tap(seeAllSuggestionsBtn);
    await tester.pumpAndSettle();

    expect(find.byType(RecipeSuggestionsScreen), findsOneWidget);
    expect(
      find.text('Metas activas: Bajar calorías, Más proteína'),
      findsOneWidget,
    );

    // Light + protein dish (Pechuga a la Plancha) appears near the top ahead of creamy dish
    final lightDish = find.text('Pechuga a la Plancha con Verduras al Vapor');
    final creamyDish = find.text('Pechuga al Curry Cremoso con Maní');
    expect(lightDish, findsOneWidget);
    expect(creamyDish, findsNothing); // Ranked lower, below initial viewport

    // Verify specific Spanish tooltip on goal-matched recipe
    final tooltipFinder = find.byKey(
      const ValueKey('goal_tooltip_pollo_plancha_vegetales'),
    );
    expect(tooltipFinder, findsOneWidget);
    expect(
      tester.widget<Tooltip>(tooltipFinder).message,
      contains('El güisquil contiene pocas calorías y aporta fibra'),
    );

    final listScrollable = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );

    // Scrolling further down reveals the penalized creamy recipe below
    await tester.scrollUntilVisible(
      creamyDish,
      200,
      scrollable: listScrollable,
    );
    await tester.pumpAndSettle();
    expect(creamyDish, findsOneWidget);

    // Scroll back up to open lightDish detail
    await tester.scrollUntilVisible(
      lightDish,
      -200,
      scrollable: listScrollable,
    );
    await tester.pumpAndSettle();

    // 3. Open recipe detail and confirm Spanish goal alignment card renders
    await tester.tap(lightDish);
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailScreen), findsOneWidget);
    expect(find.text('Alineado con tus metas de salud'), findsOneWidget);
    expect(
      find.text('El güisquil contiene pocas calorías y aporta fibra'),
      findsOneWidget,
    );
    expect(
      find.text('La pechuga de pollo es una excelente fuente de proteína'),
      findsOneWidget,
    );
  });
}


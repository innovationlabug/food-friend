import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/core/widgets/app_navigation_drawer.dart';
import 'package:food_friend/features/home/presentation/home_screen.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/nutrition/data/health_goal_storage_service.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/recipes/presentation/multi_day_planner_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_suggestions_screen.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FEAT-9: MultiDayPlannerScreen & Navigation Integration', () {
    testWidgets(
        'lets user select 2 to 7 days, displays variation and shared ingredients, and adds missing items without duplicates',
        (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );
      final history = RecipeHistoryService(
        preferences: prefs,
        ingredientStorageService: pantry,
      );
      final goals = HealthGoalStorageService(preferences: prefs);

      await pantry.saveIngredients(const [
        Ingredient(name: 'Pollo'),
        Ingredient(name: 'Tomate'),
        Ingredient(name: 'Cebolla blanca'),
        Ingredient(name: 'Ajo'),
        Ingredient(name: 'Güisquil'),
        Ingredient(name: 'Papa'),
      ]);
      await goals.saveSelectedGoals({
        HealthGoal.gainMuscle,
        HealthGoal.loseWeight,
      });
      await history.setPreference('hilachas_res', RecipePreference.never);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiDayPlannerScreen(
            ingredientStorageService: pantry,
            shoppingListService: shopping,
            historyService: history,
            healthGoalStorageService: goals,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Selector offers 2 to 7 days in Spanish
      expect(find.text('Planificador de comidas'), findsOneWidget);
      expect(find.text('¿Para cuántos días quieres cocinar?'), findsOneWidget);
      for (int d = 2; d <= 7; d++) {
        expect(find.byKey(ValueKey('day_count_chip_$d')), findsOneWidget);
      }

      // Default is 3 days
      expect(find.text('Plan de 3 días con variaciones'), findsOneWidget);
      expect(find.byKey(const ValueKey('meal_plan_day_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('meal_plan_day_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('meal_plan_day_3')), findsOneWidget);

      // Shared ingredients summary and health goal bar appear
      expect(find.textContaining('Ingredientes compartidos:'), findsOneWidget);
      expect(find.text('Metas activas: Bajar calorías, Más proteína'), findsOneWidget);

      // Switch to 5 days
      await tester.tap(find.byKey(const ValueKey('day_count_chip_5')));
      await tester.pumpAndSettle();

      expect(find.text('Plan de 5 días con variaciones'), findsOneWidget);
      final outerScrollable = find.byType(Scrollable).first;
      for (int d = 1; d <= 5; d++) {
        final dayFinder = find.byKey(ValueKey('meal_plan_day_$d'));
        await tester.scrollUntilVisible(
          dayFinder,
          200,
          scrollable: outerScrollable,
        );
        expect(dayFinder, findsOneWidget);
      }

      // Switch to 7 days
      final chip7 = find.byKey(const ValueKey('day_count_chip_7'));
      await tester.scrollUntilVisible(
        chip7,
        -300,
        scrollable: outerScrollable,
      );
      await tester.tap(chip7);
      await tester.pumpAndSettle();
      expect(find.text('Plan de 7 días con variaciones'), findsOneWidget);

      // Never-marked recipe must not appear anywhere in the plan
      expect(find.text('Hilachas de Res Saludables'), findsNothing);

      // Scroll to consolidated missing ingredients and add all in one tap
      final addAllBtn = find.byKey(const ValueKey('add_all_plan_missing_button'));
      await tester.scrollUntilVisible(
        addAllBtn,
        250,
        scrollable: outerScrollable,
      );
      await tester.pumpAndSettle();
      expect(addAllBtn, findsOneWidget);

      await tester.tap(addAllBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Todos los faltantes están en Lista de compras'),
        findsOneWidget,
      );

      final savedShopping = await shopping.getIngredients();
      expect(savedShopping, isNotEmpty);
      final uniqueNorms = savedShopping.map((i) => i.name.toLowerCase()).toSet();
      expect(uniqueNorms.length, equals(savedShopping.length));
    });

    testWidgets(
        'renders without layout overflows on narrow mobile (360x640) and wide desktop (1280x800)',
        (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      await pantry.saveIngredients(const [
        Ingredient(name: 'Pechuga de pollo'),
        Ingredient(name: 'Tomate'),
        Ingredient(name: 'Zanahoria'),
      ]);

      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiDayPlannerScreen(
            ingredientStorageService: pantry,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a planned day card opens RecipeDetailScreen',
        (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      await pantry.saveIngredients(const [
        Ingredient(name: 'Aguacate'),
        Ingredient(name: 'Tomate'),
        Ingredient(name: 'Pepino'),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiDayPlannerScreen(
            initialDaysCount: 2,
            ingredientStorageService: pantry,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('meal_plan_day_1')));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeDetailScreen), findsOneWidget);
      expect(find.text('Ingredientes requeridos'), findsOneWidget);
    });

    testWidgets(
        'opens MultiDayPlannerScreen from RecipeSuggestionsScreen and AppNavigationDrawer',
        (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      await pantry.saveIngredients(const [
        Ingredient(name: 'Aguacate'),
        Ingredient(name: 'Tomate'),
        Ingredient(name: 'Pepino'),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: RecipeSuggestionsScreen(
            selectedIngredientNames: const ['Aguacate', 'Tomate', 'Pepino'],
            ingredientStorageService: pantry,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final plannerBtn = find.byKey(const ValueKey('open_multi_day_planner_button'));
      expect(plannerBtn, findsOneWidget);
      await tester.tap(plannerBtn);
      await tester.pumpAndSettle();

      expect(find.byType(MultiDayPlannerScreen), findsOneWidget);
      expect(find.text('Planificador de comidas'), findsOneWidget);

      // Also verify AppNavigationDrawer includes Planificador de comidas
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerPlanner = find.descendant(
        of: find.byType(AppNavigationDrawer),
        matching: find.text('Planificador de comidas'),
      );
      expect(drawerPlanner, findsOneWidget);
      await tester.tap(drawerPlanner);
      await tester.pumpAndSettle();

      expect(find.byType(MultiDayPlannerScreen), findsOneWidget);
    });
  });
}

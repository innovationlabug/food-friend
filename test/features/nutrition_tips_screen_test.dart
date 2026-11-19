import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/nutrition/data/health_goal_storage_service.dart';
import 'package:food_friend/features/nutrition/data/nutrition_service.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/nutrition/presentation/nutrition_tips_screen.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';

Recipe _recipe(String id, String title, List<String> ingredients) {
  return Recipe(
    id: id,
    title: title,
    ingredients: ingredients
        .map((n) => RecipeIngredient(name: n, displayAmount: '1 porción'))
        .toList(),
    instructions: const <String>['Paso 1'],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('US-9.2 & FEAT-2: NutritionTipsScreen UI, Health Goals & Shopping List Integration',
      () {
    testWidgets(
        'displays predefined Spanish health goal options and replaces legacy static foundational tips when empty',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final historyService = RecipeHistoryService(preferences: prefs);
      final goalStorage = HealthGoalStorageService(preferences: prefs);
      final nutritionService = NutritionService(
        historyService: historyService,
        healthGoalStorageService: goalStorage,
      );
      final shoppingService = ShoppingListStorageService(preferences: prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: NutritionTipsScreen(
            nutritionService: nutritionService,
            historyService: historyService,
            shoppingListService: shoppingService,
            healthGoalStorageService: goalStorage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consejos de Nutrición'), findsOneWidget);
      expect(find.text('Tus metas de salud'), findsOneWidget);
      expect(find.text('Perder peso / Bajar calorías'), findsOneWidget);
      expect(find.text('Ganar masa muscular / Más proteína'), findsOneWidget);
      expect(
        find.text('Reducir sodio y alimentos procesados'),
        findsOneWidget,
      );
      expect(find.text('Aumentar vitaminas y fibra'), findsOneWidget);
      expect(find.text('Personaliza tu nutrición'), findsOneWidget);
      expect(find.textContaining('Lo cociné'), findsOneWidget);

      // Legacy generic static tips are no longer emitted
      expect(
        find.text('Proteína completa combinando arroz y frijoles'),
        findsNothing,
      );
      expect(find.text('Variedad diaria de frutas y verduras'), findsNothing);
      expect(find.text('Asistente de nutrición'), findsNothing);
    });

    testWidgets(
        'selects, persists, and updates dynamic goal guidance, shopping additions, and goal-matched recipe tooltips',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = await SharedPreferences.getInstance();
      final historyService = RecipeHistoryService(preferences: prefs);
      final goalStorage = HealthGoalStorageService(preferences: prefs);
      final nutritionService = NutritionService(
        historyService: historyService,
        healthGoalStorageService: goalStorage,
      );
      final shoppingService = ShoppingListStorageService(preferences: prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: NutritionTipsScreen(
            nutritionService: nutritionService,
            historyService: historyService,
            shoppingListService: shoppingService,
            healthGoalStorageService: goalStorage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Select "Ganar masa muscular / Más proteína"
      final muscleTile = find.byKey(
        ValueKey('health_goal_${HealthGoal.gainMuscle.storageKey}'),
      );
      await tester.ensureVisible(muscleTile);
      await tester.pumpAndSettle();
      await tester.tap(muscleTile);
      await tester.pumpAndSettle();

      // Persisted in storage
      expect(
        await goalStorage.getSelectedGoals(),
        equals({HealthGoal.gainMuscle}),
      );

      // Dynamic guidance & goal-matched recipe suggestions replace empty card
      expect(find.text('Personaliza tu nutrición'), findsNothing);
      final guidanceTitle = find.text('Incluye proteína completa en tus comidas');
      await tester.scrollUntilVisible(guidanceTitle, 200);
      await tester.pumpAndSettle();
      expect(guidanceTitle, findsOneWidget);

      // One-tap add recommended goal ingredient to Lista de compras
      final addChickenBtn =
          find.widgetWithText(OutlinedButton, 'Agregar Pechuga de pollo').first;
      await tester.ensureVisible(addChickenBtn);
      await tester.pumpAndSettle();
      await tester.tap(addChickenBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('"Pechuga de pollo" agregado a tu lista de compras'),
        findsOneWidget,
      );

      // Verify recommended goal recipes section and specific Spanish reasoning
      final goalRecipesHeading = find.text('Recetas alineadas con tus metas');
      await tester.scrollUntilVisible(goalRecipesHeading, 200);
      await tester.pumpAndSettle();
      expect(goalRecipesHeading, findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              (widget.key?.toString().contains('nutrition_goal_tooltip_') ??
                  false) &&
              (widget.message?.contains('proteína') ?? false),
        ),
        findsAtLeastNWidgets(1),
      );

      // Rebuild widget cleanly and confirm persisted goal remains selected
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: NutritionTipsScreen(
            nutritionService: nutritionService,
            historyService: historyService,
            shoppingListService: shoppingService,
            healthGoalStorageService: goalStorage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final persistedTile = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(
                ValueKey('health_goal_${HealthGoal.gainMuscle.storageKey}'),
              ),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(persistedTile.properties.toggled, isTrue);

      // Desktop layout verification (1280x800) with zero overflow
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders health alert, protein pairing, and vitamin suggestions and adds recommended ingredient to Lista de Compras',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
      final nutrition = NutritionService(historyService: history);

      await history.recordCooked(
        _recipe('m1', 'Huevos con salchicha', ['Salchicha', 'Huevo']),
        cookedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      await history.recordCooked(
        _recipe('m2', 'Arroz blanco sencillo', ['Arroz blanco', 'Cebolla blanca']),
        cookedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NutritionTipsScreen(
            nutritionService: nutrition,
            historyService: history,
            shoppingListService: shopping,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Health alert rendered
      final alertTitle = find.text('Modera el consumo de carnes procesadas');
      await tester.scrollUntilVisible(alertTitle, 200);
      await tester.pumpAndSettle();
      expect(alertTitle, findsOneWidget);

      // 2. Protein pairing rendered
      final proteinTitle =
          find.text('Combina granos y legumbres para lograr proteína completa');
      await tester.scrollUntilVisible(proteinTitle, 200);
      await tester.pumpAndSettle();
      expect(proteinTitle, findsOneWidget);

      // 3. Vitamin suggestion rendered (scroll if needed on compact viewport)
      final vitA = find.text('Refuerza tu aporte de Vitamina A');
      await tester.scrollUntilVisible(vitA, 200);
      await tester.pumpAndSettle();
      expect(vitA, findsOneWidget);

      // 4. Tap to add recommended vitamin source ('Zanahoria') to Lista de Compras
      final addCarrotBtn = find.widgetWithText(OutlinedButton, 'Agregar Zanahoria').first;
      await tester.ensureVisible(addCarrotBtn);
      await tester.pumpAndSettle();
      await tester.tap(addCarrotBtn);
      await tester.pumpAndSettle();

      expect(find.text('"Zanahoria" agregado a tu lista de compras'), findsOneWidget);
      expect(find.text('Zanahoria (en lista)'), findsAtLeastNWidgets(1));

      // Persisted in Lista de Compras and NOT in Mis Ingredientes
      final shoppingItems = await shopping.getIngredients();
      expect(shoppingItems.map((i) => i.name), contains('Zanahoria'));
      expect(await pantry.getIngredients(), isEmpty);
    });
  });
}


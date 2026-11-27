import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/core/settings/settings_controller.dart';
import 'package:food_friend/core/theme/app_theme.dart';
import 'package:food_friend/core/widgets/app_svg_icon.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/amount_unit.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/nutrition/data/health_goal_storage_service.dart';
import 'package:food_friend/features/nutrition/domain/health_goal.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/widgets/smart_shopping_suggestions_section.dart';
import 'package:food_friend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      SettingsController.hasCompletedModeSelectionKey: true,
    });
    SettingsController.instance.resetToDefaults();
  });

  Widget createTestWidget({
    IngredientStorageService? storageService,
    ShoppingListStorageService? shoppingListService,
    RecipeHistoryService? historyService,
    HealthGoalStorageService? healthGoalStorageService,
    int initialTab = 0,
  }) {
    return MaterialApp(
      home: ShoppingListScreen(
        storageService: storageService,
        shoppingListService: shoppingListService,
        historyService: historyService,
        healthGoalStorageService: healthGoalStorageService,
        initialTab: initialTab,
      ),
    );
  }

  group('ShoppingListScreen', () {
    testWidgets('displays empty state when no ingredients are stored',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ingredientes disponibles'), findsOneWidget);
      expect(find.text('No tienes ingredientes guardados'), findsOneWidget);
      expect(
        find.text(
          'Agrega los ingredientes que tienes disponibles en casa.',
        ),
        findsOneWidget,
      );
      expect(find.text('Agregar ingrediente'), findsAtLeastNWidgets(1));
    });

    testWidgets('AppBar does not contain redundant + action button and shows direct delete action',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final appBar = find.byType(AppBar);
      expect(
        find.descendant(of: appBar, matching: find.byTooltip('Agregar ingrediente')),
        findsNothing,
      );
      expect(
        find.descendant(of: appBar, matching: find.byTooltip('Borrar todos los ingredientes')),
        findsOneWidget,
      );
    });

    testWidgets('renders list of stored ingredients with Spanish labels and clean formatting',
        (tester) async {
      final storage = IngredientStorageService();
      await storage.saveIngredients([
        const Ingredient(
          name: 'Pechuga de pollo',
          brand: 'Pollo Rey',
          amountValue: 500,
          amountUnit: AmountUnit.grams,
        ),
        const Ingredient(name: 'Cebolla'),
      ]);

      await tester.pumpWidget(createTestWidget(storageService: storage));
      await tester.pumpAndSettle();

      expect(find.text('Ingredientes disponibles (2)'), findsOneWidget);
      expect(find.text('Pechuga de pollo'), findsOneWidget);
      expect(find.text('500 g • Pollo Rey'), findsOneWidget);
      expect(find.text('Cebolla'), findsOneWidget);
    });

    testWidgets('adds new ingredient via dialog and updates view',
        (tester) async {
      final storage = IngredientStorageService();
      await tester.pumpWidget(createTestWidget(storageService: storage));
      await tester.pumpAndSettle();

      // Tap on empty state button to add ingredient
      final addButtons = find.widgetWithText(FilledButton, 'Agregar ingrediente');
      expect(addButtons, findsOneWidget);
      await tester.tap(addButtons);
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Nombre del ingrediente'), findsOneWidget);

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del ingrediente'),
        'Zanahoria',
      );

      // Submit form via Guardar button
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      // Tap Ver lista to return to shopping list
      await tester.tap(find.text('Ver lista'));
      await tester.pumpAndSettle();

      // Verify ingredient is now rendered
      expect(find.text('Zanahoria'), findsOneWidget);
      expect(find.text('Ingredientes disponibles (1)'), findsOneWidget);
    });

    testWidgets('removes ingredient on tapping delete button',
        (tester) async {
      final storage = IngredientStorageService();
      await storage.saveIngredients([
        const Ingredient(name: 'Aguacate', amountValue: 2, amountUnit: AmountUnit.units),
      ]);

      await tester.pumpWidget(createTestWidget(storageService: storage));
      await tester.pumpAndSettle();

      expect(find.text('Aguacate'), findsOneWidget);

      // Find and tap delete button
      final deleteBtn = find.byTooltip('Eliminar ingrediente');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify empty state is now displayed
      expect(find.text('Aguacate'), findsNothing);
      expect(find.text('No tienes ingredientes guardados'), findsOneWidget);
    });

    testWidgets('cancelling delete dialog preserves ingredients, confirming clears all data',
        (tester) async {
      final storage = IngredientStorageService();
      await storage.saveIngredients([
        const Ingredient(name: 'Tomate'),
        const Ingredient(name: 'Cebolla'),
      ]);

      await tester.pumpWidget(createTestWidget(storageService: storage));
      await tester.pumpAndSettle();

      expect(find.text('Ingredientes disponibles (2)'), findsOneWidget);

      // Tap delete button in AppBar
      final clearBtn = find.byTooltip('Borrar todos los ingredientes');
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('¿Borrar todos los ingredientes?'), findsOneWidget);
      expect(
        find.text(
          'Esta acción eliminará todos los ingredientes disponibles guardados. ¿Deseas continuar?',
        ),
        findsOneWidget,
      );

      // 1. Test Cancel: tap 'Cancelar'
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and items still present
      expect(find.text('¿Borrar todos los ingredientes?'), findsNothing);
      expect(find.text('Ingredientes disponibles (2)'), findsOneWidget);

      // 2. Tap delete button again and confirm
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('¿Borrar todos los ingredientes?'), findsOneWidget);
      await tester.tap(find.text('Borrar todo'));
      await tester.pumpAndSettle();

      // Verify list is cleared and empty state is shown
      expect(find.text('No tienes ingredientes guardados'), findsOneWidget);
      final remaining = await storage.getIngredients();
      expect(remaining, isEmpty);
    });

    testWidgets('navigates from HomeScreen to ShoppingListScreen on primary button tap',
        (tester) async {
      await tester.pumpWidget(const FoodFriendApp());
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido a Food Friend'), findsOneWidget);

      // Tap primary navigation panel
      final shoppingNavBtn = find.text('Ingredientes disponibles');
      expect(shoppingNavBtn, findsAtLeastNWidgets(1));
      await tester.tap(shoppingNavBtn.first);
      await tester.pumpAndSettle();

      // Verify on Shopping List Screen
      expect(find.text('Ingredientes disponibles'), findsOneWidget);
      expect(find.text('No tienes ingredientes guardados'), findsOneWidget);
    });
  });

  group('US-8.1: Dedicated Lista de Compras tab & independent input', () {
    testWidgets('switches to Por comprar tab and adds items via search and categories without altering pantry',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );
      await pantry.addIngredient(const Ingredient(name: 'Pollo'));

      await tester.pumpWidget(
        createTestWidget(
          storageService: pantry,
          shoppingListService: shopping,
          initialTab: 1,
        ),
      );
      await tester.pumpAndSettle();

      // Verify shopping list empty state and AppBar title
      expect(find.text('Lista de compras'), findsOneWidget);
      expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

      // Tap button to add items to shopping list
      await tester.tap(find.widgetWithText(FilledButton, 'Agregar a lista de compras'));
      await tester.pumpAndSettle();

      // Verify AddIngredientScreen in shopping list mode (no Foto tab)
      expect(find.text('Agregar a lista de compras'), findsOneWidget);
      expect(find.text('Foto'), findsNothing);

      // Add via search suggestion
      final searchInput = find.widgetWithText(TextFormField, 'Nombre del ingrediente');
      await tester.enterText(searchInput, 'tomate');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tomate'));
      await tester.pumpAndSettle();

      // Add duplicate via closest-match fallback ('tomte' -> Tomate)
      await tester.enterText(searchInput, 'tomte');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      // Add via category browser
      await tester.tap(find.text('Categorías'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Granos, Cereales y Harinas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frijoles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frijoles negros'));
      await tester.pumpAndSettle();

      // Return to shopping list
      await tester.tap(find.text('Ver lista'));
      await tester.pumpAndSettle();

      // Consolidated count is 2 (Tomate + Frijoles negros)
      expect(find.text('Por comprar (2)'), findsOneWidget);
      expect(find.text('Tomate'), findsOneWidget);
      expect(find.text('Frijoles negros'), findsOneWidget);

      // Verify pantry was untouched
      final pantryItems = await pantry.getIngredients();
      expect(pantryItems.map((e) => e.name), equals(['Pollo']));

      // Clear shopping list and verify pantry still intact
      await tester.tap(find.byTooltip('Vaciar lista de compras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vaciar lista'));
      await tester.pumpAndSettle();

      expect(find.text('Tu lista de compras está vacía'), findsOneWidget);
      expect((await pantry.getIngredients()).map((e) => e.name), equals(['Pollo']));
    });
  });

  group('US-8.2: Shopping list item actions Comprado & Descartar', () {
    testWidgets('Comprado moves item to Mis ingredientes and Descartar removes without adding',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );

      await shopping.addIngredients([
        const Ingredient(name: 'Tomate'),
        const Ingredient(name: 'Cilantro'),
      ]);

      await tester.pumpWidget(
        createTestWidget(
          storageService: pantry,
          shoppingListService: shopping,
          initialTab: 1,
        ),
      );
      await tester.pumpAndSettle();

      // Verify both Comprado and Descartar action buttons with tooltips are shown
      expect(find.byTooltip('Marcar como comprado'), findsNWidgets(2));
      expect(find.byTooltip('Descartar de la lista'), findsNWidgets(2));

      // Tap Comprado on Tomate (first card)
      await tester.tap(find.byTooltip('Marcar como comprado').first);
      await tester.pumpAndSettle();

      // SnackBar confirmation and shopping list updated
      expect(find.text('"Tomate" movido a Mis ingredientes'), findsOneWidget);
      expect(find.text('Por comprar (1)'), findsOneWidget);
      expect(find.text('Cilantro'), findsOneWidget);

      // Tap Descartar on Cilantro
      await tester.tap(find.byTooltip('Descartar de la lista').first);
      await tester.pumpAndSettle();

      expect(find.text('"Cilantro" descartado de la lista de compras'), findsOneWidget);
      expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

      // Verify persistence: Tomate is in pantry, Cilantro is nowhere
      expect((await pantry.getIngredients()).map((e) => e.name), equals(['Tomate']));
      expect(await shopping.getIngredients(), isEmpty);

      // Switch to Mis ingredientes tab: Tomate is selected and ready for Buscar recetas (no count)
      await tester.tap(find.text('Mis ingredientes'));
      await tester.pumpAndSettle();
      expect(find.text('Ingredientes disponibles (1)'), findsOneWidget);
      expect(find.text('Tomate'), findsOneWidget);
      expect(find.text('Buscar recetas'), findsOneWidget);
      expect(find.textContaining('Buscar recetas ('), findsNothing);
    });

    testWidgets('shopping list item cards match the height of ingredient list cards',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );

      await pantry.addIngredient(const Ingredient(name: 'Tomate'));
      await shopping.addIngredient(const Ingredient(name: 'Cebolla'));

      await tester.pumpWidget(
        createTestWidget(
          storageService: pantry,
          shoppingListService: shopping,
          initialTab: 0,
        ),
      );
      await tester.pumpAndSettle();

      final ingredientCardHeight = tester.getSize(find.byType(Card).first).height;

      await tester.tap(find.text('Por comprar'));
      await tester.pumpAndSettle();

      final shoppingCardHeight = tester.getSize(find.byType(Card).first).height;
      expect(shoppingCardHeight, equals(ingredientCardHeight));
    });
  });

  group('FEAT-3: Smart shopping list suggestions', () {
    Future<
        ({
          IngredientStorageService pantry,
          ShoppingListStorageService shopping,
          RecipeHistoryService history,
          HealthGoalStorageService goals,
        })> seedSuggestionFixtures() async {
      final prefs = await SharedPreferences.getInstance();
      final pantry = IngredientStorageService(preferences: prefs);
      final shopping = ShoppingListStorageService(
        preferences: prefs,
        pantryStorageService: pantry,
      );
      final history = RecipeHistoryService(ingredientStorageService: pantry);
      final goals = HealthGoalStorageService(preferences: prefs);

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
      await goals.saveSelectedGoals({HealthGoal.loseWeight});

      return (
        pantry: pantry,
        shopping: shopping,
        history: history,
        goals: goals,
      );
    }

    testWidgets(
        'displays favorite and health-goal suggestions in Por comprar with Spanish copy and SVG icons',
        (tester) async {
      final deps = await seedSuggestionFixtures();

      await tester.pumpWidget(
        createTestWidget(
          storageService: deps.pantry,
          shoppingListService: deps.shopping,
          historyService: deps.history,
          healthGoalStorageService: deps.goals,
          initialTab: 1,
        ),
      );
      await tester.pumpAndSettle();

      final section = find.byType(SmartShoppingSuggestionsSection);
      expect(section, findsOneWidget);
      expect(find.text('Sugerencias para tu lista'), findsOneWidget);

      final favText = find.text(
        'Si compras Epazote y Queso de capas puedes cocinar Frijoles Negros Parados con Epazote y Queso de tus recetas favoritas',
      );
      await tester.ensureVisible(favText);
      await tester.pumpAndSettle();
      expect(favText, findsOneWidget);

      final goalText = find.text(
        'Si compras Maní puedes preparar Salteado de Verduras al Curry con Maní para tu meta de bajar calorías',
      );
      await tester.ensureVisible(goalText);
      await tester.pumpAndSettle();
      expect(goalText, findsOneWidget);

      // Verify SVG icons are used with zero Material Icon widgets
      expect(
        find.descendant(of: section, matching: find.byType(Icon)),
        findsNothing,
      );
      expect(
        find.descendant(of: section, matching: find.byType(AppSvgIcon)),
        findsAtLeastNWidgets(4),
      );
    });

    testWidgets(
        'one-tap adding updates and dismisses suggestions without duplicates, and dismissing restores them',
        (tester) async {
      final deps = await seedSuggestionFixtures();

      await tester.pumpWidget(
        createTestWidget(
          storageService: deps.pantry,
          shoppingListService: deps.shopping,
          historyService: deps.history,
          healthGoalStorageService: deps.goals,
          initialTab: 1,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Add first missing ingredient (Epazote) from 2-missing favorite suggestion
      final addEpazote = find.byKey(
        const ValueKey('add_suggestion_frijoles_parados_queso_epazote'),
      );
      await tester.ensureVisible(addEpazote);
      await tester.pumpAndSettle();
      await tester.tap(addEpazote);
      await tester.pumpAndSettle();

      expect(find.text('"Epazote" agregado a tu lista de compras'), findsOneWidget);
      expect(find.text('Por comprar (1)'), findsOneWidget);
      expect(find.text('Epazote'), findsOneWidget);
      expect(
        find.text(
          'Si compras Queso de capas puedes cocinar Frijoles Negros Parados con Epazote y Queso de tus recetas favoritas',
        ),
        findsOneWidget,
      );

      // 2. Add second missing ingredient (Queso de capas) -> favorite card is dismissed
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

      // Persisted list has exactly 2 distinct items without duplicates
      final storedShopping = await deps.shopping.getIngredients();
      expect(storedShopping.map((e) => e.name), equals(['Epazote', 'Queso de capas']));

      // 3. Dismiss Epazote from Por comprar -> favorite suggestion reappears for Epazote
      await tester.tap(find.byTooltip('Descartar de la lista').first);
      await tester.pumpAndSettle();

      expect(find.text('Por comprar (1)'), findsOneWidget);
      expect(
        find.text(
          'Si compras Epazote puedes cocinar Frijoles Negros Parados con Epazote y Queso de tus recetas favoritas',
        ),
        findsOneWidget,
      );

      // 4. Mark Queso de capas as bought -> moves to pantry and stays out of suggestions
      await tester.tap(find.byTooltip('Marcar como comprado').first);
      await tester.pumpAndSettle();

      expect((await deps.pantry.getIngredients()).map((i) => i.name), contains('Queso de capas'));
      expect(
        find.text(
          'Si compras Epazote puedes cocinar Frijoles Negros Parados con Epazote y Queso de tus recetas favoritas',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'renders smart suggestions cleanly on mobile (360x800) and desktop (1280x900) without overflow',
        (tester) async {
      final deps = await seedSuggestionFixtures();

      // Mobile viewport
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          storageService: deps.pantry,
          shoppingListService: deps.shopping,
          historyService: deps.history,
          healthGoalStorageService: deps.goals,
          initialTab: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sugerencias para tu lista'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Desktop viewport (two-column layout for suggestion cards)
      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpAndSettle();

      final favCard = find.byKey(
        const ValueKey('shopping_suggestion_frijoles_parados_queso'),
      );
      final goalCard = find.byKey(
        const ValueKey('shopping_suggestion_salteado_verduras_curry'),
      );
      expect(favCard, findsOneWidget);
      expect(goalCard, findsOneWidget);

      // Side-by-side on desktop: same top Y, second card strictly to the right
      final favRect = tester.getRect(favCard);
      final goalRect = tester.getRect(goalCard);
      expect((favRect.top - goalRect.top).abs(), lessThan(1.0));
      expect(goalRect.left, greaterThan(favRect.right));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders nutrition leaf icon on Maní suggestion using primaryContainer palette instead of blueish tertiaryContainer in light and dark mode',
        (tester) async {
      final deps = await seedSuggestionFixtures();

      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(theme.brightness),
            theme: theme,
            home: ShoppingListScreen(
              storageService: deps.pantry,
              shoppingListService: deps.shopping,
              historyService: deps.history,
              healthGoalStorageService: deps.goals,
              initialTab: 1,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final maniCard = find.byKey(
          const ValueKey('shopping_suggestion_salteado_verduras_curry'),
        );
        await tester.ensureVisible(maniCard);
        await tester.pumpAndSettle();

        final leafFinder = find.descendant(
          of: maniCard,
          matching: find.byWidgetPredicate(
            (w) => w is AppSvgIcon && w.assetName == 'nutrition',
          ),
        );
        expect(leafFinder, findsOneWidget);

        final leafIcon = tester.widget<AppSvgIcon>(leafFinder);
        expect(leafIcon.color, equals(theme.colorScheme.onPrimaryContainer));
        expect(leafIcon.color, isNot(equals(theme.colorScheme.onTertiaryContainer)));
      }
    });
  });
}


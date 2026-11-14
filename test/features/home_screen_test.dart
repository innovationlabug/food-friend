import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/core/theme/theme_controller.dart';
import 'package:food_friend/core/widgets/app_navigation_drawer.dart';
import 'package:food_friend/features/home/presentation/home_screen.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/ingredients/presentation/add_ingredient_screen.dart';
import 'package:food_friend/features/nutrition/presentation/nutrition_tips_screen.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/presentation/recipe_management_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_suggestions_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:food_friend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeController.instance.resetToLight();
  });

  Widget createTestWidget({Size size = const Size(400, 800)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen UI & Redundancy Checks', () {
    testWidgets(
        'renders all 6 clickable panels simultaneously without redundant buttons on mobile',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(size: const Size(400, 800)));
      await tester.pumpAndSettle();

      // Welcome header
      expect(find.text('Bienvenido a Food Friend'), findsOneWidget);
      expect(
        find.text('Tu asistente de cocina, compras y nutrición en Guatemala.'),
        findsOneWidget,
      );

      // All 6 panels rendered once without redundant button labels
      expect(find.text('Ingredientes disponibles'), findsOneWidget);
      expect(find.text('Agregar ingredientes'), findsOneWidget);
      expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
      expect(find.text('Gestión de recetas'), findsOneWidget);
      expect(find.text('Lista de compras'), findsOneWidget);
      expect(find.text('Consejos de Nutrición'), findsOneWidget);

      expect(find.text('Ir a ingredientes disponibles'), findsNothing);
      expect(find.text('Ir a lista de compras'), findsNothing);
      expect(find.text('Añadir ingredientes'), findsNothing);
      expect(find.text('Ver sugerencias'), findsNothing);
      expect(find.text('Gestionar recetas'), findsNothing);
      expect(find.text('Ver consejos de nutrición'), findsNothing);

      // All 6 panels fit inside the 400x800 viewport without scrolling
      for (final label in [
        'Ingredientes disponibles',
        'Agregar ingredientes',
        '¿Qué cocino hoy?',
        'Gestión de recetas',
        'Lista de compras',
        'Consejos de Nutrición',
      ]) {
        final rect = tester.getRect(find.text(label));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(800));
      }
    });

    testWidgets('renders all 6 panels cleanly on desktop viewports',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(size: const Size(1200, 900)));
      await tester.pumpAndSettle();

      expect(find.text('Agregar ingredientes'), findsOneWidget);
      expect(find.text('Ingredientes disponibles'), findsOneWidget);
      expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
      expect(find.text('Gestión de recetas'), findsOneWidget);
      expect(find.text('Lista de compras'), findsOneWidget);
      expect(find.text('Consejos de Nutrición'), findsOneWidget);
    });

    testWidgets(
        'dynamically resizes panels based on whether user has added ingredients',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Case 1: No ingredients -> Ingredients & Shopping list bigger than Recipes
      await tester.pumpWidget(createTestWidget(size: const Size(400, 800)));
      await tester.pumpAndSettle();

      final emptyIngredientsSize = tester.getSize(
        find.ancestor(
          of: find.text('Ingredientes disponibles'),
          matching: find.byType(Card),
        ),
      );
      final emptyRecipesSize = tester.getSize(
        find.ancestor(
          of: find.text('¿Qué cocino hoy?'),
          matching: find.byType(Card),
        ),
      );
      final emptyShoppingSize = tester.getSize(
        find.ancestor(
          of: find.text('Lista de compras'),
          matching: find.byType(Card),
        ),
      );

      expect(
        emptyIngredientsSize.height,
        greaterThan(emptyRecipesSize.height),
      );
      expect(
        emptyShoppingSize.height,
        greaterThan(emptyRecipesSize.height),
      );

      // Case 2: Ingredients exist -> Recipe suggestions ("¿Qué cocino hoy?") bigger
      final storage = IngredientStorageService();
      await storage.addIngredient(const Ingredient(name: 'Pollo'));

      await tester.pumpWidget(
        createTestWidget(size: const Size(400, 800)),
      );
      // Force fresh state with populated ingredients
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(createTestWidget(size: const Size(400, 800)));
      await tester.pumpAndSettle();

      final filledIngredientsSize = tester.getSize(
        find.ancestor(
          of: find.text('Ingredientes disponibles'),
          matching: find.byType(Card),
        ),
      );
      final filledRecipesSize = tester.getSize(
        find.ancestor(
          of: find.text('¿Qué cocino hoy?'),
          matching: find.byType(Card),
        ),
      );
      final filledShoppingSize = tester.getSize(
        find.ancestor(
          of: find.text('Lista de compras'),
          matching: find.byType(Card),
        ),
      );

      expect(
        filledRecipesSize.height,
        greaterThan(filledIngredientsSize.height),
      );
      expect(
        filledRecipesSize.height,
        greaterThan(filledShoppingSize.height),
      );
    });

    testWidgets(
        'navigates directly to AddIngredientScreen when tapping Agregar ingredientes panel',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar ingredientes'));
      await tester.pumpAndSettle();

      expect(find.byType(AddIngredientScreen), findsOneWidget);
      expect(find.text('Nombre del ingrediente'), findsOneWidget);
    });

    testWidgets(
        'navigates to ShoppingListScreen when tapping Ingredientes disponibles panel',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ingredientes disponibles'));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingListScreen), findsOneWidget);
    });

    testWidgets(
        'navigates to ShoppingListScreen Lista de compras tab when tapping Lista de compras panel',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lista de compras'));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(find.text('Lista de compras'), findsOneWidget);
      expect(find.text('Tu lista de compras está vacía'), findsOneWidget);
    });

    testWidgets(
        'navigates to RecipeManagementScreen when tapping Gestión de recetas panel',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gestión de recetas'));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeManagementScreen), findsOneWidget);
      expect(find.text('Gestión de Recetas'), findsOneWidget);
    });

    testWidgets(
        'navigates to NutritionTipsScreen and displays active summary on HomeScreen',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final history = RecipeHistoryService(preferences: prefs);
      await history.recordCooked(
        const Recipe(
          id: 'test_meal',
          title: 'Arroz sencillo',
          ingredients: [
            RecipeIngredient(name: 'Arroz blanco', displayAmount: '1 taza'),
          ],
          instructions: ['Cocinar arroz'],
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Consejos de Nutrición'), findsOneWidget);
      expect(
        find.textContaining('consejos de nutrición activos'),
        findsOneWidget,
      );

      await tester.tap(find.text('Consejos de Nutrición'));
      await tester.pumpAndSettle();

      expect(find.byType(NutritionTipsScreen), findsOneWidget);
      expect(find.text('Consejos de Nutrición'), findsOneWidget);
    });
  });

  group('Burger Menu & Light/Dark Theme Selector', () {
    testWidgets('starts in light mode by default and toggles to dark mode',
        (tester) async {
      await tester.pumpWidget(const FoodFriendApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.light));

      // Toggle via HomeScreen AppBar button
      await tester.tap(find.byTooltip('Cambiar a modo oscuro'));
      await tester.pumpAndSettle();

      final updatedApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(updatedApp.themeMode, equals(ThemeMode.dark));
      expect(find.byTooltip('Cambiar a modo claro'), findsOneWidget);
    });

    testWidgets(
        'burger menu navigates between logical screens while excluding add-ingredient sub-screens',
        (tester) async {
      await tester.pumpWidget(const FoodFriendApp());
      await tester.pumpAndSettle();

      // Open drawer from HomeScreen
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Drawer lists logical destinations and excludes scanner sub-screens
      expect(find.byType(AppNavigationDrawer), findsOneWidget);
      expect(find.text('Escanear refrigerador'), findsNothing);
      expect(find.text('Escanear recibo'), findsNothing);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);

      // Switch theme from drawer SegmentedButton
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();
      expect(ThemeController.instance.themeMode, equals(ThemeMode.dark));

      // Navigate to Lista de compras from drawer
      await tester.tap(
        find.descendant(
          of: find.byType(AppNavigationDrawer),
          matching: find.text('Lista de compras'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(find.text('Tu lista de compras está vacía'), findsOneWidget);

      // From ShoppingListScreen, open left burger menu via AppMenuButton and jump to ¿Qué cocino hoy?
      final menuFinder = find.byTooltip('Menú de navegación');
      expect(menuFinder, findsOneWidget);
      final menuRect = tester.getRect(menuFinder);
      final backRect = tester.getRect(find.byType(BackButton));
      // Menu button is consistently on the left half beside BackButton (never right actions)
      expect(menuRect.left, greaterThanOrEqualTo(backRect.right - 8));
      expect(menuRect.right, lessThan(200));

      final subScaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
      expect(subScaffold.hasDrawer, isTrue);
      expect(subScaffold.hasEndDrawer, isFalse);

      await tester.tap(menuFinder);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppNavigationDrawer),
          matching: find.text('¿Qué cocino hoy?'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RecipeSuggestionsScreen), findsOneWidget);
      final suggestionsScaffold =
          tester.state<ScaffoldState>(find.byType(Scaffold));
      expect(suggestionsScaffold.hasDrawer, isTrue);
      expect(suggestionsScaffold.hasEndDrawer, isFalse);
    });
  });
}

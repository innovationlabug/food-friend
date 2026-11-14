import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/core/settings/settings_controller.dart';
import 'package:food_friend/core/theme/theme_controller.dart';
import 'package:food_friend/core/widgets/app_navigation_drawer.dart';
import 'package:food_friend/features/home/presentation/home_screen.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/presentation/add_ingredient_screen.dart';
import 'package:food_friend/features/settings/presentation/settings_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsController.instance.resetToDefaults();
    ThemeController.instance.resetToLight();
  });

  group('SettingsScreen contextual ordering & drawer button', () {
    testWidgets('shows Pantalla principal on top when opened from HomeScreen',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final settingsTile = find.descendant(
        of: find.byType(AppNavigationDrawer),
        matching: find.text('Configuración'),
      );
      expect(settingsTile, findsOneWidget);

      await tester.tap(settingsTile);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      final homeHeaderPos = tester.getTopLeft(find.text('Pantalla principal'));
      final ingredientsHeaderPos =
          tester.getTopLeft(find.text('Lista y registro de ingredientes'));
      expect(homeHeaderPos.dy, lessThan(ingredientsHeaderPos.dy));
    });

    testWidgets(
        'shows Lista y registro de ingredientes on top when opened from ShoppingListScreen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ShoppingListScreen(initialTab: 0)),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      final homeHeaderPos = tester.getTopLeft(find.text('Pantalla principal'));
      final ingredientsHeaderPos =
          tester.getTopLeft(find.text('Lista y registro de ingredientes'));
      expect(ingredientsHeaderPos.dy, lessThan(homeHeaderPos.dy));
    });

    testWidgets(
        'shows Lista y registro de ingredientes on top when opened from AddIngredientScreen (including shopping list mode)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddIngredientScreen(isShoppingList: true)),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      final homeHeaderPos = tester.getTopLeft(find.text('Pantalla principal'));
      final ingredientsHeaderPos =
          tester.getTopLeft(find.text('Lista y registro de ingredientes'));
      expect(ingredientsHeaderPos.dy, lessThan(homeHeaderPos.dy));
    });
  });

  group('Main screen hide panels settings', () {
    testWidgets(
        'toggling hide panels hides Nutrition tips and Recipe management on HomeScreen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Initially all 6 panels are shown
      expect(find.text('Consejos de Nutrición'), findsOneWidget);
      expect(find.text('Gestión de recetas'), findsOneWidget);

      // Open settings from drawer
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      // Toggle both hide switches ON
      await tester.tap(find.text('Ocultar Consejos de Nutrición'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ocultar Gestión de recetas'));
      await tester.pumpAndSettle();

      expect(SettingsController.instance.hideNutritionTipsPanel, isTrue);
      expect(SettingsController.instance.hideRecipeManagementPanel, isTrue);

      // Return to HomeScreen
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Consejos de Nutrición'), findsNothing);
      expect(find.text('Gestión de recetas'), findsNothing);

      // Remaining panels expand cleanly
      expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
      expect(find.text('Lista de compras'), findsOneWidget);
      final shoppingCard = tester.getSize(
        find.ancestor(
          of: find.text('Lista de compras'),
          matching: find.byType(Card),
        ),
      );
      expect(shoppingCard.width, greaterThan(340));
    });
  });

  group('Ingredient list / add ingredient settings', () {
    testWidgets(
        'auto-return setting returns to ShoppingListScreen after adding a single ingredient when enabled',
        (tester) async {
      final storage = IngredientStorageService();

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListScreen(
            storageService: storage,
            initialTab: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enable auto-return in Settings via drawer
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Volver automáticamente a la lista'));
      await tester.pumpAndSettle();
      expect(
        SettingsController.instance.autoReturnAfterAddingIngredient,
        isTrue,
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Open AddIngredientScreen from ShoppingListScreen
      await tester.tap(find.widgetWithText(FilledButton, 'Agregar ingrediente'));
      await tester.pumpAndSettle();
      expect(find.byType(AddIngredientScreen), findsOneWidget);

      // Add a single ingredient via quick-add chip
      await tester.tap(find.text('Tomate'));
      await tester.pumpAndSettle();

      // Should have automatically returned to ShoppingListScreen with Tomate listed
      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(find.byType(AddIngredientScreen), findsNothing);
      expect(find.text('Tomate'), findsOneWidget);
    });

    testWidgets(
        'reset tooltips button re-enables the Enter shortcut tip on AddIngredientScreen',
        (tester) async {
      final storage = IngredientStorageService();

      await tester.pumpWidget(
        MaterialApp(
          home: AddIngredientScreen(storageService: storage),
        ),
      );
      await tester.pumpAndSettle();

      final input = find.widgetWithText(TextFormField, 'Nombre del ingrediente');
      await tester.enterText(input, 'p');
      await tester.pumpAndSettle();

      const tipText =
          'Consejo: Al presionar Enter se agregará automáticamente el primer ingrediente de la lista.';
      expect(find.text(tipText), findsOneWidget);

      // Dismiss the tip
      await tester.tap(find.byTooltip('Cerrar consejo'));
      await tester.pumpAndSettle();
      expect(find.text(tipText), findsNothing);

      // Typing again does not show the dismissed tip
      await tester.enterText(input, 'po');
      await tester.pumpAndSettle();
      expect(find.text(tipText), findsNothing);

      // Open Settings from drawer and press Reset tooltips
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restablecer consejos'));
      await tester.pumpAndSettle();
      expect(
        find.text('Consejos restablecidos. Se mostrarán nuevamente.'),
        findsOneWidget,
      );

      // Return to AddIngredientScreen and type again
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.enterText(input, 'pol');
      await tester.pumpAndSettle();

      expect(find.text(tipText), findsOneWidget);
    });
  });
}

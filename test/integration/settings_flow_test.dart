import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/core/settings/settings_controller.dart';
import 'package:food_friend/core/theme/theme_controller.dart';
import 'package:food_friend/features/ingredients/presentation/add_ingredient_screen.dart';
import 'package:food_friend/features/settings/presentation/settings_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:food_friend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsController.instance.resetToDefaults();
    ThemeController.instance.resetToLight();
  });

  testWidgets(
      'E2E Settings Flow: configures home panels, auto-return, and resets dismissed tips',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 1. Launch app on HomeScreen
    await tester.pumpWidget(const FoodFriendApp());
    await tester.pumpAndSettle();

    expect(find.text('Consejos de Nutrición'), findsOneWidget);
    expect(find.text('Gestión de recetas'), findsOneWidget);

    // 2. Open Settings from HomeScreen drawer -> Pantalla principal is on top
    await tester.tap(find.byTooltip('Menú de navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Pantalla principal')).dy,
      lessThan(
        tester.getTopLeft(find.text('Lista y registro de ingredientes')).dy,
      ),
    );

    // Hide Consejos de Nutrición panel
    await tester.tap(find.text('Ocultar Consejos de Nutrición'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Consejos de Nutrición'), findsNothing);
    expect(find.text('Gestión de recetas'), findsOneWidget);

    // 3. Navigate to AddIngredientScreen, trigger & dismiss Enter tip
    await tester.tap(find.text('Agregar ingredientes'));
    await tester.pumpAndSettle();
    expect(find.byType(AddIngredientScreen), findsOneWidget);

    final input = find.widgetWithText(TextFormField, 'Nombre del ingrediente');
    await tester.enterText(input, 't');
    await tester.pumpAndSettle();

    const tipText =
        'Consejo: Al presionar Enter se agregará automáticamente el primer ingrediente de la lista.';
    expect(find.text(tipText), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar consejo'));
    await tester.pumpAndSettle();
    expect(find.text(tipText), findsNothing);

    // 4. Open Settings from AddIngredientScreen -> Ingredient section is on top
    await tester.tap(find.byTooltip('Menú de navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Lista y registro de ingredientes')).dy,
      lessThan(tester.getTopLeft(find.text('Pantalla principal')).dy),
    );

    // Enable auto-return and reset tooltips
    await tester.tap(find.text('Volver automáticamente a la lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restablecer consejos'));
    await tester.pumpAndSettle();

    // Return to AddIngredientScreen
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Typing shows tip again; tapping suggestion auto-returns to ShoppingListScreen
    await tester.enterText(input, 'tom');
    await tester.pumpAndSettle();
    expect(find.text(tipText), findsOneWidget);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    expect(find.byType(ShoppingListScreen), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
  });
}

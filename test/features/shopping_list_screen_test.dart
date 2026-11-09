import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/amount_unit.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:food_friend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({IngredientStorageService? storageService}) {
    return MaterialApp(
      home: ShoppingListScreen(storageService: storageService),
    );
  }

  group('ShoppingListScreen', () {
    testWidgets('displays empty state when no ingredients are stored',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lista de compras'), findsOneWidget);
      expect(find.text('No tienes ingredientes guardados'), findsOneWidget);
      expect(
        find.text(
          'Agrega los ingredientes que tienes disponibles en casa o los que necesitas comprar.',
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
      expect(find.text('Nombre del ingrediente *'), findsOneWidget);

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del ingrediente *'),
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
          'Esta acción eliminará todos los ingredientes guardados en tu lista de compras y despensa. ¿Deseas continuar?',
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

      // Tap primary navigation button
      final shoppingNavBtn = find.text('Ir a lista de compras');
      expect(shoppingNavBtn, findsAtLeastNWidgets(1));
      await tester.tap(shoppingNavBtn.first);
      await tester.pumpAndSettle();

      // Verify on Shopping List Screen
      expect(find.text('Lista de compras'), findsOneWidget);
      expect(find.text('No tienes ingredientes guardados'), findsOneWidget);
    });
  });
}


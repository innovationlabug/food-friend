import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/presentation/add_ingredient_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IngredientStorageService storageService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storageService = IngredientStorageService();
  });

  Widget createWidget({int initialTab = 0}) {
    return MaterialApp(
      home: AddIngredientScreen(
        storageService: storageService,
        initialTab: initialTab,
      ),
    );
  }

  group('US-2.2: Add Ingredient via Text Input with Auto-Suggestions', () {
    testWidgets('presents a text field in Spanish where user can type an ingredient name',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Agregar ingrediente'), findsOneWidget);
      expect(find.text('Nombre del ingrediente *'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Guardar'), findsOneWidget);
    });

    testWidgets('displays matching suggestions in real time with case and accent insensitivity',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final input = find.widgetWithText(TextFormField, 'Nombre del ingrediente *');

      // Type unaccented lowercase 'pech'
      await tester.enterText(input, 'pech');
      await tester.pumpAndSettle();

      expect(find.text('Sugerencias en tiempo real:'), findsOneWidget);
      expect(find.text('Pechuga de pollo'), findsOneWidget);

      // Type 'guis' matching 'Güisquil'
      await tester.enterText(input, 'guis');
      await tester.pumpAndSettle();

      expect(find.text('Güisquil'), findsOneWidget);
    });

    testWidgets('tapping a suggestion immediately selects and adds that ingredient name',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final input = find.widgetWithText(TextFormField, 'Nombre del ingrediente *');
      await tester.enterText(input, 'frijol');
      await tester.pumpAndSettle();

      // Suggestions should include 'Frijoles negros'
      final suggestion = find.text('Frijoles negros');
      expect(suggestion, findsOneWidget);

      // Tap suggestion
      await tester.ensureVisible(suggestion);
      await tester.pumpAndSettle();
      await tester.tap(suggestion);
      await tester.pumpAndSettle();

      // Verify persistent storage contains the ingredient with only name
      final stored = await storageService.getIngredients();
      expect(stored.length, equals(1));
      expect(stored.first.name, equals('Frijoles negros'));
      expect(stored.first.amountValue, isNull);
      expect(stored.first.brand, isNull);
    });

    testWidgets('shows tooltip on first text input explaining Enter auto-adds first ingredient',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Before typing, tip is not displayed
      expect(
        find.text(
          'Consejo: Al presionar Enter se agregará automáticamente el primer ingrediente de la lista.',
        ),
        findsNothing,
      );

      final input = find.widgetWithText(TextFormField, 'Nombre del ingrediente *');
      await tester.enterText(input, 'p');
      await tester.pumpAndSettle();

      // Now tip is displayed
      expect(
        find.text(
          'Consejo: Al presionar Enter se agregará automáticamente el primer ingrediente de la lista.',
        ),
        findsOneWidget,
      );

      // Close tip
      final closeBtn = find.byTooltip('Cerrar consejo');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Consejo: Al presionar Enter se agregará automáticamente el primer ingrediente de la lista.',
        ),
        findsNothing,
      );
    });

    testWidgets('submitting text without tapping suggestion selects closest match automatically',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final input = find.widgetWithText(TextFormField, 'Nombre del ingrediente *');

      // Type typo 'pechuga de polo'
      await tester.enterText(input, 'pechuga de polo');
      await tester.pumpAndSettle();

      // Tap 'Guardar' button without clicking a suggestion
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      final stored = await storageService.getIngredients();
      expect(stored.length, equals(1));
      expect(stored.first.name, equals('Pechuga de pollo'));
    });

    testWidgets('quick-add chips allow one-tap ingredient addition',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final chip = find.text('Tomate');
      expect(chip, findsOneWidget);

      await tester.tap(chip);
      await tester.pumpAndSettle();

      final stored = await storageService.getIngredients();
      expect(stored.length, equals(1));
      expect(stored.first.name, equals('Tomate'));
    });

    testWidgets('has "Ver lista" action button in AppBar to navigate to shopping list',
        (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final listButton = find.text('Ver lista');
      expect(listButton, findsOneWidget);

      await tester.tap(listButton);
      await tester.pumpAndSettle();

      // Successfully navigates to ShoppingListScreen
      expect(find.text('Lista de compras'), findsOneWidget);
    });
  });
}


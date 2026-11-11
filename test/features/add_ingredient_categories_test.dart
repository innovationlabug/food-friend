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

  Widget createWidget({int initialTab = 1}) {
    return MaterialApp(
      home: AddIngredientScreen(
        storageService: storageService,
        initialTab: initialTab,
      ),
    );
  }

  group('US-2.3: Add Ingredient via Common Ingredient Categories', () {
    testWidgets('Add Ingredient screen provides an option to browse ingredients by category',
        (tester) async {
      await tester.pumpWidget(createWidget(initialTab: 0));
      await tester.pumpAndSettle();

      // Check category tab header exists
      final categoryTab = find.text('Categorías');
      expect(categoryTab, findsOneWidget);

      // Tap category tab and verify transition to category view
      await tester.tap(categoryTab);
      await tester.pumpAndSettle();

      expect(find.text('Selecciona una categoría de alimentos:'), findsOneWidget);
      expect(find.text('Proteínas y Carnes'), findsOneWidget);
      expect(find.text('Verduras y Vegetales'), findsOneWidget);
    });

    testWidgets('navigates Level 1 -> Level 2 -> Level 3 hierarchy in 3 steps',
        (tester) async {
      await tester.pumpWidget(createWidget(initialTab: 1));
      await tester.pumpAndSettle();

      // Step 1: Tap Level 1 category 'Proteínas y Carnes'
      final proteinCategory = find.text('Proteínas y Carnes');
      expect(proteinCategory, findsOneWidget);
      await tester.tap(proteinCategory);
      await tester.pumpAndSettle();

      // Verify Level 2 subcategories are revealed
      expect(find.text('Pollo'), findsOneWidget);
      expect(find.text('Res'), findsOneWidget);
      expect(find.text('Cerdo'), findsOneWidget);
      expect(find.text('Pescados y Mariscos'), findsOneWidget);
      expect(find.text('Embutidos y carnes frías'), findsOneWidget);

      // Step 2: Tap Level 2 subcategory 'Pollo'
      final polloSubcategory = find.text('Pollo');
      await tester.tap(polloSubcategory);
      await tester.pumpAndSettle();

      // Verify Level 3 selectable leaf ingredients are revealed
      expect(find.text('Pechuga de pollo'), findsOneWidget);
      expect(find.text('Alitas de pollo'), findsOneWidget);
      expect(find.text('Muslos de pollo'), findsOneWidget);

      // Step 3: Tap Level 3 leaf ingredient 'Pechuga de pollo'
      final pechugaItem = find.text('Pechuga de pollo');
      await tester.tap(pechugaItem);
      await tester.pumpAndSettle();

      // Verify leaf ingredient was added to local storage
      final stored = await storageService.getIngredients();
      expect(stored.length, equals(1));
      expect(stored.first.name, equals('Pechuga de pollo'));
    });

    testWidgets('allows navigating back up category levels via back button',
        (tester) async {
      await tester.pumpWidget(createWidget(initialTab: 1));
      await tester.pumpAndSettle();

      // Enter Level 1
      await tester.tap(find.text('Verduras y Vegetales'));
      await tester.pumpAndSettle();
      expect(find.text('Verduras para ensalada'), findsOneWidget);

      // Enter Level 2
      await tester.tap(find.text('Verduras para ensalada'));
      await tester.pumpAndSettle();
      expect(find.text('Aguacate'), findsOneWidget);

      // Tap back button
      final backButton = find.byTooltip('Volver al nivel anterior');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should be back at Level 2 view
      expect(find.text('Verduras para ensalada'), findsOneWidget);
      expect(find.text('Aguacate'), findsNothing);

      // Tap back button again to return to Level 1 root list
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Selecciona una categoría de alimentos:'), findsOneWidget);
      expect(find.text('Verduras y Vegetales'), findsOneWidget);
    });

    testWidgets('tapping leaf ingredient saves to persistent storage and shows visual confirmation',
        (tester) async {
      await tester.pumpWidget(createWidget(initialTab: 1));
      await tester.pumpAndSettle();

      // Navigate to Granos -> Frijoles -> Frijoles negros
      await tester.tap(find.text('Granos, Cereales y Harinas'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Frijoles'));
      await tester.pumpAndSettle();

      final frijolNegro = find.text('Frijoles negros');
      expect(frijolNegro, findsOneWidget);

      await tester.tap(frijolNegro);
      await tester.pump(); // Show snackbar

      expect(find.text('Ingrediente "Frijoles negros" agregado'), findsOneWidget);

      await tester.pumpAndSettle();

      final stored = await storageService.getIngredients();
      expect(stored.any((i) => i.name == 'Frijoles negros'), isTrue);
    });

    testWidgets('US-5.2: browsing categories shows newly added staples like Queso gouda and selecting adds it',
        (tester) async {
      await tester.pumpWidget(createWidget(initialTab: 1));
      await tester.pumpAndSettle();

      // Tap 'Lácteos y Huevos'
      final lacteos = find.text('Lácteos y Huevos');
      expect(lacteos, findsOneWidget);
      await tester.tap(lacteos);
      await tester.pumpAndSettle();

      // Tap 'Quesos y crema'
      final quesos = find.text('Quesos y crema');
      expect(quesos, findsOneWidget);
      await tester.tap(quesos);
      await tester.pumpAndSettle();

      // Verify newly added staples appear
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final quesoGouda = find.text('Queso gouda');
      expect(quesoGouda, findsOneWidget);
      expect(find.text('Queso parmesano'), findsOneWidget);

      // Tap Queso gouda
      await tester.tap(quesoGouda);
      await tester.pump(); // Show snackbar

      expect(find.text('Ingrediente "Queso gouda" agregado'), findsOneWidget);
      await tester.pumpAndSettle();

      final stored = await storageService.getIngredients();
      expect(stored.any((i) => i.name == 'Queso gouda'), isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/home/presentation/home_screen.dart';
import 'package:food_friend/features/ingredients/presentation/add_ingredient_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_management_screen.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
    testWidgets('renders focused welcome hero header and exactly one "Agregar ingredientes" card on mobile',
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

      // Verify "Agregar ingredientes" text appears exactly once on the entire screen
      expect(find.text('Agregar ingredientes'), findsOneWidget);

      // Verify the card's action button is "Añadir ingredientes" (no repetition)
      expect(find.text('Añadir ingredientes'), findsOneWidget);

      // Verify other feature cards
      expect(find.text('Ingredientes disponibles'), findsOneWidget);
      expect(find.text('¿Qué cocino hoy?'), findsOneWidget);
      expect(find.text('Asistente de nutrición'), findsNothing);
    });

    testWidgets('renders exactly one "Agregar ingredientes" card on desktop viewports',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(size: const Size(1200, 900)));
      await tester.pumpAndSettle();

      // Verify "Agregar ingredientes" appears exactly once
      expect(find.text('Agregar ingredientes'), findsOneWidget);
      expect(find.text('Añadir ingredientes'), findsOneWidget);
    });

    testWidgets('navigates directly to AddIngredientScreen when tapping Añadir ingredientes',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final addBtn = find.text('Añadir ingredientes');
      expect(addBtn, findsOneWidget);

      await tester.ensureVisible(addBtn);
      await tester.pumpAndSettle();

      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Verify on AddIngredientScreen
      expect(find.byType(AddIngredientScreen), findsOneWidget);
      expect(find.text('Nombre del ingrediente'), findsOneWidget);
    });

    testWidgets('navigates to ShoppingListScreen when tapping Ir a ingredientes disponibles',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final shoppingBtn = find.text('Ir a ingredientes disponibles');
      expect(shoppingBtn, findsOneWidget);

      await tester.tap(shoppingBtn);
      await tester.pumpAndSettle();

      // Verify on ShoppingListScreen
      expect(find.byType(ShoppingListScreen), findsOneWidget);
    });

    testWidgets('navigates to ShoppingListScreen Lista de compras tab when tapping Ir a lista de compras',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final buyListBtn = find.text('Ir a lista de compras');
      expect(buyListBtn, findsOneWidget);

      await tester.ensureVisible(buyListBtn);
      await tester.pumpAndSettle();

      await tester.tap(buyListBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingListScreen), findsOneWidget);
      expect(find.text('Lista de compras'), findsOneWidget);
      expect(find.text('Tu lista de compras está vacía'), findsOneWidget);
    });

    testWidgets('navigates to RecipeManagementScreen when tapping Gestionar recetas',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final manageBtn = find.text('Gestionar recetas');
      expect(manageBtn, findsOneWidget);

      await tester.ensureVisible(manageBtn);
      await tester.pumpAndSettle();

      await tester.tap(manageBtn);
      await tester.pumpAndSettle();

      // Verify on RecipeManagementScreen
      expect(find.byType(RecipeManagementScreen), findsOneWidget);
      expect(find.text('Gestión de Recetas'), findsOneWidget);
    });
  });
}

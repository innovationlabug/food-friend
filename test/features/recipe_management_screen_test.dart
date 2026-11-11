import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:food_friend/features/recipes/presentation/recipe_management_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late RecipeHistoryService historyService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    historyService = RecipeHistoryService(preferences: prefs);
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: RecipeManagementScreen(
        historyService: historyService,
      ),
    );
  }

  group('US-7.4: Recipe Management & History View (Gestión de Recetas)', () {
    testWidgets('renders all known recipes and filter tabs (Todas, Favoritas, Cocinadas, Ocultas)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify title and header
      expect(find.text('Gestión de Recetas'), findsOneWidget);
      expect(find.text('Administra tu recetario'), findsOneWidget);

      // Verify filter tabs are rendered
      expect(find.textContaining('Todas'), findsOneWidget);
      expect(find.textContaining('Favoritas'), findsOneWidget);
      expect(find.textContaining('Cocinadas'), findsOneWidget);
      expect(find.textContaining('Ocultas (Nunca)'), findsOneWidget);

      // Verify local dataset recipes are present
      expect(find.text('Pepián de Pollo Tradicional'), findsOneWidget);
    });

    testWidgets('filters recipes by Ocultas (Nunca), shows hidden recipes, and restores them',
        (WidgetTester tester) async {
      // Mark Pepian as never
      await historyService.setPreference(
        'pepian_pollo',
        RecipePreference.never,
      );

      // Mark Hilachas as favorite and cooked 2 times
      await historyService.setPreference(
        'hilachas_res',
        RecipePreference.favorite,
      );
      await historyService.recordCooked(
        LocalRecipeDataset.instance.getRecipeById('hilachas_res')!,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap "Ocultas (Nunca)" filter tab
      final ocultasTab = find.textContaining('Ocultas (Nunca)');
      await tester.tap(ocultasTab);
      await tester.pumpAndSettle();

      // Only Pepian should be visible
      expect(find.text('Pepián de Pollo Tradicional'), findsOneWidget);
      expect(find.text('Hilachas de Res Tradicionales'), findsNothing);

      // Tap "Nunca" chip on the Pepian card to toggle it off and restore it
      // Finding the "Nunca" chip inside the card
      final nuncaChip = find.descendant(
        of: find.byType(Card),
        matching: find.text('Nunca'),
      );
      expect(nuncaChip, findsOneWidget);

      await tester.tap(nuncaChip);
      await tester.pumpAndSettle();

      // Verify confirmation SnackBar
      expect(find.text('Receta restablecida para sugerencias'), findsOneWidget);

      // Verify Pepian is now restored in history service
      final updatedRecord = await historyService.getRecord('pepian_pollo');
      expect(updatedRecord.preference, RecipePreference.none);

      // Pepian should now be gone from the "Ocultas (Nunca)" filtered list
      expect(find.text('Pepián de Pollo Tradicional'), findsNothing);
      expect(find.text('No tienes recetas ocultas (Nunca).'), findsOneWidget);
    });

    testWidgets('filters by Favoritas and Cocinadas tabs correctly',
        (WidgetTester tester) async {
      // Set favorite and cook
      await historyService.setPreference(
        'pepian_pollo',
        RecipePreference.favorite,
      );
      await historyService.recordCooked(
        LocalRecipeDataset.instance.getRecipeById('pepian_pollo')!,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check "Favoritas"
      await tester.tap(find.textContaining('Favoritas'));
      await tester.pumpAndSettle();
      expect(find.text('Pepián de Pollo Tradicional'), findsOneWidget);

      // Check "Cocinadas"
      await tester.tap(find.textContaining('Cocinadas'));
      await tester.pumpAndSettle();
      expect(find.text('Pepián de Pollo Tradicional'), findsOneWidget);
      expect(find.text('Cocinada 1 vez'), findsOneWidget);
    });

    testWidgets('tapping recipe card navigates to RecipeDetailScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final pepianCard = find.text('Pepián de Pollo Tradicional');
      expect(pepianCard, findsOneWidget);

      await tester.tap(pepianCard);
      await tester.pumpAndSettle();

      // Verify on RecipeDetailScreen
      expect(find.byType(RecipeDetailScreen), findsOneWidget);
      expect(find.text('Instrucciones de preparación'), findsOneWidget);
    });
  });
}

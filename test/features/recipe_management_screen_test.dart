import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/core/widgets/app_svg_icon.dart';
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

      // Verify title, header, and info tooltip without subtitle clutter
      expect(find.text('Gestión de Recetas'), findsOneWidget);
      expect(find.text('Administra tu recetario'), findsOneWidget);
      expect(
        find.text(
          'Consulta tu frecuencia de cocina y modifica marcas de preferencia o recetas ocultas.',
        ),
        findsNothing,
      );
      final infoIcon = find.byWidgetPredicate(
        (w) => w is AppSvgIcon && w.assetName == 'info',
      );
      expect(infoIcon, findsOneWidget);
      await tester.tap(infoIcon);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Aquí puedes ver todas las recetas'),
        findsOneWidget,
      );

      // Verify filter tabs are rendered
      expect(find.textContaining('Todas'), findsOneWidget);
      expect(find.textContaining('Favoritas'), findsOneWidget);
      expect(find.textContaining('Cocinadas'), findsOneWidget);
      expect(find.textContaining('Ocultas ('), findsOneWidget);

      // Verify unhidden recipes display "Ocultar"
      expect(find.text('Ocultar'), findsWidgets);

      // Verify local dataset recipes are present
      expect(find.text('Pepián de Pollo Tradicional'), findsOneWidget);
    });

    testWidgets('filters recipes by Ocultas, shows hidden recipes as Oculta, and restores them',
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

      // Tap "Ocultas" filter tab
      final ocultasTab = find.textContaining('Ocultas (');
      await tester.tap(ocultasTab);
      await tester.pumpAndSettle();

      // Only Pepian should be visible
      expect(find.text('Pepián de Pollo Tradicional'), findsOneWidget);
      expect(find.text('Hilachas de Res Tradicionales'), findsNothing);

      // Tap "Oculta" chip on the Pepian card to toggle it off and restore it
      final ocultaChip = find.descendant(
        of: find.byType(Card),
        matching: find.text('Oculta'),
      );
      expect(ocultaChip, findsOneWidget);

      await tester.tap(ocultaChip);
      await tester.pumpAndSettle();

      // Verify confirmation SnackBar
      expect(find.text('Receta restablecida para sugerencias'), findsOneWidget);

      // Verify Pepian is now restored in history service
      final updatedRecord = await historyService.getRecord('pepian_pollo');
      expect(updatedRecord.preference, RecipePreference.none);

      // Pepian should now be gone from the "Ocultas" filtered list
      expect(find.text('Pepián de Pollo Tradicional'), findsNothing);
      expect(find.text('No tienes recetas ocultas.'), findsOneWidget);
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

    testWidgets(
        'renders meal category filter row and combines with status tabs',
        (WidgetTester tester) async {
      await historyService.setPreference(
        'pepian_pollo',
        RecipePreference.favorite,
      );
      await historyService.setPreference(
        'omelet_espinaca_queso',
        RecipePreference.favorite,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify single Todas button exists (no duplicate Todos chip) and all filter chips share uniform height
      expect(find.textContaining('Todas ('), findsOneWidget);
      expect(find.textContaining('Todos (', skipOffstage: false), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);

      final chipFinder = find.byType(FilterChip);
      final chipElements = chipFinder.evaluate().toList();
      expect(chipElements.length, greaterThanOrEqualTo(10));
      final firstHeight = tester.getSize(chipFinder.first).height;
      for (var i = 0; i < chipElements.length; i++) {
        expect(tester.getSize(chipFinder.at(i)).height, equals(firstHeight));
      }

      // Verify meal category filter chips exist in the third row
      expect(find.textContaining('Desayuno ('), findsOneWidget);
      expect(find.textContaining('Almuerzo ('), findsOneWidget);
      expect(find.textContaining('Cena ('), findsOneWidget);
      expect(find.textContaining('Sopas y Caldos ('), findsOneWidget);
      expect(find.textContaining('Ensaladas ('), findsOneWidget);

      // Filter by Desayuno in category row
      await tester.tap(find.textContaining('Desayuno ('));
      await tester.pumpAndSettle();

      expect(find.text('Omelet de Espinaca y Queso de Capas'), findsOneWidget);
      expect(find.text('Pepián de Pollo Tradicional'), findsNothing);

      // Combine with Favoritas tab in first row
      await tester.tap(find.textContaining('Favoritas ('));
      await tester.pumpAndSettle();

      expect(find.text('Omelet de Espinaca y Queso de Capas'), findsOneWidget);
      expect(find.text('Pepián de Pollo Tradicional'), findsNothing);

      // Switch status tab to Ocultas while Desayuno is active -> empty category+status message
      await tester.tap(find.textContaining('Ocultas ('));
      await tester.pumpAndSettle();

      expect(
        find.text('No se encontraron recetas de tipo "Desayuno" en esta vista.'),
        findsOneWidget,
      );
      expect(find.text('Mostrar todas las categorías'), findsOneWidget);

      // Tap reset button -> resets category and shows regular empty Ocultas message
      await tester.tap(find.text('Mostrar todas las categorías'));
      await tester.pumpAndSettle();
      expect(find.text('No tienes recetas ocultas.'), findsOneWidget);
    });

    testWidgets(
        'renders three filter rows (cooked status, preferences, categories) and filters combined',
        (WidgetTester tester) async {
      // pepian_pollo: Almuerzo, Cooked, Liked (Me gustó)
      await historyService.recordCooked(
        LocalRecipeDataset.instance.getRecipeById('pepian_pollo')!,
      );
      await historyService.setPreference('pepian_pollo', RecipePreference.liked);

      // hilachas_res: Almuerzo, Uncooked, Liked (Me gustó)
      await historyService.setPreference('hilachas_res', RecipePreference.liked);

      // caldo_pollo_verduras: Sopas y Caldos, Uncooked, Disliked (No me gustó)
      await historyService.setPreference('caldo_pollo_verduras', RecipePreference.disliked);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Row 1: Cooked status
      expect(find.textContaining('Todas ('), findsOneWidget);
      expect(find.textContaining('Cocinadas (1)'), findsOneWidget);
      expect(find.textContaining('No cocinadas ('), findsOneWidget);

      // Row 2: Preferences
      expect(find.textContaining('Favoritas (0)'), findsOneWidget);
      expect(find.textContaining('Me gustó (2)'), findsOneWidget);
      expect(find.textContaining('No me gustó (1)'), findsOneWidget);
      expect(find.textContaining('Ocultas (0)'), findsOneWidget);
      expect(find.textContaining('Sin marcar (', skipOffstage: false), findsOneWidget);

      // Tap "No cocinadas" in Row 1 -> hides cooked pepian_pollo, keeps hilachas_res
      await tester.tap(find.textContaining('No cocinadas ('));
      await tester.pumpAndSettle();
      expect(find.text('Pepián de Pollo Tradicional'), findsNothing);
      expect(find.text('Hilachas de Res Saludables'), findsOneWidget);
      expect(find.text('Caldo de Pollo con Verduras Frescas'), findsOneWidget);

      // Tap "Me gustó (" in Row 2 -> combined (No cocinadas + Me gustó): only hilachas_res
      await tester.tap(find.textContaining('Me gustó ('));
      await tester.pumpAndSettle();
      expect(find.text('Hilachas de Res Saludables'), findsOneWidget);
      expect(find.text('Caldo de Pollo con Verduras Frescas'), findsNothing);
      expect(find.text('Pepián de Pollo Tradicional'), findsNothing);

      // Tap "No me gustó (" in Row 2 -> switches preference filter to disliked (with No cocinadas)
      await tester.tap(find.textContaining('No me gustó ('));
      await tester.pumpAndSettle();
      expect(find.text('Caldo de Pollo con Verduras Frescas'), findsOneWidget);
      expect(find.text('Hilachas de Res Saludables'), findsNothing);

      // Filter Row 3 by "Almuerzo" -> empty for (No cocinadas + No me gustó + Almuerzo)
      await tester.tap(find.textContaining('Almuerzo ('));
      await tester.pumpAndSettle();
      expect(
        find.text('No se encontraron recetas de tipo "Almuerzo" en esta vista.'),
        findsOneWidget,
      );

      // Switch Row 3 back to "Todos (" and clear preference filter by toggling "No me gustó (" off
      await tester.tap(find.text('Mostrar todas las categorías'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('No me gustó ('));
      await tester.pumpAndSettle();

      // Switch Row 1 back to "Todas (" -> all recipes visible including pepian_pollo
      await tester.tap(find.textContaining('Todas ('));
      await tester.pumpAndSettle();
      expect(find.text('Pepián de Pollo Tradicional'), findsOneWidget);
    });

    testWidgets('filters recipes by search query and clears search',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'hilachas');
      await tester.pumpAndSettle();

      expect(find.text('Hilachas de Res Saludables'), findsOneWidget);
      expect(find.text('Pepián de Pollo Tradicional'), findsNothing);

      // Search with no results shows clear button
      await tester.enterText(searchField, 'platillo_inexistente_xyz');
      await tester.pumpAndSettle();
      expect(find.text('Limpiar búsqueda'), findsOneWidget);

      await tester.tap(find.text('Limpiar búsqueda'));
      await tester.pumpAndSettle();
      expect(find.text('Pepián de Pollo Tradicional'), findsOneWidget);
    });

    testWidgets('renders recipe cards in two columns on desktop viewports',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cards = find.byType(Card);
      expect(cards, findsAtLeastNWidgets(2));
      final firstRect = tester.getRect(cards.at(0));
      final secondRect = tester.getRect(cards.at(1));
      expect(secondRect.left, greaterThan(firstRect.left));
    });
  });
}

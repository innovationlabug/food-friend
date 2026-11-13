import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/recipes/domain/recipe_search_result.dart';
import 'package:food_friend/features/recipes/domain/recipe_variation.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  const sampleRecipe = Recipe(
    id: 'test_caldo',
    title: 'Caldo de Pollo Casero',
    description: 'Caldo reconfortante con verduras de temporada.',
    category: 'Sopas y Caldos',
    difficulty: 'Fácil',
    prepTimeMinutes: 15,
    cookTimeMinutes: 35,
    servings: 4,
    ingredients: [
      RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
      RecipeIngredient(name: 'Güisquil', displayAmount: '1 unidad'),
      RecipeIngredient(name: 'Papa', displayAmount: '2 unidades'),
      RecipeIngredient(name: 'Zanahoria', displayAmount: '2 unidades'),
    ],
    instructions: [
      'Poner a hervir el agua con sal en una olla grande.',
      'Añadir la pechuga de pollo y cocinar por 20 minutos.',
      'Agregar el güisquil, la papa y la zanahoria hasta que estén suaves.',
    ],
  );

  Widget createTestWidget({required RecipeSearchResult result}) {
    return MaterialApp(
      home: RecipeDetailScreen.fromResult(result: result),
    );
  }

  group('US-4.2: RecipeDetailScreen UI & Structure', () {
    testWidgets('renders title, metadata, ingredients, and instructions in Spanish',
        (WidgetTester tester) async {
      final result = RecipeSearchResult(
        recipe: sampleRecipe,
        matchedIngredients: const [
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
          RecipeIngredient(name: 'Papa', displayAmount: '2 unidades'),
        ],
        missingIngredients: const [
          RecipeIngredient(name: 'Güisquil', displayAmount: '1 unidad'),
          RecipeIngredient(name: 'Zanahoria', displayAmount: '2 unidades'),
        ],
      );

      await tester.pumpWidget(createTestWidget(result: result));
      await tester.pumpAndSettle();

      // Verify title and description
      expect(find.text('Caldo de Pollo Casero'), findsAtLeastNWidgets(1));
      expect(find.text('Caldo reconfortante con verduras de temporada.'), findsOneWidget);

      // Verify metadata
      expect(find.text('50 min'), findsOneWidget);
      expect(find.text('4 porciones'), findsOneWidget);
      expect(find.text('Sopas y Caldos'), findsOneWidget);
      expect(find.text('Fácil'), findsOneWidget);

      // Verify ingredients breakdown: available vs missing
      expect(find.text('Ingredientes requeridos'), findsOneWidget);
      expect(find.text('Tienes en casa (2)'), findsOneWidget);
      expect(find.text('Pechuga de pollo'), findsOneWidget);
      expect(find.text('1 lb'), findsOneWidget);
      expect(find.text('Papa'), findsOneWidget);
      expect(find.text('2 unidades'), findsAtLeastNWidgets(1));

      expect(find.text('Ingredientes adicionales necesarios (2)'), findsOneWidget);
      expect(find.text('Güisquil'), findsOneWidget);
      expect(find.text('1 unidad'), findsOneWidget);
      expect(find.text('Zanahoria'), findsOneWidget);

      // Verify preparation instructions
      expect(find.text('Instrucciones de preparación'), findsOneWidget);
      expect(find.text('Poner a hervir el agua con sal en una olla grande.'), findsOneWidget);
      expect(find.text('Añadir la pechuga de pollo y cocinar por 20 minutos.'), findsOneWidget);
      expect(find.text('Agregar el güisquil, la papa y la zanahoria hasta que estén suaves.'), findsOneWidget);

      // Ensure step numbers are rendered
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays completion message when user has all required ingredients',
        (WidgetTester tester) async {
      final fullMatchResult = RecipeSearchResult(
        recipe: sampleRecipe,
        matchedIngredients: sampleRecipe.ingredients,
        missingIngredients: const [],
      );

      await tester.pumpWidget(createTestWidget(result: fullMatchResult));
      await tester.pumpAndSettle();

      expect(find.text('Tienes en casa (4)'), findsOneWidget);
      expect(find.text('Ingredientes adicionales necesarios'), findsNothing);
      expect(
        find.text(
          '¡Excelente! Tienes todos los ingredientes necesarios para preparar este platillo.',
        ),
        findsOneWidget,
      );
    });
  });

  group('US-6.2: Recipe Variations Viewer in RecipeDetailScreen', () {
    testWidgets('does not display variations button when recipe has no variations',
        (WidgetTester tester) async {
      final result = RecipeSearchResult(
        recipe: sampleRecipe,
        matchedIngredients: const [],
        missingIngredients: sampleRecipe.ingredients,
      );

      await tester.pumpWidget(createTestWidget(result: result));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ver variaciones'), findsNothing);
    });

    testWidgets('displays variations button when recipe has variations and opens variations sheet',
        (WidgetTester tester) async {
      const recipeWithVariations = Recipe(
        id: 'pollo_plancha_test',
        title: 'Pechuga a la Plancha',
        ingredients: [
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
        ],
        instructions: ['Cocinar el pollo.'],
        variations: [
          RecipeVariation(
            recipeId: 'pollo_curry_crema',
            title: 'Pechuga al Curry Cremoso con Maní',
            description: 'Baña el pollo con salsa de curry y maní tostado.',
            swappedIngredients: ['Curry', 'Maní', 'Crema pura'],
          ),
        ],
      );

      final result = RecipeSearchResult(
        recipe: recipeWithVariations,
        matchedIngredients: const [],
        missingIngredients: recipeWithVariations.ingredients,
      );

      await tester.pumpWidget(createTestWidget(result: result));
      await tester.pumpAndSettle();

      // Verify button is displayed with correct label
      final variationsButton = find.text('Ver variaciones (1)');
      expect(variationsButton, findsOneWidget);

      // Tap variations button
      await tester.tap(variationsButton);
      await tester.pumpAndSettle();

      // Verify variations sheet is presented
      expect(find.text('Variaciones de la receta'), findsOneWidget);
      expect(find.text('Pechuga al Curry Cremoso con Maní'), findsOneWidget);
      expect(find.text('Baña el pollo con salsa de curry y maní tostado.'), findsOneWidget);
      expect(find.text('Curry'), findsOneWidget);
      expect(find.text('Maní'), findsOneWidget);
      expect(find.text('Crema pura'), findsOneWidget);

      // Tap variation card to navigate to its detail screen
      await tester.tap(find.text('Pechuga al Curry Cremoso con Maní'));
      await tester.pumpAndSettle();

      // Verify navigated to the linked recipe detail view
      expect(find.text('Pechuga al Curry Cremoso con Maní'), findsAtLeastNWidgets(1));
      expect(find.text('Tiras de pechuga de pollo en una salsa cremosa de curry aromático con vegetales y maní tostado.'), findsOneWidget);
    });

    testWidgets('prevents navigation recursion loop by popping back when an opened recipe is re-selected',
        (WidgetTester tester) async {
      final dataset = LocalRecipeDataset.instance;
      final curryRecipe = dataset.getRecipeById('pollo_curry_crema')!;
      final result = RecipeSearchResult(
        recipe: curryRecipe,
        matchedIngredients: const [],
        missingIngredients: curryRecipe.ingredients,
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            return MaterialPageRoute<void>(
              settings: RouteSettings(name: 'recipe_${curryRecipe.id}'),
              builder: (_) => RecipeDetailScreen.fromResult(
                result: result,
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap variations on Curry
      await tester.tap(find.textContaining('Ver variaciones'));
      await tester.pumpAndSettle();

      // Tap Pechuga a la Plancha (which links back to Curry)
      await tester.tap(find.text('Pechuga a la Plancha con Verduras al Vapor'));
      await tester.pumpAndSettle();

      expect(find.text('Pechuga a la Plancha con Verduras al Vapor'), findsAtLeastNWidgets(1));

      // Tap variations on Plancha
      await tester.tap(find.textContaining('Ver variaciones'));
      await tester.pumpAndSettle();

      // Tap Curry (already in history stack)
      await tester.tap(find.text('Pechuga al Curry Cremoso con Maní'));
      await tester.pumpAndSettle();

      // Verified: returns cleanly to Curry
      expect(find.text('Pechuga al Curry Cremoso con Maní'), findsAtLeastNWidgets(1));
    });
  });

  group('US-7.1: Recipe History Log ("Lo cociné") & Daily Idempotency', () {
    testWidgets('displays "Lo cociné" button, registers first tap, and prevents same-day duplicates',
        (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final historyService = RecipeHistoryService(preferences: prefs);

      final result = RecipeSearchResult(
        recipe: sampleRecipe,
        matchedIngredients: sampleRecipe.ingredients,
        missingIngredients: const [],
      );

      await tester.pumpWidget(MaterialApp(
        home: RecipeDetailScreen.fromResult(
          result: result,
          historyService: historyService,
        ),
      ));
      await tester.pumpAndSettle();

      // Verify "Lo cociné" button is present initially
      final cookedButton = find.text('Lo cociné');
      expect(cookedButton, findsOneWidget);

      // Tap "Lo cociné" for the first time today
      await tester.tap(cookedButton);
      await tester.pumpAndSettle();

      // Verify confirmation feedback SnackBar
      expect(find.text('¡Receta registrada como cocinada!'), findsOneWidget);

      // Verify button updates to indicate it was cooked today
      expect(find.text('Cocinada hoy (1 vez)'), findsOneWidget);

      // Tap again on the same day (sanity check for same-day idempotency)
      await tester.tap(find.text('Cocinada hoy (1 vez)'));
      await tester.pumpAndSettle();

      // Verify already cooked message is displayed
      expect(find.text('Esta receta ya fue registrada como cocinada hoy.'), findsOneWidget);

      // Verify persisted count in service remains exactly 1
      final record = await historyService.getRecord(sampleRecipe.id);
      expect(record.timesCooked, 1);
      expect(record.isCookedToday(), isTrue);
    });
  });

  group('US-7.2: Recipe Preference Marks (Favorita, Me gustó, No me gustó, Nunca)', () {
    testWidgets('displays all 4 preference marks and allows setting and toggling them',
        (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final historyService = RecipeHistoryService(preferences: prefs);

      final result = RecipeSearchResult(
        recipe: sampleRecipe,
        matchedIngredients: sampleRecipe.ingredients,
        missingIngredients: const [],
      );

      await tester.pumpWidget(MaterialApp(
        home: RecipeDetailScreen.fromResult(
          result: result,
          historyService: historyService,
        ),
      ));
      await tester.pumpAndSettle();

      // Verify preference chips are rendered without redundant heading text
      expect(find.text('Tu preferencia para esta receta:'), findsNothing);
      expect(find.text('Favorita'), findsOneWidget);
      expect(find.text('Me gustó'), findsOneWidget);
      expect(find.text('No me gustó'), findsOneWidget);
      expect(find.text('Ocultar'), findsOneWidget);

      // 1. Tap "Favorita"
      await tester.tap(find.text('Favorita'));
      await tester.pumpAndSettle();

      expect(find.text('Marcada como Favorita'), findsOneWidget);
      var record = await historyService.getRecord(sampleRecipe.id);
      expect(record.preference, RecipePreference.favorite);

      // 2. Tap "Favorita" again to toggle off (returns to none)
      await tester.tap(find.text('Favorita'));
      await tester.pumpAndSettle();

      expect(find.text('Preferencia eliminada'), findsOneWidget);
      record = await historyService.getRecord(sampleRecipe.id);
      expect(record.preference, RecipePreference.none);

      // 3. Tap "Ocultar" -> label updates to "Oculta"
      await tester.tap(find.text('Ocultar'));
      await tester.pumpAndSettle();

      expect(find.text('Oculta'), findsOneWidget);
      expect(find.text('Ocultar'), findsNothing);
      expect(find.text('Receta oculta de sugerencias'), findsOneWidget);
      record = await historyService.getRecord(sampleRecipe.id);
      expect(record.preference, RecipePreference.never);
    });
  });
}

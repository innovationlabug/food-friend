import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_search_result.dart';
import 'package:food_friend/features/recipes/presentation/recipe_detail_screen.dart';

void main() {
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
}

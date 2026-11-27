import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/domain/receipt_food_item.dart';
import 'package:food_friend/features/nutrition/domain/nutrition_metadata.dart';
import 'package:food_friend/features/pricing/data/ingredient_price_storage_service.dart';
import 'package:food_friend/features/pricing/data/quantity_parser.dart';
import 'package:food_friend/features/pricing/data/recipe_cost_calculator.dart';
import 'package:food_friend/features/pricing/domain/ingredient_price_entry.dart';
import 'package:food_friend/features/recipes/data/local_recipe_dataset.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/sales/data/fallback_sales_data.dart';
import 'package:food_friend/features/sales/domain/supermarket_deal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FEAT-7 QuantityParser', () {
    test('parses fractions, mixed numbers, ranges, and Spanish culinary units', () {
      final halfLb = QuantityParser.parse('1/2 lb');
      expect(halfLb, isNotNull);
      expect(halfLb!.value, closeTo(0.5, 0.001));
      expect(halfLb.unit, ParsedMeasureUnit.pound);

      final mixedCups = QuantityParser.parse('1 1/2 tazas cocidas');
      expect(mixedCups, isNotNull);
      expect(mixedCups!.value, closeTo(1.5, 0.001));
      expect(mixedCups.unit, ParsedMeasureUnit.cup);

      final rangeEggs = QuantityParser.parse('2 a 4 unidades');
      expect(rangeEggs, isNotNull);
      expect(rangeEggs!.value, closeTo(3.0, 0.001));
      expect(rangeEggs.unit, ParsedMeasureUnit.unit);

      final oliveOil = QuantityParser.parse('502 ml');
      expect(oliveOil, isNotNull);
      expect(oliveOil!.value, closeTo(502.0, 0.001));
      expect(oliveOil.unit, ParsedMeasureUnit.milliliter);

      final eggCarton = QuantityParser.parse('Cartón 30 uds');
      expect(eggCarton, isNotNull);
      expect(eggCarton!.value, closeTo(30.0, 0.001));
      expect(eggCarton.unit, ParsedMeasureUnit.unit);

      expect(QuantityParser.extractPackMultiplier('Leche 3 Pack'), 3);
    });
  });

  group('FEAT-7 IngredientPriceStorageService', () {
    test('persists normalized GTQ prices from scanned receipts and reloads cleanly', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = IngredientPriceStorageService(preferences: prefs);

      final receiptItems = [
        const ReceiptFoodItem(
          rawName: 'MOLINERO AR/BLA 400G',
          standardIngredient: 'Arroz blanco',
          quantity: '400 g',
          unitCount: 1,
          priceGtq: 5.95,
          totalPriceGtq: 5.95,
          confidence: 'high',
        ),
        const ReceiptFoodItem(
          rawName: 'HUEV/BLA 12UDS',
          standardIngredient: 'Huevo',
          quantity: '12 unidades',
          unitCount: 1,
          priceGtq: 21.00,
          totalPriceGtq: 21.00,
          confidence: 'high',
        ),
        const ReceiptFoodItem(
          rawName: 'ITEM SIN PRECIO',
          standardIngredient: 'Tomate',
          quantity: '2 unidades',
          confidence: 'medium',
        ),
      ];

      await storage.savePricesFromReceipt(
        receiptItems,
        supermarket: 'Despensa Familiar',
      );

      final loaded = await storage.getPrices();
      expect(loaded.length, 2);
      expect(loaded.containsKey('arroz blanco'), isTrue);
      expect(loaded.containsKey('huevo'), isTrue);
      expect(loaded.containsKey('tomate'), isFalse);

      final rice = loaded['arroz blanco']!;
      expect(rice.source, PriceSource.receipt);
      expect(rice.supermarket, 'Despensa Familiar');
      expect(rice.baseUnit, PriceUnit.gram);
      expect(rice.pricePerBaseUnitGtq, closeTo(5.95 / 400.0, 0.0001));

      final eggs = loaded['huevo']!;
      expect(eggs.baseUnit, PriceUnit.unit);
      expect(eggs.pricePerBaseUnitGtq, closeTo(21.00 / 12.0, 0.0001));
    });

    test('does not overwrite receipt prices when saving supermarket deals', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = IngredientPriceStorageService(preferences: prefs);

      await storage.savePricesFromReceipt(
        const [
          ReceiptFoodItem(
            rawName: 'ARROZ 400G',
            standardIngredient: 'Arroz blanco',
            quantity: '400 g',
            priceGtq: 5.95,
            totalPriceGtq: 5.95,
            confidence: 'high',
          ),
        ],
        supermarket: 'Paiz',
      );

      await storage.savePricesFromDeals(const [
        SupermarketDeal(
          id: 'deal-arroz',
          supermarketId: 'latorre',
          supermarketName: 'La Torre',
          productName: 'Arroz Blanco 1000 g',
          regularPriceGtq: 19.50,
          salePriceGtq: 15.60,
          discountPercent: 20,
          savingsGtq: 3.90,
          queryTerm: 'arroz blanco',
        ),
        SupermarketDeal(
          id: 'deal-frijol',
          supermarketId: 'walmart',
          supermarketName: 'Walmart',
          productName: 'Frijol negro La Chula 1000 g',
          regularPriceGtq: 12.80,
          salePriceGtq: 11.00,
          discountPercent: 14,
          savingsGtq: 1.80,
          queryTerm: 'frijoles negros',
        ),
      ]);

      final loaded = await storage.getPrices();
      expect(loaded['arroz blanco']!.source, PriceSource.receipt);
      expect(loaded['arroz blanco']!.supermarket, 'Paiz');
      expect(loaded['frijoles negros']!.source, PriceSource.supermarketDeal);
      expect(loaded['frijoles negros']!.supermarket, 'Walmart');
    });
  });

  group('FEAT-7 RecipeCostCalculator & Nutritional Comparison', () {
    test('computes GTQ cost per serving and positive takeout savings for all 51 local recipes', () {
      final recipes = LocalRecipeDataset.instance.recipes;
      expect(recipes.length, greaterThanOrEqualTo(50));

      for (final recipe in recipes) {
        final comparison = RecipeCostCalculator.compareRecipe(
          recipe,
          deals: FallbackSalesData.deals,
        );

        expect(comparison.homeTotalCostGtq, greaterThan(0), reason: recipe.id);
        expect(comparison.homeCostPerServingGtq, greaterThan(0), reason: recipe.id);
        expect(
          comparison.takeoutCostPerServingGtq,
          greaterThan(comparison.homeCostPerServingGtq),
          reason: '${recipe.id} should be cheaper at home than delivery',
        );
        expect(comparison.hasSavings, isTrue, reason: recipe.id);
        expect(comparison.nutritionHighlights.length, inInclusiveRange(2, 3), reason: recipe.id);
        expect(
          comparison.takeoutReferenceLabel,
          isNot(equals('Plato similar a domicilio')),
          reason: '${recipe.id} should match a specific takeout benchmark category',
        );
      }
    });

    test('prioritizes persisted receipt prices over supermarket deals and baseline prices', () {
      const testRecipe = Recipe(
        id: 'rice_chicken_cost',
        title: 'Arroz con Pollo',
        category: 'Almuerzo',
        servings: 2,
        ingredients: [
          RecipeIngredient(name: 'Arroz blanco', displayAmount: '1 libra'),
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1 lb'),
        ],
        instructions: ['Cocinar todo.'],
      );

      final baselineOnly = RecipeCostCalculator.compareRecipe(testRecipe);
      expect(baselineOnly.usedReceiptPricesCount, 0);
      expect(baselineOnly.usedDealPricesCount, 0);

      final withDeal = RecipeCostCalculator.compareRecipe(
        testRecipe,
        deals: const [
          SupermarketDeal(
            id: 'deal-pollo-1',
            supermarketId: 'latorre',
            supermarketName: 'La Torre',
            productName: 'Pechuga de pollo 1 lb',
            regularPriceGtq: 24.00,
            salePriceGtq: 16.00,
            discountPercent: 33,
            savingsGtq: 8.00,
            queryTerm: 'pechuga de pollo',
          ),
        ],
      );
      expect(withDeal.usedDealPricesCount, 1);
      expect(withDeal.homeTotalCostGtq, lessThan(baselineOnly.homeTotalCostGtq));

      final withReceipt = RecipeCostCalculator.compareRecipe(
        testRecipe,
        savedPrices: {
          'arroz blanco': IngredientPriceEntry(
            ingredientName: 'Arroz blanco',
            priceGtq: 12.00,
            baseUnit: PriceUnit.gram,
            pricePerBaseUnitGtq: 12.00 / 453.592,
            source: PriceSource.receipt,
            updatedAt: DateTime(2026, 11, 27),
          ),
        },
        deals: const [
          SupermarketDeal(
            id: 'deal-arroz-1',
            supermarketId: 'latorre',
            supermarketName: 'La Torre',
            productName: 'Arroz blanco 1 lb',
            regularPriceGtq: 8.00,
            salePriceGtq: 5.00,
            discountPercent: 38,
            savingsGtq: 3.00,
            queryTerm: 'arroz blanco',
          ),
        ],
      );

      expect(withReceipt.usedReceiptPricesCount, 1);
      expect(withReceipt.usedDealPricesCount, 0);
      expect(withReceipt.ingredientBreakdown.first.source, PriceSource.receipt);
      expect(withReceipt.ingredientBreakdown.first.estimatedCostGtq, closeTo(12.00, 0.05));
    });

    test('generates honest deterministic nutrition highlights for whole-food vs processed dishes', () {
      const healthySalad = Recipe(
        id: 'healthy_salad',
        title: 'Ensalada Verde con Pollo',
        category: 'Ensaladas',
        servings: 2,
        nutritionAttributes: {
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        ingredients: [
          RecipeIngredient(name: 'Pechuga de pollo', displayAmount: '1/2 lb'),
          RecipeIngredient(name: 'Espinaca', displayAmount: '2 tazas'),
          RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
          RecipeIngredient(name: 'Aguacate', displayAmount: '1 unidad'),
        ],
        instructions: ['Mezclar.'],
      );

      final healthyHighlights = RecipeCostCalculator.buildNutritionComparison(healthySalad);
      expect(healthyHighlights.any((h) => h.contains('Menos sodio y sin ultraprocesados')), isTrue);
      expect(healthyHighlights.any((h) => h.contains('Proteína de mejor calidad')), isTrue);

      const processedDish = Recipe(
        id: 'chorizo_dish',
        title: 'Huevos con Chorizo',
        category: 'Desayuno',
        servings: 2,
        ingredients: [
          RecipeIngredient(name: 'Chorizo', displayAmount: '1/2 lb'),
          RecipeIngredient(name: 'Huevo', displayAmount: '4 unidades'),
        ],
        instructions: ['Cocinar.'],
      );

      final processedHighlights = RecipeCostCalculator.buildNutritionComparison(processedDish);
      expect(processedHighlights.any((h) => h.contains('sin ultraprocesados')), isFalse);
      expect(processedHighlights.any((h) => h.contains('embutidos')), isTrue);
    });
  });
}

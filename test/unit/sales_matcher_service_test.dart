import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe.dart';
import 'package:food_friend/features/recipes/domain/recipe_history_record.dart';
import 'package:food_friend/features/recipes/domain/recipe_ingredient.dart';
import 'package:food_friend/features/recipes/domain/recipe_preference.dart';
import 'package:food_friend/features/sales/data/sales_matcher_service.dart';
import 'package:food_friend/features/sales/domain/matched_sale_deal.dart';
import 'package:food_friend/features/sales/domain/supermarket_deal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SalesMatcherService', () {
    const sampleDeals = [
      SupermarketDeal(
        id: 'deal-aceite',
        supermarketId: 'walmart',
        supermarketName: 'Walmart',
        productName: 'Aceite de Oliva Great Value Extra Virgen',
        category: 'Abarrotes / Aceites',
        regularPriceGtq: 36.25,
        salePriceGtq: 18.13,
        discountPercent: 50,
        savingsGtq: 18.12,
        queryTerm: 'aceite',
      ),
      SupermarketDeal(
        id: 'deal-atun',
        supermarketId: 'latorre',
        supermarketName: 'La Torre',
        productName: 'Atún Agua Lomo Trozos Costa Brava',
        category: 'Abarrotes / Atún',
        regularPriceGtq: 15.35,
        salePriceGtq: 10.70,
        discountPercent: 30,
        savingsGtq: 4.65,
        queryTerm: 'atun',
      ),
      SupermarketDeal(
        id: 'deal-pollo',
        supermarketId: 'latorre',
        supermarketName: 'La Torre',
        productName: 'Milanesa Pollo Rey',
        category: 'Congelados',
        regularPriceGtq: 23.45,
        salePriceGtq: 17.55,
        discountPercent: 25,
        savingsGtq: 5.90,
        queryTerm: 'pollo',
      ),
      SupermarketDeal(
        id: 'deal-galleta',
        supermarketId: 'latorre',
        supermarketName: 'La Torre',
        productName: 'Galletas Saladas Soda',
        category: 'Snacks',
        regularPriceGtq: 12.00,
        salePriceGtq: 9.00,
        discountPercent: 25,
        savingsGtq: 3.00,
        queryTerm: 'galletas',
      ),
    ];

    test('matches Por comprar, Favorita recipes, and timesUsed > 0 ingredients',
        () {
      final matcher = SalesMatcherService();
      const favRecipe = Recipe(
        id: 'rec-atun',
        title: 'Ensalada de atún',
        ingredients: [
          RecipeIngredient(name: 'Atún', displayAmount: '1 lata'),
          RecipeIngredient(name: 'Tomate', displayAmount: '2 unidades'),
        ],
        instructions: ['Mezclar'],
      );

      final report = matcher.matchDeals(
        deals: sampleDeals,
        pantryIngredients: const [
          Ingredient(name: 'Pollo', timesUsed: 5),
          Ingredient(name: 'Cebolla', timesUsed: 0),
        ],
        shoppingListIngredients: const [
          Ingredient(name: 'Aceite de oliva'),
        ],
        recipes: const [favRecipe],
        history: {
          'rec-atun': const RecipeHistoryRecord(
            recipeId: 'rec-atun',
            preference: RecipePreference.favorite,
          ),
        },
      );

      expect(report.hasMatches, isTrue);
      expect(report.matchedDeals.length, 3);
      expect(report.shoppingListMatchesCount, 1);
      expect(report.totalPotentialSavingsGtq, closeTo(28.67, 0.01));

      // Highest priority: in "Por comprar"
      expect(report.matchedDeals[0].deal.id, 'deal-aceite');
      expect(report.matchedDeals[0].isInShoppingList, isTrue);
      expect(
        report.matchedDeals[0].reasons
            .any((r) => r.type == SaleMatchReasonType.shoppingList),
        isTrue,
      );

      // Second priority: Favorita recipe ingredient (Atún)
      expect(report.matchedDeals[1].deal.id, 'deal-atun');
      expect(
        report.matchedDeals[1].reasons
            .any((r) => r.type == SaleMatchReasonType.favoriteRecipe),
        isTrue,
      );

      // Third priority: frequent ingredient (timesUsed > 0)
      expect(report.matchedDeals[2].deal.id, 'deal-pollo');
      expect(
        report.matchedDeals[2].reasons
            .any((r) => r.type == SaleMatchReasonType.frequentIngredient),
        isTrue,
      );
    });

    test('handles Spanish plurals and accent normalization', () {
      const huevosDeal = SupermarketDeal(
        id: 'deal-huevos',
        supermarketId: 'latorre',
        supermarketName: 'La Torre',
        productName: 'Huevos Blancos Guatehuevo',
        category: 'Huevos',
        regularPriceGtq: 85.60,
        salePriceGtq: 76.90,
        discountPercent: 10,
        savingsGtq: 8.70,
        queryTerm: 'huevo',
      );

      expect(SalesMatcherService.matchesDeal(huevosDeal, 'Huevo'), isTrue);
      expect(SalesMatcherService.matchesDeal(huevosDeal, 'huevos'), isTrue);
    });
  });
}

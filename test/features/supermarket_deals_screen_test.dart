import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/home/presentation/home_screen.dart';
import 'package:food_friend/features/ingredients/data/ingredient_storage_service.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/features/recipes/data/recipe_history_service.dart';
import 'package:food_friend/features/sales/data/sales_matcher_service.dart';
import 'package:food_friend/features/sales/data/sales_service.dart';
import 'package:food_friend/features/sales/presentation/supermarket_deals_screen.dart';
import 'package:food_friend/features/shopping_list/data/shopping_list_storage_service.dart';
import 'package:food_friend/features/shopping_list/presentation/shopping_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  SalesService createStubSalesService() {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'sourceMode': 'live-cache',
          'fetchedAt': DateTime.now().toIso8601String(),
          'deals': [
            {
              'id': 'latorre-pollo-1',
              'supermarketId': 'latorre',
              'supermarketName': 'La Torre',
              'productName': 'Milanesa Pollo Rey',
              'regularPriceGtq': 23.45,
              'salePriceGtq': 17.55,
              'discountPercent': 25,
              'savingsGtq': 5.90,
              'queryTerm': 'pollo',
            },
            {
              'id': 'walmart-aceite-1',
              'supermarketId': 'walmart',
              'supermarketName': 'Walmart',
              'productName': 'Aceite de Oliva Great Value',
              'regularPriceGtq': 36.25,
              'salePriceGtq': 18.13,
              'discountPercent': 50,
              'savingsGtq': 18.12,
              'queryTerm': 'aceite',
            },
          ],
        }),
        200,
      );
    });
    return SalesService(client: client);
  }

  group('SupermarketDealsScreen & ShoppingListScreen FEAT-5 Integration', () {
    testWidgets(
        'displays sales alert banner in Por comprar and allows one-tap add to Por comprar',
        (tester) async {
      final pantry = IngredientStorageService();
      final shopping = ShoppingListStorageService(pantryStorageService: pantry);
      final history = RecipeHistoryService(ingredientStorageService: pantry);
      final salesService = createStubSalesService();
      final matcher = SalesMatcherService(
        salesService: salesService,
        ingredientStorageService: pantry,
        shoppingListService: shopping,
        historyService: history,
      );

      // Seed frequent ingredient (timesUsed > 0) matching La Torre Pollo deal
      await pantry.saveIngredients([
        const Ingredient(name: 'Pollo', timesUsed: 4),
      ]);
      await shopping.addIngredient(const Ingredient(name: 'Aceite de oliva'));

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingListScreen(
            storageService: pantry,
            shoppingListService: shopping,
            historyService: history,
            salesService: salesService,
            salesMatcherService: matcher,
            initialTab: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner renders in Spanish with GTQ savings
      expect(find.byKey(const ValueKey('sales_alert_banner')), findsOneWidget);
      expect(find.text('2 ofertas en tus ingredientes'), findsOneWidget);
      expect(find.textContaining('Q 24.02'), findsOneWidget);

      // Tap "Ver ofertas" to open SupermarketDealsScreen
      await tester.tap(find.text('Ver ofertas'));
      await tester.pumpAndSettle();

      expect(find.text('Ofertas del supermercado'), findsOneWidget);
      expect(find.text('2 ofertas para ti'), findsNothing);
      expect(find.text('Milanesa Pollo Rey'), findsOneWidget);
      expect(find.text('Q 17.55'), findsOneWidget);
      expect(find.text('Q 23.45'), findsOneWidget);
      expect(find.text('Ahorras Q 5.90'), findsOneWidget);
      expect(find.text('-25%'), findsNothing);
      expect(find.text('-50%'), findsNothing);
      expect(find.text('La Torre'), findsAtLeastNWidgets(1));
      expect(find.text('Walmart'), findsAtLeastNWidgets(1));
      expect(find.text('Walmart Guatemala'), findsNothing);

      // Verify price hierarchy: sale price larger than regular price & Ahorras, which match size
      final saleStyle = tester.widget<Text>(find.text('Q 17.55')).style!;
      final regStyle = tester.widget<Text>(find.text('Q 23.45')).style!;
      final savingsStyle =
          tester.widget<Text>(find.text('Ahorras Q 5.90')).style!;
      expect(saleStyle.fontSize, greaterThan(regStyle.fontSize!));
      expect(regStyle.fontSize, equals(savingsStyle.fontSize));

      // Pollo is not yet in Por comprar -> tap Agregar a lista de compras
      await tester.tap(
        find.widgetWithText(FilledButton, 'Agregar a lista de compras').first,
      );
      await tester.pumpAndSettle();

      final updatedList = await shopping.getIngredients();
      expect(
        updatedList.any((i) => i.name.toLowerCase() == 'pollo'),
        isTrue,
      );
    });

    testWidgets('filters deals by supermarket and toggles favorite supermarket',
        (tester) async {
      final salesService = createStubSalesService();
      await tester.pumpWidget(
        MaterialApp(
          home: SupermarketDealsScreen(salesService: salesService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Milanesa Pollo Rey'), findsOneWidget);
      expect(find.text('Aceite de Oliva Great Value'), findsOneWidget);

      // Filter by La Torre chip
      await tester.tap(find.widgetWithText(InputChip, 'La Torre'));
      await tester.pumpAndSettle();

      expect(find.text('Milanesa Pollo Rey'), findsOneWidget);
      expect(find.text('Aceite de Oliva Great Value'), findsNothing);

      // Toggle favorite supermarket tooltip icon
      await tester.tap(find.byTooltip('Marcar como supermercado favorito').first);
      await tester.pumpAndSettle();

      expect(await salesService.getFavoriteSupermarketId(), 'latorre');
    });

    testWidgets(
        'HomeScreen displays compact frequent-ingredients banner without savings subtitle',
        (tester) async {
      final pantry = IngredientStorageService();
      final history = RecipeHistoryService(ingredientStorageService: pantry);
      final salesService = createStubSalesService();
      final matcher = SalesMatcherService(
        salesService: salesService,
        ingredientStorageService: pantry,
        historyService: history,
      );

      await pantry.saveIngredients([
        const Ingredient(name: 'Pollo', timesUsed: 3),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(salesMatcherService: matcher),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sales_alert_banner')), findsOneWidget);
      expect(
        find.text('1 oferta en tus ingredientes frecuentes'),
        findsOneWidget,
      );
      expect(find.textContaining('Ahorra hasta'), findsNothing);
      expect(find.textContaining('en supermercados locales'), findsNothing);
    });
  });
}

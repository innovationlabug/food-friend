import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_friend/features/sales/data/fallback_sales_data.dart';
import 'package:food_friend/features/sales/data/sales_service.dart';
import 'package:food_friend/features/sales/domain/supermarket.dart';
import 'package:food_friend/features/sales/domain/supermarket_deal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Supermarket & SupermarketDeal Models', () {
    test('serializes and formats GTQ prices accurately', () {
      const deal = SupermarketDeal(
        id: 'latorre-pollo-1',
        supermarketId: 'latorre',
        supermarketName: 'La Torre',
        productName: 'Milanesa Pollo Rey',
        brand: 'POLLO REY',
        category: 'Congelados',
        regularPriceGtq: 23.45,
        salePriceGtq: 17.55,
        discountPercent: 25,
        savingsGtq: 5.90,
        queryTerm: 'pollo',
      );

      expect(deal.formattedSalePrice, 'Q 17.55');
      expect(deal.formattedRegularPrice, 'Q 23.45');
      expect(deal.formattedSavings, 'Q 5.90');

      final decoded = SupermarketDeal.fromJson(deal.toJson());
      expect(decoded.id, deal.id);
      expect(decoded.supermarketName, 'La Torre');
      expect(decoded.salePriceGtq, 17.55);
      expect(decoded.discountPercent, 25);
    });

    test('Supermarket model supports favorite tracking metadata', () {
      const store = Supermarket(id: 'latorre', name: 'La Torre');
      final fav = store.copyWith(isFavorite: true);
      expect(fav.isFavorite, isTrue);
      expect(Supermarket.fromJson(fav.toJson()).isFavorite, isTrue);
    });
  });

  group('SalesService', () {
    test('fetches deals from /api/sales and caches locally in SharedPreferences',
        () async {
      int httpCalls = 0;
      final mockClient = MockClient((request) async {
        httpCalls++;
        return http.Response(
          jsonEncode({
            'success': true,
            'sourceMode': 'live-cache',
            'fetchedAt': DateTime.now().toIso8601String(),
            'deals': [
              {
                'id': 'live-1',
                'supermarketId': 'walmart',
                'supermarketName': 'Walmart Guatemala',
                'productName': 'Aceite de Oliva Great Value - 502 ml',
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

      final service = SalesService(client: mockClient);
      final first = await service.fetchDeals();
      expect(first.deals.length, 1);
      expect(first.deals.first.supermarketName, 'Walmart Guatemala');
      expect(first.isFallback, isFalse);
      expect(httpCalls, 1);

      // Second call within TTL reads local cache without network call
      final second = await service.fetchDeals();
      expect(second.deals.length, 1);
      expect(httpCalls, 1);
    });

    test('falls back to curated GTQ snapshot when /api/sales fails', () async {
      final failingClient = MockClient((_) async {
        return http.Response('Service Unavailable', 503);
      });

      final service = SalesService(client: failingClient);
      final result = await service.fetchDeals();

      expect(result.isFallback, isTrue);
      expect(result.deals.length, FallbackSalesData.deals.length);
      expect(result.deals.every((d) => d.salePriceGtq > 0), isTrue);
    });

    test('persists and retrieves favorite supermarket preference', () async {
      final service = SalesService(
        client: MockClient((_) async => http.Response('{}', 500)),
      );

      expect(await service.getFavoriteSupermarketId(), isNull);
      await service.setFavoriteSupermarketId('latorre');
      expect(await service.getFavoriteSupermarketId(), 'latorre');

      final stores = await service.getSupermarkets();
      expect(stores.firstWhere((s) => s.id == 'latorre').isFavorite, isTrue);
      expect(stores.firstWhere((s) => s.id == 'walmart').isFavorite, isFalse);
    });
  });
}

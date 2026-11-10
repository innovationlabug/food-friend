import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/data/fridge_vision_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('US-3.2: FridgeVisionService Tests', () {
    test('returns error when image bytes are empty', () async {
      final service = FridgeVisionService();
      final result = await service.detectFridgeIngredients(Uint8List(0));

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('vacía'));
    });

    test('parses 200 JSON response with detected items successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('detect-fridge'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['image'], isNotEmpty);

        return http.Response(
          jsonEncode({
            'success': true,
            'summary': 'Refrigerador con productos básicos',
            'items': [
              {
                'name': 'Ketchup Pollo Campero',
                'standardIngredient': 'Ketchup',
                'brand': 'Pollo Campero',
                'quantity': '1 botella',
                'confidence': 'high',
                'isLocalBrand': true,
                'category': 'Condimentos',
              },
              {
                'name': 'Comida preparada',
                'standardIngredient': 'Comida cocinada',
                'brand': 'Casero',
                'quantity': '1 refractario',
                'confidence': 'medium',
                'isLocalBrand': false,
                'category': 'Platos preparados',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = FridgeVisionService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/detect-fridge',
      );

      final result = await service.detectFridgeIngredients(
        Uint8List.fromList([1, 2, 3, 4, 5]),
      );

      expect(result.success, isTrue);
      expect(result.items.length, 2);
      expect(result.items.first.standardIngredient, 'Ketchup');
      expect(result.items.first.isSelected, isTrue);
      expect(result.items.last.isSelected, isFalse);
    });

    test('handles 500 error gracefully and returns Spanish fallback error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'Error interno del servidor de visión',
            'items': [],
          }),
          500,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = FridgeVisionService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/detect-fridge',
      );

      final result = await service.detectFridgeIngredients(
        Uint8List.fromList([1, 2, 3]),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Error interno del servidor de visión'));
    });
  });
}

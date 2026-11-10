import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/data/receipt_parser_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('US-3.4: ReceiptParserService Tests', () {
    test('returns error when receipt image bytes are empty', () async {
      final service = ReceiptParserService();
      final result = await service.parseReceipt(Uint8List(0));

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('vacía'));
    });

    test('parses 200 JSON response with supermarket and food items successfully',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('parse-receipt'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['image'], isNotEmpty);

        return http.Response(
          jsonEncode({
            'success': true,
            'supermarket': 'Despensa Familiar Villa Nueva',
            'totalFacturaGtq': 155.60,
            'totalAlimentosGtq': 120.40,
            'summary': 'Ticket con 4 alimentos',
            'items': [
              {
                'rawName': 'MOLINERO AR/BLA 400G',
                'standardIngredient': 'Arroz blanco',
                'brand': 'Molinero',
                'category': 'Granos',
                'quantity': '400 g',
                'unitCount': 2,
                'priceGtq': 5.95,
                'totalPriceGtq': 11.90,
                'confidence': 'high',
              },
              {
                'rawName': 'ITEM DUDOSO',
                'standardIngredient': 'Producto natural',
                'brand': 'Genérica',
                'category': 'Varios',
                'quantity': '1 unidad',
                'unitCount': 1,
                'priceGtq': 15.00,
                'confidence': 'low',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = ReceiptParserService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/parse-receipt',
      );

      final result = await service.parseReceipt(
        Uint8List.fromList([10, 20, 30]),
      );

      expect(result.success, isTrue);
      expect(result.supermarket, 'Despensa Familiar Villa Nueva');
      expect(result.totalFacturaGtq, 155.60);
      expect(result.totalAlimentosGtq, 120.40);
      expect(result.formattedTotalAlimentos, 'Q 120.40');
      expect(result.items.length, 2);
      expect(result.items.first.standardIngredient, 'Arroz blanco');
      expect(result.items.first.isSelected, isTrue); // high confidence pre-selected
      expect(result.items.last.isSelected, isFalse); // low confidence unselected
    });

    test('handles 500 error gracefully and returns Spanish fallback error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'Error de lectura de recibo',
            'items': [],
          }),
          500,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = ReceiptParserService(
        client: mockClient,
        proxyBaseUrl: 'https://test/api/parse-receipt',
      );

      final result = await service.parseReceipt(
        Uint8List.fromList([1, 2, 3]),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Error de lectura de recibo'));
    });
  });
}

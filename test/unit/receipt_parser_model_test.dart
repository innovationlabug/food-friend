import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/domain/receipt_food_item.dart';

void main() {
  group('US-3.4: ReceiptFoodItem Model Tests', () {
    test('deserializes JSON correctly and pre-selects high confidence items', () {
      final highJson = {
        'rawName': 'MOLINERO AR/BLA 400G',
        'standardIngredient': 'Arroz blanco',
        'brand': 'Molinero',
        'category': 'Granos',
        'quantity': '400 g',
        'unitCount': 2,
        'priceGtq': 5.95,
        'totalPriceGtq': 11.90,
        'confidence': 'high',
      };

      final item = ReceiptFoodItem.fromJson(highJson);

      expect(item.rawName, 'MOLINERO AR/BLA 400G');
      expect(item.standardIngredient, 'Arroz blanco');
      expect(item.brand, 'Molinero');
      expect(item.quantity, '400 g');
      expect(item.unitCount, 2);
      expect(item.priceGtq, 5.95);
      expect(item.totalPriceGtq, 11.90);
      expect(item.formattedPrice, 'Q 11.90');
      expect(item.confidence, 'high');
      expect(item.isHighConfidence, isTrue);
      expect(item.confidenceLabel, 'Alta');
      // Acceptance criteria: high confidence items are pre-selected by default
      expect(item.isSelected, isTrue);
    });

    test('deserializes medium and low confidence items with isSelected = false by default', () {
      final mediumJson = {
        'rawName': 'NATURALISIMO 740400370022',
        'standardIngredient': 'Semillas o infusión',
        'brand': 'Naturalísimo',
        'category': 'Alimentos Saludables',
        'quantity': '1 unidad',
        'unitCount': 1,
        'priceGtq': 29.20,
        'confidence': 'medium',
      };

      final lowJson = {
        'rawName': 'ITEM ILEGIBLE',
        'standardIngredient': 'Producto no identificado',
        'confidence': 'low',
      };

      final mediumItem = ReceiptFoodItem.fromJson(mediumJson);
      final lowItem = ReceiptFoodItem.fromJson(lowJson);

      // Acceptance criteria: medium/low confidence items are unselected by default
      expect(mediumItem.isSelected, isFalse);
      expect(mediumItem.isMediumConfidence, isTrue);
      expect(mediumItem.confidenceLabel, 'Media');
      expect(mediumItem.formattedPrice, 'Q 29.20');

      expect(lowItem.isSelected, isFalse);
      expect(lowItem.isLowConfidence, isTrue);
      expect(lowItem.confidenceLabel, 'Baja');
    });

    test('supports Spanish confidence keys (Alta, Media, Baja)', () {
      final item = ReceiptFoodItem.fromJson({
        'nombre_ticket': 'LA COSE. FJOL/NG 400',
        'ingrediente_estandar': 'Frijol negro',
        'precio_total_gtq': 9.95,
        'confianza': 'Alta',
      });

      expect(item.standardIngredient, 'Frijol negro');
      expect(item.confidence, 'high');
      expect(item.isSelected, isTrue);
      expect(item.formattedPrice, 'Q 9.95');
    });

    test('copyWith updates fields cleanly', () {
      const item = ReceiptFoodItem(
        rawName: 'IDEAL ACTE/VEG 750ML',
        standardIngredient: 'Aceite vegetal',
        confidence: 'high',
        isSelected: true,
      );

      final unselected = item.copyWith(isSelected: false);
      expect(unselected.isSelected, isFalse);
      expect(unselected.standardIngredient, 'Aceite vegetal');
    });
  });
}


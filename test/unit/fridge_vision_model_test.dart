import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/domain/fridge_detected_item.dart';

void main() {
  group('US-3.2: FridgeDetectedItem Model Tests', () {
    test('deserializes JSON correctly and pre-selects high confidence items', () {
      final highJson = {
        'name': 'Ketchup Pollo Campero',
        'standardIngredient': 'Ketchup',
        'brand': 'Pollo Campero',
        'quantity': '1 botella de 397 g',
        'confidence': 'high',
        'isLocalBrand': true,
        'category': 'Condimentos y salsas',
      };

      final item = FridgeDetectedItem.fromJson(highJson);

      expect(item.name, 'Ketchup Pollo Campero');
      expect(item.standardIngredient, 'Ketchup');
      expect(item.brand, 'Pollo Campero');
      expect(item.quantity, '1 botella de 397 g');
      expect(item.confidence, 'high');
      expect(item.isHighConfidence, isTrue);
      expect(item.confidenceLabel, 'Alta');
      expect(item.isLocalBrand, isTrue);
      // Acceptance criteria: high confidence items are pre-selected by default
      expect(item.isSelected, isTrue);
    });

    test('deserializes medium and low confidence items with isSelected = false by default', () {
      final mediumJson = {
        'name': 'Jamón en rodajas',
        'standardIngredient': 'Jamón',
        'brand': 'Genérica',
        'quantity': '1 paquete',
        'confidence': 'medium',
        'isLocalBrand': false,
        'category': 'Embutidos',
      };

      final lowJson = {
        'name': 'Bote de comida tapada',
        'standardIngredient': 'Comida cocinada',
        'brand': 'Casero',
        'quantity': '1 recipiente',
        'confidence': 'low',
        'isLocalBrand': false,
        'category': 'Platos preparados',
      };

      final mediumItem = FridgeDetectedItem.fromJson(mediumJson);
      final lowItem = FridgeDetectedItem.fromJson(lowJson);

      // Acceptance criteria: medium/low confidence items are unselected by default
      expect(mediumItem.isSelected, isFalse);
      expect(mediumItem.isMediumConfidence, isTrue);
      expect(mediumItem.confidenceLabel, 'Media');

      expect(lowItem.isSelected, isFalse);
      expect(lowItem.isLowConfidence, isTrue);
      expect(lowItem.confidenceLabel, 'Baja');
    });

    test('supports Spanish confidence keys (Alta, Media, Baja)', () {
      final item = FridgeDetectedItem.fromJson({
        'producto': 'Frijoles volteados Ducal',
        'ingrediente_estandar': 'Frijoles volteados',
        'confianza': 'Alta',
        'es_marca_local': true,
      });

      expect(item.standardIngredient, 'Frijoles volteados');
      expect(item.confidence, 'high');
      expect(item.isSelected, isTrue);
      expect(item.isLocalBrand, isTrue);
    });

    test('copyWith updates fields cleanly', () {
      const item = FridgeDetectedItem(
        name: 'Leche Trebolac',
        standardIngredient: 'Leche entera',
        confidence: 'high',
        isSelected: true,
      );

      final unselected = item.copyWith(isSelected: false);
      expect(unselected.isSelected, isFalse);
      expect(unselected.standardIngredient, 'Leche entera');
    });
  });
}


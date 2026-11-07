import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/features/ingredients/domain/amount_unit.dart';
import 'package:food_friend/features/ingredients/domain/ingredient.dart';
import 'package:food_friend/core/utils/string_normalizer.dart';

void main() {
  group('StringNormalizer', () {
    test('normalizes Spanish accents, casing, and whitespace', () {
      expect(StringNormalizer.normalize('  PLÁTANO  '), equals('platano'));
      expect(StringNormalizer.normalize('Güisquil'), equals('guisquil'));
      expect(StringNormalizer.normalize('Café Molido'), equals('cafe molido'));
      expect(StringNormalizer.normalize('Limón'), equals('limon'));
    });

    test('areEquivalent identifies identical ingredients despite casing and accents', () {
      expect(StringNormalizer.areEquivalent('Limón', 'limon'), isTrue);
      expect(StringNormalizer.areEquivalent('Pechuga de Pollo', 'pechuga de pollo'), isTrue);
      expect(StringNormalizer.areEquivalent('Güisquil', 'guisquil'), isTrue);
      expect(StringNormalizer.areEquivalent('Frijoles', 'Arroz'), isFalse);
    });
  });

  group('AmountUnit', () {
    test('parses standard internal keys', () {
      expect(AmountUnit.fromString('liters'), equals(AmountUnit.liters));
      expect(AmountUnit.fromString('grams'), equals(AmountUnit.grams));
      expect(AmountUnit.fromString('pieces'), equals(AmountUnit.pieces));
      expect(AmountUnit.fromString('units'), equals(AmountUnit.units));
      expect(AmountUnit.fromString('milliliters'), equals(AmountUnit.milliliters));
    });

    test('parses Spanish terms and abbreviations', () {
      expect(AmountUnit.fromString('litro'), equals(AmountUnit.liters));
      expect(AmountUnit.fromString('litros'), equals(AmountUnit.liters));
      expect(AmountUnit.fromString('L'), equals(AmountUnit.liters));
      expect(AmountUnit.fromString('gramo'), equals(AmountUnit.grams));
      expect(AmountUnit.fromString('gramos'), equals(AmountUnit.grams));
      expect(AmountUnit.fromString('g'), equals(AmountUnit.grams));
      expect(AmountUnit.fromString('piezas'), equals(AmountUnit.pieces));
      expect(AmountUnit.fromString('pza'), equals(AmountUnit.pieces));
      expect(AmountUnit.fromString('unidades'), equals(AmountUnit.units));
      expect(AmountUnit.fromString('ml'), equals(AmountUnit.milliliters));
    });

    test('returns null for unknown or null unit strings', () {
      expect(AmountUnit.fromString(null), isNull);
      expect(AmountUnit.fromString(''), isNull);
      expect(AmountUnit.fromString('unknown_unit'), isNull);
    });

    test('formats singular and plural Spanish labels', () {
      expect(AmountUnit.liters.formatForAmount(1.0), equals('litro'));
      expect(AmountUnit.liters.formatForAmount(2.5), equals('litros'));
      expect(AmountUnit.grams.formatForAmount(1.0), equals('gramo'));
      expect(AmountUnit.grams.formatForAmount(500), equals('gramos'));
    });
  });

  group('Ingredient Model', () {
    final testDate = DateTime(2026, 11, 20, 12, 0, 0);

    test('instantiates with required and optional fields', () {
      final ingredient = Ingredient(
        name: 'Pechuga de pollo',
        brand: 'Pollo Rey',
        amountValue: 500.0,
        amountUnit: AmountUnit.grams,
        expirationDate: testDate,
        isBestBefore: false,
      );

      expect(ingredient.name, equals('Pechuga de pollo'));
      expect(ingredient.brand, equals('Pollo Rey'));
      expect(ingredient.amountValue, equals(500.0));
      expect(ingredient.amountUnit, equals(AmountUnit.grams));
      expect(ingredient.expirationDate, equals(testDate));
      expect(ingredient.isBestBefore, isFalse);
    });

    test('serializes to JSON with all fields', () {
      final ingredient = Ingredient(
        name: 'Leche entera',
        brand: 'Trebolac',
        amountValue: 1.0,
        amountUnit: AmountUnit.liters,
        expirationDate: testDate,
        isBestBefore: true,
      );

      final json = ingredient.toJson();

      expect(json['name'], equals('Leche entera'));
      expect(json['brand'], equals('Trebolac'));
      expect(json['amountValue'], equals(1.0));
      expect(json['amountUnit'], equals('liters'));
      expect(json['expirationDate'], equals(testDate.toIso8601String()));
      expect(json['isBestBefore'], isTrue);
    });

    test('serializes to JSON omitting optional null fields', () {
      const ingredient = Ingredient(name: 'Sal');
      final json = ingredient.toJson();

      expect(json, equals(<String, dynamic>{'name': 'Sal'}));
      expect(json.containsKey('brand'), isFalse);
      expect(json.containsKey('amountValue'), isFalse);
      expect(json.containsKey('amountUnit'), isFalse);
      expect(json.containsKey('expirationDate'), isFalse);
      expect(json.containsKey('isBestBefore'), isFalse);
    });

    test('deserializes from JSON correctly', () {
      final json = <String, dynamic>{
        'name': 'Frijoles negros',
        'brand': 'Ducal',
        'amountValue': 400,
        'amountUnit': 'grams',
        'expirationDate': testDate.toIso8601String(),
        'isBestBefore': false,
      };

      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, equals('Frijoles negros'));
      expect(ingredient.brand, equals('Ducal'));
      expect(ingredient.amountValue, equals(400.0));
      expect(ingredient.amountUnit, equals(AmountUnit.grams));
      expect(ingredient.expirationDate, equals(testDate));
      expect(ingredient.isBestBefore, isFalse);
    });

    test('deserializes minimal JSON with only name', () {
      final json = <String, dynamic>{'name': 'Cebolla blanca'};
      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, equals('Cebolla blanca'));
      expect(ingredient.brand, isNull);
      expect(ingredient.amountValue, isNull);
      expect(ingredient.amountUnit, isNull);
      expect(ingredient.expirationDate, isNull);
      expect(ingredient.isBestBefore, isNull);
    });

    test('throws FormatException if name is missing or empty', () {
      expect(() => Ingredient.fromJson(<String, dynamic>{}),
          throwsA(isA<FormatException>()));
      expect(() => Ingredient.fromJson(<String, dynamic>{'name': '   '}),
          throwsA(isA<FormatException>()));
    });

    test('copyWith updates specified fields only', () {
      final original = Ingredient(
        name: 'Tomate',
        amountValue: 3.0,
        amountUnit: AmountUnit.units,
      );

      final updated = original.copyWith(
        amountValue: 5.0,
        brand: 'Local',
      );

      expect(updated.name, equals('Tomate'));
      expect(updated.amountValue, equals(5.0));
      expect(updated.amountUnit, equals(AmountUnit.units));
      expect(updated.brand, equals('Local'));
    });

    test('equality and hashCode compare field values', () {
      final a = Ingredient(
        name: 'Aguacate',
        amountValue: 2.0,
        amountUnit: AmountUnit.units,
      );
      final b = Ingredient(
        name: 'Aguacate',
        amountValue: 2.0,
        amountUnit: AmountUnit.units,
      );
      final c = Ingredient(
        name: 'Aguacate',
        amountValue: 3.0,
        amountUnit: AmountUnit.units,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('formattedAmount formats cleanly with and without unit', () {
      expect(
        const Ingredient(
          name: 'Azúcar',
          amountValue: 500.0,
          amountUnit: AmountUnit.grams,
        ).formattedAmount,
        equals('500 g'),
      );

      expect(
        const Ingredient(
          name: 'Huevos',
          amountValue: 12.0,
        ).formattedAmount,
        equals('12'),
      );

      expect(
        const Ingredient(name: 'Canela').formattedAmount,
        isNull,
      );
    });
  });
}


import 'amount_unit.dart';

/// Data model representing an ingredient available in the user's pantry or shopping list.
class Ingredient {
  const Ingredient({
    required this.name,
    this.brand,
    this.amountValue,
    this.amountUnit,
    this.expirationDate,
    this.isBestBefore,
  });

  /// Primary ingredient identifier (e.g. 'Pechuga de pollo', 'Tomate').
  final String name;

  /// Optional brand name (e.g. 'Trebolac', 'Ducal', 'Malher').
  final String? brand;

  /// Optional numeric quantity (e.g. 500, 2, 1.5).
  final double? amountValue;

  /// Optional measurement unit (e.g. grams, liters, pieces, units).
  final AmountUnit? amountUnit;

  /// Optional expiration or best-before timestamp.
  final DateTime? expirationDate;

  /// Indicates whether [expirationDate] represents a best-before date (true)
  /// or a strict expiration date (false / null).
  final bool? isBestBefore;

  /// Creates a copy of this [Ingredient] with optional updated fields.
  Ingredient copyWith({
    String? name,
    String? brand,
    double? amountValue,
    AmountUnit? amountUnit,
    DateTime? expirationDate,
    bool? isBestBefore,
  }) {
    return Ingredient(
      name: name ?? this.name,
      brand: brand ?? this.brand,
      amountValue: amountValue ?? this.amountValue,
      amountUnit: amountUnit ?? this.amountUnit,
      expirationDate: expirationDate ?? this.expirationDate,
      isBestBefore: isBestBefore ?? this.isBestBefore,
    );
  }

  /// Serializes this [Ingredient] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      if (brand != null) 'brand': brand,
      if (amountValue != null) 'amountValue': amountValue,
      if (amountUnit != null) 'amountUnit': amountUnit!.key,
      if (expirationDate != null)
        'expirationDate': expirationDate!.toIso8601String(),
      if (isBestBefore != null) 'isBestBefore': isBestBefore,
    };
  }

  /// Deserializes an [Ingredient] from a JSON map.
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    if (rawName == null || rawName is! String || rawName.trim().isEmpty) {
      throw const FormatException('Ingredient name is required and cannot be empty.');
    }

    final rawAmount = json['amountValue'];
    final double? parsedAmount = rawAmount is num ? rawAmount.toDouble() : null;

    final rawUnit = json['amountUnit'];
    final AmountUnit? parsedUnit =
        rawUnit is String ? AmountUnit.fromString(rawUnit) : null;

    final rawDate = json['expirationDate'];
    final DateTime? parsedDate =
        rawDate is String && rawDate.isNotEmpty ? DateTime.tryParse(rawDate) : null;

    final rawBestBefore = json['isBestBefore'];
    final bool? parsedBestBefore =
        rawBestBefore is bool ? rawBestBefore : null;

    return Ingredient(
      name: rawName.trim(),
      brand: json['brand'] is String ? (json['brand'] as String).trim() : null,
      amountValue: parsedAmount,
      amountUnit: parsedUnit,
      expirationDate: parsedDate,
      isBestBefore: parsedBestBefore,
    );
  }

  /// Human-readable Spanish string formatting the amount and unit (e.g. '500 g', '2 unidades').
  String? get formattedAmount {
    if (amountValue == null) return null;

    // Display clean integer representation if without fraction
    final formattedValue = (amountValue! % 1 == 0)
        ? amountValue!.toInt().toString()
        : amountValue!.toString();

    if (amountUnit == null) {
      return formattedValue;
    }

    return '$formattedValue ${amountUnit!.shortSymbol}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient &&
        other.name == name &&
        other.brand == brand &&
        other.amountValue == amountValue &&
        other.amountUnit == amountUnit &&
        other.expirationDate == expirationDate &&
        other.isBestBefore == isBestBefore;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      brand,
      amountValue,
      amountUnit,
      expirationDate,
      isBestBefore,
    );
  }

  @override
  String toString() {
    return 'Ingredient(name: $name, brand: $brand, amountValue: $amountValue, '
        'amountUnit: ${amountUnit?.key}, expirationDate: $expirationDate, '
        'isBestBefore: $isBestBefore)';
  }
}


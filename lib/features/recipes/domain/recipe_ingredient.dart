import '../../../core/utils/string_normalizer.dart';

/// Represents a single ingredient entry within a recipe,
/// including its standardized Spanish name and display quantity.
class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.displayAmount,
  });

  /// Factory constructor to deserialize from JSON map.
  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      displayAmount: json['displayAmount'] as String? ?? '',
    );
  }

  /// Normalized Spanish ingredient name (matches IngredientCatalog names).
  final String name;

  /// Human-readable quantity in Spanish (e.g., '1 lb', '2 unidades', '1 pizca').
  final String displayAmount;

  /// Normalized representation of the ingredient name for accent- and case-insensitive comparison.
  String get normalizedName => StringNormalizer.normalize(name);

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayAmount': displayAmount,
    };
  }

  /// Creates a copy with optionally updated fields.
  RecipeIngredient copyWith({
    String? name,
    String? displayAmount,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      displayAmount: displayAmount ?? this.displayAmount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecipeIngredient &&
        other.name == name &&
        other.displayAmount == displayAmount;
  }

  @override
  int get hashCode => Object.hash(name, displayAmount);

  @override
  String toString() => '$name ($displayAmount)';
}

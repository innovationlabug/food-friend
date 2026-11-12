import 'recipe_ingredient.dart';
import 'recipe_variation.dart';

/// Represents a cooking recipe with standardized Spanish metadata,
/// ingredient requirements, ordered step-by-step preparation instructions,
/// and linked pre-defined recipe variations.
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    this.description,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.servings,
    this.difficulty,
    this.category,
    this.source = 'local',
    this.variations = const [],
  });

  /// Factory constructor to deserialize from JSON map.
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: json['description'] as String?,
      prepTimeMinutes: json['prepTimeMinutes'] as int?,
      cookTimeMinutes: json['cookTimeMinutes'] as int?,
      servings: json['servings'] as int?,
      difficulty: json['difficulty'] as String?,
      category: json['category'] as String?,
      source: json['source'] as String? ?? 'local',
      variations: (json['variations'] as List<dynamic>?)
              ?.map((e) => RecipeVariation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['variationIds'] as List<dynamic>?)
              ?.map((id) => RecipeVariation(recipeId: id.toString(), title: id.toString()))
              .toList() ??
          const [],
    );
  }

  /// Unique identifier for the recipe.
  final String id;

  /// Recipe title in Spanish.
  final String title;

  /// Optional short description or culinary context in Spanish.
  final String? description;

  /// List of required ingredients with Spanish names and quantities.
  final List<RecipeIngredient> ingredients;

  /// Ordered step-by-step preparation instructions in Spanish.
  final List<String> instructions;

  /// Estimated preparation time in minutes.
  final int? prepTimeMinutes;

  /// Estimated cooking time in minutes.
  final int? cookTimeMinutes;

  /// Approximate number of servings.
  final int? servings;

  /// Difficulty level in Spanish (e.g., 'Fácil', 'Media', 'Avanzada').
  final String? difficulty;

  /// Dish category in Spanish (e.g., 'Almuerzo', 'Cena', 'Desayuno', 'Sopas y Caldos').
  final String? category;

  /// Origin of the recipe ('local' for offline preloaded recipes, or 'external').
  final String source;

  /// Pre-defined variations of this recipe linking to related recipes.
  final List<RecipeVariation> variations;

  /// List of variation identifiers for direct ID lookup.
  List<String> get variationIds => variations.map((v) => v.recipeId).toList();

  /// Whether this recipe has at least one pre-defined variation.
  bool get hasVariations => variations.isNotEmpty;

  /// Total estimated time in minutes (prep + cook).
  int? get totalTimeMinutes {
    if (prepTimeMinutes == null && cookTimeMinutes == null) return null;
    return (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);
  }

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      if (prepTimeMinutes != null) 'prepTimeMinutes': prepTimeMinutes,
      if (cookTimeMinutes != null) 'cookTimeMinutes': cookTimeMinutes,
      if (servings != null) 'servings': servings,
      if (difficulty != null) 'difficulty': difficulty,
      if (category != null) 'category': category,
      'source': source,
      if (variations.isNotEmpty) 'variations': variations.map((v) => v.toJson()).toList(),
      if (variations.isNotEmpty) 'variationIds': variationIds,
    };
  }

  /// Creates a copy with optionally updated fields.
  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? servings,
    String? difficulty,
    String? category,
    String? source,
    List<RecipeVariation>? variations,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      source: source ?? this.source,
      variations: variations ?? this.variations,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Recipe(id: $id, title: "$title")';
}

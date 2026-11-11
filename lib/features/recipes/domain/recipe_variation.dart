/// Represents a pre-defined variation of a recipe, linking to another related
/// recipe that shares most base ingredients while changing 1-2 ingredients
/// or preparation style (e.g., swapping a sauce, protein, or side/topping).
class RecipeVariation {
  const RecipeVariation({
    required this.recipeId,
    required this.title,
    this.description,
    this.swappedIngredients = const [],
  });

  /// Factory constructor to deserialize from JSON map.
  factory RecipeVariation.fromJson(Map<String, dynamic> json) {
    return RecipeVariation(
      recipeId: json['recipeId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      swappedIngredients: (json['swappedIngredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// The unique identifier of the linked variation recipe.
  final String recipeId;

  /// Display title of the variation in Spanish (e.g., "Pechuga al Curry Cremoso").
  final String title;

  /// Short explanation in Spanish of what changes in ingredients or cooking method.
  final String? description;

  /// List of swapped or added ingredients highlighting the difference.
  final List<String> swappedIngredients;

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'title': title,
      if (description != null) 'description': description,
      if (swappedIngredients.isNotEmpty) 'swappedIngredients': swappedIngredients,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecipeVariation && other.recipeId == recipeId;
  }

  @override
  int get hashCode => recipeId.hashCode;

  @override
  String toString() => 'RecipeVariation(recipeId: $recipeId, title: "$title")';
}

/// User preference states for a recipe.
enum RecipePreference {
  none,
  favorite,
  liked,
  disliked,
  never;

  /// User-facing label in Spanish.
  String get label {
    switch (this) {
      case RecipePreference.favorite:
        return 'Favorita';
      case RecipePreference.liked:
        return 'Me gustó';
      case RecipePreference.disliked:
        return 'No me gustó';
      case RecipePreference.never:
        return 'Nunca';
      case RecipePreference.none:
        return 'Sin marcar';
    }
  }

  /// Serializes the preference to a storage string.
  String toJson() => name;

  /// Deserializes a preference string.
  static RecipePreference fromJson(String? value) {
    if (value == null) return RecipePreference.none;
    return RecipePreference.values.firstWhere(
      (p) => p.name == value,
      orElse: () => RecipePreference.none,
    );
  }
}

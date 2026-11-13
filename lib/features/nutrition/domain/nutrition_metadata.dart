/// Protein completeness classification for nutrition pairing analysis.
enum ProteinGroup {
  /// Foods with negligible protein contribution or not classified as grain/legume/animal protein.
  none,

  /// Plant grains and cereals (rich in methionine, limiting in lysine).
  plantGrain,

  /// Plant legumes, nuts, and seeds (rich in lysine, limiting in methionine).
  plantLegumeOrSeed,

  /// Animal-derived proteins providing all essential amino acids cleanly in one source.
  completeAnimal,
}

/// Key vitamins and micronutrients tracked across cooked recipes.
enum TrackedNutrient {
  vitaminA('Vitamina A'),
  vitaminC('Vitamina C'),
  vitaminKFolate('Vitamina K / Folato'),
  iron('Hierro'),
  potassium('Potasio');

  const TrackedNutrient(this.label);

  /// Standardized Spanish label shown in UI tips and reports.
  final String label;
}

/// Lightweight nutritional metadata attached to catalog and recipe ingredients.
class IngredientNutritionProfile {
  const IngredientNutritionProfile({
    required this.canonicalName,
    this.isProcessedMeat = false,
    this.nutrients = const <TrackedNutrient>{},
    this.proteinGroup = ProteinGroup.none,
  });

  /// Canonical Spanish ingredient name.
  final String canonicalName;

  /// True for processed meats and high-sodium cured items whose frequent intake is flagged.
  final bool isProcessedMeat;

  /// Set of key tracked vitamins/micronutrients meaningfully contributed by this ingredient.
  final Set<TrackedNutrient> nutrients;

  /// Protein group used to detect unpaired vs. complementary protein pairings.
  final ProteinGroup proteinGroup;
}


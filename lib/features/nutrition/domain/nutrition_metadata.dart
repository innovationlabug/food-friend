import 'health_goal.dart';

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

/// Structured nutritional tags attached to ingredients and recipes for
/// deterministic health-goal alignment and tooltip generation.
enum NutritionalAttribute {
  highProtein,
  lowCalorieDensity,
  highFiberOrVitamins,
  lowSodiumWholeFood,
  highSodiumOrProcessed,
  calorieDense;

  /// Resolves a [NutritionalAttribute] from its serialized [name], or null if unknown.
  static NutritionalAttribute? fromName(String name) {
    for (final value in NutritionalAttribute.values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }
}

/// Lightweight nutritional metadata attached to catalog and recipe ingredients.
class IngredientNutritionProfile {
  const IngredientNutritionProfile({
    required this.canonicalName,
    this.isProcessedMeat = false,
    this.nutrients = const <TrackedNutrient>{},
    this.proteinGroup = ProteinGroup.none,
    this.attributes = const <NutritionalAttribute>{},
    this.goalReasons = const <HealthGoal, String>{},
  });

  /// Canonical Spanish ingredient name.
  final String canonicalName;

  /// True for processed meats and high-sodium cured items whose frequent intake is flagged.
  final bool isProcessedMeat;

  /// Set of key tracked vitamins/micronutrients meaningfully contributed by this ingredient.
  final Set<TrackedNutrient> nutrients;

  /// Protein group used to detect unpaired vs. complementary protein pairings.
  final ProteinGroup proteinGroup;

  /// Structured nutritional attributes supporting health-goal matching.
  final Set<NutritionalAttribute> attributes;

  /// Specific, grammatically natural Spanish tooltip explanations per [HealthGoal].
  final Map<HealthGoal, String> goalReasons;

  /// Whether this ingredient meaningfully contributes protein.
  bool get isHighProtein => attributes.contains(NutritionalAttribute.highProtein);

  /// Whether this ingredient is naturally low in calorie density.
  bool get isLowCalorieDensity =>
      attributes.contains(NutritionalAttribute.lowCalorieDensity);

  /// Whether this ingredient is rich in dietary fiber or essential vitamins.
  bool get isHighFiberOrVitamins =>
      attributes.contains(NutritionalAttribute.highFiberOrVitamins);

  /// Whether this ingredient is a fresh, minimally processed, low-sodium food.
  bool get isLowSodiumWholeFood =>
      attributes.contains(NutritionalAttribute.lowSodiumWholeFood);

  /// Whether this ingredient is cured, processed, or high in sodium.
  bool get isHighSodiumOrProcessed =>
      isProcessedMeat ||
      attributes.contains(NutritionalAttribute.highSodiumOrProcessed);

  /// Whether this ingredient is relatively calorie-dense (heavy creams, fats, sweets).
  bool get isCalorieDense =>
      attributes.contains(NutritionalAttribute.calorieDense);
}


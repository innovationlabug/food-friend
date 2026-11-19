/// Predefined personal health goals selectable by the user in Spanish.
enum HealthGoal {
  loseWeight(
    storageKey: 'lose_weight',
    label: 'Perder peso / Bajar calorías',
    shortLabel: 'Bajar calorías',
    description:
        'Prioriza platillos ligeros con vegetales frescos y proteínas magras.',
    iconName: 'nutrition',
  ),
  gainMuscle(
    storageKey: 'gain_muscle',
    label: 'Ganar masa muscular / Más proteína',
    shortLabel: 'Más proteína',
    description:
        'Destaca recetas con buenas fuentes de proteína animal o vegetal.',
    iconName: 'sparkles',
  ),
  reduceSodiumAndProcessed(
    storageKey: 'reduce_sodium_processed',
    label: 'Reducir sodio y alimentos procesados',
    shortLabel: 'Menos sodio',
    description:
        'Favorece ingredientes naturales sin embutidos ni salsas cargadas de sodio.',
    iconName: 'heart',
  ),
  increaseVitaminsAndFiber(
    storageKey: 'increase_vitamins_fiber',
    label: 'Aumentar vitaminas y fibra',
    shortLabel: 'Vitaminas y fibra',
    description:
        'Impulsa comidas ricas en verduras, frutas, legumbres y granos integrales.',
    iconName: 'nutrition',
  );

  const HealthGoal({
    required this.storageKey,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.iconName,
  });

  /// Stable identifier persisted in local storage.
  final String storageKey;

  /// Full Spanish label shown in the goal selection UI.
  final String label;

  /// Concise Spanish label used in compact filter summaries.
  final String shortLabel;

  /// Brief Spanish explanation of what the goal prioritizes.
  final String description;

  /// SVG icon asset name in `assets/icons/`.
  final String iconName;

  /// Concise Spanish phrase used in shopping suggestion prompts.
  String get shoppingGoalPhrase => switch (this) {
        HealthGoal.loseWeight => 'bajar calorías',
        HealthGoal.gainMuscle => 'ganar masa muscular',
        HealthGoal.reduceSodiumAndProcessed => 'reducir sodio',
        HealthGoal.increaseVitaminsAndFiber => 'aumentar vitaminas y fibra',
      };

  /// Resolves a [HealthGoal] from its persisted [storageKey], or null if unknown.
  static HealthGoal? fromStorageKey(String key) {
    for (final goal in HealthGoal.values) {
      if (goal.storageKey == key) {
        return goal;
      }
    }
    return null;
  }
}

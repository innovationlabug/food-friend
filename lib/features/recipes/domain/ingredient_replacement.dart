import '../../nutrition/domain/health_goal.dart';
import 'recipe_ingredient.dart';

/// Represents an availability-driven culinary substitution where a missing
/// recipe ingredient can be replaced by a compatible ingredient already
/// present in `"Mis ingredientes"`.
class AvailabilityReplacement {
  const AvailabilityReplacement({
    required this.missingIngredient,
    required this.availableIngredientName,
    this.note,
  });

  /// The ingredient required by the recipe that the user does not directly have.
  final RecipeIngredient missingIngredient;

  /// The compatible ingredient name currently available in `"Mis ingredientes"`.
  final String availableIngredientName;

  /// Optional short culinary context in Spanish.
  final String? note;

  /// Standardized Spanish message surfaced on recipe cards and detail screens.
  String get message =>
      'Puedes usar $availableIngredientName en lugar de ${missingIngredient.name}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AvailabilityReplacement &&
        other.missingIngredient == missingIngredient &&
        other.availableIngredientName == availableIngredientName &&
        other.note == note;
  }

  @override
  int get hashCode =>
      Object.hash(missingIngredient, availableIngredientName, note);
}

/// Represents a health-goal-driven ingredient replacement suggesting
/// healthier catalog alternatives for a less-optimal recipe ingredient.
class HealthGoalReplacement {
  const HealthGoalReplacement({
    required this.targetIngredient,
    required this.healthierAlternatives,
    required this.matchingGoals,
    required this.reason,
    this.availableAlternativesInPantry = const [],
  });

  /// The recipe ingredient for which a healthier alternative is suggested.
  final RecipeIngredient targetIngredient;

  /// Ordered list of healthier Spanish ingredient alternatives from [IngredientCatalog].
  final List<String> healthierAlternatives;

  /// Active user health goals served by this swap.
  final Set<HealthGoal> matchingGoals;

  /// Concise Spanish nutritional explanation for the swap.
  final String reason;

  /// Subset of [healthierAlternatives] currently available in `"Mis ingredientes"`.
  final List<String> availableAlternativesInPantry;

  /// Formats [healthierAlternatives] naturally in Spanish (`A` or `A o B`).
  String get formattedAlternatives {
    if (healthierAlternatives.isEmpty) return '';
    if (healthierAlternatives.length == 1) return healthierAlternatives.first;
    if (healthierAlternatives.length == 2) {
      return '${healthierAlternatives[0]} o ${healthierAlternatives[1]}';
    }
    final leading =
        healthierAlternatives.take(healthierAlternatives.length - 1).join(', ');
    return '$leading o ${healthierAlternatives.last}';
  }

  /// Concise Spanish swap instruction.
  String get message =>
      'Cambia ${targetIngredient.name} por $formattedAlternatives';

  /// Compact Spanish summary suitable for recipe suggestion cards.
  String get cardMessage => 'Sugerencia saludable: $message';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthGoalReplacement &&
        other.targetIngredient == targetIngredient &&
        other.reason == reason &&
        _listEquals(other.healthierAlternatives, healthierAlternatives) &&
        _listEquals(
          other.availableAlternativesInPantry,
          availableAlternativesInPantry,
        );
  }

  @override
  int get hashCode => Object.hash(
        targetIngredient,
        reason,
        Object.hashAll(healthierAlternatives),
        Object.hashAll(availableAlternativesInPantry),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

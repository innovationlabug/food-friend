import 'package:flutter/material.dart';
import '../../domain/recipe_preference.dart';

/// Resolves brightness-aware accent colors and SVG icon names for
/// [RecipePreference] chips so active states remain legible in both light
/// and dark themes.
class RecipePreferenceStyle {
  const RecipePreferenceStyle._();

  /// Returns the high-contrast foreground/border color for [preference] under
  /// the current [ThemeData] brightness.
  static Color colorFor(BuildContext context, RecipePreference preference) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return switch (preference) {
      RecipePreference.favorite =>
        isDark ? Colors.red.shade300 : Colors.red.shade600,
      RecipePreference.liked =>
        isDark ? Colors.green.shade300 : Colors.green.shade700,
      RecipePreference.disliked =>
        isDark ? Colors.orange.shade300 : Colors.orange.shade800,
      RecipePreference.never => colorScheme.error,
      RecipePreference.none => colorScheme.onSurfaceVariant,
    };
  }

  /// Returns the SVG asset name representing [preference].
  static String iconFor(RecipePreference preference) {
    return switch (preference) {
      RecipePreference.favorite => 'heart',
      RecipePreference.liked => 'thumb_up',
      RecipePreference.disliked => 'thumb_down',
      RecipePreference.never => 'block',
      RecipePreference.none => 'restaurant',
    };
  }

  /// Returns the Spanish display label for [preference], optionally reflecting
  /// whether it is already selected.
  static String labelFor(
    RecipePreference preference, {
    bool isSelected = false,
  }) {
    return switch (preference) {
      RecipePreference.favorite => 'Favorita',
      RecipePreference.liked => 'Me gustó',
      RecipePreference.disliked => 'No me gustó',
      RecipePreference.never => isSelected ? 'Oculta' : 'Ocultar',
      RecipePreference.none => 'Sin calificar',
    };
  }
}

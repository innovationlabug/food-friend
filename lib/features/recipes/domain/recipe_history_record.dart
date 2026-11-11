import 'recipe.dart';
import 'recipe_preference.dart';

/// Per-recipe record tracking cooking frequency, dates, and user preference.
class RecipeHistoryRecord {
  const RecipeHistoryRecord({
    required this.recipeId,
    this.timesCooked = 0,
    this.cookedDates = const <DateTime>[],
    this.preference = RecipePreference.none,
    this.cachedRecipe,
  });

  /// Identifier of the associated recipe.
  final String recipeId;

  /// Total number of times this recipe was cooked (incremented at most once per calendar day).
  final int timesCooked;

  /// Chronological list of timestamps when this recipe was cooked.
  final List<DateTime> cookedDates;

  /// User preference mark (favorite, liked, disliked, never, none).
  final RecipePreference preference;

  /// Optional cached recipe definition for externally-generated AI recipes.
  final Recipe? cachedRecipe;

  /// Returns true if this recipe was already logged as cooked on the specified [date].
  bool isCookedOn(DateTime date) {
    return cookedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  /// Returns true if this recipe has already been cooked today.
  bool isCookedToday({DateTime? now}) {
    return isCookedOn(now ?? DateTime.now());
  }

  /// Most recent date this recipe was cooked, or null if never cooked.
  DateTime? get lastCookedDate {
    if (cookedDates.isEmpty) return null;
    return cookedDates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Registers a cooking event on [cookedAt].
  /// If the recipe was already cooked on that calendar day, returns [this] unchanged (idempotent).
  RecipeHistoryRecord markCooked({DateTime? cookedAt}) {
    final date = cookedAt ?? DateTime.now();
    if (isCookedOn(date)) {
      return this;
    }
    return copyWith(
      timesCooked: timesCooked + 1,
      cookedDates: <DateTime>[...cookedDates, date],
    );
  }

  /// Creates a copy of this record with updated fields.
  RecipeHistoryRecord copyWith({
    String? recipeId,
    int? timesCooked,
    List<DateTime>? cookedDates,
    RecipePreference? preference,
    Recipe? cachedRecipe,
  }) {
    return RecipeHistoryRecord(
      recipeId: recipeId ?? this.recipeId,
      timesCooked: timesCooked ?? this.timesCooked,
      cookedDates: cookedDates ?? this.cookedDates,
      preference: preference ?? this.preference,
      cachedRecipe: cachedRecipe ?? this.cachedRecipe,
    );
  }

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recipeId': recipeId,
      'timesCooked': timesCooked,
      'cookedDates': cookedDates.map((d) => d.toIso8601String()).toList(),
      'preference': preference.toJson(),
      if (cachedRecipe != null) 'cachedRecipe': cachedRecipe!.toJson(),
    };
  }

  /// Deserializes a record from JSON.
  factory RecipeHistoryRecord.fromJson(Map<String, dynamic> json) {
    final recipeId = json['recipeId'] as String? ?? '';
    final timesCooked = (json['timesCooked'] as num?)?.toInt() ?? 0;
    final datesRaw = json['cookedDates'] as List<dynamic>? ?? const [];
    final cookedDates = datesRaw
        .map((e) => DateTime.tryParse(e.toString()))
        .whereType<DateTime>()
        .toList();
    final preference = RecipePreference.fromJson(json['preference'] as String?);

    Recipe? cachedRecipe;
    if (json['cachedRecipe'] is Map<String, dynamic>) {
      try {
        cachedRecipe = Recipe.fromJson(json['cachedRecipe'] as Map<String, dynamic>);
      } catch (_) {
        cachedRecipe = null;
      }
    }

    return RecipeHistoryRecord(
      recipeId: recipeId,
      timesCooked: timesCooked,
      cookedDates: cookedDates,
      preference: preference,
      cachedRecipe: cachedRecipe,
    );
  }
}

import '../../../core/utils/string_normalizer.dart';
import '../../nutrition/domain/health_goal.dart';
import '../domain/ingredient_replacement.dart';
import '../domain/recipe.dart';
import '../domain/recipe_ingredient.dart';
import 'recipe_search_service.dart';

class _HealthGoalSwapRule {
  const _HealthGoalSwapRule({
    required this.keywords,
    required this.goals,
    required this.alternatives,
    required this.reason,
  });

  final List<String> keywords;
  final Set<HealthGoal> goals;
  final List<String> alternatives;
  final String reason;
}

/// Deterministic culinary substitution and health-goal swap engine.
/// Runs 100% locally on device with zero external LLM calls.
class IngredientReplacementService {
  IngredientReplacementService._();

  /// Bidirectional / ordered culinary equivalents linking compatible
  /// ingredients from [IngredientCatalog].
  ///
  /// Keys are normalized Spanish names; values list ordered replacement
  /// candidates in preferred culinary order.
  static const Map<String, List<String>> _availabilitySubstitutes =
      <String, List<String>>{
    // Oils & fats
    'aceite de oliva': ['Aceite vegetal', 'Aceite de maíz'],
    'aceite vegetal': ['Aceite de maíz', 'Aceite de oliva'],
    'aceite de maiz': ['Aceite vegetal', 'Aceite de oliva'],
    'mantequilla': ['Margarina', 'Aceite de oliva', 'Aceite vegetal'],
    'margarina': ['Mantequilla', 'Aceite vegetal'],

    // Cheeses & dairy
    'queso mozzarella': ['Queso de capas', 'Queso gouda', 'Queso cheddar'],
    'queso de capas': ['Queso mozzarella', 'Queso fresco', 'Queso gouda'],
    'queso fresco': ['Queso de capas', 'Queso seco'],
    'queso gouda': ['Queso cheddar', 'Queso mozzarella', 'Queso de capas'],
    'queso cheddar': ['Queso gouda', 'Queso mozzarella'],
    'queso seco': ['Queso parmesano', 'Queso fresco'],
    'queso parmesano': ['Queso seco'],
    'crema pura': ['Crema fresca', 'Yogur natural', 'Yogur griego'],
    'crema fresca': ['Crema pura', 'Yogur natural', 'Yogur griego'],
    'crema agria': ['Yogur natural', 'Yogur griego', 'Crema fresca'],
    'yogur natural': ['Yogur griego', 'Crema fresca'],
    'yogur griego': ['Yogur natural', 'Crema fresca'],
    'leche entera': ['Leche descremada', 'Leche deslactosada', 'Leche'],
    'leche descremada': ['Leche deslactosada', 'Leche entera', 'Leche'],
    'leche deslactosada': ['Leche descremada', 'Leche entera', 'Leche'],

    // Grains, rice, pasta & flours
    'arroz blanco': ['Arroz integral', 'Arroz precocido'],
    'arroz integral': ['Arroz blanco', 'Arroz precocido'],
    'arroz precocido': ['Arroz blanco', 'Arroz integral'],
    'pasta': ['Espagueti', 'Coditos', 'Fideos'],
    'espagueti': ['Pasta', 'Coditos', 'Fideos'],
    'coditos': ['Pasta', 'Espagueti', 'Fideos'],
    'fideos': ['Pasta', 'Espagueti', 'Coditos'],
    'frijoles negros': ['Frijoles colorados', 'Frijoles blancos'],
    'frijoles colorados': ['Frijoles negros', 'Frijoles blancos'],
    'frijoles blancos': ['Frijoles negros', 'Frijoles colorados'],
    'harina de maiz': ['Masa de maíz'],
    'masa de maiz': ['Harina de maíz'],
    'avena en hojuelas': ['Avena molida', 'Avena'],
    'avena molida': ['Avena en hojuelas', 'Avena'],

    // Vegetables & fresh herbs
    'guisquil': ['Perulero', 'Güicoy'],
    'perulero': ['Güisquil', 'Güicoy'],
    'guicoy': ['Güisquil', 'Perulero'],
    'cebolla blanca': ['Cebolla morada', 'Cebolla con tallo', 'Puerro'],
    'cebolla morada': ['Cebolla blanca', 'Cebolla con tallo'],
    'cebolla con tallo': ['Cebolla blanca', 'Cebolla morada', 'Puerro'],
    'espinaca': ['Acelga', 'Berro'],
    'acelga': ['Espinaca', 'Berro'],
    'berro': ['Espinaca', 'Acelga'],
    'lechuga': ['Repollo blanco', 'Espinaca'],
    'repollo blanco': ['Repollo morado', 'Lechuga'],
    'repollo morado': ['Repollo blanco'],
    'cilantro': ['Perejil', 'Samat'],
    'perejil': ['Cilantro'],
    'oregano seco': ['Tomillo', 'Romero', 'Albahaca'],
    'tomillo': ['Orégano seco', 'Romero'],
    'romero': ['Tomillo', 'Orégano seco'],
    'chile jalapeno': ['Chile serrano'],
    'chile serrano': ['Chile jalapeño'],
    'chile guaque': ['Chile pasa'],
    'chile pasa': ['Chile guaque'],
    'brocoli': ['Coliflor'],
    'coliflor': ['Brócoli'],
    'ejote': ['Arveja', 'Arveja china'],
    'arveja': ['Arveja china', 'Ejote'],
    'arveja china': ['Arveja', 'Ejote'],

    // Proteins within same culinary family
    'pechuga de pollo': [
      'Muslos de pollo',
      'Cuadriles de pollo',
      'Pollo desmenuzado',
    ],
    'muslos de pollo': ['Cuadriles de pollo', 'Pechuga de pollo'],
    'cuadriles de pollo': ['Muslos de pollo', 'Pechuga de pollo'],
    'filete de pescado': [
      'Filete de tilapia',
      'Filete de robalo',
      'Mojarra entera',
      'Salmón',
    ],
    'filete de tilapia': [
      'Filete de robalo',
      'Filete de pescado',
      'Salmón',
    ],
    'filete de robalo': [
      'Filete de tilapia',
      'Filete de pescado',
      'Salmón',
    ],
    'salmon': ['Filete de robalo', 'Filete de tilapia', 'Filete de pescado'],
    'posta de res': ['Lomo de res', 'Bolovique', 'Carne de res'],
    'lomo de res': ['Posta de res', 'Carne de res'],
    'lomo de cerdo': ['Posta de cerdo', 'Chuleta de cerdo'],
    'posta de cerdo': ['Lomo de cerdo', 'Chuleta de cerdo'],
    'salchicha': ['Jamón', 'Longaniza guatemalteca', 'Chorizo colorado'],
    'jamon': ['Jamón de pavo', 'Salchicha'],
    'jamon de pavo': ['Jamón'],

    // Nuts, seeds, pantry & fruits
    'mani': ['Almendras', 'Nueces', 'Semillas de marañón', 'Semillas de girasol'],
    'almendras': ['Nueces', 'Maní', 'Semillas de marañón'],
    'nueces': ['Almendras', 'Maní', 'Semillas de marañón'],
    'semillas de girasol': ['Ajonjolí', 'Maní', 'Almendras'],
    'ajonjoli': ['Semillas de girasol'],
    'vinagre blanco': ['Vinagre de manzana'],
    'vinagre de manzana': ['Vinagre blanco'],
    'azucar blanca': ['Azúcar morena', 'Panela'],
    'azucar morena': ['Azúcar blanca', 'Panela'],
    'panela': ['Azúcar morena', 'Azúcar blanca'],
    'limon criollo': ['Limón persa', 'Limón'],
    'limon persa': ['Limón criollo', 'Limón'],
    'manzana roja': ['Manzana verde', 'Manzana'],
    'manzana verde': ['Manzana roja', 'Manzana'],
    'fresa': ['Mora'],
    'mora': ['Fresa'],
    'banano': ['Plátano maduro'],
    'naranja': ['Mandarina'],
    'mandarina': ['Naranja'],
  };

  /// Deterministic healthier replacement rules tailored to user [HealthGoal]s.
  static const List<_HealthGoalSwapRule> _healthGoalRules = <_HealthGoalSwapRule>[
    _HealthGoalSwapRule(
      keywords: ['crema pura', 'crema fresca', 'crema agria', 'crema'],
      goals: {
        HealthGoal.loseWeight,
        HealthGoal.gainMuscle,
        HealthGoal.reduceSodiumAndProcessed,
      },
      alternatives: ['Yogur natural', 'Aguacate'],
      reason: 'Reduce grasas saturadas y calorías manteniendo cremosidad',
    ),
    _HealthGoalSwapRule(
      keywords: ['arroz blanco', 'arroz precocido'],
      goals: {
        HealthGoal.increaseVitaminsAndFiber,
        HealthGoal.loseWeight,
      },
      alternatives: ['Arroz integral'],
      reason: 'Aporta más fibra natural, vitaminas y mayor saciedad',
    ),
    _HealthGoalSwapRule(
      keywords: [
        'salchicha',
        'jamon',
        'chorizo',
        'longaniza',
        'tocino',
        'mortadela',
        'salami',
        'embutido',
      ],
      goals: {
        HealthGoal.reduceSodiumAndProcessed,
        HealthGoal.loseWeight,
        HealthGoal.gainMuscle,
      },
      alternatives: ['Pechuga de pollo', 'Huevo', 'Frijoles negros'],
      reason: 'Evita embutidos y exceso de sodio aportando proteína natural',
    ),
    _HealthGoalSwapRule(
      keywords: ['mantequilla', 'margarina', 'manteca vegetal', 'manteca'],
      goals: {
        HealthGoal.loseWeight,
        HealthGoal.reduceSodiumAndProcessed,
      },
      alternatives: ['Aceite de oliva', 'Aguacate'],
      reason: 'Sustituye grasas saturadas o hidrogenadas por grasas saludables',
    ),
    _HealthGoalSwapRule(
      keywords: ['aceite vegetal', 'aceite de maiz'],
      goals: {
        HealthGoal.reduceSodiumAndProcessed,
        HealthGoal.loseWeight,
      },
      alternatives: ['Aceite de oliva'],
      reason: 'Opción menos procesada rica en grasas saludables',
    ),
    _HealthGoalSwapRule(
      keywords: ['mayonesa'],
      goals: {
        HealthGoal.loseWeight,
        HealthGoal.reduceSodiumAndProcessed,
      },
      alternatives: ['Yogur natural', 'Aguacate'],
      reason: 'Disminuye calorías y sodio conservando textura suave',
    ),
    _HealthGoalSwapRule(
      keywords: ['queso cheddar', 'queso gouda', 'queso crema'],
      goals: {
        HealthGoal.loseWeight,
        HealthGoal.reduceSodiumAndProcessed,
      },
      alternatives: ['Queso fresco', 'Queso de capas', 'Yogur griego'],
      reason: 'Menor contenido de grasa y sodio que quesos maduros o crema',
    ),
    _HealthGoalSwapRule(
      keywords: ['queso parmesano'],
      goals: {HealthGoal.reduceSodiumAndProcessed},
      alternatives: ['Queso fresco'],
      reason: 'Reduce el aporte de sodio manteniendo un toque lácteo',
    ),
    _HealthGoalSwapRule(
      keywords: ['azucar blanca', 'azucar morena', 'leche condensada'],
      goals: {
        HealthGoal.loseWeight,
        HealthGoal.reduceSodiumAndProcessed,
        HealthGoal.increaseVitaminsAndFiber,
      },
      alternatives: ['Banano', 'Canela en polvo'],
      reason: 'Endulza y aromatiza naturalmente evitando azúcares refinados',
    ),
    _HealthGoalSwapRule(
      keywords: ['consome de pollo', 'consome', 'sal de ajo', 'sal de cebolla'],
      goals: {HealthGoal.reduceSodiumAndProcessed},
      alternatives: ['Ajo', 'Cilantro', 'Cebolla blanca'],
      reason: 'Sazona con hierbas y vegetales frescos sin sodio añadido',
    ),
    _HealthGoalSwapRule(
      keywords: ['salsa de soya', 'salsa inglesa'],
      goals: {HealthGoal.reduceSodiumAndProcessed},
      alternatives: ['Limón', 'Ajo', 'Cilantro'],
      reason: 'Realza el sabor del plato reduciendo el exceso de sodio',
    ),
    _HealthGoalSwapRule(
      keywords: ['ketchup', 'salsa dulce'],
      goals: {
        HealthGoal.reduceSodiumAndProcessed,
        HealthGoal.loseWeight,
      },
      alternatives: ['Tomate', 'Ajo'],
      reason: 'Evita azúcares y sodio añadidos usando tomate natural',
    ),
    _HealthGoalSwapRule(
      keywords: ['pasta', 'espagueti', 'coditos', 'fideos'],
      goals: {
        HealthGoal.loseWeight,
        HealthGoal.increaseVitaminsAndFiber,
      },
      alternatives: ['Güicoy', 'Arroz integral'],
      reason: 'Aumenta la fibra natural y aligera la densidad calórica',
    ),
    _HealthGoalSwapRule(
      keywords: ['leche entera', 'leche evaporada'],
      goals: {
        HealthGoal.loseWeight,
        HealthGoal.gainMuscle,
      },
      alternatives: ['Leche descremada', 'Yogur natural'],
      reason: 'Mantiene proteína y calcio con menos grasa saturada',
    ),
    _HealthGoalSwapRule(
      keywords: ['harina de trigo'],
      goals: {
        HealthGoal.increaseVitaminsAndFiber,
        HealthGoal.loseWeight,
      },
      alternatives: ['Avena molida', 'Avena en hojuelas'],
      reason: 'Aporta fibra soluble en lugar de harina refinada',
    ),
  ];

  /// Detects which [missingIngredients] can be replaced right away by a
  /// compatible ingredient currently in [availableIngredientNames].
  static List<AvailabilityReplacement> findAvailabilityReplacements({
    required List<RecipeIngredient> missingIngredients,
    required List<String> availableIngredientNames,
  }) {
    if (missingIngredients.isEmpty || availableIngredientNames.isEmpty) {
      return const [];
    }

    final availableClean = availableIngredientNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (availableClean.isEmpty) return const [];

    final replacements = <AvailabilityReplacement>[];

    for (final missing in missingIngredients) {
      final candidateSubs = _lookupSubstitutes(missing.name);
      if (candidateSubs.isEmpty) continue;

      String? matchedUserIngredient;
      for (final sub in candidateSubs) {
        final subNorm = StringNormalizer.normalize(sub);
        if (subNorm.isEmpty) continue;

        for (final userIng in availableClean) {
          final userNorm = StringNormalizer.normalize(userIng);
          if (userNorm.isEmpty) continue;
          // Do not treat exact/direct match to missing ingredient as a swap
          if (RecipeSearchService.isIngredientMatch(
              userNorm, missing.normalizedName)) {
            continue;
          }
          if (RecipeSearchService.isIngredientMatch(userNorm, subNorm)) {
            matchedUserIngredient = userIng;
            break;
          }
        }
        if (matchedUserIngredient != null) break;
      }

      if (matchedUserIngredient != null) {
        replacements.add(
          AvailabilityReplacement(
            missingIngredient: missing,
            availableIngredientName: matchedUserIngredient,
          ),
        );
      }
    }

    return replacements;
  }

  /// Evaluates [recipe] ingredients against [activeHealthGoals] and returns
  /// practical, non-intrusive healthier replacement suggestions in Spanish.
  static List<HealthGoalReplacement> findHealthGoalReplacements({
    required Recipe recipe,
    required Set<HealthGoal> activeHealthGoals,
    List<String> availableIngredientNames = const [],
  }) {
    if (activeHealthGoals.isEmpty || recipe.ingredients.isEmpty) {
      return const [];
    }

    final availableNorms = availableIngredientNames
        .map((name) => (raw: name.trim(), norm: StringNormalizer.normalize(name)))
        .where((entry) => entry.norm.isNotEmpty)
        .toList();

    final replacements = <HealthGoalReplacement>[];
    final seenTargets = <String>{};

    for (final ingredient in recipe.ingredients) {
      final targetNorm = ingredient.normalizedName;
      if (targetNorm.isEmpty || !seenTargets.add(targetNorm)) continue;

      final rule = _findHealthGoalRule(targetNorm);
      if (rule == null) continue;

      final matchingGoals = rule.goals.intersection(activeHealthGoals);
      if (matchingGoals.isEmpty) continue;

      // Skip if any suggested alternative matches the target itself (safety check)
      final filteredAlternatives = rule.alternatives.where((alt) {
        final altNorm = StringNormalizer.normalize(alt);
        return altNorm != targetNorm &&
            !RecipeSearchService.isIngredientMatch(altNorm, targetNorm);
      }).toList();
      if (filteredAlternatives.isEmpty) continue;

      final availableAlternatives = <String>[];
      for (final alt in filteredAlternatives) {
        final altNorm = StringNormalizer.normalize(alt);
        final hasInPantry = availableNorms.any(
          (u) => RecipeSearchService.isIngredientMatch(u.norm, altNorm),
        );
        if (hasInPantry) {
          availableAlternatives.add(alt);
        }
      }

      replacements.add(
        HealthGoalReplacement(
          targetIngredient: ingredient,
          healthierAlternatives: filteredAlternatives,
          matchingGoals: matchingGoals,
          reason: rule.reason,
          availableAlternativesInPantry: availableAlternatives,
        ),
      );
    }

    return replacements;
  }

  static List<String> _lookupSubstitutes(String ingredientName) {
    final norm = StringNormalizer.normalize(ingredientName);
    if (norm.isEmpty) return const [];

    final direct = _availabilitySubstitutes[norm];
    if (direct != null) return direct;

    // Fallback: longest matching key on token boundaries (e.g., "queso mozzarella rallado")
    List<String>? bestMatch;
    int bestLen = 0;
    for (final entry in _availabilitySubstitutes.entries) {
      if (entry.key.length > bestLen && _containsTokenPhrase(norm, entry.key)) {
        bestMatch = entry.value;
        bestLen = entry.key.length;
      }
    }
    return bestMatch ?? const [];
  }

  static _HealthGoalSwapRule? _findHealthGoalRule(String normalizedIngredient) {
    for (final rule in _healthGoalRules) {
      for (final kw in rule.keywords) {
        if (normalizedIngredient == kw ||
            _containsTokenPhrase(normalizedIngredient, kw)) {
          return rule;
        }
      }
    }
    return null;
  }

  static bool _containsTokenPhrase(String haystack, String needle) {
    if (haystack == needle) return true;
    final escaped = RegExp.escape(needle);
    final pattern = RegExp('(?:^|[^a-z0-9])$escaped(?:e?s)?(?:\$|[^a-z0-9])');
    return pattern.hasMatch(haystack);
  }
}

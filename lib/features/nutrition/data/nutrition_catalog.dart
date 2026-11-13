import '../../../core/utils/string_normalizer.dart';
import '../domain/nutrition_metadata.dart';

/// Deterministic nutrition metadata mapping for Guatemalan supermarket staples
/// in [IngredientCatalog] and [LocalRecipeDataset].
class NutritionCatalog {
  NutritionCatalog._();

  /// Recommended Spanish food sources from [IngredientCatalog] per tracked micronutrient.
  static const Map<TrackedNutrient, List<String>> recommendedSources =
      <TrackedNutrient, List<String>>{
    TrackedNutrient.vitaminA: <String>[
      'Zanahoria',
      'Espinaca',
      'Mango',
      'Camote',
      'Papaya',
    ],
    TrackedNutrient.vitaminC: <String>[
      'Naranja',
      'Chile pimiento',
      'Brócoli',
      'Fresa',
      'Limón',
    ],
    TrackedNutrient.vitaminKFolate: <String>[
      'Espinaca',
      'Brócoli',
      'Aguacate',
      'Lechuga',
      'Ejote',
    ],
    TrackedNutrient.iron: <String>[
      'Espinaca',
      'Frijoles negros',
      'Lentejas',
      'Acelga',
      'Garbanzos',
    ],
    TrackedNutrient.potassium: <String>[
      'Banano',
      'Aguacate',
      'Papa',
      'Tomate',
      'Plátano maduro',
    ],
  };

  /// Normalized profile lookup table indexed by [StringNormalizer.normalize].
  static final Map<String, IngredientNutritionProfile> _profiles =
      _buildProfileMap();

  /// Normalized keyword fragments used as fallback when an external or user-entered
  /// ingredient includes preparation descriptors (e.g. "Salchicha de pavo").
  static const List<String> _processedMeatKeywords = <String>[
    'salchicha',
    'jamon',
    'chorizo',
    'longaniza',
    'tocino',
    'mortadela',
    'salami',
    'embutido',
    'peperoni',
    'pepperoni',
  ];

  static const List<String> _grainKeywords = <String>[
    'arroz',
    'tortilla',
    'masa de maiz',
    'harina de maiz',
    'harina de trigo',
    'maicena',
    'avena',
    'pasta',
    'espagueti',
    'coditos',
    'fideos',
    'elote',
    'pan',
  ];

  static const List<String> _legumeKeywords = <String>[
    'frijol',
    'lenteja',
    'garbanzo',
    'mani',
    'cacahuate',
    'almendra',
    'nuez',
    'nueces',
    'ajonjoli',
    'maranon',
  ];

  static const List<String> _animalProteinKeywords = <String>[
    'pollo',
    'pechuga',
    'muslo',
    'carne',
    'res',
    'cerdo',
    'lomo',
    'chuleta',
    'pescado',
    'filete',
    'mojarra',
    'atun',
    'camaron',
    'marisco',
    'huevo',
    'queso',
    'requeson',
    'yogur',
    'leche',
  ];

  /// Returns nutritional metadata for [ingredientName] (exact normalized lookup,
  /// then keyword fallback).
  static IngredientNutritionProfile evaluateIngredient(String ingredientName) {
    final normalized = StringNormalizer.normalize(ingredientName);
    if (normalized.isEmpty) {
      return IngredientNutritionProfile(canonicalName: ingredientName.trim());
    }

    final exact = _profiles[normalized];
    if (exact != null) {
      return exact;
    }

    // Check longest matching profile key inside multi-word strings
    IngredientNutritionProfile? bestPartialMatch;
    int bestLength = 0;
    for (final entry in _profiles.entries) {
      if (_containsWholeTokenOrPhrase(normalized, entry.key) &&
          entry.key.length > bestLength) {
        bestPartialMatch = entry.value;
        bestLength = entry.key.length;
      }
    }
    if (bestPartialMatch != null) {
      return bestPartialMatch;
    }

    // Deterministic keyword classification fallback
    final isProcessed = _matchesAnyKeyword(normalized, _processedMeatKeywords);
    ProteinGroup proteinGroup = ProteinGroup.none;
    if (_matchesAnyKeyword(normalized, _legumeKeywords)) {
      proteinGroup = ProteinGroup.plantLegumeOrSeed;
    } else if (_matchesAnyKeyword(normalized, _grainKeywords)) {
      proteinGroup = ProteinGroup.plantGrain;
    } else if (_matchesAnyKeyword(normalized, _animalProteinKeywords)) {
      proteinGroup = ProteinGroup.completeAnimal;
    }

    return IngredientNutritionProfile(
      canonicalName: ingredientName.trim(),
      isProcessedMeat: isProcessed,
      proteinGroup: proteinGroup,
    );
  }

  static bool _matchesAnyKeyword(String normalizedText, List<String> keywords) {
    for (final keyword in keywords) {
      if (_containsWholeTokenOrPhrase(normalizedText, keyword)) {
        return true;
      }
    }
    return false;
  }

  static bool _containsWholeTokenOrPhrase(String haystack, String needle) {
    if (haystack == needle) return true;
    final paddedHaystack = ' $haystack ';
    return paddedHaystack.contains(' $needle ');
  }

  static Map<String, IngredientNutritionProfile> _buildProfileMap() {
    final entries = <IngredientNutritionProfile>[
      // -----------------------------------------------------------------------
      // Processed meats & cured high-sodium items (Rule 1)
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Salchicha',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Jamón',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Jamón de pavo',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chorizo',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chorizo colorado',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chorizo negro',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Longaniza',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Longaniza guatemalteca',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Tocino',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mortadela',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Salami',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
      ),

      // -----------------------------------------------------------------------
      // Fruits & vegetables with micronutrient contributions (Rule 2)
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Zanahoria',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminA, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Camote',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminA, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Ayote',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminA, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Güicoy',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminA, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Güisquil',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.vitaminKFolate},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Perulero',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Papa',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Yuca',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Tomate',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Miltomate',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chile pimiento',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminA, TrackedNutrient.vitaminC},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Brócoli',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.potassium,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Coliflor',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.vitaminKFolate},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Espinaca',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Acelga',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Berro',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.iron,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Lechuga',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminA, TrackedNutrient.vitaminKFolate},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Repollo blanco',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.vitaminKFolate},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Repollo morado',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.vitaminKFolate},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Aguacate',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminKFolate, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Ejote',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminKFolate, TrackedNutrient.vitaminC},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Arveja',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminKFolate, TrackedNutrient.iron},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Arveja china',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.vitaminKFolate},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Cilantro',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminKFolate},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Perejil',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.vitaminKFolate},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Apio',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminKFolate, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Pepino',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminKFolate, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Rábano',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Remolacha',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Naranja',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Limón',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mandarina',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.vitaminA},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Fresa',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mora',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC, TrackedNutrient.vitaminKFolate},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Piña',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Papaya',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mango',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminA, TrackedNutrient.vitaminC},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Melón',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Sandía',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminA, TrackedNutrient.potassium},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Banano',
        nutrients: <TrackedNutrient>{TrackedNutrient.potassium, TrackedNutrient.vitaminC},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Plátano',
        nutrients: <TrackedNutrient>{TrackedNutrient.potassium, TrackedNutrient.vitaminA},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Plátano maduro',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.potassium,
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Plátano verde',
        nutrients: <TrackedNutrient>{TrackedNutrient.potassium, TrackedNutrient.vitaminC},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Manzana',
        nutrients: <TrackedNutrient>{TrackedNutrient.potassium},
      ),

      // -----------------------------------------------------------------------
      // Plant grains & cereals (Rule 3)
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Arroz blanco',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Arroz integral',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Arroz precocido',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Arroz',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Masa de maíz',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Harina de maíz',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Tortillas de maíz',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Avena',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Avena en hojuelas',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Avena molida',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Granola',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Pasta',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Espagueti',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Coditos',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Fideos',
        proteinGroup: ProteinGroup.plantGrain,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Elote',
        proteinGroup: ProteinGroup.plantGrain,
      ),

      // -----------------------------------------------------------------------
      // Plant legumes, nuts & seeds (Rule 3 + Iron)
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Frijoles negros',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron, TrackedNutrient.potassium},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Frijoles colorados',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron, TrackedNutrient.potassium},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Frijoles rojos',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron, TrackedNutrient.potassium},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Frijoles blancos',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron, TrackedNutrient.potassium},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Frijol',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron, TrackedNutrient.potassium},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Lentejas',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron, TrackedNutrient.potassium},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Garbanzos',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron, TrackedNutrient.potassium},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Maní',
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Almendras',
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Nueces',
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Ajonjolí',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Semillas de girasol',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Semillas de marañón',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
      ),

      // -----------------------------------------------------------------------
      // Complete animal proteins (non-processed)
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Pollo',
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Pechuga de pollo',
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Carne de res',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Carne molida de res',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Posta de res',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Filete de pescado',
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Huevo',
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Huevos',
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Queso de capas',
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Queso gouda',
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Queso parmesano',
        proteinGroup: ProteinGroup.completeAnimal,
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Requesón',
        proteinGroup: ProteinGroup.completeAnimal,
      ),
    ];

    return <String, IngredientNutritionProfile>{
      for (final profile in entries)
        StringNormalizer.normalize(profile.canonicalName): profile,
    };
  }
}


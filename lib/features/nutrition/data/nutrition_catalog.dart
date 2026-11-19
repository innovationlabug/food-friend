import '../../../core/utils/string_normalizer.dart';
import '../domain/health_goal.dart';
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

  /// Recommended Spanish food sources from [IngredientCatalog] per [HealthGoal].
  static const Map<HealthGoal, List<String>> recommendedSourcesForGoal =
      <HealthGoal, List<String>>{
    HealthGoal.loseWeight: <String>[
      'Pechuga de pollo',
      'Güisquil',
      'Espinaca',
      'Pepino',
      'Brócoli',
    ],
    HealthGoal.gainMuscle: <String>[
      'Pechuga de pollo',
      'Huevo',
      'Filete de pescado',
      'Frijoles negros',
      'Lentejas',
    ],
    HealthGoal.reduceSodiumAndProcessed: <String>[
      'Limón',
      'Cilantro',
      'Ajo',
      'Hierbabuena',
      'Pechuga de pollo',
    ],
    HealthGoal.increaseVitaminsAndFiber: <String>[
      'Espinaca',
      'Brócoli',
      'Lentejas',
      'Zanahoria',
      'Naranja',
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

  static const List<String> _highSodiumKeywords = <String>[
    ..._processedMeatKeywords,
    'consome',
    'sal de ajo',
    'sal de cebolla',
    'salsa de soya',
    'salsa inglesa',
    'ketchup',
    'salsa dulce',
    'mayonesa',
    'parmesano',
    'gouda',
    'cheddar',
    'sal',
  ];

  static const List<String> _calorieDenseKeywords = <String>[
    ..._processedMeatKeywords,
    'crema',
    'mantequilla',
    'margarina',
    'manteca',
    'chicharron',
    'azucar',
    'nutella',
    'leche condensada',
    'mayonesa',
    'queso crema',
    'gouda',
    'cheddar',
  ];

  static const List<String> _lowCalorieKeywords = <String>[
    'guisquil',
    'perulero',
    'pepino',
    'tomate',
    'miltomate',
    'espinaca',
    'acelga',
    'berro',
    'brocoli',
    'coliflor',
    'lechuga',
    'repollo',
    'zanahoria',
    'ejote',
    'arveja',
    'chile pimiento',
    'rabano',
    'apio',
    'champinones',
    'berenjena',
    'ayote',
    'guicoy',
    'pechuga',
    'pescado',
    'tilapia',
    'robalo',
    'mojarra',
    'fresa',
    'mora',
    'sandia',
    'melon',
    'papaya',
    'manzana',
    'limon',
    'naranja',
  ];

  static const List<String> _fiberProduceKeywords = <String>[
    'espinaca',
    'acelga',
    'berro',
    'brocoli',
    'coliflor',
    'zanahoria',
    'guisquil',
    'perulero',
    'ejote',
    'arveja',
    'tomate',
    'chile pimiento',
    'pepino',
    'rabano',
    'remolacha',
    'aguacate',
    'lechuga',
    'repollo',
    'manzana',
    'naranja',
    'limon',
    'mandarina',
    'fresa',
    'mora',
    'pina',
    'papaya',
    'mango',
    'melon',
    'sandia',
    'banano',
    'platano',
    'camote',
    'avena',
    'arroz integral',
  ];

  static const List<String> _wholeFoodAromaticKeywords = <String>[
    'limon',
    'cilantro',
    'hierbabuena',
    'epazote',
    'perejil',
    'ajo',
    'cebolla',
    'oregano',
    'curry',
    'laurel',
    'tomillo',
    'romero',
    'albahaca',
    'jengibre',
    'curcuma',
    'paprika',
    'aceite de oliva',
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
    'salmon',
    'marisco',
    'huevo',
    'queso',
    'requeson',
    'yogur',
    'leche',
  ];

  /// Returns nutritional metadata for [ingredientName] (exact normalized lookup,
  /// then partial key match, then deterministic keyword fallback).
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
    final isHighSodium =
        isProcessed || _matchesAnyKeyword(normalized, _highSodiumKeywords);
    final isCalorieDense =
        isProcessed || _matchesAnyKeyword(normalized, _calorieDenseKeywords);

    ProteinGroup proteinGroup = ProteinGroup.none;
    if (_matchesAnyKeyword(normalized, _legumeKeywords)) {
      proteinGroup = ProteinGroup.plantLegumeOrSeed;
    } else if (_matchesAnyKeyword(normalized, _grainKeywords)) {
      proteinGroup = ProteinGroup.plantGrain;
    } else if (_matchesAnyKeyword(normalized, _animalProteinKeywords)) {
      proteinGroup = ProteinGroup.completeAnimal;
    }

    final attributes = <NutritionalAttribute>{};
    if (isHighSodium) {
      attributes.add(NutritionalAttribute.highSodiumOrProcessed);
    }
    if (isCalorieDense) {
      attributes.add(NutritionalAttribute.calorieDense);
    }
    if (!isProcessed &&
        (proteinGroup == ProteinGroup.completeAnimal ||
            proteinGroup == ProteinGroup.plantLegumeOrSeed)) {
      attributes.add(NutritionalAttribute.highProtein);
    }

    final isLowCalorie =
        !isCalorieDense && _matchesAnyKeyword(normalized, _lowCalorieKeywords);
    if (isLowCalorie) {
      attributes.add(NutritionalAttribute.lowCalorieDensity);
    }

    if (proteinGroup == ProteinGroup.plantLegumeOrSeed ||
        _matchesAnyKeyword(normalized, _fiberProduceKeywords)) {
      attributes.add(NutritionalAttribute.highFiberOrVitamins);
    }

    if (!isHighSodium &&
        (isLowCalorie ||
            proteinGroup == ProteinGroup.plantLegumeOrSeed ||
            _matchesAnyKeyword(normalized, _wholeFoodAromaticKeywords))) {
      attributes.add(NutritionalAttribute.lowSodiumWholeFood);
    }

    return IngredientNutritionProfile(
      canonicalName: ingredientName.trim(),
      isProcessedMeat: isProcessed,
      proteinGroup: proteinGroup,
      attributes: attributes,
    );
  }

  /// Returns a concise, grammatically natural Spanish explanation linking
  /// [profile] to [goal], or `null` if the ingredient does not support [goal].
  static String? reasonFor(
    IngredientNutritionProfile profile,
    HealthGoal goal,
  ) {
    final explicit = profile.goalReasons[goal];
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit;
    }

    final lowerName = profile.canonicalName.trim().toLowerCase();
    if (lowerName.isEmpty) return null;

    switch (goal) {
      case HealthGoal.gainMuscle:
        if (profile.isHighProtein && !profile.isProcessedMeat) {
          return 'Aporta proteína con $lowerName para apoyar tu masa muscular';
        }
        return null;
      case HealthGoal.loseWeight:
        if (profile.isLowCalorieDensity && !profile.isCalorieDense) {
          return 'Incluye $lowerName, una opción ligera con pocas calorías';
        }
        return null;
      case HealthGoal.reduceSodiumAndProcessed:
        if (profile.isLowSodiumWholeFood && !profile.isHighSodiumOrProcessed) {
          return 'Usa $lowerName como ingrediente natural sin sodio añadido';
        }
        return null;
      case HealthGoal.increaseVitaminsAndFiber:
        if (profile.isHighFiberOrVitamins || profile.nutrients.isNotEmpty) {
          if (profile.nutrients.isNotEmpty) {
            final nutrientLabel = profile.nutrients.first.label;
            return 'Aporta $nutrientLabel y fibra natural con $lowerName';
          }
          return 'Aporta fibra natural con $lowerName';
        }
        return null;
    }
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
      // Processed meats & high-sodium cured / packaged items
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Salchicha',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Jamón',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Jamón de pavo',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chorizo',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chorizo colorado',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chorizo negro',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Longaniza',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Longaniza guatemalteca',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Tocino',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mortadela',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Salami',
        isProcessedMeat: true,
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Consomé de pollo',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Sal de ajo',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Sal de cebolla',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Sal',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Salsa de soya',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Salsa inglesa',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Ketchup',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mayonesa',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highSodiumOrProcessed,
          NutritionalAttribute.calorieDense,
        },
      ),

      // -----------------------------------------------------------------------
      // Rich / calorie-dense dairy, fats & sweets
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Crema pura',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Crema fresca',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mantequilla',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Margarina',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Manteca vegetal',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Queso crema',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chicharrón',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.calorieDense,
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Azúcar blanca',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Azúcar morena',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Leche condensada',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Nutella',
        attributes: <NutritionalAttribute>{NutritionalAttribute.calorieDense},
      ),

      // -----------------------------------------------------------------------
      // Fruits & vegetables with micronutrient, fiber & low-calorie attributes
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Zanahoria',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'La zanahoria contiene pocas calorías y aporta saciedad natural',
          HealthGoal.increaseVitaminsAndFiber:
              'La zanahoria es rica en Vitamina A y fibra natural',
          HealthGoal.reduceSodiumAndProcessed:
              'La zanahoria es un vegetal fresco y natural libre de sodio añadido',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Camote',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'El camote aporta Vitamina A, potasio y fibra saludable',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Ayote',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El ayote contiene pocas calorías y aporta fibra natural',
          HealthGoal.increaseVitaminsAndFiber:
              'El ayote aporta Vitamina A, potasio y fibra',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Güicoy',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El güicoy contiene pocas calorías y es ideal para platos ligeros',
          HealthGoal.increaseVitaminsAndFiber:
              'El güicoy aporta Vitamina A y fibra natural',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Güisquil',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El güisquil contiene pocas calorías y aporta fibra',
          HealthGoal.increaseVitaminsAndFiber:
              'El güisquil aporta Vitamina C, folato y fibra ligera',
          HealthGoal.reduceSodiumAndProcessed:
              'El güisquil es un vegetal fresco naturalmente bajo en sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Perulero',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El perulero contiene muy pocas calorías y aporta fibra',
          HealthGoal.increaseVitaminsAndFiber:
              'El perulero aporta Vitamina C y fibra suave',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Papa',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'La papa cocida aporta potasio y Vitamina C sin procesar',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Yuca',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'La yuca aporta Vitamina C y energía natural con fibra',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Tomate',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El tomate contiene pocas calorías y aporta frescura al plato',
          HealthGoal.increaseVitaminsAndFiber:
              'El tomate aporta Vitamina C, Vitamina A y potasio',
          HealthGoal.reduceSodiumAndProcessed:
              'La salsa natural de tomate evita aderezos procesados altos en sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Miltomate',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El miltomate contiene pocas calorías y da cuerpo natural al recado',
          HealthGoal.increaseVitaminsAndFiber:
              'El miltomate aporta Vitamina C y potasio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chile pimiento',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El chile pimiento contiene pocas calorías y aporta color y fibra',
          HealthGoal.increaseVitaminsAndFiber:
              'El chile pimiento es una excelente fuente de Vitamina C y Vitamina A',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Brócoli',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El brócoli contiene pocas calorías y brinda gran saciedad',
          HealthGoal.increaseVitaminsAndFiber:
              'El brócoli es rico en fibra, Vitamina C y Vitamina K',
          HealthGoal.reduceSodiumAndProcessed:
              'El brócoli aporta nutrientes frescos sin sodio añadido',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Coliflor',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'La coliflor es muy baja en calorías y rica en fibra',
          HealthGoal.increaseVitaminsAndFiber:
              'La coliflor aporta Vitamina C, folato y fibra vegetal',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Espinaca',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'La espinaca contiene muy pocas calorías y aporta volumen nutritivo',
          HealthGoal.increaseVitaminsAndFiber:
              'La espinaca es rica en hierro, fibra, Vitamina A y Vitamina K',
          HealthGoal.reduceSodiumAndProcessed:
              'La espinaca aporta hojas verdes frescas sin ingredientes procesados',
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
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'La acelga contiene pocas calorías y aporta fibra',
          HealthGoal.increaseVitaminsAndFiber:
              'La acelga aporta hierro, Vitamina A y Vitamina K',
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
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El berro contiene muy pocas calorías y es muy denso en nutrientes',
          HealthGoal.increaseVitaminsAndFiber:
              'El berro destaca por su aporte de vitaminas A, C, K y hierro',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Lechuga',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminKFolate,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'La lechuga aporta frescura y volumen con muy pocas calorías',
          HealthGoal.increaseVitaminsAndFiber:
              'La lechuga aporta Vitamina A, folato y fibra fresca',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Repollo blanco',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El repollo contiene pocas calorías y aporta fibra crujiente',
          HealthGoal.increaseVitaminsAndFiber:
              'El repollo aporta Vitamina C y fibra digestiva',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Repollo morado',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El repollo morado contiene pocas calorías y antioxidantes',
          HealthGoal.increaseVitaminsAndFiber:
              'El repollo morado es rico en Vitamina C y fibra',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Aguacate',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'El aguacate aporta fibra, potasio y folato saludable',
          HealthGoal.reduceSodiumAndProcessed:
              'El aguacate aporta cremosidad natural libre de sodio y procesados',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Ejote',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.vitaminC,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El ejote contiene pocas calorías y aporta fibra vegetal',
          HealthGoal.increaseVitaminsAndFiber:
              'El ejote aporta fibra, Vitamina C y folato',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Arveja',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.iron,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'La arveja aporta fibra, hierro y folato',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Arveja china',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'La arveja china contiene pocas calorías y textura crujiente',
          HealthGoal.increaseVitaminsAndFiber:
              'La arveja china aporta Vitamina C y fibra fresca',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Champiñones',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'Los champiñones contienen muy pocas calorías y dan saciedad',
          HealthGoal.reduceSodiumAndProcessed:
              'Los champiñones realzan el sabor natural sin necesidad de sodio extra',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Berenjena',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'La berenjena contiene pocas calorías y aporta fibra',
          HealthGoal.increaseVitaminsAndFiber:
              'La berenjena aporta fibra dietética natural',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Cilantro',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminKFolate},
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'El cilantro aporta aroma fresco natural para cocinar con menos sal',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Perejil',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'El perejil fresco condimenta el platillo sin añadir sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Hierbabuena',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'La hierbabuena perfuma el plato naturalmente sin sazonadores procesados',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Epazote',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'El epazote aporta sabor tradicional sin agregar sodio ni aditivos',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Orégano seco',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'El orégano sazona naturalmente con cero sodio añadido',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Curry',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'Las especias del curry aportan gran sabor sin exceso de sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Ajo',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'El ajo potencia el sabor natural ayudando a reducir el consumo de sal',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Cebolla blanca',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'La cebolla blanca sazona naturalmente sin ingredientes procesados',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Cebolla morada',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'La cebolla morada aporta frescura y sabor natural sin sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chile pasa',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Chile guaque',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Aceite de oliva',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Aceite vegetal',
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Apio',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El apio contiene muy pocas calorías y aporta fibra hidratante',
          HealthGoal.increaseVitaminsAndFiber:
              'El apio aporta fibra, folato y potasio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Pepino',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El pepino contiene muy pocas calorías y aporta hidratación y fibra',
          HealthGoal.increaseVitaminsAndFiber:
              'El pepino aporta Vitamina K, potasio y fibra fresca',
          HealthGoal.reduceSodiumAndProcessed:
              'El pepino es un vegetal fresco naturalmente libre de sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Rábano',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'El rábano contiene muy pocas calorías y aporta textura crujiente',
          HealthGoal.increaseVitaminsAndFiber:
              'El rábano aporta Vitamina C y fibra fresca',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Remolacha',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminKFolate,
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'La remolacha es rica en folato, hierro, potasio y fibra',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Naranja',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'La naranja es una excelente fuente de Vitamina C y fibra',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Limón',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC},
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.reduceSodiumAndProcessed:
              'El limón realza el sabor de forma natural sin agregar sodio',
          HealthGoal.increaseVitaminsAndFiber:
              'El limón aporta Vitamina C fresca y facilita la absorción de hierro',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mandarina',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminA,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Fresa',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mora',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminC,
          TrackedNutrient.vitaminKFolate,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Piña',
        nutrients: <TrackedNutrient>{TrackedNutrient.vitaminC},
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Papaya',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mango',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Melón',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Sandía',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.vitaminA,
          TrackedNutrient.potassium,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Banano',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.potassium,
          TrackedNutrient.vitaminC,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Plátano',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.potassium,
          TrackedNutrient.vitaminA,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Plátano maduro',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.potassium,
          TrackedNutrient.vitaminA,
          TrackedNutrient.vitaminC,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'El plátano maduro cocido aporta potasio, Vitamina A y fibra natural',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Plátano verde',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.potassium,
          TrackedNutrient.vitaminC,
        },
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Manzana',
        nutrients: <TrackedNutrient>{TrackedNutrient.potassium},
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.loseWeight:
              'La manzana contiene pocas calorías y aporta fibra saciante',
          HealthGoal.increaseVitaminsAndFiber:
              'La manzana aporta fibra soluble natural',
        },
      ),

      // -----------------------------------------------------------------------
      // Plant grains & cereals
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Arroz blanco',
        proteinGroup: ProteinGroup.plantGrain,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Arroz integral',
        proteinGroup: ProteinGroup.plantGrain,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'El arroz integral aporta mayor fibra y minerales naturales',
        },
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
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Harina de maíz',
        proteinGroup: ProteinGroup.plantGrain,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Tortillas de maíz',
        proteinGroup: ProteinGroup.plantGrain,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Avena',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantGrain,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'La avena aporta fibra soluble y hierro para tu energía diaria',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Avena en hojuelas',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantGrain,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Avena molida',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantGrain,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
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
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'El elote tierno aporta fibra natural al caldo',
        },
      ),

      // -----------------------------------------------------------------------
      // Plant legumes, nuts & seeds
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Frijoles negros',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'Los frijoles negros son una gran fuente de proteína vegetal',
          HealthGoal.increaseVitaminsAndFiber:
              'Los frijoles negros aportan hierro, potasio y abundante fibra',
          HealthGoal.reduceSodiumAndProcessed:
              'Los frijoles cocidos en casa evitan conservantes y exceso de sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Frijoles colorados',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'Los frijoles colorados aportan proteína vegetal y minerales',
          HealthGoal.increaseVitaminsAndFiber:
              'Los frijoles colorados son ricos en fibra y hierro',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Frijoles rojos',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Frijoles blancos',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Frijol',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Lentejas',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'Las lentejas aportan proteína vegetal y hierro para tus músculos',
          HealthGoal.loseWeight:
              'Las lentejas aportan mucha saciedad con pocas calorías',
          HealthGoal.increaseVitaminsAndFiber:
              'Las lentejas son una excelente fuente de fibra y hierro',
          HealthGoal.reduceSodiumAndProcessed:
              'Las lentejas preparadas en casa son naturales y bajas en sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Garbanzos',
        nutrients: <TrackedNutrient>{
          TrackedNutrient.iron,
          TrackedNutrient.potassium,
        },
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'Los garbanzos aportan proteína vegetal y energía sostenida',
          HealthGoal.increaseVitaminsAndFiber:
              'Los garbanzos son ricos en fibra e hierro',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Maní',
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'El maní aporta proteína vegetal y grasas saludables',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Almendras',
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Nueces',
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.increaseVitaminsAndFiber:
              'Las nueces aportan fibra y grasas saludables de origen natural',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Ajonjolí',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Semillas de girasol',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Semillas de marañón',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.plantLegumeOrSeed,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highFiberOrVitamins,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),

      // -----------------------------------------------------------------------
      // Complete animal proteins & dairy (non-processed)
      // -----------------------------------------------------------------------
      const IngredientNutritionProfile(
        canonicalName: 'Pollo',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'El pollo es una excelente fuente de proteína completa',
          HealthGoal.loseWeight:
              'El pollo aporta proteína magra que ayuda a mantener la saciedad',
          HealthGoal.reduceSodiumAndProcessed:
              'El pollo fresco cocinado en casa evita conservantes y sodio extra',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Pechuga de pollo',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'La pechuga de pollo es una excelente fuente de proteína',
          HealthGoal.loseWeight:
              'La pechuga de pollo aporta proteína magra con pocas calorías',
          HealthGoal.reduceSodiumAndProcessed:
              'La pechuga de pollo fresca es una proteína natural baja en sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Muslos de pollo',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'Los muslos de pollo aportan proteína completa de alta calidad',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Cuadriles de pollo',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Pollo desmenuzado',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Pollo entero',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Carne de res',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'La carne de res aporta proteína completa e hierro para tus músculos',
          HealthGoal.reduceSodiumAndProcessed:
              'La carne fresca preparada en casa evita aditivos y sodio procesado',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Carne molida de res',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'La carne molida de res es una buena fuente de proteína e hierro',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Posta de res',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'La posta de res es un corte magro rico en proteína completa e hierro',
          HealthGoal.loseWeight:
              'La posta de res es un corte magro con buen aporte proteico',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Lomo de res',
        nutrients: <TrackedNutrient>{TrackedNutrient.iron},
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Lomo de cerdo',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Filete de pescado',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'El filete de pescado es una excelente fuente de proteína magra',
          HealthGoal.loseWeight:
              'El filete de pescado contiene pocas calorías y proteína de fácil digestión',
          HealthGoal.reduceSodiumAndProcessed:
              'El pescado fresco al vapor es naturalmente bajo en sodio',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Filete de tilapia',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Filete de robalo',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Mojarra entera',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Salmón',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Atún en lata',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Camarones',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Huevo',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'El huevo aporta proteína completa de alto valor biológico',
          HealthGoal.loseWeight:
              'El huevo brinda saciedad prolongada con pocas calorías',
          HealthGoal.reduceSodiumAndProcessed:
              'El huevo es un alimento natural entero sin sodio añadido',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Huevos',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'Los huevos aportan proteína completa de alto valor biológico',
          HealthGoal.loseWeight:
              'Los huevos brindan saciedad prolongada con pocas calorías',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Queso de capas',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{NutritionalAttribute.highProtein},
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'El queso de capas suma proteína láctea suave al platillo',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Queso fresco',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Queso gouda',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.calorieDense,
          NutritionalAttribute.highSodiumOrProcessed,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'El queso gouda aporta proteína y calcio al plato',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Queso parmesano',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.highSodiumOrProcessed,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'El queso parmesano concentra proteína láctea',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Queso cheddar',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.calorieDense,
          NutritionalAttribute.highSodiumOrProcessed,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Requesón',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'El requesón es una fuente ligera y rica en proteína',
          HealthGoal.loseWeight:
              'El requesón aporta proteína con bajo contenido calórico',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Yogur griego',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
        goalReasons: <HealthGoal, String>{
          HealthGoal.gainMuscle:
              'El yogur griego es una excelente fuente de proteína ligera',
          HealthGoal.loseWeight:
              'El yogur griego aporta proteína y saciedad con pocas calorías',
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Yogur natural',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Yogur',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
      const IngredientNutritionProfile(
        canonicalName: 'Leche descremada',
        proteinGroup: ProteinGroup.completeAnimal,
        attributes: <NutritionalAttribute>{
          NutritionalAttribute.highProtein,
          NutritionalAttribute.lowCalorieDensity,
          NutritionalAttribute.lowSodiumWholeFood,
        },
      ),
    ];

    return <String, IngredientNutritionProfile>{
      for (final profile in entries)
        StringNormalizer.normalize(profile.canonicalName): profile,
    };
  }
}

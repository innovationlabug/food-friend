import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sections of the settings screen, used to surface contextually relevant
/// settings at the top depending on the screen where settings was opened.
enum SettingsSection {
  home,
  ingredients,
}

/// High-level experience presets offered at first launch and in Settings.
enum ExperienceMode {
  simple,
  full,
  custom;

  String get label => switch (this) {
        ExperienceMode.simple => 'Simple',
        ExperienceMode.full => 'Completa',
        ExperienceMode.custom => 'Personalizada',
      };

  String get shortLabel => switch (this) {
        ExperienceMode.simple => 'Simple',
        ExperienceMode.full => 'Completa',
        ExperienceMode.custom => 'Personalizada',
      };

  String get description => switch (this) {
        ExperienceMode.simple =>
          'Solo las funciones esenciales: despensa, lista de compras, búsqueda manual y recetas locales.',
        ExperienceMode.full =>
          'Todas las funciones activas: escaneo con IA, planificador, nutrición, ofertas y precios en Quetzales.',
        ExperienceMode.custom =>
          'Elige exactamente qué categorías de funciones opcionales deseas activar.',
      };
}

/// Logical groupings of optional features shown during Custom onboarding and in Settings.
enum FeatureCategory {
  ai,
  planning,
  health,
  pricesAndSales;

  String get label => switch (this) {
        FeatureCategory.ai => 'IA',
        FeatureCategory.planning => 'Planificación y asistencia',
        FeatureCategory.health => 'Salud y nutrición',
        FeatureCategory.pricesAndSales => 'Precios y ofertas',
      };

  String get description => switch (this) {
        FeatureCategory.ai =>
          'Escaneo de refrigerador y recibos, y generación de recetas con IA.',
        FeatureCategory.planning =>
          'Planificador semanal, historial y favoritas, compras inteligentes y reemplazos.',
        FeatureCategory.health =>
          'Metas de salud, consejos nutricionales y recomendaciones saludables.',
        FeatureCategory.pricesAndSales =>
          'Ofertas de supermercados, alertas y comparación de precios en Quetzales.',
      };

  String get iconName => switch (this) {
        FeatureCategory.ai => 'sparkles',
        FeatureCategory.planning => 'calendar',
        FeatureCategory.health => 'nutrition',
        FeatureCategory.pricesAndSales => 'savings',
      };

  List<OptionalFeature> get features => OptionalFeature.values
      .where((feature) => feature.category == this)
      .toList(growable: false);
}

/// Granular optional features that can be enabled or disabled independently.
enum OptionalFeature {
  fridgeScanner(
    category: FeatureCategory.ai,
    storageKey: 'settings_feature_fridge_scanner',
    title: 'Escáner de refrigerador con IA',
    description:
        'Detecta ingredientes desde una foto de tu refrigerador o despensa.',
    iconName: 'fridge',
  ),
  receiptScanner(
    category: FeatureCategory.ai,
    storageKey: 'settings_feature_receipt_scanner',
    title: 'Escáner de recibos con IA',
    description:
        'Extrae alimentos y precios en Quetzales desde fotos de facturas.',
    iconName: 'receipt',
  ),
  aiRecipes(
    category: FeatureCategory.ai,
    storageKey: 'settings_feature_ai_recipes',
    title: 'Recetas generadas con IA',
    description:
        'Genera recetas adicionales con IA cuando hay pocas coincidencias locales.',
    iconName: 'sparkles',
  ),
  multiDayPlanner(
    category: FeatureCategory.planning,
    storageKey: 'settings_feature_multi_day_planner',
    title: 'Planificador de comidas (2–7 días)',
    description:
        'Organiza menús diarios rotando variaciones y agregando faltantes.',
    iconName: 'calendar',
  ),
  recipeManagement(
    category: FeatureCategory.planning,
    storageKey: 'settings_feature_recipe_management',
    title: 'Gestión de recetas, historial y favoritas',
    description:
        'Guarda preferencias, historial de cocinado y oculta recetas marcadas como Nunca.',
    iconName: 'heart',
  ),
  smartShoppingSuggestions(
    category: FeatureCategory.planning,
    storageKey: 'settings_feature_smart_shopping_suggestions',
    title: 'Sugerencias inteligentes de compra',
    description:
        'Recomienda ingredientes útiles dentro de la pestaña Por comprar.',
    iconName: 'plus',
  ),
  ingredientReplacements(
    category: FeatureCategory.planning,
    storageKey: 'settings_feature_ingredient_replacements',
    title: 'Reemplazos de ingredientes',
    description:
        'Sugiere sustitutos disponibles en despensa y opciones más saludables.',
    iconName: 'refresh',
  ),
  nutritionAndGoals(
    category: FeatureCategory.health,
    storageKey: 'settings_feature_nutrition_and_goals',
    title: 'Consejos de nutrición y metas de salud',
    description:
        'Activa metas de salud, consejos personalizados y etiquetas nutricionales.',
    iconName: 'nutrition',
  ),
  supermarketDeals(
    category: FeatureCategory.pricesAndSales,
    storageKey: 'settings_feature_supermarket_deals',
    title: 'Ofertas de supermercados y alertas',
    description:
        'Muestra ofertas vigentes en Guatemala y avisos cuando coinciden con tus listas.',
    iconName: 'shopping_cart',
  ),
  gtqPricing(
    category: FeatureCategory.pricesAndSales,
    storageKey: 'settings_feature_gtq_pricing',
    title: 'Precios en Quetzales y ahorro en casa',
    description:
        'Calcula costos estimados en Q y los compara frente a comida a domicilio.',
    iconName: 'savings',
  );

  const OptionalFeature({
    required this.category,
    required this.storageKey,
    required this.title,
    required this.description,
    required this.iconName,
  });

  final FeatureCategory category;
  final String storageKey;
  final String title;
  final String description;
  final String iconName;
}

/// Manages user-configurable application settings, experience mode presets,
/// and optional feature toggles with local persistence.
class SettingsController extends ChangeNotifier {
  SettingsController._();

  static final SettingsController instance = SettingsController._();

  static const String hasCompletedModeSelectionKey =
      'settings_has_completed_mode_selection';
  static const String experienceModeKey = 'settings_experience_mode';
  static const String legacyHideNutritionTipsPanelKey =
      'settings_hide_nutrition_tips_panel';
  static const String legacyHideRecipeManagementPanelKey =
      'settings_hide_recipe_management_panel';
  static const String autoReturnAfterAddingIngredientKey =
      'settings_auto_return_after_adding_ingredient';
  static const String hasSeenEnterTipKey = 'has_seen_enter_tip';

  bool _isLoaded = false;
  bool _hasCompletedModeSelection = false;
  ExperienceMode _experienceMode = ExperienceMode.full;
  final Map<OptionalFeature, bool> _featureFlags = {
    for (final feature in OptionalFeature.values) feature: true,
  };
  bool _autoReturnAfterAddingIngredient = false;
  bool _hasSeenEnterTip = false;

  /// Whether persisted settings have been loaded at least once.
  bool get isLoaded => _isLoaded;

  /// Whether the user has completed the initial experience mode selection.
  bool get hasCompletedModeSelection => _hasCompletedModeSelection;

  /// Active experience mode derived from current feature flags.
  ExperienceMode get experienceMode => _experienceMode;

  /// Returns whether a specific [OptionalFeature] is currently enabled.
  bool isFeatureEnabled(OptionalFeature feature) =>
      _featureFlags[feature] ?? true;

  /// Returns whether all features inside [category] are enabled.
  bool isCategoryEnabled(FeatureCategory category) =>
      category.features.every(isFeatureEnabled);

  /// Returns whether at least one feature inside [category] is enabled.
  bool isAnyFeatureInCategoryEnabled(FeatureCategory category) =>
      category.features.any(isFeatureEnabled);

  bool get enableFridgeScanner => isFeatureEnabled(OptionalFeature.fridgeScanner);
  bool get enableReceiptScanner =>
      isFeatureEnabled(OptionalFeature.receiptScanner);
  bool get enableAiRecipes => isFeatureEnabled(OptionalFeature.aiRecipes);
  bool get enableAnyAiScanner => enableFridgeScanner || enableReceiptScanner;
  bool get enableMultiDayPlanner =>
      isFeatureEnabled(OptionalFeature.multiDayPlanner);
  bool get enableRecipeManagement =>
      isFeatureEnabled(OptionalFeature.recipeManagement);
  bool get enableSmartShoppingSuggestions =>
      isFeatureEnabled(OptionalFeature.smartShoppingSuggestions);
  bool get enableIngredientReplacements =>
      isFeatureEnabled(OptionalFeature.ingredientReplacements);
  bool get enableNutritionAndGoals =>
      isFeatureEnabled(OptionalFeature.nutritionAndGoals);
  bool get enableSupermarketDeals =>
      isFeatureEnabled(OptionalFeature.supermarketDeals);
  bool get enableGtqPricing => isFeatureEnabled(OptionalFeature.gtqPricing);

  /// Whether the app automatically returns to the ingredient list after
  /// adding a single ingredient.
  bool get autoReturnAfterAddingIngredient => _autoReturnAfterAddingIngredient;

  /// Whether the user has already seen/dismissed the Enter shortcut tip.
  bool get hasSeenEnterTip => _hasSeenEnterTip;

  ExperienceMode _deriveModeFromFlags() {
    final values = OptionalFeature.values.map(isFeatureEnabled);
    if (values.every((enabled) => enabled)) {
      return ExperienceMode.full;
    }
    if (values.every((enabled) => !enabled)) {
      return ExperienceMode.simple;
    }
    return ExperienceMode.custom;
  }

  /// Loads persisted settings from local storage.
  Future<void> load({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();

    final completed = prefs.getBool(hasCompletedModeSelectionKey) ?? false;
    final legacyHideNutrition =
        prefs.getBool(legacyHideNutritionTipsPanelKey) ?? false;
    final legacyHideRecipeMgmt =
        prefs.getBool(legacyHideRecipeManagementPanelKey) ?? false;

    final savedModeName = prefs.getString(experienceModeKey);
    final defaultFlagForSavedMode = savedModeName != 'simple';

    final loadedFlags = <OptionalFeature, bool>{};
    for (final feature in OptionalFeature.values) {
      if (prefs.containsKey(feature.storageKey)) {
        loadedFlags[feature] =
            prefs.getBool(feature.storageKey) ?? defaultFlagForSavedMode;
      } else if (!completed &&
          feature == OptionalFeature.nutritionAndGoals &&
          legacyHideNutrition) {
        loadedFlags[feature] = false;
      } else if (!completed &&
          feature == OptionalFeature.recipeManagement &&
          legacyHideRecipeMgmt) {
        loadedFlags[feature] = false;
      } else {
        loadedFlags[feature] = defaultFlagForSavedMode;
      }
    }

    final autoReturn =
        prefs.getBool(autoReturnAfterAddingIngredientKey) ?? false;
    final seenEnterTip = prefs.getBool(hasSeenEnterTipKey) ?? false;

    var changed = !_isLoaded ||
        completed != _hasCompletedModeSelection ||
        autoReturn != _autoReturnAfterAddingIngredient ||
        seenEnterTip != _hasSeenEnterTip;

    for (final entry in loadedFlags.entries) {
      if (_featureFlags[entry.key] != entry.value) {
        changed = true;
      }
      _featureFlags[entry.key] = entry.value;
    }

    final derivedMode = savedModeName == 'custom'
        ? ExperienceMode.custom
        : _deriveModeFromFlags();
    if (derivedMode != _experienceMode) {
      changed = true;
    }

    _isLoaded = true;
    _hasCompletedModeSelection = completed;
    _experienceMode = derivedMode;
    _autoReturnAfterAddingIngredient = autoReturn;
    _hasSeenEnterTip = seenEnterTip;

    if (changed) {
      notifyListeners();
    }
  }

  /// Applies an [ExperienceMode] preset (`simple`, `full`, or `custom`).
  /// When [mode] is `custom` and [customCategories] is provided, enables every
  /// feature belonging to [customCategories] and disables the others.
  Future<void> applyExperienceMode(
    ExperienceMode mode, {
    Set<FeatureCategory>? customCategories,
    bool markOnboardingComplete = true,
    SharedPreferences? preferences,
  }) async {
    final nextFlags = <OptionalFeature, bool>{};
    switch (mode) {
      case ExperienceMode.simple:
        for (final feature in OptionalFeature.values) {
          nextFlags[feature] = false;
        }
      case ExperienceMode.full:
        for (final feature in OptionalFeature.values) {
          nextFlags[feature] = true;
        }
      case ExperienceMode.custom:
        for (final feature in OptionalFeature.values) {
          nextFlags[feature] = customCategories != null
              ? customCategories.contains(feature.category)
              : isFeatureEnabled(feature);
        }
    }

    var changed = false;
    for (final entry in nextFlags.entries) {
      if (_featureFlags[entry.key] != entry.value) {
        _featureFlags[entry.key] = entry.value;
        changed = true;
      }
    }

    final nextMode = switch (mode) {
      ExperienceMode.simple => ExperienceMode.simple,
      ExperienceMode.full => ExperienceMode.full,
      ExperienceMode.custom =>
        customCategories != null ? _deriveModeFromFlags() : ExperienceMode.custom,
    };
    if (_experienceMode != nextMode) {
      _experienceMode = nextMode;
      changed = true;
    }

    if (markOnboardingComplete && !_hasCompletedModeSelection) {
      _hasCompletedModeSelection = true;
      changed = true;
    }

    _isLoaded = true;
    if (changed) {
      notifyListeners();
    }

    final prefs = preferences ?? await SharedPreferences.getInstance();
    for (final entry in nextFlags.entries) {
      await prefs.setBool(entry.key.storageKey, entry.value);
    }
    await prefs.setString(experienceModeKey, nextMode.name);
    if (markOnboardingComplete) {
      await prefs.setBool(hasCompletedModeSelectionKey, true);
    }
  }

  /// Enables or disables a single [OptionalFeature] and updates [experienceMode].
  Future<void> setFeatureEnabled(
    OptionalFeature feature,
    bool value, {
    SharedPreferences? preferences,
  }) async {
    var changed = false;
    if (_featureFlags[feature] != value) {
      _featureFlags[feature] = value;
      changed = true;
    }

    final nextMode = _deriveModeFromFlags();
    if (_experienceMode != nextMode) {
      _experienceMode = nextMode;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }

    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(feature.storageKey, value);
    await prefs.setString(experienceModeKey, nextMode.name);
  }

  /// Enables or disables all optional features belonging to [category].
  Future<void> setCategoryEnabled(
    FeatureCategory category,
    bool value, {
    SharedPreferences? preferences,
  }) async {
    var changed = false;
    for (final feature in category.features) {
      if (_featureFlags[feature] != value) {
        _featureFlags[feature] = value;
        changed = true;
      }
    }

    final nextMode = _deriveModeFromFlags();
    if (_experienceMode != nextMode) {
      _experienceMode = nextMode;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }

    final prefs = preferences ?? await SharedPreferences.getInstance();
    for (final feature in category.features) {
      await prefs.setBool(feature.storageKey, value);
    }
    await prefs.setString(experienceModeKey, nextMode.name);
  }

  /// Toggles automatic return to the ingredient list after adding an ingredient.
  Future<void> setAutoReturnAfterAddingIngredient(
    bool value, {
    SharedPreferences? preferences,
  }) async {
    if (_autoReturnAfterAddingIngredient != value) {
      _autoReturnAfterAddingIngredient = value;
      notifyListeners();
    }
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(autoReturnAfterAddingIngredientKey, value);
  }

  /// Marks the Enter shortcut tip as seen so it does not keep reappearing.
  Future<void> markEnterTipSeen({SharedPreferences? preferences}) async {
    if (!_hasSeenEnterTip) {
      _hasSeenEnterTip = true;
      notifyListeners();
    }
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(hasSeenEnterTipKey, true);
  }

  /// Resets previously dismissed tips/tooltips so they appear again.
  Future<void> resetTooltips({SharedPreferences? preferences}) async {
    if (_hasSeenEnterTip) {
      _hasSeenEnterTip = false;
      notifyListeners();
    }
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(hasSeenEnterTipKey, false);
  }

  /// Resets in-memory state to defaults (useful for isolated widget tests).
  void resetToDefaults() {
    var changed = _isLoaded ||
        _hasCompletedModeSelection ||
        _experienceMode != ExperienceMode.full ||
        _autoReturnAfterAddingIngredient ||
        _hasSeenEnterTip;

    for (final feature in OptionalFeature.values) {
      if (_featureFlags[feature] != true) {
        changed = true;
      }
      _featureFlags[feature] = true;
    }

    _isLoaded = false;
    _hasCompletedModeSelection = false;
    _experienceMode = ExperienceMode.full;
    _autoReturnAfterAddingIngredient = false;
    _hasSeenEnterTip = false;

    if (changed) {
      notifyListeners();
    }
  }
}

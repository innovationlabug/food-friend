import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sections of the settings screen, used to surface contextually relevant
/// settings at the top depending on the screen where settings was opened.
enum SettingsSection {
  home,
  ingredients,
}

/// Manages user-configurable application settings with local persistence.
class SettingsController extends ChangeNotifier {
  SettingsController._();

  static final SettingsController instance = SettingsController._();

  static const String hideNutritionTipsPanelKey =
      'settings_hide_nutrition_tips_panel';
  static const String hideRecipeManagementPanelKey =
      'settings_hide_recipe_management_panel';
  static const String autoReturnAfterAddingIngredientKey =
      'settings_auto_return_after_adding_ingredient';
  static const String hasSeenEnterTipKey = 'has_seen_enter_tip';

  bool _hideNutritionTipsPanel = false;
  bool _hideRecipeManagementPanel = false;
  bool _autoReturnAfterAddingIngredient = false;
  bool _hasSeenEnterTip = false;

  /// Whether the Nutrition Tips panel is hidden on the home screen.
  bool get hideNutritionTipsPanel => _hideNutritionTipsPanel;

  /// Whether the Recipe Management panel is hidden on the home screen.
  bool get hideRecipeManagementPanel => _hideRecipeManagementPanel;

  /// Whether the app automatically returns to the ingredient list after
  /// adding a single ingredient.
  bool get autoReturnAfterAddingIngredient => _autoReturnAfterAddingIngredient;

  /// Whether the user has already seen/dismissed the Enter shortcut tip.
  bool get hasSeenEnterTip => _hasSeenEnterTip;

  /// Loads persisted settings from local storage.
  Future<void> load({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final hideNutrition = prefs.getBool(hideNutritionTipsPanelKey) ?? false;
    final hideRecipeMgmt = prefs.getBool(hideRecipeManagementPanelKey) ?? false;
    final autoReturn =
        prefs.getBool(autoReturnAfterAddingIngredientKey) ?? false;
    final seenEnterTip = prefs.getBool(hasSeenEnterTipKey) ?? false;

    final changed = hideNutrition != _hideNutritionTipsPanel ||
        hideRecipeMgmt != _hideRecipeManagementPanel ||
        autoReturn != _autoReturnAfterAddingIngredient ||
        seenEnterTip != _hasSeenEnterTip;

    _hideNutritionTipsPanel = hideNutrition;
    _hideRecipeManagementPanel = hideRecipeMgmt;
    _autoReturnAfterAddingIngredient = autoReturn;
    _hasSeenEnterTip = seenEnterTip;

    if (changed) {
      notifyListeners();
    }
  }

  /// Toggles visibility of the Nutrition Tips panel on the home screen.
  Future<void> setHideNutritionTipsPanel(
    bool value, {
    SharedPreferences? preferences,
  }) async {
    if (_hideNutritionTipsPanel != value) {
      _hideNutritionTipsPanel = value;
      notifyListeners();
    }
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(hideNutritionTipsPanelKey, value);
  }

  /// Toggles visibility of the Recipe Management panel on the home screen.
  Future<void> setHideRecipeManagementPanel(
    bool value, {
    SharedPreferences? preferences,
  }) async {
    if (_hideRecipeManagementPanel != value) {
      _hideRecipeManagementPanel = value;
      notifyListeners();
    }
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(hideRecipeManagementPanelKey, value);
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
    final changed = _hideNutritionTipsPanel ||
        _hideRecipeManagementPanel ||
        _autoReturnAfterAddingIngredient ||
        _hasSeenEnterTip;

    _hideNutritionTipsPanel = false;
    _hideRecipeManagementPanel = false;
    _autoReturnAfterAddingIngredient = false;
    _hasSeenEnterTip = false;

    if (changed) {
      notifyListeners();
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/core/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SettingsController.instance.resetToDefaults();
  });

  group('SettingsController', () {
    test('defaults to full features in memory, onboarding incomplete, auto-return off, and enter tip unseen',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await SettingsController.instance.load(preferences: prefs);

      expect(SettingsController.instance.hasCompletedModeSelection, isFalse);
      expect(SettingsController.instance.experienceMode, ExperienceMode.full);
      for (final feature in OptionalFeature.values) {
        expect(SettingsController.instance.isFeatureEnabled(feature), isTrue);
      }
      expect(
        SettingsController.instance.autoReturnAfterAddingIngredient,
        isFalse,
      );
      expect(SettingsController.instance.hasSeenEnterTip, isFalse);
    });

    test('applies Simple, Full, and Custom experience modes and persists them',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = SettingsController.instance;

      await controller.applyExperienceMode(
        ExperienceMode.simple,
        preferences: prefs,
      );
      expect(controller.hasCompletedModeSelection, isTrue);
      expect(controller.experienceMode, ExperienceMode.simple);
      for (final feature in OptionalFeature.values) {
        expect(controller.isFeatureEnabled(feature), isFalse);
      }

      controller.resetToDefaults();
      await controller.load(preferences: prefs);
      expect(controller.hasCompletedModeSelection, isTrue);
      expect(controller.experienceMode, ExperienceMode.simple);
      expect(controller.enableNutritionAndGoals, isFalse);
      expect(controller.enableAiRecipes, isFalse);

      await controller.applyExperienceMode(
        ExperienceMode.custom,
        customCategories: {FeatureCategory.ai, FeatureCategory.pricesAndSales},
        preferences: prefs,
      );
      expect(controller.experienceMode, ExperienceMode.custom);
      expect(controller.enableFridgeScanner, isTrue);
      expect(controller.enableReceiptScanner, isTrue);
      expect(controller.enableAiRecipes, isTrue);
      expect(controller.enableSupermarketDeals, isTrue);
      expect(controller.enableGtqPricing, isTrue);
      expect(controller.enableMultiDayPlanner, isFalse);
      expect(controller.enableNutritionAndGoals, isFalse);

      await controller.applyExperienceMode(
        ExperienceMode.full,
        preferences: prefs,
      );
      expect(controller.experienceMode, ExperienceMode.full);
      for (final feature in OptionalFeature.values) {
        expect(controller.isFeatureEnabled(feature), isTrue);
      }
    });

    test('toggling individual features updates experienceMode and persists',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = SettingsController.instance;

      await controller.setFeatureEnabled(
        OptionalFeature.nutritionAndGoals,
        false,
        preferences: prefs,
      );
      expect(controller.enableNutritionAndGoals, isFalse);
      expect(controller.experienceMode, ExperienceMode.custom);

      controller.resetToDefaults();
      await controller.load(preferences: prefs);
      expect(controller.enableNutritionAndGoals, isFalse);
      expect(controller.experienceMode, ExperienceMode.custom);
    });

    test('migrates legacy hide-panel preferences on first load', () async {
      SharedPreferences.setMockInitialValues({
        SettingsController.legacyHideNutritionTipsPanelKey: true,
        SettingsController.legacyHideRecipeManagementPanelKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final controller = SettingsController.instance;

      await controller.load(preferences: prefs);
      expect(controller.enableNutritionAndGoals, isFalse);
      expect(controller.enableRecipeManagement, isFalse);
      expect(controller.experienceMode, ExperienceMode.custom);
    });

    test('persists auto-return setting and reloads it', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = SettingsController.instance;

      await controller.setAutoReturnAfterAddingIngredient(
        true,
        preferences: prefs,
      );
      expect(controller.autoReturnAfterAddingIngredient, isTrue);

      controller.resetToDefaults();
      expect(controller.autoReturnAfterAddingIngredient, isFalse);

      await controller.load(preferences: prefs);
      expect(controller.autoReturnAfterAddingIngredient, isTrue);
    });

    test('marks enter tip as seen and resetTooltips restores it', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = SettingsController.instance;

      await controller.markEnterTipSeen(preferences: prefs);
      expect(controller.hasSeenEnterTip, isTrue);
      expect(prefs.getBool(SettingsController.hasSeenEnterTipKey), isTrue);

      await controller.resetTooltips(preferences: prefs);
      expect(controller.hasSeenEnterTip, isFalse);
      expect(prefs.getBool(SettingsController.hasSeenEnterTipKey), isFalse);

      controller.resetToDefaults();
      await controller.load(preferences: prefs);
      expect(controller.hasSeenEnterTip, isFalse);
    });
  });
}

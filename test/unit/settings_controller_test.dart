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
    test('defaults to showing all panels, auto-return off, and enter tip unseen',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await SettingsController.instance.load(preferences: prefs);

      expect(SettingsController.instance.hideNutritionTipsPanel, isFalse);
      expect(SettingsController.instance.hideRecipeManagementPanel, isFalse);
      expect(
        SettingsController.instance.autoReturnAfterAddingIngredient,
        isFalse,
      );
      expect(SettingsController.instance.hasSeenEnterTip, isFalse);
    });

    test('persists panel visibility toggles and reloads them', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = SettingsController.instance;

      await controller.setHideNutritionTipsPanel(true, preferences: prefs);
      await controller.setHideRecipeManagementPanel(true, preferences: prefs);

      expect(controller.hideNutritionTipsPanel, isTrue);
      expect(controller.hideRecipeManagementPanel, isTrue);

      controller.resetToDefaults();
      expect(controller.hideNutritionTipsPanel, isFalse);
      expect(controller.hideRecipeManagementPanel, isFalse);

      await controller.load(preferences: prefs);
      expect(controller.hideNutritionTipsPanel, isTrue);
      expect(controller.hideRecipeManagementPanel, isTrue);
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

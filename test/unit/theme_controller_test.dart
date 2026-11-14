import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_friend/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeController.instance.resetToLight();
  });

  group('ThemeController', () {
    test('defaults to light mode when no preference is stored', () async {
      final prefs = await SharedPreferences.getInstance();
      await ThemeController.instance.load(preferences: prefs);

      expect(ThemeController.instance.themeMode, equals(ThemeMode.light));
      expect(ThemeController.instance.isDarkMode, isFalse);
    });

    test('persists dark mode preference and reloads it', () async {
      final prefs = await SharedPreferences.getInstance();
      await ThemeController.instance.setThemeMode(
        ThemeMode.dark,
        preferences: prefs,
      );

      expect(ThemeController.instance.themeMode, equals(ThemeMode.dark));
      expect(ThemeController.instance.isDarkMode, isTrue);

      ThemeController.instance.resetToLight();
      expect(ThemeController.instance.themeMode, equals(ThemeMode.light));

      await ThemeController.instance.load(preferences: prefs);
      expect(ThemeController.instance.themeMode, equals(ThemeMode.dark));
    });

    test('toggleTheme switches between light and dark modes', () async {
      final prefs = await SharedPreferences.getInstance();
      await ThemeController.instance.toggleTheme(preferences: prefs);
      expect(ThemeController.instance.themeMode, equals(ThemeMode.dark));

      await ThemeController.instance.toggleTheme(preferences: prefs);
      expect(ThemeController.instance.themeMode, equals(ThemeMode.light));
    });
  });
}


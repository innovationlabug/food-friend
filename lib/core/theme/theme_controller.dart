import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the application's active [ThemeMode] with local persistence.
/// Defaults to [ThemeMode.light] until the user explicitly switches to dark mode.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _storageKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  /// Current active theme mode. Defaults to [ThemeMode.light].
  ThemeMode get themeMode => _themeMode;

  /// Whether dark mode is currently active.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Loads the persisted theme preference, falling back to [ThemeMode.light].
  Future<void> load({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    final loadedMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    if (loadedMode != _themeMode) {
      _themeMode = loadedMode;
      notifyListeners();
    }
  }

  /// Updates the active theme mode and persists the choice locally.
  Future<void> setThemeMode(
    ThemeMode mode, {
    SharedPreferences? preferences,
  }) async {
    final normalized = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode != normalized) {
      _themeMode = normalized;
      notifyListeners();
    }
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      normalized == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  /// Toggles between light and dark theme modes.
  Future<void> toggleTheme({SharedPreferences? preferences}) {
    return setThemeMode(
      isDarkMode ? ThemeMode.light : ThemeMode.dark,
      preferences: preferences,
    );
  }

  /// Resets in-memory state to light mode (useful for isolated widget tests).
  void resetToLight() {
    if (_themeMode != ThemeMode.light) {
      _themeMode = ThemeMode.light;
      notifyListeners();
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';

/// Owns the light/dark choice and persists it. Toggling swaps the global
/// [AppColors] palette and notifies, so the app (rebuilt from MaterialApp) picks
/// up the new colours everywhere.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'll_theme_light';

  ThemeProvider(this._light) {
    AppColors.setLight(_light);
    _applySystemOverlay(_light);
  }

  /// Keeps the status-bar / nav-bar icons legible against the active theme:
  /// dark icons on the white light theme, light icons on the black dark theme.
  void _applySystemOverlay(bool light) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
      statusBarBrightness: light ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          light ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      systemNavigationBarIconBrightness:
          light ? Brightness.dark : Brightness.light,
    ));
  }

  bool _light;
  bool get isLight => _light;

  /// Reads the stored preference (defaults to dark). Call before runApp.
  static Future<bool> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() => setLight(!_light);

  Future<void> setLight(bool value) async {
    if (_light == value) return;
    _light = value;
    AppColors.setLight(value);
    _applySystemOverlay(value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

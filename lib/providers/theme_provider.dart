import 'package:flutter/material.dart';
import '../data/settings_service.dart';

class ThemeProvider with ChangeNotifier {
  final SettingsService _settingsService;
  late AppSettings _settings;

  ThemeProvider(this._settingsService);

  ThemeMode get themeMode => _settings.themeMode;
  bool get useDynamicColor => _settings.useDynamicColor;

  Future<void> loadSettings() async {
    _settings = await _settingsService.getSettings();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    _settings = _settings.copyWith(themeMode: newThemeMode);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateDynamicColor(bool? shouldUse) async {
    if (shouldUse == null) return;
    _settings = _settings.copyWith(useDynamicColor: shouldUse);
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }
}

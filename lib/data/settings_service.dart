import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'file_system_service.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool useDynamicColor;
  final String? selectedModelId;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.selectedModelId,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    String? selectedModelId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      selectedModelId: selectedModelId ?? this.selectedModelId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode.name,
      'use_dynamic_color': useDynamicColor,
      'selected_model_id': selectedModelId,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['theme_mode'],
        orElse: () => ThemeMode.system,
      ),
      useDynamicColor: json['use_dynamic_color'] ?? true,
      selectedModelId: json['selected_model_id'],
    );
  }
}

class SettingsService {
  final FileSystemService _fileSystemService;
  static const String _settingsFileName = 'settings.json';

  SettingsService({required FileSystemService fileSystemService})
      : _fileSystemService = fileSystemService;

  Future<File> _getSettingsFile() async {
    final appDataDir = await _fileSystemService.getAppDataDirectory();
    return File('${appDataDir.path}/$_settingsFileName');
  }

  Future<void> saveSettings(AppSettings settings) async {
    final file = await _getSettingsFile();
    await file.writeAsString(jsonEncode(settings.toJson()));
  }

  Future<AppSettings> getSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(content);
        return AppSettings.fromJson(json);
      }
    } catch (e) {
      // Ignore errors and return default if file is corrupt or unreadable
    }
    return AppSettings();
  }
}

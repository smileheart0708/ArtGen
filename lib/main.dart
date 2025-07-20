import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/api_key_service.dart';
import 'data/backup_service.dart';
import 'data/file_system_service.dart';
import 'data/settings_service.dart';
import 'providers/theme_provider.dart';
import 'providers/video_generation_provider.dart';
import 'ui/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _defaultLightColorScheme =
      ColorScheme.fromSeed(seedColor: Colors.deepPurple);
  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FileSystemService>(create: (_) => FileSystemService()),
        Provider<ApiKeyService>(create: (_) => ApiKeyService()),
        ProxyProvider<FileSystemService, SettingsService>(
          update: (_, fileSystemService, _) =>
              SettingsService(fileSystemService: fileSystemService),
        ),
        ProxyProvider2<ApiKeyService, FileSystemService, BackupService>(
          update: (_, apiKeyService, fileSystemService, _) => BackupService(
            apiKeyService: apiKeyService,
            fileSystemService: fileSystemService,
          ),
        ),
        ChangeNotifierProxyProvider<SettingsService, ThemeProvider>(
          create: (context) =>
              ThemeProvider(context.read<SettingsService>())..loadSettings(),
          update: (_, settingsService, previous) =>
              ThemeProvider(settingsService)..loadSettings(),
        ),
        ChangeNotifierProxyProvider2<ApiKeyService, SettingsService,
            VideoGenerationProvider>(
          create: (context) => VideoGenerationProvider(
            apiKeyService: context.read<ApiKeyService>(),
            settingsService: context.read<SettingsService>(),
          ),
          update: (_, apiKeyService, settingsService, _) =>
              VideoGenerationProvider(
            apiKeyService: apiKeyService,
            settingsService: settingsService,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return DynamicColorBuilder(
            builder: (lightColorScheme, darkColorScheme) {
              final useDynamic = themeProvider.useDynamicColor;
              return MaterialApp(
                title: 'ArtifyAI',
                theme: ThemeData(
                  colorScheme: useDynamic && lightColorScheme != null
                      ? lightColorScheme
                      : _defaultLightColorScheme,
                  useMaterial3: true,
                ),
                darkTheme: ThemeData(
                  colorScheme: useDynamic && darkColorScheme != null
                      ? darkColorScheme
                      : _defaultDarkColorScheme,
                  useMaterial3: true,
                ),
                themeMode: themeProvider.themeMode,
                home: const MainScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

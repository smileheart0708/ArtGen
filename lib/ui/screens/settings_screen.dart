import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/ai_provider.dart';
import '../../data/api_key_service.dart';
import '../../data/backup_service.dart';
import '../../data/settings_service.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ThemeProvider(context.read<SettingsService>())..loadSettings(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  bool _isProcessing = false;

  void _showResult(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置与数据管理')),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const ListTile(
                    title: Text('个性化',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                ListTile(
                  title: const Text('主题模式'),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('跟随系统'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('浅色模式'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('深色模式'),
                      ),
                    ],
                    onChanged: (mode) => themeProvider.updateThemeMode(mode),
                  ),
                ),
                SwitchListTile(
                  title: const Text('使用动态颜色 (Material You)'),
                  subtitle: const Text('仅在 Android 12+ 上可用'),
                  value: themeProvider.useDynamicColor,
                  onChanged: (value) =>
                      themeProvider.updateDynamicColor(value),
                ),
                const Divider(),
                const ListTile(
                    title: Text('API Key 管理',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                ...AiProviderType.values
                    .map((provider) => ApiKeyTile(provider: provider)),
                const Divider(),
                const ListTile(
                    title: Text('数据管理',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('警告：备份文件包含未加密的API Keys，请妥善保管。',
                      style: TextStyle(color: Colors.orange)),
                ),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('备份数据'),
                  onTap: () async {
                    setState(() => _isProcessing = true);
                    try {
                      final backupService = context.read<BackupService>();
                      String? dir =
                          await FilePicker.platform.getDirectoryPath();
                      if (dir != null) {
                        final result = await backupService.exportBackup(dir);
                        if (!mounted) return;
                        _showResult(result);
                      }
                    } catch (e) {
                      if (!mounted) return;
                      _showResult(e.toString(), isError: true);
                    }
                    if (!mounted) return;
                    setState(() => _isProcessing = false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined),
                  title: const Text('从备份恢复'),
                  onTap: () async {
                    setState(() => _isProcessing = true);
                    try {
                      final backupService = context.read<BackupService>();
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['zip']);
                      if (result != null && result.files.single.path != null) {
                        final message = await backupService
                            .importBackup(result.files.single.path!);
                        if (!mounted) return;
                        _showResult(message);
                      }
                    } catch (e) {
                      if (!mounted) return;
                      _showResult(e.toString(), isError: true);
                    }
                    if (!mounted) return;
                    setState(() => _isProcessing = false);
                  },
                ),
              ],
            ),
    );
  }
}

class ApiKeyTile extends StatefulWidget {
  final AiProviderType provider;
  const ApiKeyTile({super.key, required this.provider});
  @override
  State<ApiKeyTile> createState() => _ApiKeyTileState();
}

class _ApiKeyTileState extends State<ApiKeyTile> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ApiKeyService>().getApiKey(widget.provider).then((key) {
      if (key != null && mounted) _controller.text = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.provider.displayName),
      subtitle: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: '在此输入或粘贴 API Key'),
        obscureText: true,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.save),
        onPressed: () async {
          final apiKeyService = context.read<ApiKeyService>();
          final messenger = ScaffoldMessenger.of(context);
          final focusScope = FocusScope.of(context);

          await apiKeyService.saveApiKey(widget.provider, _controller.text);

          if (!mounted) return;
          messenger.showSnackBar(SnackBar(content: Text('${widget.provider.displayName} Key 已保存！')));
          focusScope.unfocus();
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

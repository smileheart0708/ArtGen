import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import '../core/ai_provider.dart';
import 'api_key_service.dart';
import 'file_system_service.dart';

class BackupService {
  final ApiKeyService _apiKeyService;
  final FileSystemService _fileSystemService;
  static const String _apiKeyBackupFileName = 'apikeys_backup.json';

  BackupService({
    required ApiKeyService apiKeyService,
    required FileSystemService fileSystemService,
  })  : _apiKeyService = apiKeyService,
        _fileSystemService = fileSystemService;

  Future<String> exportBackup(String targetDirectoryPath) async {
    final appDataDir = await _fileSystemService.getAppDataDirectory();
    final backupJsonFile = File('${appDataDir.path}/$_apiKeyBackupFileName');
    try {
      final allKeys = await _apiKeyService.getAllApiKeys();
      await backupJsonFile.writeAsString(jsonEncode(allKeys));

      final encoder = ZipFileEncoder();
      final backupZipPath = '$targetDirectoryPath/ArtifyAI_Backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      encoder.zipDirectory(appDataDir, filename: backupZipPath);
      return '备份成功！已保存至: $backupZipPath';
    } catch (e) {
      throw Exception('备份失败: $e');
    } finally {
      if (await backupJsonFile.exists()) {
        await backupJsonFile.delete();
      }
    }
  }

  Future<String> importBackup(String backupZipPath) async {
    final appDataDir = await _fileSystemService.getAppDataDirectory();
    final backupJsonFile = File('${appDataDir.path}/$_apiKeyBackupFileName');
    try {
      final inputStream = InputFileStream(backupZipPath);
      final archive = ZipDecoder().decodeBytes(inputStream.toUint8List());
      extractArchiveToDisk(archive, appDataDir.path);

      if (!await backupJsonFile.exists()) {
        throw Exception('备份文件中未找到API Key数据。');
      }
      final content = await backupJsonFile.readAsString();
      final Map<String, dynamic> keysFromJson = jsonDecode(content);

      for (final entry in keysFromJson.entries) {
        final provider = AiProviderType.values.firstWhere((p) => p.name == entry.key);
        await _apiKeyService.saveApiKey(provider, entry.value);
      }
      return '恢复成功！请重启应用以确保所有设置生效。';
    } catch (e) {
      throw Exception('恢复失败: $e');
    } finally {
      if (await backupJsonFile.exists()) {
        await backupJsonFile.delete();
      }
    }
  }
}

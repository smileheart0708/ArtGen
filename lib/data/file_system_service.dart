import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileSystemService {
  Future<Directory> getAppDataDirectory() async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final appDataDir = Directory('${appDocumentsDir.path}/app_data');
    if (!await appDataDir.exists()) {
      await appDataDir.create(recursive: true);
    }
    return appDataDir;
  }
}

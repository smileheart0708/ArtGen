import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/ai_provider.dart';

class ApiKeyService {
  final _secureStorage = const FlutterSecureStorage();

  String _keyForProvider(AiProviderType provider) => 'api_key_${provider.name}';

  Future<void> saveApiKey(AiProviderType provider, String apiKey) async {
    await _secureStorage.write(key: _keyForProvider(provider), value: apiKey);
  }

  Future<String?> getApiKey(AiProviderType provider) async {
    return await _secureStorage.read(key: _keyForProvider(provider));
  }

  Future<Map<String, String>> getAllApiKeys() async {
    final Map<String, String> allKeys = {};
    for (final provider in AiProviderType.values) {
      final key = await getApiKey(provider);
      if (key != null && key.isNotEmpty) {
        allKeys[provider.name] = key;
      }
    }
    return allKeys;
  }
}

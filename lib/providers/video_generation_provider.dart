import 'package:flutter/material.dart';
import '../core/ai_provider.dart';
import '../core/api_service.dart';
import '../data/api_key_service.dart';
import '../data/settings_service.dart';
import '../models/video_model.dart';
import '../services/zhipu_api_service.dart';

class VideoGenerationProvider with ChangeNotifier {
  final ApiKeyService _apiKeyService;
  final SettingsService _settingsService;

  VideoGenerationProvider({
    required ApiKeyService apiKeyService,
    required SettingsService settingsService,
  })  : _apiKeyService = apiKeyService,
        _settingsService = settingsService {
    _loadInitialData();
  }

  // Available Models
  final List<VideoModel> _availableModels = [
    const VideoModel(id: 'cogvideox-2', name: 'CogVideoX-2', tag: '0.5元/次', provider: AiProviderType.zhipu),
    const VideoModel(id: 'cogvideox-flash', name: 'CogVideoX-Flash', tag: '免费', provider: AiProviderType.zhipu),
    const VideoModel(id: 'cogvideox-3', name: 'CogVideoX-3', tag: '1元/次', provider: AiProviderType.zhipu),
  ];

  List<VideoModel> get availableModels => _availableModels;
  
  VideoModel? _selectedModel;
  VideoModel? get selectedModel => _selectedModel;

  bool _isLoading = false;
  String? _errorMessage;
  String? _videoUrl;
  String _statusMessage = '准备就绪';
  AiProviderType _selectedProvider = AiProviderType.zhipu;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get videoUrl => _videoUrl;
  String get statusMessage => _statusMessage;
  AiProviderType get selectedProvider => _selectedProvider;

  Future<void> _loadInitialData() async {
    final settings = await _settingsService.getSettings();
    if (settings.selectedModelId != null) {
      _selectedModel = _availableModels.firstWhere(
        (m) => m.id == settings.selectedModelId,
        orElse: () => _availableModels.first,
      );
    } else {
      _selectedModel = _availableModels.first;
    }
    notifyListeners();
  }

  Future<void> selectModel(VideoModel model) async {
    _selectedModel = model;
    final currentSettings = await _settingsService.getSettings();
    await _settingsService.saveSettings(
      currentSettings.copyWith(selectedModelId: model.id),
    );
    notifyListeners();
  }

  void setProvider(AiProviderType provider) {
    _selectedProvider = provider;
    notifyListeners();
  }

  Future<BaseApiService?> _getApiService(AiProviderType provider) async {
    final apiKey = await _apiKeyService.getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) {
      _errorMessage = '${provider.displayName} 的 API Key 未设置。';
      return null;
    }
    switch (provider) {
      case AiProviderType.zhipu:
        return ZhipuApiService(apiKey: apiKey);
    }
  }

  Future<void> generateVideo(String prompt) async {
    if (_selectedModel == null) {
      _errorMessage = '请先选择一个模型。';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _videoUrl = null;
    _statusMessage = 'AI正在生成中，请稍后';
    notifyListeners();

    final apiService = await _getApiService(_selectedProvider);
    if (apiService == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final taskId = await apiService.createVideoGenerationTask(prompt, modelId: _selectedModel!.id);
      
      final result = await apiService.getTaskResult(taskId, onStatusUpdate: (status) {
        // The status is now handled inside the service, but we keep the callback
        // in case we want to add more detailed status updates in the future.
      });
      if (result['video_result'] != null && result['video_result'].isNotEmpty) {
        _videoUrl = result['video_result'][0]['url'];
      } else {
        throw Exception('未找到视频结果。');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _statusMessage = '发生错误';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

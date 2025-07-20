enum AiProviderType {
  zhipu,
  // 未来可在此添加: midjourney, runwayML
}

extension AiProviderTypeExtension on AiProviderType {
  String get displayName {
    switch (this) {
      case AiProviderType.zhipu:
        return '智谱AI';
    }
  }
}

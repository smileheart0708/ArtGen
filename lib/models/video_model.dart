import '../core/ai_provider.dart';

class VideoModel {
  final String id;
  final String name;
  final String tag;
  final AiProviderType provider;

  const VideoModel({
    required this.id,
    required this.name,
    required this.tag,
    required this.provider,
  });

  // Helper method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'provider': provider.name,
    };
  }

  // Helper method for JSON deserialization
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      name: json['name'],
      tag: json['tag'],
      provider: AiProviderType.values.firstWhere((e) => e.name == json['provider']),
    );
  }
}

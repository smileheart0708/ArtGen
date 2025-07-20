abstract class BaseApiService {
  Future<String> createVideoGenerationTask(String prompt, {String? modelId});
  Future<Map<String, dynamic>> getTaskResult(
    String taskId, {
    required Function(String status) onStatusUpdate,
  });
}

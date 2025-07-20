import 'package:dio/dio.dart';
import '../core/api_service.dart';

class ZhipuApiService implements BaseApiService {
  final Dio _dio;
  static const String _baseUrl = "https://open.bigmodel.cn/api/paas/v4";
  static const String _createTaskUrl = "/videos/generations";
  static const String _getResultUrl = "/async-result/";

  ZhipuApiService({required String apiKey}) : _dio = Dio() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer $apiKey';
        handler.next(options);
      },
    ));
  }

  @override
  Future<String> createVideoGenerationTask(String prompt, {String? modelId}) async {
    final response = await _dio.post("$_baseUrl$_createTaskUrl", data: {
      'model': modelId ?? 'cogvideox-2', 'prompt': prompt,
    });
    if (response.statusCode == 200 && response.data != null) {
      return response.data['id'];
    } else {
      throw Exception('创建任务失败: ${response.statusMessage}');
    }
  }

  @override
  Future<Map<String, dynamic>> getTaskResult(String taskId, {required Function(String status) onStatusUpdate}) async {
    // 1. 初始延迟
    await Future.delayed(const Duration(seconds: 5));

    // 2. 快速轮询阶段
    const int fastRetries = 20;
    const Duration fastPollInterval = Duration(seconds: 2);
    for (int i = 0; i < fastRetries; i++) {
      onStatusUpdate('AI正在生成中，请稍后');
      final result = await _queryTaskStatus(taskId);
      if (result != null) {
        onStatusUpdate('任务成功！');
        return result;
      }
      await Future.delayed(fastPollInterval);
    }

    // 3. 慢速轮询阶段
    const Duration slowPollInterval = Duration(seconds: 10);
    while (true) {
      onStatusUpdate('AI正在生成中，请稍后');
      final result = await _queryTaskStatus(taskId);
      if (result != null) {
        onStatusUpdate('任务成功！');
        return result;
      }
      await Future.delayed(slowPollInterval);
    }
  }

  Future<Map<String, dynamic>?> _queryTaskStatus(String taskId) async {
    final response = await _dio.get("$_baseUrl$_getResultUrl$taskId");
    if (response.statusCode == 200 && response.data != null) {
      final status = response.data['task_status'];
      if (status == 'SUCCESS') {
        return response.data;
      } else if (status == 'FAIL') {
        throw Exception('任务处理失败: ${response.data}');
      }
    } else {
      // 在轮询中，暂时忽略查询失败，等待下一次重试
    }
    return null;
  }
}

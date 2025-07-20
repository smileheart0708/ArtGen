import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_store/flutter_media_store.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/video_generation_provider.dart';
import '../widgets/error_dialog.dart';
import '../../core/ai_provider.dart';

class VideoGenerationScreen extends StatefulWidget {
  const VideoGenerationScreen({super.key});
  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  final _promptController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isDownloading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<VideoGenerationProvider>(context);
    if (provider.videoUrl != null) {
      _initializeVideoPlayer(provider.videoUrl!);
    }
    provider.addListener(_onProviderChange);
  }

  void _onProviderChange() {
    final provider = Provider.of<VideoGenerationProvider>(context, listen: false);
    if (provider.errorMessage != null) {
      showErrorDialog(context, provider.errorMessage!);
      provider.clearError();
    }
    if (provider.videoUrl != null && provider.videoUrl != _videoController?.dataSource) {
      _initializeVideoPlayer(provider.videoUrl!);
    } else if (provider.videoUrl == null) {
      _videoController?.dispose();
      _videoController = null;
    }
  }

  void _initializeVideoPlayer(String url) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _videoController?.play();
        _videoController?.setLooping(true);
      });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _videoController?.dispose();
    Provider.of<VideoGenerationProvider>(context, listen: false).removeListener(_onProviderChange);
    super.dispose();
  }

  void _showModelSelectionSheet(BuildContext context) {
    final provider = context.read<VideoGenerationProvider>();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('选择视频生成模型', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...provider.availableModels.map((model) {
                return ListTile(
                  title: Text(model.name),
                  subtitle: Text(model.provider.displayName),
                  trailing: Chip(label: Text(model.tag)),
                  onTap: () {
                    provider.selectModel(model);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ArtifyAI 视频生成')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<VideoGenerationProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(labelText: '输入视频描述 (Prompt)', border: OutlineInputBorder()),
                    enabled: !provider.isLoading,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _showModelSelectionSheet(context),
                    child: Text(provider.selectedModel?.name ?? '选择模型'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.isLoading ? null : () {
                      if (_promptController.text.isNotEmpty) {
                        provider.generateVideo(_promptController.text);
                        FocusScope.of(context).unfocus();
                      }
                    },
                    child: const Text('开始生成视频'),
                  ),
                  const SizedBox(height: 24),
                  _buildStatusSection(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusSection(VideoGenerationProvider provider) {
    if (provider.isLoading) {
      return Column(children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(provider.statusMessage)]);
    }
    if (provider.videoUrl != null && _videoController?.value.isInitialized == true) {
      return Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
              VideoPlayer(_videoController!),
              if (!_videoController!.value.isPlaying)
                Icon(Icons.play_arrow, size: 50, color: Colors.white.withAlpha((255 * 0.7).round())),
            ],
          ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: _isDownloading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
            label: Text(_isDownloading ? '下载中...' : '下载视频'),
            onPressed: _isDownloading ? null : () => _downloadVideo(provider),
          ),
        ],
      );
    }
    return Text(provider.statusMessage);
  }

  Future<void> _downloadVideo(VideoGenerationProvider provider) async {
    setState(() => _isDownloading = true);

    try {
      // 1. 检查权限
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackBar('存储权限被拒绝，无法下载视频。');
        setState(() => _isDownloading = false);
        return;
      }

      // 2. 准备文件名和路径
      final videoUrl = provider.videoUrl!;
      final modelId = provider.selectedModel?.id ?? 'unknown_model';
      final timestamp = DateFormat('HH_mm_ss').format(DateTime.now());
      final extension = videoUrl.split('.').last.split('?').first;
      final fileName = '${modelId}_$timestamp.$extension';

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';

      // 3. 使用 Dio 下载到临时文件
      await Dio().download(videoUrl, tempPath);

      // 4. 使用 flutter_media_store 保存到公共目录
      final file = File(tempPath);
      final bytes = await file.readAsBytes();
      await FlutterMediaStore().saveFile(
        fileData: bytes,
        fileName: fileName,
        mimeType: "video/mp4",
        rootFolderName: "Movies",
        folderName: "ArtifyAI",
        onSuccess: (filePath, fileName) {
          _showSnackBar('视频已成功保存到相册 "Movies/ArtifyAI"');
        },
        onError: (error) {
          _showSnackBar('保存视频失败: $error', isError: true);
        },
      );
      
      // 5. 删除临时文件
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

    } catch (e) {
      if (mounted) {
        showErrorDialog(context, '下载视频时发生错误: ${e.toString()}');
      }
    } finally {
      if(mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Enum để quản lý trạng thái của player một cách rõ ràng
enum PlayerStatus { loading, ready, error }

class SimpleVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoComplete;
  final Function(Duration position, Duration total)? onProgressUpdate;

  const SimpleVideoPlayer({
    super.key,
    required this.videoUrl,
    this.onVideoComplete,
    this.onProgressUpdate,
  });

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  
  PlayerStatus _playerStatus = PlayerStatus.loading;
  bool _isListenerAdded = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    // Luôn luôn remove listener trước khi dispose
    if (_isListenerAdded) {
      _videoController.removeListener(_videoListener);
    }
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SimpleVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      // Dispose controller cũ
      if (_isListenerAdded) {
        _videoController.removeListener(_videoListener);
        _isListenerAdded = false;
      }
      _videoController.dispose();
      _chewieController?.dispose();
      _playerStatus = PlayerStatus.loading;
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    // Reset state khi thử lại
    setState(() {
      _playerStatus = PlayerStatus.loading;
    });

    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      await _videoController.initialize();
      // KHI initialize() THÀNH CÔNG
      _setupChewieController();
      _videoController.addListener(_videoListener);
      _isListenerAdded = true;

      // Cập nhật trạng thái để build UI của player
      if (mounted) {
        setState(() {
          _playerStatus = PlayerStatus.ready;
        });
      }
    } catch (error) {
      print("LỖI KHỞI TẠO VIDEO PLAYER: $error");
      if (mounted) {
        setState(() {
          _playerStatus = PlayerStatus.error;
        });
      }
    }
  }

  void _setupChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      // Các tùy chỉnh khác của Chewie
    );
  }

  void _videoListener() {
    if (!_videoController.value.isInitialized || _videoController.value.duration.inMilliseconds == 0) {
      // Nếu chưa init hoặc duration = 0 thì báo về zero để tránh bug
      widget.onProgressUpdate?.call(Duration.zero, Duration.zero);
      return;
    }

    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    // Cập nhật tiến trình ra bên ngoài
    widget.onProgressUpdate?.call(position, duration);

    // Kiểm tra hoàn thành video
    if (duration.inSeconds > 0 && position.inSeconds >= duration.inSeconds - 1) {
      if (widget.onVideoComplete != null) {
        widget.onVideoComplete!();
      }
      // Gỡ listener sau khi hoàn thành để tránh gọi lại
      _videoController.removeListener(_videoListener);
      _isListenerAdded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_playerStatus) {
      case PlayerStatus.loading:
        return _buildLoadingView();
      case PlayerStatus.error:
        return _buildErrorView();
      case PlayerStatus.ready:
        // Đảm bảo chewie controller đã được tạo
        if (_chewieController != null) {
          return Chewie(controller: _chewieController!);
        }
        // Fallback trong trường hợp hi hữu
        return _buildErrorView();
    }
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 10),
          const Text('Không thể tải video.'),
          ElevatedButton(
            onPressed: _initializePlayer,
            child: const Text('Thử lại'),
          )
        ],
      ),
    );
  }
}
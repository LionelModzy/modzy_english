import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

enum PlayerStatus { loading, ready, error }

class UnifiedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoComplete;
  final Function(Duration position, Duration total)? onProgressUpdate;
  final double width;
  final double height;

  const UnifiedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.onVideoComplete,
    this.onProgressUpdate,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  State<UnifiedVideoPlayer> createState() => _UnifiedVideoPlayerState();
}

class _UnifiedVideoPlayerState extends State<UnifiedVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  
  PlayerStatus _playerStatus = PlayerStatus.loading;
  bool _isListenerAdded = false;
  bool _isFullscreen = false;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    if (_isListenerAdded) {
      _videoController.removeListener(_videoListener);
    }
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UnifiedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
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
    setState(() {
      _playerStatus = PlayerStatus.loading;
    });

    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      await _videoController.initialize();
      _setupChewieController();
      _videoController.addListener(_videoListener);
      _isListenerAdded = true;

      // Start progress timer
      _startProgressTimer();

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
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      showControls: true,
      showOptions: true,
      playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.red,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey[300]!,
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              const Text('Không thể tải video', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _initializePlayer,
                child: const Text('Thử lại'),
              )
            ],
          ),
        );
      },
    );
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && _videoController.value.isInitialized) {
        final position = _videoController.value.position;
        final duration = _videoController.value.duration;
        
        if (duration.inMilliseconds > 0) {
          widget.onProgressUpdate?.call(position, duration);
        }
      }
    });
  }

  void _videoListener() {
    if (!_videoController.value.isInitialized || _videoController.value.duration.inMilliseconds == 0) {
      widget.onProgressUpdate?.call(Duration.zero, Duration.zero);
      return;
    }

    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

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
        if (_chewieController != null) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.black,
            child: Chewie(controller: _chewieController!),
          );
        }
        return _buildErrorView();
    }
  }

  Widget _buildLoadingView() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            const Text('Không thể tải video', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _initializePlayer,
              child: const Text('Thử lại'),
            )
          ],
        ),
      ),
    );
  }
} 
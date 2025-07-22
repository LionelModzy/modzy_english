import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class MobileOptimizedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;

  const MobileOptimizedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.width = double.infinity,
    this.height = 200,
  });

  @override
  State<MobileOptimizedVideoPlayer> createState() => _MobileOptimizedVideoPlayerState();
}

class _MobileOptimizedVideoPlayerState extends State<MobileOptimizedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant MobileOptimizedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initController();
    }
  }

  Future<void> _initController() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _controller!.initialize();
    await _controller!.setPlaybackSpeed(_playbackSpeed);
    setState(() {
      _isInitialized = true;
      _isPlaying = false;
    });
    _controller!.addListener(_videoListener);
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    setState(() {
      _isPlaying = _controller!.value.isPlaying;
    });
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isPlaying = false;
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  void _seekRelative(int seconds) {
    if (_controller == null || !_isInitialized) return;
    final current = _controller!.value.position;
    final duration = _controller!.value.duration;
    var newPosition = current + Duration(seconds: seconds);
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > duration) newPosition = duration;
    _controller!.seekTo(newPosition);
  }

  void _changeSpeed(double speed) async {
    if (_controller == null) return;
    await _controller!.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
  }

  void _showSpeedMenu() async {
    final speeds = [0.5, 1.0, 1.5, 2.0];
    final selected = await showModalBottomSheet<double>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds.map((s) => ListTile(
            title: Text('${s}x'),
            selected: _playbackSpeed == s,
            onTap: () => Navigator.pop(ctx, s),
          )).toList(),
        ),
      ),
    );
    if (selected != null) _changeSpeed(selected);
  }

  void _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    setState(() => _isFullscreen = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          bottomNavigationBar: _buildControls(fullscreen: true),
        ),
      ),
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setState(() => _isFullscreen = false);
  }

  Widget _buildControls({bool fullscreen = false}) {
    final duration = _controller?.value.duration ?? Duration.zero;
    final position = _controller?.value.position ?? Duration.zero;
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                onPressed: () => _seekRelative(-10),
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
                onPressed: _togglePlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                onPressed: () => _seekRelative(10),
              ),
              IconButton(
                icon: const Icon(Icons.speed, color: Colors.white, size: 28),
                onPressed: _showSpeedMenu,
              ),
              IconButton(
                icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white, size: 32),
                onPressed: fullscreen ? () => Navigator.of(context).pop() : _enterFullscreen,
              ),
            ],
          ),
          Row(
            children: [
              Text(_formatDuration(position), style: const TextStyle(color: Colors.white, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble(),
                  onChanged: (v) => _controller!.seekTo(Duration(milliseconds: v.toInt())),
                  activeColor: Colors.red,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
              ),
              Text(_formatDuration(duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }
}
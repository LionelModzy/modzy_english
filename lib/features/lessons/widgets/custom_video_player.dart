import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final bool enableAutoPlay;
  final Function(double progress, Duration position, Duration total)? onProgressUpdate;
  final VoidCallback? onTap;
  final Function(CustomVideoPlayer)? onPlayerReady;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.width = double.infinity,
    this.height = 200,
    this.enableAutoPlay = false,
    this.onProgressUpdate,
    this.onTap,
    this.onPlayerReady,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _showControls = true;
  bool _isUserSeeking = false;
  
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  Timer? _hideControlsTimer;
  Timer? _progressTimer;
  
  // Saved position that will be applied once
  Duration? _savedPosition;
  bool _hasAppliedSavedPosition = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() => _isLoading = true);
      
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
        _duration = _controller!.value.duration;
        _isLoading = false;
      });

      // Setup position tracking timer (instead of listener for mobile stability)
      _setupProgressTimer();

      // Notify parent that player is ready
      widget.onPlayerReady?.call(widget);

      if (widget.enableAutoPlay && !_hasAppliedSavedPosition) {
        await _controller!.play();
        setState(() => _isPlaying = true);
      }

    } catch (e) {
      print('Error initializing video: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_controller != null && 
          _controller!.value.isInitialized && 
          !_isUserSeeking) {
        
        final position = _controller!.value.position;
        final isPlaying = _controller!.value.isPlaying;
        
        setState(() {
          _position = position;
          _isPlaying = isPlaying;
        });

        // Only report progress if duration is valid
        if (_duration.inMilliseconds > 0) {
          final progress = position.inMilliseconds / _duration.inMilliseconds;
          widget.onProgressUpdate?.call(
            progress.clamp(0.0, 1.0), 
            position, 
            _duration
          );
        }
      }
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  Future<void> _togglePlayPause() async {
    if (_controller == null || !_isInitialized) return;

    if (_isPlaying) {
      await _controller!.pause();
    } else {
      await _controller!.play();
    }
    
    setState(() => _isPlaying = !_isPlaying);
    _showControlsTemporarily();
  }

  void _onSliderChanged(double value) {
    if (_controller == null || !_isInitialized) return;
    
    setState(() => _isUserSeeking = true);
    
    final position = Duration(milliseconds: value.toInt());
    setState(() => _position = position);
  }

  void _onSliderChangeEnd(double value) {
    if (_controller == null || !_isInitialized) return;
    
    final position = Duration(milliseconds: value.toInt());
    _controller!.seekTo(position);
    
    // Wait a bit before resuming progress tracking
    Timer(const Duration(milliseconds: 1000), () {
      setState(() => _isUserSeeking = false);
    });
  }

  void seekToPosition(Duration position) {
    if (_controller == null || !_isInitialized) return;
    
    _savedPosition = position;
    _applySavedPosition();
  }

  void _applySavedPosition() {
    if (_savedPosition != null && _controller != null && _isInitialized && !_hasAppliedSavedPosition) {
      _hasAppliedSavedPosition = true;
      _controller!.seekTo(_savedPosition!);
      
      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khôi phục vị trí: ${_formatDuration(_savedPosition!)}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
      
      _savedPosition = null;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Public methods for external control
  void togglePlayPause() {
    _togglePlayPause();
  }

  void play() {
    if (_controller != null && _isInitialized && !_isPlaying) {
      _controller!.play();
      setState(() => _isPlaying = true);
    }
  }

  void pause() {
    if (_controller != null && _isInitialized && _isPlaying) {
      _controller!.pause();
      setState(() => _isPlaying = false);
    }
  }

  void seekTo(double progress) {
    if (_controller == null || !_isInitialized) {
      // Store for later if not ready
      _savedPosition = Duration(milliseconds: (progress * _duration.inMilliseconds).toInt());
      return;
    }
    
    final position = Duration(milliseconds: (progress * _duration.inMilliseconds).toInt());
    _controller!.seekTo(position);
    setState(() => _position = position);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        _showControlsTemporarily();
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Player
              if (_isInitialized && _controller != null)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),

              // Loading indicator
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),

              // Controls overlay
              if (_showControls && _isInitialized)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top controls (if needed)
                        Container(),
                        
                        // Center play button
                        Center(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        
                        // Bottom controls
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Progress slider
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  value: _duration.inMilliseconds > 0
                                      ? _position.inMilliseconds.toDouble().clamp(
                                          0.0, 
                                          _duration.inMilliseconds.toDouble()
                                        )
                                      : 0.0,
                                  min: 0.0,
                                  max: _duration.inMilliseconds.toDouble(),
                                  activeColor: Colors.red,
                                  inactiveColor: Colors.white.withOpacity(0.3),
                                  onChanged: _onSliderChanged,
                                  onChangeEnd: _onSliderChangeEnd,
                                ),
                              ),
                              
                              // Time labels
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Error placeholder
              if (!_isLoading && !_isInitialized)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không thể tải video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _initializeVideo,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
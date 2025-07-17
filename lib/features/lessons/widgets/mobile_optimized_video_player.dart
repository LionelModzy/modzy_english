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
  final bool enableAutoPlay;
  final Function(double progress, Duration position, Duration total)? onProgressUpdate;
  final VoidCallback? onTap;
  final Duration? initialPosition;

  const MobileOptimizedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.width = double.infinity,
    this.height = 200,
    this.enableAutoPlay = false,
    this.onProgressUpdate,
    this.onTap,
    this.initialPosition,
  });

  @override
  State<MobileOptimizedVideoPlayer> createState() => _MobileOptimizedVideoPlayerState();
}

class _MobileOptimizedVideoPlayerState extends State<MobileOptimizedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _showControls = true;
  bool _isBuffering = false;
  
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  Timer? _hideControlsTimer;
  Timer? _progressUpdateTimer;
  Timer? _bufferingCheckTimer;
  
  // Mobile-specific optimizations
  bool _isMobile = false;
  bool _hasSetInitialPosition = false;
  Duration? _pendingSeekPosition;

  @override
  void initState() {
    super.initState();
    _checkPlatform();
    _initializeVideo();
  }

  void _checkPlatform() {
    _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressUpdateTimer?.cancel();
    _bufferingCheckTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() => _isLoading = true);
      
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Add error handling listener
      _controller!.addListener(_videoListener);
      
      await _controller!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
        _duration = _controller!.value.duration;
        _isLoading = false;
      });

      // Setup mobile-optimized progress tracking
      _setupProgressTracking();
      
      // Apply initial position if provided
      if (widget.initialPosition != null && widget.initialPosition!.inSeconds > 0) {
        _applyInitialPosition(widget.initialPosition!);
      }

      // Setup buffering check for mobile
      if (_isMobile) {
        _setupBufferingCheck();
      }

      if (widget.enableAutoPlay && !_hasSetInitialPosition) {
        _playVideo();
      }

    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    
    final VideoPlayerValue value = _controller!.value;
    
    setState(() {
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
    });
    
    if (value.hasError) {
      print('Video player error: ${value.errorDescription}');
    }
  }

  void _setupProgressTracking() {
    // Use different intervals for web vs mobile for better performance
    final interval = _isMobile 
        ? const Duration(milliseconds: 1000)  // Less frequent for mobile
        : const Duration(milliseconds: 500);
        
    _progressUpdateTimer = Timer.periodic(interval, (timer) {
      if (_controller != null && 
          _controller!.value.isInitialized && 
          _pendingSeekPosition == null) {
        
        final currentPosition = _controller!.value.position;
        final duration = _controller!.value.duration;
        
        if (duration.inMilliseconds > 0) {
          setState(() {
            _position = currentPosition;
          });

          final progress = currentPosition.inMilliseconds / duration.inMilliseconds;
          widget.onProgressUpdate?.call(
            progress.clamp(0.0, 1.0), 
            currentPosition, 
            duration
          );
        }
      }
    });
  }

  void _setupBufferingCheck() {
    _bufferingCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_controller != null && _controller!.value.isBuffering) {
        print('Video is buffering on mobile...');
      }
    });
  }

  void _applyInitialPosition(Duration position) {
    if (_controller == null || !_isInitialized) {
      _pendingSeekPosition = position;
      return;
    }
    
    _hasSetInitialPosition = true;
    
    // On mobile, add extra delay to ensure stability
    final delay = _isMobile ? const Duration(seconds: 2) : const Duration(milliseconds: 500);
    
    Future.delayed(delay, () {
      if (mounted && _controller != null) {
        _controller!.seekTo(position).then((_) {
          _pendingSeekPosition = null;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Khôi phục vị trí: ${_formatDuration(position)}'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }).catchError((error) {
          print('Error seeking to position: $error');
          _pendingSeekPosition = null;
        });
      }
    });
  }

  Future<void> _playVideo() async {
    if (_controller == null || !_isInitialized) return;
    
    try {
      await _controller!.play();
      setState(() => _isPlaying = true);
      _startHideControlsTimer();
    } catch (e) {
      print('Error playing video: $e');
    }
  }

  Future<void> _pauseVideo() async {
    if (_controller == null || !_isInitialized) return;
    
    try {
      await _controller!.pause();
      setState(() => _isPlaying = false);
      _showControlsTemporarily();
    } catch (e) {
      print('Error pausing video: $e');
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying && !_isBuffering) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _pauseVideo();
    } else {
      await _playVideo();
    }
  }

  void _onSliderChanged(double value) {
    if (_controller == null || !_isInitialized) return;
    
    final position = Duration(milliseconds: value.toInt());
    setState(() {
      _position = position;
      _pendingSeekPosition = position;
    });
  }

  void _onSliderChangeEnd(double value) {
    if (_controller == null || !_isInitialized) return;
    
    final position = Duration(milliseconds: value.toInt());
    
    _controller!.seekTo(position).then((_) {
      _pendingSeekPosition = null;
    }).catchError((error) {
      print('Error seeking: $error');
      _pendingSeekPosition = null;
    });
  }

  // Public methods for external control
  void togglePlayPause() => _togglePlayPause();
  
  void play() => _playVideo();
  
  void pause() => _pauseVideo();
  
  void seekTo(double progress) {
    if (_duration.inMilliseconds > 0) {
      final position = Duration(milliseconds: (progress * _duration.inMilliseconds).toInt());
      _applyInitialPosition(position);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),

              // Loading indicator
              if (_isLoading || _isBuffering)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Đang tải video...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

              // Controls overlay
              if (_showControls && _isInitialized && !_isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top section (empty for now)
                        Container(height: 50),
                        
                        // Center play button
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        
                        // Bottom controls
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // Progress slider with better mobile handling
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: _isMobile ? 4 : 3,
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: _isMobile ? 8 : 6,
                                  ),
                                  overlayShape: RoundSliderOverlayShape(
                                    overlayRadius: _isMobile ? 16 : 12,
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_pendingSeekPosition != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, 
                                        vertical: 4
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Đang tìm...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    _formatDuration(_duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
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
                        const Text(
                          'Vui lòng kiểm tra kết nối mạng',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
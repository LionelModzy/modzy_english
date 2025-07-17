import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class LessonMediaWidget extends StatefulWidget {
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enableAutoPlay;
  final bool showControls;
  final Function(double progress, Duration position, Duration total)? onProgressUpdate;
  
  const LessonMediaWidget({
    super.key,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.width = double.infinity,
    this.height = 200,
    this.borderRadius,
    this.onTap,
    this.enableAutoPlay = false,
    this.showControls = true,
    this.onProgressUpdate,
  });

  @override
  State<LessonMediaWidget> createState() => LessonMediaWidgetState();
}

class LessonMediaWidgetState extends State<LessonMediaWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  AudioPlayer? _audioPlayer;
  bool _isVideoPlaying = false;
  bool _isAudioPlaying = false;
  bool _isLoading = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializeMedia() async {
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      await _initializeVideo();
    } else if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      await _initializeAudio();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() => _isLoading = true);
      
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      await _videoController!.initialize();

      // Create Chewie controller for better UI & fullscreen support
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        aspectRatio: _videoController!.value.aspectRatio == 0
            ? 16 / 9
            : _videoController!.value.aspectRatio,
        autoPlay: widget.enableAutoPlay,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
      );
      
      _videoController!.addListener(() {
        setState(() {
          _isVideoPlaying = _videoController!.value.isPlaying;
          
          // Update progress
          if (_videoController!.value.isInitialized && _videoController!.value.duration.inSeconds > 0) {
            final position = _videoController!.value.position;
            final duration = _videoController!.value.duration;
            final progress = position.inSeconds / duration.inSeconds;
            if (widget.onProgressUpdate != null) {
              widget.onProgressUpdate!(progress.clamp(0.0, 1.0), position, duration);
            }
          }
        });
      });
      
      if (widget.enableAutoPlay) {
        await _videoController!.play();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing video: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeAudio() async {
    try {
      setState(() => _isLoading = true);
      
      _audioPlayer = AudioPlayer();
      
      _audioPlayer!.onDurationChanged.listen((duration) {
        setState(() {
          _audioDuration = duration;
        });
      });
      
      _audioPlayer!.onPositionChanged.listen((position) {
        setState(() {
          _audioPosition = position;
          
          // Update progress
          if (_audioDuration.inSeconds > 0) {
            final progress = position.inSeconds / _audioDuration.inSeconds;
            if (widget.onProgressUpdate != null) {
              widget.onProgressUpdate!(progress.clamp(0.0, 1.0), position, _audioDuration);
            }
          }
        });
      });
      
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        setState(() {
          _isAudioPlaying = state == PlayerState.playing;
        });
      });
      
      _audioPlayer!.onPlayerComplete.listen((_) {
        // Reset position when audio completes
        setState(() {
          _audioPosition = Duration.zero;
          _isAudioPlaying = false;
        });
        
        if (widget.onProgressUpdate != null) {
          widget.onProgressUpdate!(1.0, _audioDuration, _audioDuration);
        }
      });
      
      // Preload audio source
      await _audioPlayer!.setSourceUrl(widget.audioUrl!);
      
      if (widget.enableAutoPlay) {
        await _playAudio();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing audio: $e');
      setState(() => _isLoading = false);
    }
  }
  
  // Public methods to control media playback
  
  void togglePlayPause() {
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _playPauseVideo();
    } else if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      _playAudio();
    }
  }
  
  void pause() {
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
    
    if (_audioPlayer != null && _isAudioPlaying) {
      _audioPlayer!.pause();
    }
  }
  
  void play() {
    if (_videoController != null && !_videoController!.value.isPlaying) {
      _videoController!.play();
    }
    
    if (_audioPlayer != null && !_isAudioPlaying) {
      _playAudio();
    }
  }
  
  void seekTo(double progress) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final duration = _videoController!.value.duration;
      final position = duration * progress;
      _videoController!.seekTo(position);
    }
    
    if (_audioPlayer != null && _audioDuration.inSeconds > 0) {
      final position = _audioDuration * progress;
      _audioPlayer!.seek(position);
    }
  }
  
  void skipForward() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final currentPosition = _videoController!.value.position;
      _videoController!.seekTo(currentPosition + const Duration(seconds: 5));
    }
    
    if (_audioPlayer != null) {
      final newPosition = _audioPosition + const Duration(seconds: 5);
      if (newPosition <= _audioDuration) {
        _audioPlayer!.seek(newPosition);
      } else {
        _audioPlayer!.seek(_audioDuration);
      }
    }
  }
  
  void skipBackward() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final currentPosition = _videoController!.value.position;
      final newPosition = currentPosition - const Duration(seconds: 5);
      _videoController!.seekTo(newPosition.inSeconds > 0 ? newPosition : Duration.zero);
    }
    
    if (_audioPlayer != null) {
      final newPosition = _audioPosition - const Duration(seconds: 5);
      _audioPlayer!.seek(newPosition.inSeconds > 0 ? newPosition : Duration.zero);
    }
  }

  Future<void> _playPauseVideo() async {
    if (_videoController == null) return;
    
    if (_videoController!.value.isPlaying) {
      await _videoController!.pause();
    } else {
      await _videoController!.play();
    }
  }

  Future<void> _playAudio() async {
    if (_audioPlayer == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_isAudioPlaying) {
        await _audioPlayer!.pause();
      } else {
        if (_audioPosition > Duration.zero) {
          // Resume from current position
          await _audioPlayer!.resume();
        } else {
          // Start from beginning
          await _audioPlayer!.play(UrlSource(widget.audioUrl!));
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
    } finally {
      setState(() => _isLoading = false);
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
    // Priority: video > image > audio > placeholder
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      return _buildVideoPlayer();
    } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return _buildImage();
    } else if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      return _buildAudioPlayer();
    } else {
      return _buildDefaultPlaceholder();
    }
  }

  Widget _buildVideoPlayer() {
    if (_chewieController == null || !_videoController!.value.isInitialized) {
      return _buildVideoPlaceholder();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          child: Chewie(controller: _chewieController!),
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withOpacity(0.8),
              Colors.red.withOpacity(0.6),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Loading or play button
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
            ),
            
            // Video label
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.videocam, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return GestureDetector(
      onTap: widget.onTap ?? _playAudio,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.8),
              Colors.blue,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Audio wave background
            Positioned.fill(
              child: CustomPaint(
                painter: _AudioWavesPainter(),
              ),
            ),
            
            // Audio label
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.audiotrack, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Audio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Centered control box
            Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Skip backward
                      InkWell(
                        onTap: skipBackward,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.replay_5,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Play/Pause button
                      InkWell(
                        onTap: _playAudio,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  strokeWidth: 3,
                                )
                              : Icon(
                                  _isAudioPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.blue,
                                  size: 36,
                                ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Skip forward
                      InkWell(
                        onTap: skipForward,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.forward_5,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress slider
                  if (_audioDuration.inSeconds > 0)
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _audioPosition.inMilliseconds.toDouble(),
                        min: 0,
                        max: _audioDuration.inMilliseconds.toDouble(),
                        activeColor: Colors.white,
                        inactiveColor: Colors.white.withOpacity(0.3),
                        onChanged: (value) {
                          _audioPlayer?.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                  
                  // Time display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_audioPosition),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        _formatDuration(_audioDuration),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              Image.network(
                widget.imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultPlaceholder();
                },
              ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
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

  Widget _buildDefaultPlaceholder() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_rounded,
              size: 48,
              color: AppColors.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Bài Học',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for audio waves
class _AudioWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    const waveHeight = 20.0;
    const waveLength = 40.0;
    
    for (double x = 0; x < size.width; x += waveLength) {
      for (double y = 0; y < size.height; y += waveHeight * 2) {
        path.moveTo(x, y);
        path.quadraticBezierTo(
          x + waveLength / 2, 
          y + waveHeight, 
          x + waveLength, 
          y
        );
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 
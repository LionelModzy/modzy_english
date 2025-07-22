import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/learning_progress_service.dart';
import '../../../models/lesson_model.dart';
import '../widgets/lesson_media_widget.dart';
import '../widgets/unified_video_player.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class LessonPlayerScreen extends StatefulWidget {
  final LessonModel lesson;
  final LessonSection section;
  final int sectionIndex;
  
  const LessonPlayerScreen({
    super.key, 
    required this.lesson,
    required this.section,
    required this.sectionIndex,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isCompleted = false;
  bool _isProgressSaved = false;
  DateTime? _startTime;
  Timer? _progressTimer;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
    
    // Start tracking time when lesson starts
    _startTime = DateTime.now();
    _startProgressTimer();
    
    // Load saved progress
    _loadSavedProgress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }
  
  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Update UI every second if needed
        });
      }
    });
  }

  String _getVietnameseCategory(String englishCategory) {
    switch (englishCategory) {
      case 'Grammar': return 'Ngữ pháp';
      case 'Vocabulary': return 'Từ vựng';
      case 'Speaking': return 'Nói';
      case 'Listening': return 'Nghe';
      case 'Writing': return 'Viết';
      default: return englishCategory;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Grammar': return const Color(0xFF8B5CF6);
      case 'Vocabulary': return const Color(0xFF06B6D4);
      case 'Speaking': return const Color(0xFF10B981);
      case 'Listening': return const Color(0xFFF59E0B);
      case 'Writing': return const Color(0xFFEF4444);
      default: return AppColors.primary;
    }
  }

  Color _getSectionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video': return const Color(0xFFEF4444);
      case 'audio': return const Color(0xFF06B6D4);
      case 'exercise': return const Color(0xFF10B981);
      case 'text':
      default: return const Color(0xFF8B5CF6);
    }
  }

  String _getSectionTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'video': return 'Video';
      case 'audio': return 'Âm thanh';
      case 'exercise': return 'Bài tập';
      case 'text':
      default: return 'Văn bản';
    }
  }

  void _onVideoComplete() {
    if (!_isCompleted) {
      setState(() => _isCompleted = true);
      _saveProgress();
      _showCompletionDialog();
    }
  }

  Future<void> _loadSavedProgress() async {
    try {
      final progress = await LearningProgressService.getLessonSectionMediaProgress(
        lessonId: widget.lesson.id,
        sectionIndex: widget.sectionIndex,
      );
      
      if (progress != null && mounted) {
        setState(() {
          _isCompleted = progress['completed'] ?? false;
          if (progress['positionInSeconds'] != null) {
            _currentPosition = Duration(seconds: progress['positionInSeconds']);
          }
          if (progress['durationInSeconds'] != null) {
            _totalDuration = Duration(seconds: progress['durationInSeconds']);
          }
        });
      }
    } catch (e) {
      print('Error loading saved progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final progress = _totalDuration.inSeconds > 0 
          ? _currentPosition.inSeconds / _totalDuration.inSeconds
          : 0.0;
      
      await LearningProgressService.trackLessonSectionMediaProgress(
        lessonId: widget.lesson.id,
        sectionIndex: widget.sectionIndex,
        mediaType: widget.section.type.toLowerCase(),
        positionInSeconds: _currentPosition.inSeconds,
        durationInSeconds: _totalDuration.inSeconds,
        progress: progress,
        completed: _isCompleted,
      );
      
      if (mounted) {
        setState(() {
          _isProgressSaved = true;
        });
        
        // Reset indicator after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isProgressSaved = false;
            });
          }
        });
      }
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  void _onProgressUpdate(Duration position, Duration total) {
    setState(() {
      _currentPosition = position;
      _totalDuration = total;
    });
    
    // Save progress periodically (every 5 seconds)
    if (position.inSeconds % 5 == 0 && position.inSeconds > 0) {
      _saveProgress();
    }
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hoàn thành!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bạn đã hoàn thành phần học này thành công!',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (widget.sectionIndex < widget.lesson.sections.length - 1) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getCategoryColor(widget.lesson.category).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: _getCategoryColor(widget.lesson.category),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tiếp theo: ${widget.lesson.sections[widget.sectionIndex + 1].title}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getCategoryColor(widget.lesson.category),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _restartSection,
            icon: const Icon(Icons.replay),
            label: const Text('Học lại'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (widget.sectionIndex < widget.lesson.sections.length - 1) {
                _navigateToNextSection();
              } else {
                Navigator.pop(context, true); // Go back to lesson list
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCategoryColor(widget.lesson.category),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              widget.sectionIndex < widget.lesson.sections.length - 1 
                  ? Icons.arrow_forward 
                  : Icons.check_circle
            ),
            label: Text(
              widget.sectionIndex < widget.lesson.sections.length - 1 
                  ? 'Tiếp theo' 
                  : 'Hoàn thành'
            ),
          ),
        ],
      ),
    );
  }
  
  void _restartSection() async {
    setState(() {
      _isCompleted = false;
      _startTime = DateTime.now();
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero; // Reset luôn duration
    });
    
    // Save reset progress
    await _saveProgress();
    
    // Close dialog if open
    Navigator.of(context).popUntil((route) => route.settings.name != '/dialog');
    
    // Force reload the screen to reset video
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LessonPlayerScreen(
          lesson: widget.lesson,
          section: widget.section,
          sectionIndex: widget.sectionIndex,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _navigateToNextSection() {
    if (widget.sectionIndex < widget.lesson.sections.length - 1) {
      // Reset progress khi chuyển section
      setState(() {
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LessonPlayerScreen(
            lesson: widget.lesson,
            section: widget.lesson.sections[widget.sectionIndex + 1],
            sectionIndex: widget.sectionIndex + 1,
          ),
        ),
      );
    } else {
      Navigator.pop(context, true);
    }
  }
  
  void _navigateToPreviousSection() {
    if (widget.sectionIndex > 0) {
      // Reset progress khi chuyển section
      setState(() {
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LessonPlayerScreen(
            lesson: widget.lesson,
            section: widget.lesson.sections[widget.sectionIndex - 1],
            sectionIndex: widget.sectionIndex - 1,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Media player area
                  Expanded(
                    child: _buildMediaPlayer(),
                  ),
                  
                  // Simple progress bar
                  if (widget.section.type.toLowerCase() == 'video' || 
                      widget.section.type.toLowerCase() == 'audio')
                    _buildProgressBar(),
                  
                  // Navigation controls
                  _buildNavigationControls(),
                ],
              ),
              
              // Top overlay with back button and info
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopOverlay(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 
        MediaQuery.of(context).padding.top + 10, 
        20, 
        20
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Row(
        children: [
          // Back button with better styling
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.section.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSectionTypeColor(widget.section.type),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getSectionTypeText(widget.section.type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Hoàn thành',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_isProgressSaved) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.save,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Đã lưu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _totalDuration.inSeconds > 0 
        ? _currentPosition.inSeconds / _totalDuration.inSeconds
        : 0.0;
        
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bar with better styling
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.lesson.category),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_currentPosition),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    _formatDuration(_totalDuration),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.schedule,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPlayer() {
    if (widget.section.type.toLowerCase() == 'video') {
      return _buildVideoPlayer();
    } else if (widget.section.type.toLowerCase() == 'audio') {
      return _buildAudioPlayer();
    } else if (widget.section.type.toLowerCase() == 'exercise') {
      return _buildExerciseContent();
    } else {
      return _buildTextContent();
    }
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: widget.section.mediaUrl != null && widget.section.mediaUrl!.isNotEmpty
        ? UnifiedVideoPlayer(
            videoUrl: widget.section.mediaUrl!,
            width: double.infinity,
            height: double.infinity,
            onVideoComplete: _onVideoComplete,
            onProgressUpdate: _onProgressUpdate,
          )
        : _buildVideoPlaceholder(),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(widget.lesson.category).withOpacity(0.3),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 70,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Video không khả dụng',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    // Use the LessonMediaWidget for audio playback
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getCategoryColor(widget.lesson.category).withOpacity(0.8),
            _getCategoryColor(widget.lesson.category),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio visualization or player - increased size
          Container(
            height: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
            width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
            constraints: const BoxConstraints(
              minHeight: 280,
              maxHeight: 400,
              minWidth: 320,
            ),
            child: widget.section.mediaUrl != null && widget.section.mediaUrl!.isNotEmpty
              ? LessonMediaWidget(
                  audioUrl: widget.section.mediaUrl,
                  width: double.infinity,
                  height: double.infinity,
                  enableAutoPlay: true,
                  showControls: true,
                  onProgressUpdate: (progress, position, total) {
                    _onProgressUpdate(position, total);
                    // Check if audio completed
                    if (progress >= 0.95 && !_isCompleted) {
                      _onVideoComplete();
                    }
                  },
                )
              : _buildAudioPlaceholder(),
          ),
          
          const SizedBox(height: 30),
          
          // Title and description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  widget.section.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.section.content.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.section.content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlaceholder() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 60,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Âm thanh không khả dụng',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[50]!,
            Colors.green[100]!,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with exercise icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.section.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Bài tập thực hành',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Exercise content
              if (widget.section.content.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hướng dẫn bài tập:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.section.content,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black87,
                          height: 1.7,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Interactive elements placeholder
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green[200]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.construction,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tính năng bài tập tương tác',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tính năng này đang được phát triển. Bài tập tương tác sẽ sớm có mặt!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (!_isCompleted) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Mark as completed for now
                            setState(() {
                              _isCompleted = true;
                              _currentPosition = _totalDuration; // Set to total duration
                            });
                            await _saveProgress();
                            _showCompletionDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Bắt đầu học'),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _restartSection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.replay),
                              label: const Text('Học lại'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (widget.sectionIndex < widget.lesson.sections.length - 1) {
                                  _navigateToNextSection();
                                } else {
                                  Navigator.pop(context, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Hoàn thành'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green[200]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 48,
                        color: Colors.green[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nội dung bài tập sẽ được hiển thị ở đây',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Action buttons for text content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                                         if (!_isCompleted) ...[
                       ElevatedButton.icon(
                         onPressed: () async {
                           setState(() {
                             _isCompleted = true;
                             _currentPosition = _totalDuration;
                           });
                           await _saveProgress();
                           _showCompletionDialog();
                         },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getCategoryColor(widget.lesson.category),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Bắt đầu học'),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _restartSection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.replay),
                              label: const Text('Học lại'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (widget.sectionIndex < widget.lesson.sections.length - 1) {
                                  _navigateToNextSection();
                                } else {
                                  Navigator.pop(context, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getCategoryColor(widget.lesson.category),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Hoàn thành'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[100]!,
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and category
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getCategoryColor(widget.lesson.category).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(widget.lesson.category),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.article_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.section.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(widget.lesson.category),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getSectionTypeText(widget.section.type),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getCategoryColor(widget.lesson.category).withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Content
              if (widget.section.content.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.section.content,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.black87,
                      height: 1.7,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nội dung văn bản sẽ được hiển thị ở đây',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Action buttons for text content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (!_isCompleted) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _isCompleted = true;
                            _currentPosition = _totalDuration;
                          });
                          await _saveProgress();
                          _showCompletionDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getCategoryColor(widget.lesson.category),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Bắt đầu học'),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _restartSection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.replay),
                              label: const Text('Học lại'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (widget.sectionIndex < widget.lesson.sections.length - 1) {
                                  _navigateToNextSection();
                                } else {
                                  Navigator.pop(context, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getCategoryColor(widget.lesson.category),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Hoàn thành'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Section indicator and progress
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(widget.lesson.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getCategoryColor(widget.lesson.category),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: _getCategoryColor(widget.lesson.category),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.sectionIndex + 1}/${widget.lesson.sections.length}',
                        style: TextStyle(
                          color: _getCategoryColor(widget.lesson.category),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isProgressSaved) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.save,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.sectionIndex > 0 ? _navigateToPreviousSection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.skip_previous, size: 20),
                    label: const Text('Trước'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Restart button (only show when completed)
                if (_isCompleted)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _restartSection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.replay, size: 20),
                      label: const Text('Học lại'),
                    ),
                  ),
                
                if (_isCompleted) const SizedBox(width: 12),
                
                // Next/Complete button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCompleted 
                        ? (widget.sectionIndex < widget.lesson.sections.length - 1 
                            ? _navigateToNextSection 
                            : () => Navigator.pop(context, true))
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted 
                          ? _getCategoryColor(widget.lesson.category) 
                          : Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      widget.sectionIndex < widget.lesson.sections.length - 1 
                          ? Icons.skip_next 
                          : Icons.check_circle,
                      size: 20,
                    ),
                    label: Text(
                      widget.sectionIndex < widget.lesson.sections.length - 1 
                          ? 'Tiếp' 
                          : 'Hoàn thành'
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
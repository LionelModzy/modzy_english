import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/learning_progress_service.dart';
import '../../../models/lesson_model.dart';
import '../widgets/lesson_media_widget.dart';

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
  
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isCompleted = false;
  double _progress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero; // Remove default duration
  
  // Key for LessonMediaWidget
  final _mediaWidgetKey = GlobalKey<LessonMediaWidgetState>();
  
  // Timer for periodic progress tracking
  late bool _hasLoadedSavedPosition = false;
  
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
    
    // Load saved completion status first
    _checkCompletionStatus();
    
    // Wait for animations to complete before loading media
    Future.delayed(const Duration(milliseconds: 300), () {
      _loadMedia();
    });
    
    // Setup periodic progress tracker
    _setupPeriodicProgressTracker();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Save progress before disposing
    _saveMediaProgress();
    super.dispose();
  }
  
  void _setupPeriodicProgressTracker() {
    // Save progress every 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _saveMediaProgress();
        _setupPeriodicProgressTracker();
      }
    });
  }
  
  Future<void> _saveMediaProgress() async {
    if (_mediaWidgetKey.currentState != null && widget.section.mediaUrl != null) {
      final mediaType = widget.section.type.toLowerCase();
      if (mediaType == 'video' || mediaType == 'audio') {
        await LearningProgressService.trackLessonSectionMediaProgress(
          lessonId: widget.lesson.id,
          sectionIndex: widget.sectionIndex,
          mediaType: mediaType,
          positionInSeconds: _currentPosition.inSeconds,
          durationInSeconds: _totalDuration.inSeconds,
          progress: _progress,
          completed: _progress >= 0.95, // Consider completed if >95% watched/listened
        );
      }
    }
  }

  Future<void> _checkCompletionStatus() async {
    try {
      final savedProgress = await LearningProgressService.getLessonSectionMediaProgress(
        lessonId: widget.lesson.id,
        sectionIndex: widget.sectionIndex,
      );
      
      if (savedProgress != null) {
        setState(() {
          _isCompleted = savedProgress['completed'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking completion status: $e');
    }
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    
    // Try to load saved media progress
    if (widget.section.mediaUrl != null) {
      try {
        final savedProgress = await LearningProgressService.getLessonSectionMediaProgress(
          lessonId: widget.lesson.id,
          sectionIndex: widget.sectionIndex,
        );
        
        if (savedProgress != null) {
          // Extract saved fields with proper types
          final double savedProg = (savedProgress['progress'] ?? 0.0).toDouble();
          final int savedPositionSec = savedProgress['positionInSeconds'] ?? 0;
          final int? savedDurationSec = savedProgress['durationInSeconds'];
          final bool savedCompleted = savedProgress['completed'] ?? false;

          // Only restore progress when it is meaningful (<95%) and not marked completed
          final bool shouldRestore = !savedCompleted && savedProg < 0.95 && savedProg > 0.05;

          if (shouldRestore) {
            // Store saved position but don't apply immediately
            _hasLoadedSavedPosition = true;
            _progress = savedProg;
            _currentPosition = Duration(seconds: savedPositionSec);
            if (savedDurationSec != null) {
              _totalDuration = Duration(seconds: savedDurationSec);
            }

            // Apply saved position after media has fully loaded (with delay)
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _mediaWidgetKey.currentState != null) {
                _mediaWidgetKey.currentState!.seekTo(_progress);
                _hasLoadedSavedPosition = false;
                
                // Show progress restoration notification
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã khôi phục tiến độ tại ${(_progress * 100).toInt()}%'),
                    backgroundColor: _getCategoryColor(widget.lesson.category),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            });
          } else {
            // Either completed or near completion -> start fresh
            _hasLoadedSavedPosition = false;
            _progress = 0.0;
            _currentPosition = Duration.zero;
            _totalDuration = Duration.zero;

            // Also treat the section as not completed in the UI so user can replay normally
            setState(() {
              _isCompleted = false;
            });
          }
        }
      } catch (e) {
        print('Error loading saved media progress: $e');
      }
    }
    
    setState(() => _isLoading = false);
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

  void _togglePlayPause() {
    if (_mediaWidgetKey.currentState != null) {
      _mediaWidgetKey.currentState!.togglePlayPause();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _updateProgress(double progress, Duration position, Duration total) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _currentPosition = position;
        _totalDuration = total;
        
        // Mark as completed if progress is >= 95%
        if (progress >= 0.95 && !_isCompleted) {
          _isCompleted = true;
          _showCompletionDialog();
        }
      });
      
      // Remove the immediate seekTo call that was causing issues
    }
  }
  
  void _showCompletionDialog() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hoàn thành!'),
            content: const Text('Bạn đã hoàn thành phần học này.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _restartSection();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(widget.lesson.category),
                ),
                child: const Text('Học lại'),
              ),
            ],
          ),
        );
      }
    });
  }
  
  void _restartSection() {
    if (_mediaWidgetKey.currentState != null) {
      _mediaWidgetKey.currentState!.seekTo(0.0);
      _mediaWidgetKey.currentState!.play();
      setState(() {
        _isCompleted = false;
        _progress = 0.0;
        _currentPosition = Duration.zero;
      });
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
                  
                  // Progress tracking area
                  _buildProgressTrackingArea(),
                  
                  // Controls area - conditionally show only for text content
                  if (widget.section.type.toLowerCase() == 'text')
                    _buildControlsArea(),
                ],
              ),
              
              // Top overlay with back button and info
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopOverlay(),
              ),
              
              // Loading overlay
              if (_isLoading) _buildLoadingOverlay(),
              
              // Completed overlay (if needed)
              if (_isCompleted) _buildCompletedOverlay(),
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
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 28,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tùy chọn thêm')),
              );
            },
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressTrackingArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            _getCategoryColor(widget.lesson.category).withOpacity(0.2),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section progress
            Row(
              children: [
                Text(
                  'Phần ${widget.sectionIndex + 1}/${widget.lesson.sections.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          flex: ((widget.sectionIndex + 1) * 100 ~/ widget.lesson.sections.length),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 100 - ((widget.sectionIndex + 1) * 100 ~/ widget.lesson.sections.length),
                          child: Container(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Current section progress
            Row(
              children: [
                Icon(
                  widget.section.type.toLowerCase() == 'video'
                      ? Icons.videocam
                      : widget.section.type.toLowerCase() == 'audio'
                          ? Icons.audiotrack
                          : Icons.article,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.section.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(widget.lesson.category)),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                    color: _getCategoryColor(widget.lesson.category),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Time display for audio/video
            if (widget.section.type.toLowerCase() == 'audio' || widget.section.type.toLowerCase() == 'video')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ' / ${_formatDuration(_totalDuration)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
                      ElevatedButton.icon(
                        onPressed: () {
                          // Mark as completed for now
                          setState(() {
                            _isCompleted = true;
                            _progress = 1.0;
                          });
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
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Đánh dấu hoàn thành'),
                      ),
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
            ],
          ),
        ),
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
    // Use the LessonMediaWidget for video playback
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: widget.section.mediaUrl != null && widget.section.mediaUrl!.isNotEmpty
        ? Stack(
            children: [
              // Video player
              LessonMediaWidget(
                key: _mediaWidgetKey,
                videoUrl: widget.section.mediaUrl,
                width: double.infinity,
                height: double.infinity,
                enableAutoPlay: !_isCompleted, // Don't autoplay if already completed
                showControls: true,
                onProgressUpdate: _updateProgress,
              ),
              
              // Custom overlay for better UX
              if (_isCompleted)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Video đã hoàn thành!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tiến độ: ${(_progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _restartSection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getCategoryColor(widget.lesson.category),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24, 
                                  vertical: 12
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Xem lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
                  key: _mediaWidgetKey,
                  audioUrl: widget.section.mediaUrl,
                  width: double.infinity,
                  height: double.infinity,
                  enableAutoPlay: !_isCompleted, // Don't autoplay if already completed
                  showControls: true,
                  onProgressUpdate: _updateProgress,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsArea() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Previous button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
              tooltip: 'Quay lại',
            ),
            
            // Play/pause button - only show for text content
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _getCategoryColor(widget.lesson.category),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getCategoryColor(widget.lesson.category).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
                tooltip: _isPlaying ? 'Tạm dừng' : 'Phát',
              ),
            ),
            
            // Restart button
            IconButton(
              onPressed: _restartSection,
              icon: const Icon(Icons.replay, color: Colors.white70),
              tooltip: 'Học lại',
            ),
          ],
        ),
      ),
    );
  }

  void _completeSection() {
    // Stop media playback
    if (_mediaWidgetKey.currentState != null) {
      _mediaWidgetKey.currentState!.pause();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 Hoàn thành phần học!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn đã hoàn thành phần "${widget.section.title}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phần ${widget.sectionIndex + 1}/${widget.lesson.sections.length} hoàn thành',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to lesson detail with completion = true
            },
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCategoryColor(widget.lesson.category),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Đang tải nội dung...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedOverlay() {
    return Positioned(
      bottom: 80,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getCategoryColor(widget.lesson.category),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            const Text(
              'Đã hoàn thành',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: _restartSection,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Học lại',
                  style: TextStyle(
                    color: _getCategoryColor(widget.lesson.category),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/learning_progress_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/notes_service.dart';
import '../../../models/lesson_model.dart';
import '../../../models/vocab_model.dart';
import '../../../models/quiz_model.dart';
import 'lesson_player_screen.dart';
import '../../quiz/screens/quiz_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final LessonModel lesson;
  
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentSectionIndex = 0;
  bool _isPlaying = false;
  bool _isFavorite = false;
  double _progress = 0.0;
  
  // Timer related variables
  Timer? _learningTimer;
  int _elapsedSeconds = 0;
  int _totalLessonSeconds = 0;
  bool _isLessonCompleted = false;
  List<bool> _sectionCompletionStatus = [];
  
  // Section progress data
  final Map<int, Map<String, dynamic>> _sectionProgress = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
    
    // Initialize lesson timer data
    _totalLessonSeconds = widget.lesson.estimatedDuration * 60; // Convert minutes to seconds
    _sectionCompletionStatus = List.filled(widget.lesson.sections.length, false);
    
    _animationController.forward();
    _loadLessonProgress();
    _checkFavoriteStatus();
  }

  // Load existing lesson progress
  Future<void> _loadLessonProgress() async {
    try {
      final progress = await LearningProgressService.getLessonProgress(widget.lesson.id);
      if (progress != null) {
        setState(() {
          _elapsedSeconds = progress['timeSpent'] ?? 0;
          _progress = (progress['completionPercentage'] ?? 0.0) / 100.0;
          if (_progress >= 1.0) {
            _isLessonCompleted = true;
            _sectionCompletionStatus = List.filled(widget.lesson.sections.length, true);
          } else {
            // Calculate current section based on progress
            _currentSectionIndex = (_progress * widget.lesson.sections.length).floor();
            if (_currentSectionIndex >= widget.lesson.sections.length) {
              _currentSectionIndex = widget.lesson.sections.length - 1;
            }
            // Mark completed sections
            for (int i = 0; i < _currentSectionIndex; i++) {
              _sectionCompletionStatus[i] = true;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading lesson progress: $e');
    }
  }

  // Check if lesson is in favorites
  Future<void> _checkFavoriteStatus() async {
    try {
      final favorites = await FavoritesService.getFavoriteLessons();
      setState(() {
        _isFavorite = favorites.any((lesson) => lesson.id == widget.lesson.id);
      });
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _learningTimer?.cancel();
    super.dispose();
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

  String _getVietnameseDifficulty(String englishDifficulty) {
    switch (englishDifficulty) {
      case 'Beginner': return 'Cơ bản';
      case 'Elementary': return 'Sơ cấp';
      case 'Intermediate': return 'Trung cấp';
      case 'Upper Intermediate': return 'Trung cấp cao';
      case 'Advanced': return 'Nâng cao';
      default: return 'Cơ bản';
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

  // Format time in MM:SS format
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Start the learning timer
  void _startLearningTimer() {
    _learningTimer?.cancel();
    _learningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        
        // Check if lesson is completed by time
        if (_elapsedSeconds >= _totalLessonSeconds) {
          _completeLessonByTime();
        }
        
        // Auto advance sections based on time distribution
        _checkSectionProgress();
      });
    });
  }

  // Stop the learning timer
  void _stopLearningTimer() {
    _learningTimer?.cancel();
    // Save progress when stopping
    if (_elapsedSeconds > 0) {
      _trackLessonProgress();
    }
  }

  // Pause/Resume learning timer
  void _toggleLearningTimer() {
    if (_elapsedSeconds == 0 && !_isPlaying) {
      // Show start lesson dialog if first time starting
      _showStartLessonDialog();
    } else {
      // Continue/pause existing session
      if (_isPlaying) {
        _stopLearningTimer();
      } else {
        _startLearningTimer();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  // Complete lesson by time
  void _completeLessonByTime() {
    setState(() {
      _isLessonCompleted = true;
      _isPlaying = false;
      _progress = 1.0;
      _sectionCompletionStatus = List.filled(widget.lesson.sections.length, true);
    });
    _stopLearningTimer();
    
    // Track lesson completion
    _trackLessonProgress();
    
    // Show completion dialog
    _showLessonCompletionDialog();
  }

  // Track lesson progress
  Future<void> _trackLessonProgress() async {
    try {
      await LearningProgressService.trackLessonProgress(
        lessonId: widget.lesson.id,
        timeSpent: _elapsedSeconds,
        completionPercentage: (_progress * 100).round().toDouble(),
        details: {
          'lessonTitle': widget.lesson.title,
          'category': widget.lesson.category,
          'difficulty': widget.lesson.difficultyLevel,
          'currentSection': _currentSectionIndex,
          'sectionsCompleted': _sectionCompletionStatus.where((status) => status).length,
          'totalSections': widget.lesson.sections.length,
          'completedAt': _isLessonCompleted ? DateTime.now().millisecondsSinceEpoch : null,
        },
      );
    } catch (e) {
      print('Error tracking lesson progress: $e');
    }
  }

  // Check section progress based on time
  void _checkSectionProgress() {
    if (widget.lesson.sections.isEmpty) return;
    
    double timePerSection = _totalLessonSeconds / widget.lesson.sections.length;
    int expectedSection = (_elapsedSeconds / timePerSection).floor();
    
    if (expectedSection >= widget.lesson.sections.length) {
      expectedSection = widget.lesson.sections.length - 1;
    }
    
    // Auto advance to next section if time elapsed
    if (expectedSection > _currentSectionIndex && !_isLessonCompleted) {
      setState(() {
        _sectionCompletionStatus[_currentSectionIndex] = true;
        _currentSectionIndex = expectedSection;
        _progress = (_currentSectionIndex + 1) / widget.lesson.sections.length;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎓 Chuyển sang phần ${_currentSectionIndex + 1}: ${widget.lesson.sections[_currentSectionIndex].title}'),
          backgroundColor: _getCategoryColor(widget.lesson.category),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Show lesson completion dialog
  void _showLessonCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chúc mừng!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã hoàn thành bài học "${widget.lesson.title}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thời gian học: ${_formatTime(_elapsedSeconds)}',
              style: TextStyle(
                fontSize: 14,
                color: _getCategoryColor(widget.lesson.category),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Quay lại'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetLesson();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getCategoryColor(widget.lesson.category),
                    ),
                    child: const Text('Học lại', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Reset lesson to start over
  void _resetLesson() {
    setState(() {
      _elapsedSeconds = 0;
      _currentSectionIndex = 0;
      _progress = 0.0;
      _isPlaying = false;
      _isLessonCompleted = false;
      _sectionCompletionStatus = List.filled(widget.lesson.sections.length, false);
    });
    _stopLearningTimer();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Grammar': return Icons.menu_book_rounded;
      case 'Vocabulary': return Icons.library_books_rounded;
      case 'Speaking': return Icons.record_voice_over_rounded;
      case 'Listening': return Icons.headphones_rounded;
      case 'Writing': return Icons.edit_rounded;
      default: return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                backgroundColor: _getCategoryColor(widget.lesson.category),
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        if (_isFavorite) {
                          await FavoritesService.removeLessonFromFavorites(widget.lesson.id);
                        } else {
                          await FavoritesService.addLessonToFavorites(widget.lesson.id);
                        }
                        setState(() => _isFavorite = !_isFavorite);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isFavorite ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chia sẻ bài học')),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getCategoryColor(widget.lesson.category),
                          _getCategoryColor(widget.lesson.category).withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PatternPainter(),
                          ),
                        ),
                        
                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryIcon(widget.lesson.category),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getVietnameseCategory(widget.lesson.category),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Title
                              Text(
                                widget.lesson.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Stats row
                              Row(
                                children: [
                                  _buildStatBadge(
                                    Icons.schedule,
                                    widget.lesson.formattedDuration,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatBadge(
                                    Icons.signal_cellular_alt,
                                    _getVietnameseDifficulty(widget.lesson.difficultyLevelName),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatBadge(
                                    Icons.menu_book,
                                    '${widget.lesson.sections.length} phần',
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
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Nội Dung'),
                    Tab(text: 'Từ Vựng'),
                    Tab(text: 'Kiểm Tra'),
                    Tab(text: 'Ghi Chú'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildContentTab(),
                _buildVocabularyTab(),
                _buildQuizTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final currentIndex = _tabController.index;
    switch (currentIndex) {
      case 0:
        return _buildContentTab();
      case 1:
        return _buildVocabularyTab();
      case 2:
        return _buildQuizTab();
      case 3:
        return _buildNotesTab();
      default:
        return _buildContentTab();
    }
  }

  Widget _buildContentTab() {
    return Column(
        children: [
        // Progress tracking
        if (!_isLessonCompleted)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                  _getCategoryColor(widget.lesson.category).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getCategoryColor(widget.lesson.category).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: _getCategoryColor(widget.lesson.category),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tiến Độ Học Tập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    if (_isPlaying)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, color: Colors.green, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Đang học',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Time progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _totalLessonSeconds > 0 ? _elapsedSeconds / _totalLessonSeconds : 0,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCategoryColor(widget.lesson.category),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Time display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getCategoryColor(widget.lesson.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '/ ${_formatTime(_totalLessonSeconds)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Section progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phần ${_currentSectionIndex + 1}/${widget.lesson.sections.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toInt()}% hoàn thành',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
        // Section list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: widget.lesson.sections.length,
            itemBuilder: (context, index) {
              final section = widget.lesson.sections[index];
              final isCurrentSection = index == _currentSectionIndex;
              final isCompleted = _sectionProgress.containsKey(index) && 
                  (_sectionProgress[index]?['completed'] == true || 
                   (_sectionProgress[index]?['progress'] ?? 0) >= 0.95);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openSectionPlayer(section, index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                        color: isCurrentSection 
                            ? _getCategoryColor(widget.lesson.category).withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                border: Border.all(
                          color: isCurrentSection
                    ? _getCategoryColor(widget.lesson.category)
                              : Colors.grey.shade200,
                          width: isCurrentSection ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                  ),
                ],
              ),
                      child: Row(
                        children: [
                          // Section icon based on type
                          Container(
                            width: 50,
                            height: 50,
                  decoration: BoxDecoration(
                              color: _getSectionTypeColor(section.type).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                        child: Icon(
                                _getSectionTypeIcon(section.type),
                                color: _getSectionTypeColor(section.type),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Section info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                        color: _getSectionTypeColor(section.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getSectionTypeText(section.type),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getSectionTypeColor(section.type),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isCompleted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Đã hoàn thành',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                                    color: isCurrentSection
                                        ? _getCategoryColor(widget.lesson.category)
                                        : Colors.black,
                  ),
                ),
                                const SizedBox(height: 4),
                    Text(
                                  section.content.length > 100
                                      ? '${section.content.substring(0, 100)}...'
                                      : section.content,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                                
                                // Progress indicator for section
                                if (_sectionProgress.containsKey(index))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: _sectionProgress[index]?['progress'] ?? 0.0,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isCompleted 
                                                  ? Colors.green 
                                                  : _getCategoryColor(widget.lesson.category),
                                              ),
                                              minHeight: 4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${((_sectionProgress[index]?['progress'] ?? 0.0) * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                                            color: isCompleted ? Colors.green : Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                if (isCompleted) const SizedBox(height: 8),
                                if (isCompleted)
                                  InkWell(
                                    onTap: () => _openSectionPlayer(section, index),
                                    child: Text(
                                      'Học lại',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _getCategoryColor(widget.lesson.category),
                        ),
                      ),
                    ),
                  ],
                ),
                          ),
                          // Play/view button
                          Icon(
                            _getSectionTypeIcon(section.type) == Icons.menu_book_rounded
                                ? Icons.visibility_rounded
                                : Icons.play_circle_outline_rounded,
                            color: _getCategoryColor(widget.lesson.category),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVocabularyTab() {
    return widget.lesson.vocabulary.isEmpty
        ? _buildEmptyVocabularyState()
        : FutureBuilder<List<VocabularyModel>>(
            future: _loadLessonVocabulary(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildVocabularyErrorState(snapshot.error.toString());
              }

              final vocabularyDetails = snapshot.data ?? [];
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with stats
                    _buildVocabularyHeader(vocabularyDetails),
                    
                    const SizedBox(height: 20),
                    
                    // Vocabulary cards
                    ...vocabularyDetails.asMap().entries.map((entry) {
                      int index = entry.key;
                      VocabularyModel vocabulary = entry.value;
                      
                      return _buildEnhancedVocabularyCard(vocabulary, index);
                    }),
                    
                    // Add remaining words that might not be in vocabulary database
                    ..._buildMissingVocabularyCards(vocabularyDetails),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildEmptyVocabularyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 60,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có từ vựng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Từ vựng sẽ được cập nhật sớm',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
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

  Widget _buildVocabularyErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lỗi tải từ vựng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    error,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}), // Trigger rebuild
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<VocabularyModel>> _loadLessonVocabulary() async {
    try {
      final List<VocabularyModel> vocabularyDetails = [];
      
      for (String word in widget.lesson.vocabulary) {
        try {
          final vocabularies = await VocabularyService.searchVocabulary(word);
          final exactMatch = vocabularies.firstWhere(
            (vocab) => vocab.word.toLowerCase() == word.toLowerCase(),
            orElse: () => vocabularies.isNotEmpty ? vocabularies.first : throw Exception('Not found'),
          );
          vocabularyDetails.add(exactMatch);
        } catch (e) {
          // Word not found in vocabulary database, skip for now
          continue;
        }
      }
      
      return vocabularyDetails;
    } catch (e) {
      throw Exception('Không thể tải từ vựng: $e');
    }
  }

  Widget _buildVocabularyHeader(List<VocabularyModel> vocabularyDetails) {
    final totalWords = widget.lesson.vocabulary.length;
    final wordsWithDetails = vocabularyDetails.length;
    final wordsWithAudio = vocabularyDetails.where((v) => v.hasAudio).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(widget.lesson.category).withOpacity(0.1),
            _getCategoryColor(widget.lesson.category).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor(widget.lesson.category).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.library_books_rounded,
                color: _getCategoryColor(widget.lesson.category),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Từ Vựng Trong Bài',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Học và luyện tập các từ quan trọng',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getCategoryColor(widget.lesson.category),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildVocabularyStatCard(
                  'Tổng từ',
                  totalWords.toString(),
                  Icons.format_list_bulleted,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVocabularyStatCard(
                  'Chi tiết',
                  wordsWithDetails.toString(),
                  Icons.info_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVocabularyStatCard(
                  'Có audio',
                  wordsWithAudio.toString(),
                  Icons.volume_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedVocabularyCard(VocabularyModel vocabulary, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor(widget.lesson.category).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(widget.lesson.category).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Index number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(widget.lesson.category),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Word and pronunciation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vocabulary.word,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(widget.lesson.category),
                            ),
                          ),
                        ),
                        if (vocabulary.hasAudio)
                          _buildVocabularyAudioButton(vocabulary.word),
                      ],
                    ),
                    if (vocabulary.pronunciation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        vocabulary.pronunciation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Meaning and part of speech
          Row(
            children: [
              if (vocabulary.partOfSpeech.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vocabulary.partOfSpeech,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  vocabulary.meaning,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          // Examples
          if (vocabulary.examples.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ví dụ:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vocabulary.examples.first,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Action buttons
                            Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildVocabularyActionButton(
                              icon: Icons.info_outline,
                              label: 'Chi Tiết',
                              color: AppColors.primary,
                              onTap: () => _showEnhancedVocabularyDetail(vocabulary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildVocabularyActionButton(
                              icon: Icons.favorite_outline,
                              label: 'Yêu Thích',
                              color: Colors.red,
                              onTap: () => _addToFavorites(vocabulary.word),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _buildVocabularyActionButton(
                          icon: Icons.quiz_outlined,
                          label: 'Luyện Tập',
                          color: Colors.green,
                          onTap: () => _startVocabularyPractice(vocabulary),
                        ),
                      ),
                    ],
                  ),
        ],
      ),
    );
  }

  List<Widget> _buildMissingVocabularyCards(List<VocabularyModel> foundVocabulary) {
    final foundWords = foundVocabulary.map((v) => v.word.toLowerCase()).toSet();
    final missingWords = widget.lesson.vocabulary
        .where((word) => !foundWords.contains(word.toLowerCase()))
        .toList();
    
    if (missingWords.isEmpty) return [];
    
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Từ chưa có chi tiết',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Những từ này chưa có thông tin chi tiết trong hệ thống:',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missingWords.map((word) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    word,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildVocabularyCard(String word, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor(widget.lesson.category).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(widget.lesson.category).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Index number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(widget.lesson.category),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Word details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            word,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(widget.lesson.category),
                            ),
                          ),
                        ),
                        _buildVocabularyAudioButton(word),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Từ vựng trong bài học ${widget.lesson.title}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              // Learn button
              Expanded(
                child: _buildVocabularyActionButton(
                  icon: Icons.school_outlined,
                  label: 'Học Từ Này',
                  color: AppColors.primary,
                  onTap: () => _showVocabularyDetail(word),
                ),
              ),
              const SizedBox(width: 8),
              // Add to favorites
              Expanded(
                child: _buildVocabularyActionButton(
                  icon: Icons.favorite_outline,
                  label: 'Yêu Thích',
                  color: Colors.red,
                  onTap: () => _addToFavorites(word),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyAudioButton(String word) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _playVocabularyAudio(word),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.volume_up_rounded,
            size: 16,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildVocabularyActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playVocabularyAudio(String word) async {
    try {
      // Try to find vocabulary with audio
      final vocabularies = await VocabularyService.searchVocabulary(word);
      final vocabWithAudio = vocabularies.firstWhere(
        (vocab) => vocab.word.toLowerCase() == word.toLowerCase() && vocab.hasAudio,
        orElse: () => vocabularies.isNotEmpty ? vocabularies.first : VocabularyModel(
          id: '',
          word: word,
          pronunciation: '',
          meaning: '',
          examples: [],
          category: '',
          difficultyLevel: 1,
          synonyms: [],
          antonyms: [],
          partOfSpeech: '',
          lessonIds: [],
          createdAt: DateTime.now(),
          isActive: true,
          usageCount: 0,
          metadata: {},
        ),
      );
      
      if (vocabWithAudio.hasAudio) {
        // Play real audio from vocabulary
        final audioPlayer = AudioPlayer();
        await audioPlayer.play(UrlSource(vocabWithAudio.audioUrl!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔊 Phát âm: ${vocabWithAudio.word}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Fallback to TTS or mock
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔊 Phát âm: $word (Mock TTS)'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Fallback to mock TTS
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔊 Phát âm: $word (TTS)'),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showVocabularyDetail(String word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVocabularyDetailSheet(word),
    );
  }

  void _showEnhancedVocabularyDetail(VocabularyModel vocabulary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEnhancedVocabularyDetailSheet(vocabulary),
    );
  }

  void _startVocabularyPractice(VocabularyModel vocabulary) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎯 Bắt đầu luyện tập từ "${vocabulary.word}"'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Bắt đầu',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to vocabulary practice screen
            Navigator.pushNamed(context, '/vocabulary_practice', arguments: vocabulary);
          },
        ),
      ),
    );
  }

  Widget _buildVocabularyDetailSheet(String word) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(widget.lesson.category),
                        ),
                      ),
                      const Text(
                        'Chi tiết từ vựng',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mock vocabulary details
                  _buildDetailSection('Nghĩa', 'Nghĩa tiếng Việt của từ $word'),
                  _buildDetailSection('Phát âm', '/$word/'),
                  _buildDetailSection('Từ loại', 'Danh từ'),
                  _buildDetailSection('Ví dụ', 'This is an example sentence with $word.'),
                  _buildDetailSection('Từ đồng nghĩa', 'synonym1, synonym2'),
                  _buildDetailSection('Từ trái nghĩa', 'antonym1, antonym2'),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addToFavorites(word),
                          icon: const Icon(Icons.favorite_outline),
                          label: const Text('Thêm vào yêu thích'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addToStudyList(word),
                          icon: const Icon(Icons.library_add_outlined),
                          label: const Text('Thêm vào danh sách học'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedVocabularyDetailSheet(VocabularyModel vocabulary) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vocabulary.word,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(widget.lesson.category),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (vocabulary.hasAudio)
                            GestureDetector(
                              onTap: () => _playVocabularyAudio(vocabulary.word),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: const Icon(
                                  Icons.volume_up_rounded,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (vocabulary.pronunciation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          vocabulary.pronunciation,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (vocabulary.partOfSpeech.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                vocabulary.partOfSpeech,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(vocabulary.category).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vocabulary.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getCategoryColor(vocabulary.category),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meaning
                  _buildEnhancedDetailSection(
                    'Nghĩa',
                    vocabulary.meaning,
                    Icons.translate,
                    Colors.blue,
                  ),
                  
                  // Examples
                  if (vocabulary.examples.isNotEmpty)
                    _buildEnhancedDetailSection(
                      'Ví dụ',
                      vocabulary.examples.join('\n• '),
                      Icons.format_quote,
                      Colors.green,
                    ),
                  
                  // Synonyms
                  if (vocabulary.synonyms.isNotEmpty)
                    _buildEnhancedDetailSection(
                      'Từ đồng nghĩa',
                      vocabulary.synonyms.join(', '),
                      Icons.compare_arrows,
                      Colors.purple,
                    ),
                  
                  // Antonyms
                  if (vocabulary.antonyms.isNotEmpty)
                    _buildEnhancedDetailSection(
                      'Từ trái nghĩa',
                      vocabulary.antonyms.join(', '),
                      Icons.swap_horiz,
                      Colors.red,
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Usage stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.trending_up, color: Colors.blue, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              'Level ${vocabulary.difficultyLevel}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'Độ khó',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                        Column(
                          children: [
                            const Icon(Icons.school, color: Colors.green, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              '${vocabulary.usageCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'Lượt học',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                        Column(
                          children: [
                            Icon(
                              vocabulary.hasAudio ? Icons.volume_up : Icons.volume_off,
                              color: vocabulary.hasAudio ? Colors.orange : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vocabulary.hasAudio ? 'Có' : 'Không',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: vocabulary.hasAudio ? Colors.orange : Colors.grey,
                              ),
                            ),
                            const Text(
                              'Audio',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addToFavorites(vocabulary.word),
                          icon: const Icon(Icons.favorite_outline),
                          label: const Text('Yêu thích'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _startVocabularyPractice(vocabulary);
                          },
                          icon: const Icon(Icons.quiz_outlined),
                          label: const Text('Luyện tập'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addToStudyList(vocabulary.word),
                      icon: const Icon(Icons.library_add_outlined),
                      label: const Text('Thêm vào danh sách học'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailSection(String title, String content, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1F2937),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _addToFavorites(String word) async {
    try {
      // Find vocabulary by word
      final vocabularies = await VocabularyService.searchVocabulary(word);
      if (vocabularies.isNotEmpty) {
        final vocabulary = vocabularies.firstWhere(
          (v) => v.word.toLowerCase() == word.toLowerCase(),
          orElse: () => vocabularies.first,
        );
        
        final success = await FavoritesService.toggleVocabularyFavorite(vocabulary.id);
        if (success) {
          final isFavorite = await FavoritesService.isVocabularyInFavorites(vocabulary.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFavorite 
                ? '❤️ Đã thêm "$word" vào danh sách yêu thích'
                : '💔 Đã xóa "$word" khỏi danh sách yêu thích'),
              backgroundColor: isFavorite ? Colors.red : Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm vào yêu thích: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addToStudyList(String word) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📚 Đã thêm "$word" vào danh sách cần học'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildObjectivesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mục Tiêu Học Tập',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          
          ...widget.lesson.objectives.asMap().entries.map((entry) {
            int index = entry.key;
            String objective = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.lesson.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      objective,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 24),
          
          // Tags section
          if (widget.lesson.tags.isNotEmpty) ...[
            const Text(
              'Thẻ Từ Khóa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.lesson.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getCategoryColor(widget.lesson.category).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getCategoryColor(widget.lesson.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ghi Chú Của Tôi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddNoteDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Thêm ghi chú', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(widget.lesson.category),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes list
          FutureBuilder<List<Map<String, dynamic>>>(
            future: NotesService.getLessonNotes(widget.lesson.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Lỗi tải ghi chú',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final notes = snapshot.data ?? [];

              if (notes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có ghi chú',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thêm ghi chú để ghi nhớ những điểm quan trọng',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddNoteDialog(),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Thêm ghi chú đầu tiên', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getCategoryColor(widget.lesson.category),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: notes.map((note) => _buildNoteCard(note)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final DateTime createdAt = note['createdAt']?.toDate() ?? DateTime.now();
    final DateTime? updatedAt = note['updatedAt']?.toDate();
    final bool isEdited = updatedAt != null && updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Note header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.note,
                  color: _getCategoryColor(widget.lesson.category),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatNoteDate(createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getCategoryColor(widget.lesson.category),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isEdited)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Đã sửa',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditNoteDialog(note);
                    } else if (value == 'delete') {
                      _showDeleteNoteDialog(note);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Note content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              note['content'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.note_add,
              color: _getCategoryColor(widget.lesson.category),
            ),
            const SizedBox(width: 12),
            const Text('Thêm ghi chú'),
          ],
        ),
        content: TextField(
          controller: noteController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú của bạn...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isNotEmpty) {
                try {
                  await NotesService.addLessonNote(
                    lessonId: widget.lesson.id,
                    content: noteController.text.trim(),
                  );
                  Navigator.pop(context);
                  setState(() {}); // Refresh the notes tab
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thêm ghi chú'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCategoryColor(widget.lesson.category),
            ),
            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(Map<String, dynamic> note) {
    final TextEditingController noteController = TextEditingController(
      text: note['content'] ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.edit_note,
              color: _getCategoryColor(widget.lesson.category),
            ),
            const SizedBox(width: 12),
            const Text('Sửa ghi chú'),
          ],
        ),
        content: TextField(
          controller: noteController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú của bạn...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isNotEmpty) {
                try {
                  await NotesService.updateNote(
                    note['id'],
                    noteController.text.trim(),
                  );
                  Navigator.pop(context);
                  setState(() {}); // Refresh the notes tab
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật ghi chú'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCategoryColor(widget.lesson.category),
            ),
            child: const Text('Cập nhật', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteNoteDialog(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 12),
            Text('Xóa ghi chú'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn xóa ghi chú này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await NotesService.deleteNote(note['id']);
                Navigator.pop(context);
                setState(() {}); // Refresh the notes tab
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa ghi chú'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatNoteDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildQuizTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kiểm Tra Kiến Thức',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Quiz loading section
          FutureBuilder<List<QuizModel>>(
            future: QuizService.getQuizzesByLesson(widget.lesson.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Lỗi tải kiểm tra',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final quizzes = snapshot.data ?? [];

              if (quizzes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có bài kiểm tra',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bài kiểm tra sẽ được thêm sau khi hoàn thành bài học',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: quizzes.map((quiz) => _buildQuizCard(quiz)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(QuizModel quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Quiz header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCategoryColor(widget.lesson.category),
                  _getCategoryColor(widget.lesson.category).withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.quiz,
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
                        quiz.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quiz.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quiz details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildQuizStat(
                        Icons.quiz,
                        '${quiz.questions.length} câu hỏi',
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildQuizStat(
                        Icons.schedule,
                        quiz.formattedTimeLimit,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildQuizStat(
                        Icons.grade,
                        '${quiz.passingScore}% đạt',
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Quiz result section
                FutureBuilder<QuizResult?>(
                  future: QuizService.getUserBestResult(quiz.id),
                  builder: (context, resultSnapshot) {
                    if (resultSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final bestResult = resultSnapshot.data;

                    if (bestResult != null) {
                      return _buildQuizResultCard(bestResult, quiz);
                    }

                    return _buildQuizStartButton(quiz);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResultCard(QuizResult result, QuizModel quiz) {
    Color resultColor = result.passed ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resultColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                result.passed ? Icons.check_circle : Icons.cancel,
                color: resultColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.passed ? 'Đã hoàn thành' : 'Chưa đạt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                    Text(
                      'Điểm: ${result.score}/${result.totalPoints} (${result.percentage.toStringAsFixed(1)}%)',
                                             style: TextStyle(
                         fontSize: 14,
                         color: resultColor.withOpacity(0.8),
                       ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // View result details
                    _showQuizResultDetails(result, quiz);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: resultColor),
                  ),
                  child: Text(
                    'Xem chi tiết',
                    style: TextStyle(color: resultColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _startQuiz(quiz);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCategoryColor(widget.lesson.category),
                  ),
                  child: const Text(
                    'Làm lại',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStartButton(QuizModel quiz) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _startQuiz(quiz);
        },
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text(
          'Bắt đầu kiểm tra',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getCategoryColor(widget.lesson.category),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _startQuiz(QuizModel quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(quiz: quiz),
      ),
    ).then((result) {
      // Refresh the quiz tab when returning from quiz
      setState(() {});
    });
  }

  void _showQuizResultDetails(QuizResult result, QuizModel quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Kết quả kiểm tra',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _getCategoryColor(widget.lesson.category),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quiz.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildResultDetailRow(
              Icons.grade,
              'Điểm số',
              '${result.score}/${result.totalPoints}',
            ),
            _buildResultDetailRow(
              Icons.percent,
              'Phần trăm',
              '${result.percentage.toStringAsFixed(1)}%',
            ),
            _buildResultDetailRow(
              Icons.schedule,
              'Thời gian',
              '${result.timeSpent.inMinutes}m ${result.timeSpent.inSeconds % 60}s',
            ),
            _buildResultDetailRow(
              Icons.check_circle,
              'Kết quả',
              result.passed ? 'Đạt' : 'Không đạt',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startQuiz(quiz);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCategoryColor(widget.lesson.category),
            ),
            child: const Text(
              'Làm lại',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous section button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _currentSectionIndex > 0 
                  ? const Color(0xFFF1F5F9) 
                  : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                onPressed: _currentSectionIndex > 0 ? () {
                  setState(() {
                    _currentSectionIndex--;
                    _progress = _currentSectionIndex / widget.lesson.sections.length;
                  });
                } : null,
                icon: Icon(
                  Icons.skip_previous_rounded,
                  color: _currentSectionIndex > 0 
                    ? const Color(0xFF64748B) 
                    : const Color(0xFFCBD5E1),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Play/Continue button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLessonCompleted ? null : _toggleLearningTimer,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow_rounded),
                label: Text(
                  _isLessonCompleted ? 'Hoàn Thành' : (_isPlaying ? 'Tạm Dừng' : 'Bắt Đầu'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLessonCompleted 
                    ? Colors.green 
                    : _getCategoryColor(widget.lesson.category),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Next section button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _currentSectionIndex < widget.lesson.sections.length - 1 
                  ? const Color(0xFFF1F5F9) 
                  : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                onPressed: _currentSectionIndex < widget.lesson.sections.length - 1 ? () {
                  setState(() {
                    _currentSectionIndex++;
                    _progress = _currentSectionIndex / widget.lesson.sections.length;
                  });
                } : null,
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: _currentSectionIndex < widget.lesson.sections.length - 1 
                    ? const Color(0xFF64748B) 
                    : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
  
  IconData _getSectionTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video': return Icons.videocam_rounded;
      case 'audio': return Icons.audiotrack_rounded;
      case 'exercise': return Icons.assignment_rounded;
      case 'text':
      default: return Icons.menu_book_rounded;
    }
  }

  void _openSection(int index) {
    setState(() {
      _currentSectionIndex = index;
      _progress = _currentSectionIndex / widget.lesson.sections.length;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang mở phần ${index + 1}: ${widget.lesson.sections[index].title}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showStartLessonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _getCategoryIcon(widget.lesson.category),
              color: _getCategoryColor(widget.lesson.category),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bắt đầu bài học',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getCategoryColor(widget.lesson.category),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lesson.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getCategoryColor(widget.lesson.category).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: _getCategoryColor(widget.lesson.category),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thời gian dự kiến: ${widget.lesson.formattedDuration}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getCategoryColor(widget.lesson.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: _getCategoryColor(widget.lesson.category),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.lesson.sections.length} phần học',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getCategoryColor(widget.lesson.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt_rounded,
                        color: _getCategoryColor(widget.lesson.category),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Độ khó: ${_getVietnameseDifficulty(widget.lesson.difficultyLevelName)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getCategoryColor(widget.lesson.category),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn có thể tạm dừng và tiếp tục bất cứ lúc nào',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startLearningSession();
            },
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: const Text('Bắt Đầu Học', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCategoryColor(widget.lesson.category),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _startLearningSession() {
    setState(() {
      _isPlaying = true;
    });
    _startLearningTimer();
    
    // Show section selection dialog
    _showSectionSelectionDialog();
  }

  void _showSectionSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Chọn phần học',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: widget.lesson.sections.length,
            itemBuilder: (context, index) {
              final section = widget.lesson.sections[index];
              final isCompleted = _sectionCompletionStatus[index];
              final isActive = _currentSectionIndex == index;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isActive 
                    ? _getCategoryColor(widget.lesson.category).withOpacity(0.1)
                    : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive 
                      ? _getCategoryColor(widget.lesson.category)
                      : Colors.grey[300]!,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted 
                      ? Colors.green 
                      : isActive 
                        ? _getCategoryColor(widget.lesson.category)
                        : Colors.grey[400],
                    child: Icon(
                      isCompleted 
                        ? Icons.check_rounded 
                        : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? _getCategoryColor(widget.lesson.category) : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    _getSectionTypeText(section.type),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openSectionPlayer(section, index);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _openSectionPlayer(LessonSection section, int index) {
    setState(() {
      _currentSectionIndex = index;
      _progress = (index + 1) / widget.lesson.sections.length;
    });

    // Check if the section has a mediaUrl if it's a video or audio type
    if ((section.type.toLowerCase() == 'video' || section.type.toLowerCase() == 'audio') && 
        (section.mediaUrl == null || section.mediaUrl!.isEmpty)) {
      // Show error message if no media URL
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có media cho phần này. Vui lòng liên hệ quản trị viên.'),
          backgroundColor: Colors.red,
        )
      );
      return;
    }

    // Save current lesson progress
    _trackLessonProgress();

    // Navigate to lesson player for specific section
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonPlayerScreen(
          lesson: widget.lesson,
          section: section,
          sectionIndex: index,
        ),
      ),
    ).then((result) {
      // When returning from lesson player screen
      if (result == true) {
        // Section was completed
        _fetchLessonProgress();
      }
    });
  }

  void _fetchLessonProgress() {
    // First get overall lesson progress
    LearningProgressService.getLessonProgress(widget.lesson.id).then((progress) {
      if (progress != null) {
          setState(() {
          _elapsedSeconds = progress['timeSpent'] ?? 0;
          _progress = (progress['completionPercentage'] ?? 0.0) / 100.0;
          if (_progress >= 1.0) {
            _isLessonCompleted = true;
            _sectionCompletionStatus = List.filled(widget.lesson.sections.length, true);
        } else {
            // Calculate current section based on progress
            _currentSectionIndex = (_progress * widget.lesson.sections.length).floor();
            if (_currentSectionIndex >= widget.lesson.sections.length) {
              _currentSectionIndex = widget.lesson.sections.length - 1;
            }
          }
        });
      }
      
      // Now fetch individual section progress status
      _fetchSectionProgress();
    });
  }
  
  void _fetchSectionProgress() {
    // Fetch progress for each section
    for (int i = 0; i < widget.lesson.sections.length; i++) {
      final int sectionIndex = i; // Create local var to use in closure
      
      LearningProgressService.getLessonSectionMediaProgress(
        lessonId: widget.lesson.id,
        sectionIndex: sectionIndex,
      ).then((sectionProgress) {
        if (sectionProgress != null) {
          setState(() {
            // Check if section is completed based on progress or completed flag
            bool isCompleted = sectionProgress['completed'] == true || 
                (sectionProgress['progress'] ?? 0.0) >= 0.95;
                
            // Update the section completion status map
            _sectionProgress[sectionIndex] = sectionProgress;
            _sectionCompletionStatus[sectionIndex] = isCompleted;
          });
        }
      });
    }
  }
}

// Custom pattern painter for background decoration
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 0; i < size.width; i += 30) {
      for (int j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 
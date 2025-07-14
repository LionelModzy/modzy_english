import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/lesson_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/learning_progress_service.dart';
import '../../../models/lesson_model.dart';
import '../widgets/lesson_media_widget.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedCategory = 'Tất cả';
  String _selectedDifficulty = 'Tất cả';
  String _searchQuery = '';
  
  List<LessonModel> _allLessons = [];
  List<LessonModel> _filteredLessons = [];
  Map<String, dynamic> _learningStats = {};
  List<Map<String, dynamic>> _recentHistory = [];
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  
  // Vietnamese category mapping
  final Map<String, String> _categoryMapping = {
    'Tất cả': 'All',
    'Ngữ pháp': 'Grammar',
    'Từ vựng': 'Vocabulary', 
    'Nói': 'Speaking',
    'Nghe': 'Listening',
    'Viết': 'Writing',
  };
  
  final Map<String, String> _difficultyMapping = {
    'Tất cả': 'All',
    'Cơ bản': 'Beginner',
    'Sơ cấp': 'Elementary', 
    'Trung cấp': 'Intermediate',
    'Trung cấp cao': 'Upper Intermediate',
    'Nâng cao': 'Advanced',
  };
  
  final List<String> _categories = ['Tất cả', 'Ngữ pháp', 'Từ vựng', 'Nói', 'Nghe', 'Viết'];
  final List<String> _difficulties = ['Tất cả', 'Cơ bản', 'Sơ cấp', 'Trung cấp', 'Trung cấp cao', 'Nâng cao'];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _loadLessons();
    _loadLearningData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    try {
      setState(() => _isLoading = true);
      final lessons = await LessonService.getAllLessons();
      setState(() {
        _allLessons = lessons.where((lesson) => lesson.isActive).toList();
        _isLoading = false;
      });
      print('✅ Loaded ${_allLessons.length} active lessons from Firebase');
      for (var lesson in _allLessons) {
        print('📚 Lesson: ${lesson.title}');
        print('  - Image: ${lesson.imageUrl ?? "None"}');
        print('  - Video: ${lesson.videoUrl ?? "None"}');
        print('  - Audio: ${lesson.audioUrl ?? "None"}');
        print('  - Category: ${lesson.category}');
        print('  - Difficulty: ${lesson.difficultyLevelName}');
      }
      _filterLessons();
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading lessons: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải bài học: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadLearningData() async {
    try {
      // Load learning statistics and recent history in parallel
      final results = await Future.wait([
        LearningProgressService.getLearningStats(),
        LearningProgressService.getRecentHistory(limit: 5),
      ]);
      
      setState(() {
        _learningStats = results[0] as Map<String, dynamic>;
        _recentHistory = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      print('❌ Error loading learning data: $e');
    }
  }

  void _filterLessons() {
    List<LessonModel> filtered = List.from(_allLessons);
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((lesson) =>
        lesson.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        lesson.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        lesson.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    
    // Category filter
    if (_selectedCategory != 'Tất cả') {
      String englishCategory = _categoryMapping[_selectedCategory] ?? '';
      filtered = filtered.where((lesson) => lesson.category == englishCategory).toList();
    }
    
    // Difficulty filter  
    if (_selectedDifficulty != 'Tất cả') {
      String englishDifficulty = _difficultyMapping[_selectedDifficulty] ?? '';
      filtered = filtered.where((lesson) => lesson.difficultyLevelName == englishDifficulty).toList();
    }
    
    setState(() {
      _filteredLessons = filtered;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Lessons',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LessonSearchDelegate(_allLessons),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All Lessons'),
            Tab(text: 'Progress'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllLessonsTab(),
          _buildProgressTab(),
          _buildFavoritesTab(),
        ],
      ),
    );
  }

  Widget _buildAllLessonsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                            _filterLessons();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Difficulty',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _difficulties.map((difficulty) {
                    final isSelected = _selectedDifficulty == difficulty;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(difficulty),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDifficulty = difficulty;
                            _filterLessons();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.secondary.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.secondary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredLessons.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredLessons.length,
                  itemBuilder: (context, index) {
                    return _buildLessonCard(_filteredLessons[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    return FutureBuilder<List<LessonModel>>(
      future: FavoritesService.getFavoriteLessons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lỗi tải yêu thích',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Thử lại',
                  onPressed: () => setState(() {}),
                  icon: Icons.refresh,
                ),
              ],
            ),
          );
        }

        final favoriteLessons = snapshot.data ?? [];

        if (favoriteLessons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: Colors.red.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chưa có bài học yêu thích',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thêm bài học vào yêu thích để học lại dễ dàng',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Khám phá bài học',
                  onPressed: () => _tabController.animateTo(0),
                  icon: Icons.explore,
                  color: Colors.red,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Favorites summary header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bài học yêu thích',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${favoriteLessons.length} bài học được lưu',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${favoriteLessons.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Favorites list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: favoriteLessons.length,
                itemBuilder: (context, index) {
                  final lesson = favoriteLessons[index];
                  return _buildFavoriteLessonCard(lesson);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall progress card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tiến độ học tập',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Tổng thời gian học: ${_learningStats['totalStudyTime'] ?? 0} phút',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressStat(
                        'Hoàn thành', 
                        '${_learningStats['completedLessons'] ?? 0}', 
                        Icons.check_circle
                      ),
                    ),
                    Expanded(
                      child: _buildProgressStat(
                        'Đang học', 
                        '${_learningStats['inProgressLessons'] ?? 0}', 
                        Icons.play_circle
                      ),
                    ),
                    Expanded(
                      child: _buildProgressStat(
                        'Còn lại', 
                        '${_allLessons.length - (_learningStats['totalLessons'] ?? 0)}', 
                        Icons.pending
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Study streak card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chuỗi học tập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hiện tại: ${_learningStats['currentStreak'] ?? 0} ngày',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Tốt nhất: ${_learningStats['bestStreak'] ?? 0} ngày',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_learningStats['currentStreak'] ?? 0}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent activity section
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hoạt động gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full learning history
                },
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_recentHistory.isEmpty)
            _buildEmptyHistoryState()
          else
            ..._recentHistory.map((activity) => _buildActivityCard(activity)),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    IconData activityIcon;
    Color activityColor;
    
    switch (activity['type']) {
      case 'lesson':
        activityIcon = Icons.book_rounded;
        activityColor = AppColors.primary;
        break;
      case 'vocabulary':
        activityIcon = Icons.quiz_rounded;
        activityColor = AppColors.secondary;
        break;
      default:
        activityIcon = Icons.school_rounded;
        activityColor = AppColors.accent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activityColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: activityColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activityIcon,
              color: activityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Hoạt động',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  activity['subtitle'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (activity['details'] != null)
                  Text(
                    _getActivityDetails(activity),
                    style: TextStyle(
                      fontSize: 11,
                      color: activityColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${activity['accuracy']?.round() ?? activity['completion']?.round() ?? 0}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: activityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActivityDetails(Map<String, dynamic> activity) {
    final details = activity['details'] as Map<String, dynamic>?;
    if (details == null) return '';
    
    if (activity['type'] == 'vocabulary') {
      return '${details['correctAnswers']}/${details['totalQuestions']} đúng';
    } else if (activity['type'] == 'lesson') {
      final timeSpent = details['timeSpent'] as int? ?? 0;
      final minutes = (timeSpent / 60).round();
      return 'Học $minutes phút';
    }
    return '';
  }

  Widget _buildEmptyHistoryState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có hoạt động học tập',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bắt đầu học để xem tiến độ ở đây',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Bắt đầu học',
            onPressed: () => _tabController.animateTo(0),
            icon: Icons.play_arrow,
            width: 140,
            height: 36,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(LessonModel lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Media Section
          LessonMediaWidget(
            imageUrl: lesson.imageUrl,
            videoUrl: lesson.videoUrl,
            audioUrl: lesson.audioUrl,
            height: 180,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            onTap: () => _openLesson(lesson),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(lesson.category),
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lesson.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (lesson.isPremium) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.adminGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lesson.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 8,
                  children: lesson.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildLessonInfo(Icons.schedule, lesson.formattedDuration),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLessonInfo(Icons.signal_cellular_alt, lesson.difficultyLevelName),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLessonInfo(Icons.category, lesson.category),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Start Lesson',
                    onPressed: () => _openLesson(lesson),
                    icon: Icons.play_arrow_rounded,
                    height: 44,
                  ),
                ),
                const SizedBox(width: 12),
                FutureBuilder<bool>(
                  future: _checkIfFavorite(lesson.id),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;
                    return Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: isFavorite ? Colors.red : AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                        color: isFavorite ? Colors.red.withOpacity(0.1) : null,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.red : AppColors.textSecondary,
                        ),
                        onPressed: () async {
                          bool success;
                          if (isFavorite) {
                            success = await FavoritesService.removeLessonFromFavorites(lesson.id);
                          } else {
                            success = await FavoritesService.addLessonToFavorites(lesson.id);
                          }
                          
                          if (success) {
                            setState(() {}); // Refresh to update the UI
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFavorite 
                                  ? 'Đã xóa "${lesson.title}" khỏi yêu thích'
                                  : 'Đã thêm "${lesson.title}" vào yêu thích'
                                ),
                                backgroundColor: isFavorite ? Colors.grey : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No lessons found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grammar':
        return Icons.menu_book_rounded;
      case 'vocabulary':
        return Icons.library_books_rounded;
      case 'speaking':
        return Icons.record_voice_over_rounded;
      case 'listening':
        return Icons.headphones_rounded;
      case 'writing':
        return Icons.edit_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  Widget _buildFavoriteLessonCard(LessonModel lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getCategoryColor(lesson.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(lesson.category),
                color: _getCategoryColor(lesson.category),
                size: 20,
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              lesson.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(lesson.category, _getCategoryColor(lesson.category)),
                const SizedBox(width: 8),
                _buildInfoChip(lesson.difficultyLevelName, Colors.orange),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
              onPressed: () async {
                final success = await FavoritesService.removeLessonFromFavorites(lesson.id);
                if (success) {
                  setState(() {}); // Refresh the favorites tab
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa "${lesson.title}" khỏi yêu thích'),
                      backgroundColor: Colors.grey,
                    ),
                  );
                }
              },
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
        onTap: () => _openLesson(lesson),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'grammar':
        return const Color(0xFF8B5CF6);
      case 'vocabulary':
        return const Color(0xFF06B6D4);
      case 'speaking':
        return const Color(0xFF10B981);
      case 'listening':
        return const Color(0xFFF59E0B);
      case 'writing':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  Future<bool> _checkIfFavorite(String lessonId) async {
    try {
      final favorites = await FavoritesService.getFavoriteLessons();
      return favorites.any((lesson) => lesson.id == lessonId);
    } catch (e) {
      return false;
    }
  }

  void _openLesson(LessonModel lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );
  }
}

// Search Delegate for Lessons
class LessonSearchDelegate extends SearchDelegate<LessonModel?> {
  final List<LessonModel> lessons;

  LessonSearchDelegate(this.lessons);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = lessons.where((lesson) {
      final titleMatch = lesson.title.toLowerCase().contains(query.toLowerCase());
      final descriptionMatch = lesson.description.toLowerCase().contains(query.toLowerCase());
      final categoryMatch = lesson.category.toLowerCase().contains(query.toLowerCase());
      final tagMatch = lesson.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      
      return titleMatch || descriptionMatch || categoryMatch || tagMatch;
    }).toList();

    if (query.isEmpty) {
      return _buildSearchSuggestions();
    }

    if (results.isEmpty) {
      return _buildNoResultsFound();
    }

    return Builder(
      builder: (context) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final lesson = results[index];
          return _buildSearchResultCard(lesson, context);
        },
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      'Grammar lessons',
      'Beginner vocabulary',
      'Speaking practice',
      'Present tense',
      'Listening exercises',
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: AppColors.textSecondary),
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy bài học nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác cho "$query"',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(LessonModel lesson, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCategoryColor(lesson.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(lesson.category),
            color: _getCategoryColor(lesson.category),
            size: 20,
          ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              lesson.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(lesson.category, _getCategoryColor(lesson.category)),
                const SizedBox(width: 8),
                _buildInfoChip(lesson.difficultyLevelName, Colors.orange),
                const SizedBox(width: 8),
                _buildInfoChip(lesson.formattedDuration, Colors.blue),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
        onTap: () {
          // Navigate to lesson detail and close search
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LessonDetailScreen(lesson: lesson),
            ),
          ).then((_) => close(context, lesson));
        },
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'grammar':
        return const Color(0xFF8B5CF6);
      case 'vocabulary':
        return const Color(0xFF06B6D4);
      case 'speaking':
        return const Color(0xFF10B981);
      case 'listening':
        return const Color(0xFFF59E0B);
      case 'writing':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grammar':
        return Icons.menu_book_rounded;
      case 'vocabulary':
        return Icons.library_books_rounded;
      case 'speaking':
        return Icons.record_voice_over_rounded;
      case 'listening':
        return Icons.headphones_rounded;
      case 'writing':
        return Icons.edit_rounded;
      default:
        return Icons.school_rounded;
    }
  }
} 
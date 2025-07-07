import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/lesson_service.dart';
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon!')),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yêu Thích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các bài học yêu thích sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        children: const [
                          Text(
                            'Learning Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Keep up the great work!',
                            style: TextStyle(
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
                      child: _buildProgressStat('Completed', '3', Icons.check_circle),
                    ),
                    Expanded(
                      child: _buildProgressStat('In Progress', '2', Icons.play_circle),
                    ),
                    Expanded(
                      child: _buildProgressStat('Remaining', '${_allLessons.length - 5}', Icons.pending),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Continue Learning',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildContinueLearningCard(),
          
          const SizedBox(height: 24),
          
          const Text(
            'Recently Completed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._allLessons.take(3).map((lesson) => _buildCompletedLessonCard(lesson)),
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

  Widget _buildContinueLearningCard() {
    return Container(
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
              Icons.play_circle_filled_rounded,
              color: AppColors.accent,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Present Tense Mastery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Progress: 65%',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CustomButton(
            text: 'Continue',
                         onPressed: () => _allLessons.isNotEmpty ? _openLesson(_allLessons[0]) : null,
            width: 80,
            height: 36,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedLessonCard(LessonModel lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Completed • Score: 95%',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
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
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added "${lesson.title}" to favorites')),
                      );
                    },
                  ),
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

  void _openLesson(LessonModel lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );
  }
} 
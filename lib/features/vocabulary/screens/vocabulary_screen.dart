import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/services/learning_progress_service.dart';
import '../../../core/services/bookmark_service.dart';
import '../../../models/vocab_model.dart';
import '../widgets/vocabulary_card_widget.dart';
import 'vocabulary_practice_screen.dart';
import 'bookmark_management_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<VocabularyModel> _vocabularies = [];
  List<VocabularyModel> _filteredVocabularies = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';
  
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = [
    'Tất cả', 'Grammar', 'Vocabulary', 'Speaking', 'Listening', 'Writing'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVocabularies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabularies() async {
    try {
      setState(() => _isLoading = true);
      final vocabularies = await VocabularyService.getAllVocabulary();
      setState(() {
        _vocabularies = vocabularies;
        _isLoading = false;
      });
      _filterVocabularies();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải từ vựng: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _filterVocabularies() {
    List<VocabularyModel> filtered = List.from(_vocabularies);
    
    // Category filter
    if (_selectedCategory != 'Tất cả') {
      filtered = filtered.where((vocab) => vocab.category == _selectedCategory).toList();
    }
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((vocab) =>
        vocab.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        vocab.meaning.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    setState(() {
      _filteredVocabularies = filtered;
    });
  }

  Future<List<VocabularyModel>> _loadFavoriteVocabularies() async {
    try {
      return await FavoritesService.getFavoriteVocabularies();
    } catch (e) {
      throw Exception('Không thể tải từ vựng yêu thích: $e');
    }
  }

  Future<void> _removeFromFavorites(VocabularyModel vocabulary) async {
    try {
      final success = await FavoritesService.removeVocabularyFromFavorites(vocabulary.id);
      if (success) {
        setState(() {}); // Trigger rebuild to update favorites list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${vocabulary.word}" khỏi danh sách yêu thích'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        throw Exception('Không thể xóa khỏi danh sách yêu thích');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _playVocabularyAudio(String audioUrl) async {
    try {
      final audioPlayer = AudioPlayer();
      await audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể phát âm thanh: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _loadLearningStatistics() async {
    try {
      final learningStats = await LearningProgressService.getLearningStats();
      final favoriteStats = await FavoritesService.getFavoritesCount();
      
      // Get bookmark stats
      final bookmarkCount = await BookmarkService.getBookmarkCount();
      final bookmarkStats = await BookmarkService.getBookmarkStats();
      
      return {
        'learning': learningStats,
        'favorites': favoriteStats,
        'bookmarks': {
          'total': bookmarkCount,
          ...bookmarkStats,
        },
      };
    } catch (e) {
      print('Error loading learning statistics: $e');
      return {};
    }
  }

  // Force refresh statistics
  void _refreshStatistics() {
    setState(() {
      // This will trigger FutureBuilder to rebuild
    });
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'] ?? '';
    final timestamp = activity['timestamp'];
    String timeAgo = 'Vừa xong';
    
    if (timestamp != null) {
      final activityTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(activityTime);
      
      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes} phút trước';
      }
    }
    
    IconData icon;
    Color color;
    String title;
    String subtitle;
    
    if (type == 'vocabulary') {
      icon = Icons.quiz;
      color = Colors.blue;
      title = 'Luyện tập từ vựng';
      subtitle = 'Độ chính xác: ${activity['accuracy'] ?? 0}%';
    } else {
      icon = Icons.book;
      color = Colors.green;
      title = 'Học bài';
      subtitle = 'Hoàn thành: ${activity['completion'] ?? 0}%';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Từ Vựng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VocabularyPracticeScreen(),
                ),
              ).then((_) {
                // Refresh statistics when returning from practice
                _refreshStatistics();
              });
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
            Tab(text: 'Tất cả'),
            Tab(text: 'Yêu thích'),
            Tab(text: 'Thống kê'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllVocabularyTab(),
          _buildFavoritesTab(),
          _buildStatisticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showPracticeOptions();
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.quiz, color: Colors.white),
        label: const Text(
          'Luyện tập',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAllVocabularyTab() {
    return Column(
      children: [
        // Search and filters
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm từ vựng...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _filterVocabularies();
                },
              ),
              
              const SizedBox(height: 12),
              
              // Category filter
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
                          _filterVocabularies();
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.accent.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.accent : AppColors.border,
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
        
        // Vocabulary list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredVocabularies.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _filteredVocabularies.length,
                      itemBuilder: (context, index) {
                        final vocabulary = _filteredVocabularies[index];
                        return VocabularyCardWidget(
                          vocabulary: vocabulary,
                          onTap: () => _showVocabularyDetail(vocabulary),
                          onPractice: () => _startPracticeWith(vocabulary),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    return FutureBuilder<List<VocabularyModel>>(
      future: _loadFavoriteVocabularies(),
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
                  'Lỗi tải từ vựng yêu thích',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
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
              ],
            ),
          );
        }
        
        final favoriteVocabularies = snapshot.data ?? [];
        
        if (favoriteVocabularies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có từ vựng yêu thích',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thêm từ vựng vào yêu thích để xem ở đây',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _tabController.animateTo(0); // Switch to All tab
                    });
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Khám phá từ vựng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
                     child: GridView.builder(
             padding: const EdgeInsets.all(16),
             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: 2,
               childAspectRatio: 0.65,
               crossAxisSpacing: 8,
               mainAxisSpacing: 8,
             ),
            itemCount: favoriteVocabularies.length,
            itemBuilder: (context, index) {
              final vocabulary = favoriteVocabularies[index];
              return VocabularyCardWidget(
                vocabulary: vocabulary,
                onTap: () => _showVocabularyDetail(vocabulary),
                onPractice: () => _startPracticeWith(vocabulary),
                isInStudyList: true, // All favorites are in study list
                onRemoveFromStudyList: () => _removeFromFavorites(vocabulary),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(DateTime.now().millisecondsSinceEpoch), // Force rebuild when refreshed
      future: _loadLearningStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Đang tải thống kê...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final totalWords = _vocabularies.length;
        final wordsWithAudio = _vocabularies.where((v) => v.hasAudio).length;
        final categories = _vocabularies.map((v) => v.category).toSet().length;
        final learningStats = stats['learning'] ?? {};
        final favoriteStats = stats['favorites'] ?? {};
        final bookmarkStats = stats['bookmarks'] ?? {};

        return RefreshIndicator(
          onRefresh: () async {
            _refreshStatistics(); // Use our refresh method
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê từ vựng',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Basic vocabulary stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Tổng số từ',
                        totalWords.toString(),
                        Icons.library_books,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Có âm thanh',
                        wordsWithAudio.toString(),
                        Icons.volume_up,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Danh mục',
                        categories.toString(),
                        Icons.category,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Yêu thích',
                        (favoriteStats['vocabulary'] ?? 0).toString(),
                        Icons.favorite,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookmarkManagementScreen(),
                            ),
                          ).then((_) => setState(() {})); // Refresh when returning
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.bookmark, color: Colors.amber, size: 24),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.touch_app, color: Colors.grey, size: 16),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (bookmarkStats['total'] ?? 0).toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              const Text(
                                'Bookmark\n(Bấm để xem)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // Navigate directly to review mode in bookmark screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookmarkManagementScreen(),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.refresh, color: Colors.cyan, size: 24),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.touch_app, color: Colors.grey, size: 16),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (bookmarkStats['needingReview'] ?? 0).toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan,
                                ),
                              ),
                              const Text(
                                'Cần ôn lại\n(Bấm để ôn)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Learning progress stats
                const Text(
                  'Tiến độ học tập',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Lần luyện tập',
                        (learningStats['totalPractices'] ?? 0).toString(),
                        Icons.quiz,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Độ chính xác',
                        '${learningStats['averageAccuracy'] ?? 0}%',
                        Icons.track_changes,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Chuỗi học liên tiếp',
                        '${learningStats['currentStreak'] ?? 0} ngày',
                        Icons.local_fire_department,
                        Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Thời gian học',
                        '${learningStats['totalStudyTime'] ?? 0} phút',
                        Icons.access_time,
                        Colors.indigo,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Recent activity
                const Text(
                  'Hoạt động gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                FutureBuilder<List<Map<String, dynamic>>>(
                                        future: LearningProgressService.getRecentHistory(limit: 3),
                  builder: (context, historySnapshot) {
                    if (historySnapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    final history = historySnapshot.data ?? [];
                    
                    if (history.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.timeline,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Chưa có hoạt động nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Bắt đầu luyện tập để thấy hoạt động ở đây',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: history.map((activity) => _buildActivityItem(activity)).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
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

  Widget _buildEmptyState() {
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
            'Không tìm thấy từ vựng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showVocabularyDetail(VocabularyModel vocabulary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vocabulary.word,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (vocabulary.pronunciation.isNotEmpty)
                            Text(
                              vocabulary.pronunciation,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (vocabulary.hasAudio)
                      IconButton(
                        onPressed: () => _playVocabularyAudio(vocabulary.audioUrl!),
                        icon: const Icon(Icons.volume_up),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accent.withOpacity(0.1),
                          foregroundColor: AppColors.accent,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection('Nghĩa', vocabulary.meaning),
                        if (vocabulary.partOfSpeech.isNotEmpty)
                          _buildDetailSection('Loại từ', vocabulary.partOfSpeech),
                        if (vocabulary.examples.isNotEmpty)
                          _buildDetailSection('Ví dụ', vocabulary.examples.join('\n')),
                        if (vocabulary.synonyms.isNotEmpty)
                          _buildDetailSection('Từ đồng nghĩa', vocabulary.synonyms.join(', ')),
                        if (vocabulary.antonyms.isNotEmpty)
                          _buildDetailSection('Từ trái nghĩa', vocabulary.antonyms.join(', ')),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _startPracticeWith(vocabulary);
                        },
                        icon: const Icon(Icons.quiz),
                        label: const Text('Luyện tập'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<bool>(
                        future: FavoritesService.isVocabularyInFavorites(vocabulary.id),
                        builder: (context, snapshot) {
                          final isFavorite = snapshot.data ?? false;
                          return ElevatedButton.icon(
                            onPressed: () async {
                              final success = await FavoritesService.toggleVocabularyFavorite(vocabulary.id);
                              if (success) {
                                final newStatus = await FavoritesService.isVocabularyInFavorites(vocabulary.id);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(newStatus 
                                        ? 'Đã thêm "${vocabulary.word}" vào yêu thích'
                                        : 'Đã xóa "${vocabulary.word}" khỏi yêu thích'),
                                    backgroundColor: newStatus ? AppColors.success : AppColors.warning,
                                  ),
                                );
                                setState(() {}); // Refresh the UI
                              }
                            },
                            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                            label: Text(isFavorite ? 'Đã yêu thích' : 'Yêu thích'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFavorite ? AppColors.error : AppColors.accent,
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startPracticeWith(VocabularyModel vocabulary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VocabularyPracticeScreen(
          initialVocabulary: vocabulary,
        ),
      ),
    ).then((_) {
      // Refresh statistics when returning from practice
      _refreshStatistics();
    });
  }

  void _showPracticeOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn chế độ luyện tập',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildPracticeOption(
              'Luyện tập tất cả',
              'Ôn luyện toàn bộ từ vựng',
              Icons.quiz,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VocabularyPracticeScreen(),
                  ),
                ).then((_) {
                  // Refresh statistics when returning from practice
                  _refreshStatistics();
                });
              },
            ),

            FutureBuilder<Map<String, dynamic>>(
              future: BookmarkService.getBookmarkStats(),
              builder: (context, snapshot) {
                final bookmarkStats = snapshot.data ?? {};
                final needingReview = bookmarkStats['needingReview'] ?? 0;
                final total = bookmarkStats['total'] ?? 0;
                
                return _buildPracticeOption(
                  'Ôn lại Bookmark',
                  total > 0 
                    ? 'Ôn lại $needingReview/$total từ đã bookmark'
                    : 'Chưa có bookmark nào để ôn',
                  Icons.bookmark_added,
                  () {
                    if (total > 0) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookmarkManagementScreen(),
                        ),
                      ).then((_) {
                        // Refresh statistics when returning
                        _refreshStatistics();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📌 Chưa có bookmark nào để ôn lại. Hãy bookmark từ vựng trong khi luyện tập!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                );
              },
            ),
            
            _buildPracticeOption(
              'Theo danh mục',
              'Chọn danh mục cụ thể',
              Icons.category,
              () {
                Navigator.pop(context);
                _showCategorySelection();
              },
            ),
            
            _buildPracticeOption(
              'Theo độ khó',
              'Chọn mức độ khó',
              Icons.trending_up,
              () {
                Navigator.pop(context);
                _showDifficultySelection();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn danh mục',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            ..._categories.skip(1).map((category) => _buildCategoryOption(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VocabularyPracticeScreen(category: category),
              ),
            ).then((_) {
              // Refresh statistics when returning from practice
              _refreshStatistics();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDifficultySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn độ khó',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            for (int i = 1; i <= 5; i++)
              _buildDifficultyOption(i),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(int level) {
    final levelNames = ['', 'Cơ bản', 'Sơ cấp', 'Trung cấp', 'Trung cấp cao', 'Nâng cao'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VocabularyPracticeScreen(difficultyLevel: level),
              ),
            ).then((_) {
              // Refresh statistics when returning from practice
              _refreshStatistics();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < level ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 16,
                  )),
                ),
                const SizedBox(width: 12),
                Text(
                  levelNames[level],
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
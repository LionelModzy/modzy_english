import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/bookmark_service.dart';
import '../../../models/vocab_model.dart';
import '../widgets/vocabulary_card_widget.dart';
import 'vocabulary_practice_session.dart';

class BookmarkManagementScreen extends StatefulWidget {
  const BookmarkManagementScreen({super.key});

  @override
  State<BookmarkManagementScreen> createState() => _BookmarkManagementScreenState();
}

class _BookmarkManagementScreenState extends State<BookmarkManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<VocabularyModel> _allBookmarks = [];
  List<VocabularyModel> _needReviewBookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    try {
      setState(() => _isLoading = true);
      
      final allBookmarks = await BookmarkService.getBookmarkedVocabularies();
      final needReview = await BookmarkService.getVocabulariesNeedingReview();
      
      setState(() {
        _allBookmarks = allBookmarks;
        _needReviewBookmarks = needReview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải bookmark: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _removeBookmark(VocabularyModel vocabulary) async {
    try {
      final success = await BookmarkService.removeVocabularyBookmark(vocabulary.id);
      if (success) {
        setState(() {
          _allBookmarks.removeWhere((v) => v.id == vocabulary.id);
          _needReviewBookmarks.removeWhere((v) => v.id == vocabulary.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Đã xóa bookmark "${vocabulary.word}"'),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        throw Exception('Không thể xóa bookmark');
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

  Future<void> _markAsReviewed(VocabularyModel vocabulary) async {
    try {
      final success = await BookmarkService.markAsReviewed(vocabulary.id);
      if (success) {
        setState(() {
          _needReviewBookmarks.removeWhere((v) => v.id == vocabulary.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã đánh dấu "${vocabulary.word}" đã ôn lại'),
            backgroundColor: AppColors.success,
          ),
        );
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

  void _startReviewSession() {
    if (_needReviewBookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📚 Không có từ vựng nào cần ôn lại'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VocabularyPracticeSession(
          vocabularies: _needReviewBookmarks,
          mode: 'flashcard',
          onComplete: (correct, total) {
            // Mark all as reviewed after practice
            for (var vocab in _needReviewBookmarks) {
              BookmarkService.markAsReviewed(vocab.id);
            }
            _loadBookmarks(); // Refresh the list
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Bookmark Manager',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_needReviewBookmarks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _startReviewSession,
              tooltip: 'Ôn lại từ bookmark',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              text: 'Tất cả (${_allBookmarks.length})',
              icon: const Icon(Icons.bookmark, size: 18),
            ),
            Tab(
              text: 'Cần ôn (${_needReviewBookmarks.length})',
              icon: const Icon(Icons.refresh, size: 18),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllBookmarksTab(),
          _buildNeedReviewTab(),
        ],
      ),
      floatingActionButton: _needReviewBookmarks.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _startReviewSession,
              backgroundColor: Colors.amber[700],
              icon: const Icon(Icons.quiz, color: Colors.white),
              label: const Text(
                'Ôn Bookmark',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildAllBookmarksTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allBookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có bookmark nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bookmark từ vựng trong khi luyện tập để xem ở đây',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _allBookmarks.length,
        itemBuilder: (context, index) {
          final vocabulary = _allBookmarks[index];
          return _buildBookmarkCard(vocabulary, showReviewAction: false);
        },
      ),
    );
  }

  Widget _buildNeedReviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_needReviewBookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có từ nào cần ôn lại',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tuyệt vời! Bạn đã ôn lại tất cả từ bookmark',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      child: Column(
        children: [
          // Review session button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _startReviewSession,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                'Ôn lại ${_needReviewBookmarks.length} từ vựng',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          // Vocabulary grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _needReviewBookmarks.length,
              itemBuilder: (context, index) {
                final vocabulary = _needReviewBookmarks[index];
                return _buildBookmarkCard(vocabulary, showReviewAction: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard(VocabularyModel vocabulary, {bool showReviewAction = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: showReviewAction ? Colors.amber.withOpacity(0.3) : Colors.transparent,
          width: showReviewAction ? 2 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with bookmark indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: showReviewAction ? Colors.amber[50] : AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  showReviewAction ? Icons.refresh : Icons.bookmark,
                  color: showReviewAction ? Colors.amber[700] : AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    showReviewAction ? 'Cần ôn lại' : 'Đã bookmark',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: showReviewAction ? Colors.amber[700] : AppColors.primary,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') {
                      _removeBookmark(vocabulary);
                    } else if (value == 'reviewed' && showReviewAction) {
                      _markAsReviewed(vocabulary);
                    }
                  },
                  itemBuilder: (context) => [
                    if (showReviewAction)
                      const PopupMenuItem(
                        value: 'reviewed',
                        child: Row(
                          children: [
                            Icon(Icons.check, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Đã ôn xong'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Xóa bookmark'),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vocabulary.word,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (vocabulary.pronunciation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      vocabulary.pronunciation,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: Text(
                      vocabulary.meaning,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vocabulary.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
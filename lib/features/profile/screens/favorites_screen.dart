import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for favorites
  final List<Map<String, dynamic>> _favoriteLessons = [
    {
      'id': '1',
      'title': 'Advanced Grammar Rules',
      'description': 'Master complex sentence structures',
      'difficulty': 'Advanced',
      'duration': '25 min',
      'type': 'lesson',
      'addedDate': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': '2',
      'title': 'Business English Phrases',
      'description': 'Professional communication skills',
      'difficulty': 'Intermediate',
      'duration': '30 min',
      'type': 'lesson',
      'addedDate': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': '3',
      'title': 'Pronunciation Practice',
      'description': 'Improve your speaking skills',
      'difficulty': 'Beginner',
      'duration': '20 min',
      'type': 'lesson',
      'addedDate': DateTime.now().subtract(const Duration(days: 7)),
    },
  ];

  final List<Map<String, dynamic>> _favoriteWords = [
    {
      'id': '1',
      'word': 'Serendipity',
      'pronunciation': '/ˌserənˈdipədē/',
      'meaning': 'The occurrence of events by chance in a happy way',
      'example': 'Meeting my best friend was pure serendipity.',
      'difficulty': 'Advanced',
      'addedDate': DateTime.now().subtract(const Duration(hours: 6)),
    },
    {
      'id': '2',
      'word': 'Eloquent',
      'pronunciation': '/ˈeləkwənt/',
      'meaning': 'Fluent and persuasive in speaking or writing',
      'example': 'She gave an eloquent speech about climate change.',
      'difficulty': 'Intermediate',
      'addedDate': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '3',
      'word': 'Resilient',
      'pronunciation': '/rəˈzilyənt/',
      'meaning': 'Able to withstand or recover quickly from difficulties',
      'example': 'Children are remarkably resilient to stress.',
      'difficulty': 'Intermediate',
      'addedDate': DateTime.now().subtract(const Duration(days: 3)),
    },
  ];

  final List<Map<String, dynamic>> _favoriteVideos = [
    {
      'id': '1',
      'title': 'English Conversation Tips',
      'description': 'How to sound more natural in English',
      'duration': '12:34',
      'views': '1.2M',
      'type': 'video',
      'addedDate': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '2',
      'title': 'Common English Mistakes',
      'description': 'Avoid these frequent errors',
      'duration': '8:45',
      'views': '850K',
      'type': 'video',
      'addedDate': DateTime.now().subtract(const Duration(days: 4)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Favorites',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Lessons'),
            Tab(text: 'Words'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLessonsTab(),
          _buildWordsTab(),
          _buildVideosTab(),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    if (_favoriteLessons.isEmpty) {
      return _buildEmptyState(
        icon: Icons.book_rounded,
        title: 'No Favorite Lessons',
        subtitle: 'Start adding lessons to your favorites to see them here',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_favoriteLessons.length} Saved Lessons',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ..._favoriteLessons.map((lesson) => _buildLessonCard(lesson)),
        ],
      ),
    );
  }

  Widget _buildWordsTab() {
    if (_favoriteWords.isEmpty) {
      return _buildEmptyState(
        icon: Icons.language_rounded,
        title: 'No Favorite Words',
        subtitle: 'Save vocabulary words to review them later',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_favoriteWords.length} Saved Words',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ..._favoriteWords.map((word) => _buildWordCard(word)),
        ],
      ),
    );
  }

  Widget _buildVideosTab() {
    if (_favoriteVideos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.video_library_rounded,
        title: 'No Favorite Videos',
        subtitle: 'Save interesting videos to watch them again',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_favoriteVideos.length} Saved Videos',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ..._favoriteVideos.map((video) => _buildVideoCard(video)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Explore Content',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icons.explore_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lesson['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(
                            lesson['difficulty'],
                            _getDifficultyColor(lesson['difficulty']),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            lesson['duration'],
                            AppColors.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeFavorite(lesson['id'], 'lesson'),
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Added ${_formatDate(lesson['addedDate'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                CustomButton(
                  text: 'Start Lesson',
                  onPressed: () {
                    // TODO: Navigate to lesson
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Starting ${lesson['title']}')),
                    );
                  },
                  width: 100,
                  height: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(Map<String, dynamic> word) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.translate_rounded,
                  color: AppColors.success,
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
                        Text(
                          word['word'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          word['difficulty'],
                          _getDifficultyColor(word['difficulty']),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word['pronunciation'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeFavorite(word['id'], 'word'),
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            word['meaning'],
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Example:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${word['example']}"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Added ${_formatDate(word['addedDate'])}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Video Thumbnail
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    size: 64,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    onPressed: () => _removeFavorite(video['id'], 'video'),
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.error,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      video['duration'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${video['views']} views',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Added ${_formatDate(video['addedDate'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    CustomButton(
                      text: 'Watch',
                      onPressed: () {
                        // TODO: Open video player
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playing ${video['title']}')),
                        );
                      },
                      width: 80,
                      height: 32,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _removeFavorite(String id, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Remove Favorite'),
        content: Text('Remove this $type from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Remove',
            onPressed: () {
              setState(() {
                if (type == 'lesson') {
                  _favoriteLessons.removeWhere((item) => item['id'] == id);
                } else if (type == 'word') {
                  _favoriteWords.removeWhere((item) => item['id'] == id);
                } else if (type == 'video') {
                  _favoriteVideos.removeWhere((item) => item['id'] == id);
                }
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed from favorites')),
              );
            },
            width: 100,
            height: 40,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
} 
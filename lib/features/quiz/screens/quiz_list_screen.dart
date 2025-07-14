import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/quiz_service.dart';
import '../../../models/quiz_model.dart';
import 'quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  List<QuizModel> _allQuizzes = [];
  List<QuizModel> _filteredQuizzes = [];
  bool _isLoading = true;
  
  final List<String> _categories = ['All', 'Grammar', 'Vocabulary', 'Speaking', 'Listening', 'Writing'];
  final List<String> _difficulties = ['All', 'Beginner', 'Elementary', 'Intermediate', 'Upper Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadQuizzes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    try {
      setState(() => _isLoading = true);
      
      // Get all quizzes, then filter for standalone ones (no lessonId)
      final allQuizzes = await QuizService.getAllQuizzes();
      final standaloneQuizzes = allQuizzes.where((quiz) => quiz.lessonId == null).toList();
      
      setState(() {
        _allQuizzes = standaloneQuizzes;
        _isLoading = false;
      });
      
      _filterQuizzes();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải quiz: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterQuizzes() {
    List<QuizModel> filtered = List.from(_allQuizzes);
    
    // Category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((quiz) => quiz.category == _selectedCategory).toList();
    }
    
    // Difficulty filter  
    if (_selectedDifficulty != 'All') {
      filtered = filtered.where((quiz) => quiz.difficultyLevelName == _selectedDifficulty).toList();
    }
    
    setState(() {
      _filteredQuizzes = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Practice Quizzes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showSearch(
                context: context,
                delegate: QuizSearchDelegate(_allQuizzes),
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
            Tab(text: 'All Quizzes'),
            Tab(text: 'My Results'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllQuizzesTab(),
          _buildMyResultsTab(),
          _buildCategoriesTab(),
        ],
      ),
    );
  }

  Widget _buildAllQuizzesTab() {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
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
                            _filterQuizzes();
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
              
              const SizedBox(height: 12),
              
              // Difficulty filter
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
                            _filterQuizzes();
                          });
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
        
        // Quiz list
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuizzes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredQuizzes.length,
                    itemBuilder: (context, index) {
                      return _buildQuizCard(_filteredQuizzes[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyResultsTab() {
    return FutureBuilder<List<QuizResult>>(
      future: QuizService.getUserQuizResults(),
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
                  'Error loading results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No quiz results yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take some quizzes to see your results here',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return _buildResultCard(results[index]);
          },
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    final categoryGroups = <String, List<QuizModel>>{};
    
    for (var quiz in _allQuizzes) {
      if (!categoryGroups.containsKey(quiz.category)) {
        categoryGroups[quiz.category] = [];
      }
      categoryGroups[quiz.category]!.add(quiz);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categoryGroups.keys.length,
      itemBuilder: (context, index) {
        final category = categoryGroups.keys.elementAt(index);
        final quizzes = categoryGroups[category]!;
        
        return _buildCategorySection(category, quizzes);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No quizzes available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for new practice quizzes',
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

  Widget _buildQuizCard(QuizModel quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCategoryColor(quiz.category),
                  _getCategoryColor(quiz.category).withOpacity(0.8),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(quiz.category),
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
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildQuizStat(
                        Icons.quiz,
                        '${quiz.questions.length} questions',
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
                        Icons.signal_cellular_alt,
                        quiz.difficultyLevelName,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Best result or start button
                FutureBuilder<QuizResult?>(
                  future: QuizService.getUserBestResult(quiz.id),
                  builder: (context, resultSnapshot) {
                    final bestResult = resultSnapshot.data;
                    
                    if (bestResult != null) {
                      return _buildQuizResultRow(bestResult, quiz);
                    }
                    
                    return _buildStartQuizButton(quiz);
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResultRow(QuizResult result, QuizModel quiz) {
    Color resultColor = result.passed ? Colors.green : Colors.red;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  result.passed ? Icons.check_circle : Icons.cancel,
                  color: resultColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Best: ${result.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: resultColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _startQuiz(quiz),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getCategoryColor(quiz.category),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Retake',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStartQuizButton(QuizModel quiz) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _startQuiz(quiz),
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text(
          'Start Quiz',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getCategoryColor(quiz.category),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(QuizResult result) {
    Color resultColor = result.passed ? Colors.green : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resultColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: resultColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Quiz Result',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                    Text(
                      '${result.percentage.toStringAsFixed(1)}% (${result.score}/${result.totalPoints})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(result.completedAt),
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

  Widget _buildCategorySection(String category, List<QuizModel> quizzes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getCategoryColor(category).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(category),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${quizzes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...quizzes.take(3).map((quiz) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCompactQuizCard(quiz),
              )),
          if (quizzes.length > 3)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = category;
                    _tabController.animateTo(0);
                    _filterQuizzes();
                  });
                },
                child: Text(
                  'View all ${quizzes.length} quizzes',
                  style: TextStyle(
                    color: _getCategoryColor(category),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactQuizCard(QuizModel quiz) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCategoryColor(quiz.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.quiz,
              color: _getCategoryColor(quiz.category),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${quiz.questions.length} questions • ${quiz.difficultyLevelName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _startQuiz(quiz),
            icon: Icon(
              Icons.play_arrow,
              color: _getCategoryColor(quiz.category),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Grammar': return const Color(0xFF8B5CF6);
      case 'Vocabulary': return const Color(0xFF06B6D4);
      case 'Speaking': return const Color(0xFF10B981);
      case 'Listening': return const Color(0xFFF59E0B);
      case 'Writing': return const Color(0xFFEF4444);
      default: return AppColors.secondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Grammar': return Icons.menu_book_rounded;
      case 'Vocabulary': return Icons.library_books_rounded;
      case 'Speaking': return Icons.record_voice_over_rounded;
      case 'Listening': return Icons.headphones_rounded;
      case 'Writing': return Icons.edit_rounded;
      default: return Icons.quiz_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _startQuiz(QuizModel quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(quiz: quiz),
      ),
    ).then((result) {
      // Refresh when returning from quiz
      setState(() {});
    });
  }
}

// Search delegate for quizzes
class QuizSearchDelegate extends SearchDelegate<QuizModel> {
  final List<QuizModel> quizzes;

  QuizSearchDelegate(this.quizzes);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, quizzes.first);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = quizzes.where((quiz) =>
        quiz.title.toLowerCase().contains(query.toLowerCase()) ||
        quiz.description.toLowerCase().contains(query.toLowerCase()) ||
        quiz.category.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final quiz = results[index];
        return ListTile(
          title: Text(quiz.title),
          subtitle: Text('${quiz.category} • ${quiz.questions.length} questions'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreen(quiz: quiz),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = quizzes.where((quiz) =>
        quiz.title.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final quiz = suggestions[index];
        return ListTile(
          title: Text(quiz.title),
          subtitle: Text(quiz.category),
          onTap: () {
            query = quiz.title;
            showResults(context);
          },
        );
      },
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/learning_progress_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../models/user_model.dart';

class LearningHistoryScreen extends StatefulWidget {
  final UserModel? user;

  const LearningHistoryScreen({super.key, this.user});

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Real data from Firebase
  List<Map<String, dynamic>> _lessonHistory = [];
  List<Map<String, dynamic>> _quizHistory = [];
  List<Map<String, dynamic>> _vocabularyHistory = [];
  
  // Filtered data for search
  List<Map<String, dynamic>> _filteredLessonHistory = [];
  List<Map<String, dynamic>> _filteredQuizHistory = [];
  List<Map<String, dynamic>> _filteredVocabularyHistory = [];
  
  // Search controllers
  final TextEditingController _lessonSearchController = TextEditingController();
  final TextEditingController _quizSearchController = TextEditingController();
  final TextEditingController _vocabularySearchController = TextEditingController();
  
  // Loading states
  bool _isLoadingLessons = true;
  bool _isLoadingQuizzes = true;
  bool _isLoadingVocabulary = true;
  
  // Error states
  String? _lessonError;
  String? _quizError;
  String? _vocabularyError;

  // Sorting and filtering states
  String _sortBy = 'date'; // date, score, title
  bool _sortAscending = false;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lessonSearchController.dispose();
    _quizSearchController.dispose();
    _vocabularySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadLessonHistory(),
      _loadQuizHistory(),
      _loadVocabularyHistory(),
    ]);
  }

  Future<void> _loadLessonHistory() async {
    try {
      setState(() {
        _isLoadingLessons = true;
        _lessonError = null;
      });

      // Get lesson progress from Firebase using the detailed method
      final allHistory = await LearningProgressService.getDetailedLearningHistory(limit: 20);
      
      // Filter for lessons only - data is already in the correct format
      final lessonHistory = allHistory
          .where((activity) => activity['type'] == 'lesson')
          .toList();

      // Fetch actual lesson titles from lessons collection
      final lessonIds = lessonHistory.map((lesson) => lesson['lessonId'] as String).where((id) => id.isNotEmpty).toList();
      final lessonTitles = <String, String>{};
      
      if (lessonIds.isNotEmpty) {
        try {
          final lessonsSnapshot = await FirebaseFirestore.instance
              .collection('lessons')
              .where(FieldPath.documentId, whereIn: lessonIds)
              .get();
          
          for (var doc in lessonsSnapshot.docs) {
            final data = doc.data();
            lessonTitles[doc.id] = data['title'] ?? 'Unknown Lesson';
          }
        } catch (e) {
          print('Error fetching lesson titles: $e');
        }
      }

      // Update lesson titles with actual titles
      for (var lesson in lessonHistory) {
        final lessonId = lesson['lessonId'] as String;
        if (lessonId.isNotEmpty && lessonTitles.containsKey(lessonId)) {
          lesson['title'] = lessonTitles[lessonId]!;
        }
      }

      if (mounted) {
        setState(() {
          _lessonHistory = lessonHistory;
          _filteredLessonHistory = lessonHistory;
          _isLoadingLessons = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lessonError = 'Failed to load lesson history: $e';
          _isLoadingLessons = false;
        });
      }
    }
  }

  Future<void> _loadQuizHistory() async {
    try {
      setState(() {
        _isLoadingQuizzes = true;
        _quizError = null;
      });

      // Get quiz history from Firebase
      final userId = widget.user?.uid;
      if (userId == null) {
        setState(() {
          _quizHistory = [];
          _isLoadingQuizzes = false;
        });
        return;
      }

      // Use the correct collection path - quiz_results is a top-level collection
      final quizHistory = await FirebaseFirestore.instance
          .collection('quiz_results')
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(20)
          .get();

      final quizData = quizHistory.docs.map((doc) {
        final data = doc.data();
        final score = (data['score'] ?? 0).round();
        final totalQuestions = data['totalQuestions'] ?? 0;
        final correctAnswers = data['correctAnswers'] ?? 0;
        
        return {
          'title': data['quizTitle'] ?? 'Unknown Quiz',
          'date': (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'score': score,
          'type': 'quiz',
          'status': 'completed',
          'totalQuestions': totalQuestions,
          'correctAnswers': correctAnswers,
          'timeSpent': data['timeSpent'] ?? 0,
          'category': data['category'] ?? 'General',
          'difficulty': data['difficulty'] ?? 'Beginner',
          'accuracy': totalQuestions > 0 ? ((correctAnswers / totalQuestions) * 100).round() : 0,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _quizHistory = quizData;
          _filteredQuizHistory = quizData;
          _isLoadingQuizzes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quizError = 'Failed to load quiz history: $e';
          _isLoadingQuizzes = false;
        });
      }
    }
  }

  Future<void> _loadVocabularyHistory() async {
    try {
      setState(() {
        _isLoadingVocabulary = true;
        _vocabularyError = null;
      });

      // Get vocabulary learning history from Firebase using the detailed method
      final allHistory = await LearningProgressService.getDetailedLearningHistory(limit: 20);
      
      // Filter for vocabulary only - data is already in the correct format
      final vocabData = allHistory
          .where((activity) => activity['type'] == 'vocabulary')
          .toList();

      if (mounted) {
        setState(() {
          _vocabularyHistory = vocabData;
          _filteredVocabularyHistory = vocabData;
          _isLoadingVocabulary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _vocabularyError = 'Failed to load vocabulary history: $e';
          _isLoadingVocabulary = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadAllData();
  }

  // Search and filter methods
  void _filterLessonHistory(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredLessonHistory = _lessonHistory;
      });
    } else {
      setState(() {
        _filteredLessonHistory = _lessonHistory.where((lesson) {
          final title = lesson['title'].toString().toLowerCase();
          return title.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void _filterQuizHistory(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredQuizHistory = _quizHistory;
      });
    } else {
      setState(() {
        _filteredQuizHistory = _quizHistory.where((quiz) {
          final title = quiz['title'].toString().toLowerCase();
          final category = quiz['category'].toString().toLowerCase();
          return title.contains(query.toLowerCase()) || 
                 category.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void _filterVocabularyHistory(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredVocabularyHistory = _vocabularyHistory;
      });
    } else {
      setState(() {
        _filteredVocabularyHistory = _vocabularyHistory.where((word) {
          final wordText = word['word'].toString().toLowerCase();
          final translation = word['translation'].toString().toLowerCase();
          final category = word['category'].toString().toLowerCase();
          return wordText.contains(query.toLowerCase()) || 
                 translation.contains(query.toLowerCase()) ||
                 category.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Learning History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'sort':
                  _showSortDialog();
                  break;
                case 'filter':
                  _showDateFilterDialog();
                  break;
                case 'export':
                  _showExportDialog();
                  break;
                case 'refresh':
                  _refreshData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort',
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 20),
                    SizedBox(width: 12),
                    Text('Sort'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 20),
                    SizedBox(width: 12),
                    Text('Date Filter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Export/Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Lessons'),
            Tab(text: 'Quizzes'),
            Tab(text: 'Vocabulary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLessonsTab(),
          _buildQuizzesTab(),
          _buildVocabularyTab(),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    if (_isLoadingLessons) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading lesson history...'),
          ],
        ),
      );
    }

    if (_lessonError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _lessonError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLessonHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLessonHistory,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Summary Card
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
                      Icon(
                        Icons.book_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lesson Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                                                         Text(
                               '${_filteredLessonHistory.length} of ${_lessonHistory.length} lessons',
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                                             Expanded(
                         child: _buildSummaryItem(
                           'Total Score',
                           '${_calculateAverageScore(_filteredLessonHistory)}%',
                         ),
                       ),
                       Expanded(
                         child: _buildSummaryItem(
                           'Best Score',
                           '${_findBestScore(_filteredLessonHistory)}%',
                         ),
                       ),
                       Expanded(
                         child: _buildSummaryItem(
                           'This Week',
                           _getThisWeekCount(_filteredLessonHistory).toString(),
                         ),
                       ),
                    ],
                  ),
                ],
              ),
            ),
                         const SizedBox(height: 24),
             // Search Bar
             Container(
               margin: const EdgeInsets.only(bottom: 16),
               child: TextField(
                 controller: _lessonSearchController,
                 onChanged: _filterLessonHistory,
                 decoration: InputDecoration(
                   hintText: 'Search lessons...',
                   prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                   suffixIcon: _lessonSearchController.text.isNotEmpty
                       ? IconButton(
                           icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                           onPressed: () {
                             _lessonSearchController.clear();
                             _filterLessonHistory('');
                           },
                         )
                       : null,
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: const BorderSide(color: AppColors.border),
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: const BorderSide(color: AppColors.border),
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: const BorderSide(color: AppColors.primary),
                   ),
                   filled: true,
                   fillColor: Colors.white,
                 ),
               ),
             ),
             // Lessons List
             if (_filteredLessonHistory.isEmpty)
               _buildEmptyState(
                 _lessonHistory.isEmpty 
                   ? 'No lessons completed yet' 
                   : 'No lessons found matching your search',
                 Icons.book_outlined
               )
             else
               ..._filteredLessonHistory.map((lesson) => _buildLessonCard(lesson)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesTab() {
    if (_isLoadingQuizzes) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.secondary),
            SizedBox(height: 16),
            Text('Loading quiz history...'),
          ],
        ),
      );
    }

    if (_quizError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _quizError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuizHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuizHistory,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.secondary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.quiz_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quiz Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                                                         Text(
                               '${_filteredQuizHistory.length} of ${_quizHistory.length} quizzes',
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                                             Expanded(
                         child: _buildSummaryItem(
                           'Average',
                           '${_calculateAverageScore(_filteredQuizHistory)}%',
                         ),
                       ),
                       Expanded(
                         child: _buildSummaryItem(
                           'Best Score',
                           '${_findBestScore(_filteredQuizHistory)}%',
                         ),
                       ),
                       Expanded(
                         child: _buildSummaryItem(
                           'This Week',
                           _getThisWeekCount(_filteredQuizHistory).toString(),
                         ),
                       ),
                    ],
                  ),
                ],
              ),
            ),
                         const SizedBox(height: 24),
             // Search Bar
             Container(
               margin: const EdgeInsets.only(bottom: 16),
               child: TextField(
                 controller: _quizSearchController,
                 onChanged: _filterQuizHistory,
                 decoration: InputDecoration(
                   hintText: 'Search quizzes...',
                   prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                   suffixIcon: _quizSearchController.text.isNotEmpty
                       ? IconButton(
                           icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                           onPressed: () {
                             _quizSearchController.clear();
                             _filterQuizHistory('');
                           },
                         )
                       : null,
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: const BorderSide(color: AppColors.border),
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: const BorderSide(color: AppColors.border),
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: const BorderSide(color: AppColors.secondary),
                   ),
                   filled: true,
                   fillColor: Colors.white,
                 ),
               ),
             ),
             // Quizzes List
             if (_filteredQuizHistory.isEmpty)
               _buildEmptyState(
                 _quizHistory.isEmpty 
                   ? 'No quizzes completed yet' 
                   : 'No quizzes found matching your search',
                 Icons.quiz_outlined
               )
             else
               ..._filteredQuizHistory.map((quiz) => _buildQuizCard(quiz)),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabularyTab() {
    if (_isLoadingVocabulary) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.success),
            SizedBox(height: 16),
            Text('Loading vocabulary history...'),
          ],
        ),
      );
    }

    if (_vocabularyError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _vocabularyError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVocabularyHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVocabularyHistory,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, const Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vocabulary Progress',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                                                         Text(
                               '${_filteredVocabularyHistory.length} of ${_vocabularyHistory.length} words',
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                                             Expanded(
                         child: _buildSummaryItem(
                           'Learned',
                           _filteredVocabularyHistory.where((w) => w['mastery'] == 'learned').length.toString(),
                         ),
                       ),
                       Expanded(
                         child: _buildSummaryItem(
                           'Practicing',
                           _filteredVocabularyHistory.where((w) => w['mastery'] == 'practicing').length.toString(),
                         ),
                       ),
                       Expanded(
                         child: _buildSummaryItem(
                           'This Week',
                           _getThisWeekCount(_filteredVocabularyHistory).toString(),
                         ),
                       ),
                    ],
                  ),
                ],
              ),
            ),
                         const SizedBox(height: 24),
             // Search Bar
             Container(
               margin: const EdgeInsets.only(bottom: 16),
               child: TextField(
                 controller: _vocabularySearchController,
                 onChanged: _filterVocabularyHistory,
                 decoration: InputDecoration(
                   hintText: 'Search vocabulary...',
                   prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                   suffixIcon: _vocabularySearchController.text.isNotEmpty
                       ? IconButton(
                           icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                           onPressed: () {
                             _vocabularySearchController.clear();
                             _filterVocabularyHistory('');
                           },
                         )
                       : null,
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: const BorderSide(color: AppColors.border),
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: const BorderSide(color: AppColors.border),
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(12),
                     borderSide: const BorderSide(color: AppColors.success),
                   ),
                   filled: true,
                   fillColor: Colors.white,
                 ),
               ),
             ),
             // Vocabulary List
             if (_filteredVocabularyHistory.isEmpty)
               _buildEmptyState(
                 _vocabularyHistory.isEmpty 
                   ? 'No vocabulary learned yet' 
                   : 'No vocabulary found matching your search',
                 Icons.language_outlined
               )
             else
               ..._filteredVocabularyHistory.map((word) => _buildVocabularyCard(word)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    return GestureDetector(
      onTap: () => _showItemDetails(lesson),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(lesson['timeSpent'] ?? 0),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(lesson['score']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${lesson['score']}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(lesson['score']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(lesson['date']),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    return GestureDetector(
      onTap: () => _showItemDetails(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.1),
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
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz_rounded,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quiz['category'] ?? 'General',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quiz['difficulty'] ?? 'Beginner',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(quiz['score']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${quiz['score']}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(quiz['score']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuizDetailItem(
                  'Questions',
                  '${quiz['correctAnswers']}/${quiz['totalQuestions']}',
                  Icons.question_answer,
                ),
              ),
              Expanded(
                child: _buildQuizDetailItem(
                  'Accuracy',
                  '${quiz['accuracy']}%',
                  Icons.track_changes,
                ),
              ),
              Expanded(
                child: _buildQuizDetailItem(
                  'Time',
                  _formatDuration(quiz['timeSpent']),
                  Icons.timer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(quiz['date']),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildQuizDetailItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVocabularyCard(Map<String, dynamic> word) {
    final bool isLearned = word['mastery'] == 'learned';
    
    return GestureDetector(
      onTap: () => _showItemDetails(word),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withOpacity(0.2),
          width: 1,
        ),
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
                    Text(
                      word['word'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word['translation'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            word['partOfSpeech'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            word['difficulty'] ?? 'Beginner',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLearned 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLearned ? Icons.check_circle : Icons.timer,
                      size: 14,
                      color: isLearned ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLearned ? 'Learned' : 'Practicing',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLearned ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildVocabularyDetailItem(
                  'Practice',
                  '${word['practiceCount']} times',
                  Icons.repeat,
                ),
              ),
              Expanded(
                child: _buildVocabularyDetailItem(
                  'Accuracy',
                  '${word['accuracy']}%',
                  Icons.track_changes,
                ),
              ),
              Expanded(
                child: _buildVocabularyDetailItem(
                  'Category',
                  word['category'] ?? 'General',
                  Icons.category,
                ),
              ),
            ],
          ),
          if (word['example'] != null && word['example'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                'Example: ${word['example']}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _formatDate(word['date']),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildVocabularyDetailItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
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

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 80) return AppColors.primary;
    if (score >= 70) return AppColors.warning;
    return AppColors.error;
  }

  int _calculateAverageScore(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 0;
    final total = items.fold<int>(0, (sum, item) => sum + (item['score'] as int));
    return (total / items.length).round();
  }

  int _findBestScore(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 0;
    return items.map<int>((item) => item['score'] as int).reduce((a, b) => a > b ? a : b);
  }

  int _getThisWeekCount(List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return items.where((item) {
      final date = item['date'];
      return date != null && date is DateTime && date.isAfter(startOfWeek);
    }).length;
  }

  // Enhanced filtering and sorting methods
  List<Map<String, dynamic>> _applySortingAndFiltering(List<Map<String, dynamic>> items) {
    var filteredItems = items;

    // Apply date filtering
    if (_filterStartDate != null || _filterEndDate != null) {
      filteredItems = filteredItems.where((item) {
        final date = item['date'] as DateTime?;
        if (date == null) return false;
        
        if (_filterStartDate != null && date.isBefore(_filterStartDate!)) {
          return false;
        }
        if (_filterEndDate != null && date.isAfter(_filterEndDate!.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }

    // Apply sorting
    filteredItems.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'date':
          final dateA = a['date'] as DateTime? ?? DateTime.now();
          final dateB = b['date'] as DateTime? ?? DateTime.now();
          comparison = dateA.compareTo(dateB);
          break;
        case 'score':
          final scoreA = a['score'] as int? ?? 0;
          final scoreB = b['score'] as int? ?? 0;
          comparison = scoreA.compareTo(scoreB);
          break;
        case 'title':
          final titleA = a['title']?.toString() ?? '';
          final titleB = b['title']?.toString() ?? '';
          comparison = titleA.compareTo(titleB);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    return filteredItems;
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Date'),
              value: 'date',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
                _applySortingToCurrentTab();
              },
            ),
            RadioListTile<String>(
              title: const Text('Score'),
              value: 'score',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
                _applySortingToCurrentTab();
              },
            ),
            RadioListTile<String>(
              title: const Text('Title'),
              value: 'title',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
                _applySortingToCurrentTab();
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Ascending Order'),
              value: _sortAscending,
              onChanged: (value) {
                setState(() {
                  _sortAscending = value;
                });
                _applySortingToCurrentTab();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(_filterStartDate?.toString().split(' ')[0] ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filterStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _filterStartDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(_filterEndDate?.toString().split(' ')[0] ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filterEndDate ?? DateTime.now(),
                  firstDate: _filterStartDate ?? DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _filterEndDate = date;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStartDate = null;
                _filterEndDate = null;
              });
              Navigator.pop(context);
              _applySortingToCurrentTab();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applySortingToCurrentTab();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Learning History'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose export format:'),
            SizedBox(height: 16),
            Text('📊 Your learning progress summary will be generated.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateSummaryReport();
            },
            child: const Text('Generate Summary'),
          ),
        ],
      ),
    );
  }

  void _applySortingToCurrentTab() {
    setState(() {
      _filteredLessonHistory = _applySortingAndFiltering(_lessonHistory);
      _filteredQuizHistory = _applySortingAndFiltering(_quizHistory);
      _filteredVocabularyHistory = _applySortingAndFiltering(_vocabularyHistory);
    });
  }

  void _generateSummaryReport() {
    final totalLessons = _lessonHistory.length;
    final totalQuizzes = _quizHistory.length;
    final totalVocabulary = _vocabularyHistory.length;
    
    final avgLessonScore = _calculateAverageScore(_lessonHistory);
    final avgQuizScore = _calculateAverageScore(_quizHistory);
    
    final report = '''
📚 LEARNING HISTORY SUMMARY 📚

📖 Lessons Completed: $totalLessons
   Average Score: $avgLessonScore%
   Best Score: ${_findBestScore(_lessonHistory)}%

🧠 Quizzes Completed: $totalQuizzes
   Average Score: $avgQuizScore%
   Best Score: ${_findBestScore(_quizHistory)}%

📝 Vocabulary Practiced: $totalVocabulary words
   Learned: ${_vocabularyHistory.where((w) => w['mastery'] == 'learned').length}
   Practicing: ${_vocabularyHistory.where((w) => w['mastery'] == 'practicing').length}

🗓️ This Week Activity:
   Lessons: ${_getThisWeekCount(_lessonHistory)}
   Quizzes: ${_getThisWeekCount(_quizHistory)}
   Vocabulary: ${_getThisWeekCount(_vocabularyHistory)}

Generated on: ${DateTime.now().toString().split('.')[0]}
    ''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Learning Summary'),
        content: SingleChildScrollView(
          child: SelectableText(
            report,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard functionality could be added here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Summary ready! You can copy the text above.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    String details = '';
    String title = '';
    
    switch (item['type']) {
      case 'lesson':
        title = '📖 ${item['title']}';
        details = '''
📅 Date: ${_formatDate(item['date'])}
🎯 Score: ${item['score']}%
⏱️ Time Spent: ${_formatDuration(item['timeSpent'] ?? 0)}
📚 Status: ${item['status']}
        ''';
        break;
      case 'quiz':
        title = '🧠 ${item['title']}';
        details = '''
📅 Date: ${_formatDate(item['date'])}
🎯 Score: ${item['score']}%
✅ Correct: ${item['correctAnswers']}/${item['totalQuestions']}
📊 Accuracy: ${item['accuracy']}%
⏱️ Time Spent: ${_formatDuration(item['timeSpent'] ?? 0)}
📂 Category: ${item['category']}
📈 Difficulty: ${item['difficulty']}
        ''';
        break;
      case 'vocabulary':
        title = '📝 ${item['word']}';
        details = '''
🔤 Word: ${item['word']}
🌐 Translation: ${item['translation']}
📅 Date: ${_formatDate(item['date'])}
🎯 Mastery: ${item['mastery']}
🔄 Practice Count: ${item['practiceCount']}
📊 Accuracy: ${item['accuracy']}%
📂 Category: ${item['category']}
📈 Difficulty: ${item['difficulty']}
🗣️ Part of Speech: ${item['partOfSpeech']}
${item['example'].isNotEmpty ? '\n💡 Example: ${item['example']}' : ''}
        ''';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(details),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 
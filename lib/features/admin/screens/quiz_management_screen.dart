import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../models/quiz_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizManagementScreen extends StatefulWidget {
  const QuizManagementScreen({super.key});

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<QuizModel> _quizzes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Filter variables for statistics tab
  String _selectedCategory = 'Tất cả';
  String _selectedDifficulty = 'Tất cả';
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Filter variables for quiz tabs
  String _quizSelectedCategory = 'Tất cả';
  String _quizSelectedDifficulty = 'Tất cả';
  DateTime? _quizStartDate;
  DateTime? _quizEndDate;
  bool _showQuizFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to show/hide search section
    });
    _loadQuizzes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final quizzes = await QuizService.getAllQuizzesForAdmin();
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách quiz: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<QuizModel> get _activeQuizzes {
    List<QuizModel> activeQuizzes = _quizzes.where((quiz) => quiz.isActive).toList();
    
    // Apply filters
    activeQuizzes = _applyQuizFilters(activeQuizzes);
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      activeQuizzes = activeQuizzes.where((quiz) {
        return quiz.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               quiz.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               quiz.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return activeQuizzes;
  }
  
  List<QuizModel> get _inactiveQuizzes {
    List<QuizModel> inactiveQuizzes = _quizzes.where((quiz) => !quiz.isActive).toList();
    
    // Apply filters
    inactiveQuizzes = _applyQuizFilters(inactiveQuizzes);
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      inactiveQuizzes = inactiveQuizzes.where((quiz) {
        return quiz.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               quiz.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               quiz.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return inactiveQuizzes;
  }
  
  List<QuizModel> _applyQuizFilters(List<QuizModel> quizzes) {
    List<QuizModel> filtered = quizzes;
    
    // Filter by category
    if (_quizSelectedCategory != 'Tất cả') {
      filtered = filtered.where((quiz) => quiz.category == _quizSelectedCategory).toList();
    }
    
    // Filter by difficulty
    if (_quizSelectedDifficulty != 'Tất cả') {
      final difficultyLevel = int.tryParse(_quizSelectedDifficulty) ?? 1;
      filtered = filtered.where((quiz) => quiz.difficultyLevel == difficultyLevel).toList();
    }
    
    // Filter by date range
    if (_quizStartDate != null) {
      filtered = filtered.where((quiz) => quiz.createdAt.isAfter(_quizStartDate!)).toList();
    }
    if (_quizEndDate != null) {
      filtered = filtered.where((quiz) => quiz.createdAt.isBefore(_quizEndDate!.add(const Duration(days: 1)))).toList();
    }
    
    return filtered;
  }

  // Filtered quizzes for statistics tab
  List<QuizModel> get _filteredQuizzes {
    List<QuizModel> filtered = _quizzes;
    
    // Filter by category
    if (_selectedCategory != 'Tất cả') {
      filtered = filtered.where((quiz) => quiz.category == _selectedCategory).toList();
    }
    
    // Filter by difficulty
    if (_selectedDifficulty != 'Tất cả') {
      final difficultyLevel = int.tryParse(_selectedDifficulty) ?? 1;
      filtered = filtered.where((quiz) => quiz.difficultyLevel == difficultyLevel).toList();
    }
    
    // Filter by date range
    if (_startDate != null) {
      filtered = filtered.where((quiz) => quiz.createdAt.isAfter(_startDate!)).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((quiz) => quiz.createdAt.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }
    
    return filtered;
  }

  // Get unique categories for filter
  List<String> get _categories {
    final categories = _quizzes.map((q) => q.category).toSet().toList();
    categories.sort();
    return ['Tất cả', ...categories];
  }

  // Temporary helper method for testing - makes current user admin
  Future<void> _makeCurrentUserAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseService.updateUserDocument(
          uid: user.uid,
          userData: {'role': 'admin'},
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ User role updated to admin! Please restart the app.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error updating user role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Tất cả';
      _selectedDifficulty = 'Tất cả';
      _startDate = null;
      _endDate = null;
    });
  }
  
  void _resetQuizFilters() {
    setState(() {
      _quizSelectedCategory = 'Tất cả';
      _quizSelectedDifficulty = 'Tất cả';
      _quizStartDate = null;
      _quizEndDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quản lý Quiz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Quiz Hoạt động',
            ),
            Tab(
              icon: Icon(Icons.pause_circle),
              text: 'Quiz Tạm dừng',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Thống kê',
            ),
          ],
        ),
        actions: [
          // Temporary admin button for testing
          IconButton(
            onPressed: _makeCurrentUserAdmin,
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Cấp quyền Admin (Test)',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadQuizzes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Add Section (only for quiz tabs)
          if (_tabController.index < 2)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Search and Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm quiz...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => setState(() => _showQuizFilters = !_showQuizFilters),
                        icon: Icon(
                          _showQuizFilters ? Icons.filter_list_off : Icons.filter_list,
                          color: _showQuizFilters ? AppColors.primary : Colors.grey,
                        ),
                        tooltip: 'Bộ lọc',
                      ),
                    ],
                  ),
                  
                  // Filter Section
                  if (_showQuizFilters) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Bộ lọc Quiz',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _resetQuizFilters,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Đặt lại'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Filter Row 1
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _quizSelectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Danh mục',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: _categories.map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat, style: const TextStyle(fontSize: 14)),
                                  )).toList(),
                                  onChanged: (value) => setState(() => _quizSelectedCategory = value ?? 'Tất cả'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _quizSelectedDifficulty,
                                  decoration: InputDecoration(
                                    labelText: 'Độ khó',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: ['Tất cả', '1', '2', '3', '4', '5'].map((diff) => DropdownMenuItem(
                                    value: diff,
                                    child: Text(diff == 'Tất cả' ? diff : 'Cấp $diff', style: const TextStyle(fontSize: 14)),
                                  )).toList(),
                                  onChanged: (value) => setState(() => _quizSelectedDifficulty = value ?? 'Tất cả'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Filter Row 2 - Date Range
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _quizStartDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() => _quizStartDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          _quizStartDate != null 
                                              ? '${_quizStartDate!.day}/${_quizStartDate!.month}/${_quizStartDate!.year}'
                                              : 'Từ ngày',
                                          style: TextStyle(
                                            color: _quizStartDate != null ? AppColors.textPrimary : Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _quizEndDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() => _quizEndDate = date);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          _quizEndDate != null 
                                              ? '${_quizEndDate!.day}/${_quizEndDate!.month}/${_quizEndDate!.year}'
                                              : 'Đến ngày',
                                          style: TextStyle(
                                            color: _quizEndDate != null ? AppColors.textPrimary : Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Add Quiz Button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Tạo Quiz Mới',
                      onPressed: () => _showCreateQuizDialog(),
                      color: AppColors.success,
                      icon: Icons.add_rounded,
                    ),
                  ),
                ],
              ),
            ),
          
          // Quiz Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Quizzes Tab
                _buildQuizList(_activeQuizzes, true),
                // Inactive Quizzes Tab  
                _buildQuizList(_inactiveQuizzes, false),
                // Statistics Tab
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredQuizzes = _filteredQuizzes;
    final totalQuizzes = filteredQuizzes.length;
    final activeQuizzes = filteredQuizzes.where((q) => q.isActive).length;
    final categories = filteredQuizzes.map((q) => q.category).toSet().length;
    final totalQuestions = filteredQuizzes.fold(0, (sum, q) => sum + q.questions.length);
    final totalPoints = filteredQuizzes.fold(0, (sum, q) => sum + q.questions.fold(0, (qSum, question) => qSum + question.points));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Bộ lọc',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Đặt lại'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Filter Row 1
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Danh mục',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value ?? 'Tất cả'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDifficulty,
                        decoration: InputDecoration(
                          labelText: 'Độ khó',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: ['Tất cả', '1', '2', '3', '4', '5'].map((diff) => DropdownMenuItem(
                          value: diff,
                          child: Text(diff == 'Tất cả' ? diff : 'Cấp $diff', style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedDifficulty = value ?? 'Tất cả'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Filter Row 2 - Date Range
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _startDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _startDate != null 
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                    : 'Từ ngày',
                                style: TextStyle(
                                  color: _startDate != null ? AppColors.textPrimary : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _endDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _endDate != null 
                                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : 'Đến ngày',
                                style: TextStyle(
                                  color: _endDate != null ? AppColors.textPrimary : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Statistics Cards
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 3,
                child: _buildStatCard(
                  title: 'Tổng Quiz',
                  value: '$totalQuizzes',
                  icon: Icons.quiz_rounded,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 3,
                child: _buildStatCard(
                  title: 'Hoạt động',
                  value: '$activeQuizzes',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 3,
                child: _buildStatCard(
                  title: 'Danh mục',
                  value: '$categories',
                  icon: Icons.category_rounded,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 3,
                child: _buildStatCard(
                  title: 'Câu hỏi',
                  value: '$totalQuestions',
                  icon: Icons.question_answer_rounded,
                  color: Colors.blue,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 3,
                child: _buildStatCard(
                  title: 'Tổng điểm',
                  value: '$totalPoints',
                  icon: Icons.stars_rounded,
                  color: Colors.orange,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 64) / 3,
                child: _buildStatCard(
                  title: 'Tỷ lệ',
                  value: totalQuizzes > 0 ? '${((activeQuizzes / totalQuizzes) * 100).toStringAsFixed(1)}%' : '0%',
                  icon: Icons.trending_up_rounded,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Category Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê theo danh mục',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildCategoryStats(),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Difficulty Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê theo độ khó',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildDifficultyStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryStats() {
    final categoryMap = <String, int>{};
    for (final quiz in _filteredQuizzes) {
      categoryMap[quiz.category] = (categoryMap[quiz.category] ?? 0) + 1;
    }
    
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories.map((entry) {
      final percentage = _filteredQuizzes.isNotEmpty 
          ? (entry.value / _filteredQuizzes.length * 100).toStringAsFixed(1)
          : '0.0';
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getCategoryColor(entry.key),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${entry.value} (${percentage}%)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildDifficultyStats() {
    final difficultyMap = <int, int>{};
    for (final quiz in _filteredQuizzes) {
      difficultyMap[quiz.difficultyLevel] = (difficultyMap[quiz.difficultyLevel] ?? 0) + 1;
    }
    
    return List.generate(5, (index) {
      final level = index + 1;
      final count = difficultyMap[level] ?? 0;
      final percentage = _filteredQuizzes.isNotEmpty 
          ? (count / _filteredQuizzes.length * 100).toStringAsFixed(1)
          : '0.0';
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getDifficultyColor(level),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cấp $level',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$count (${percentage}%)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    });
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      case 5: return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _buildQuizList(List<QuizModel> quizzes, bool isActiveTab) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (quizzes.isEmpty) {
      return _buildEmptyState(isActiveTab);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        return _buildQuizCard(quizzes[index]);
      },
    );
  }

  Widget _buildEmptyState([bool isActiveTab = true]) {
    final hasFilters = _quizSelectedCategory != 'Tất cả' || 
                      _quizSelectedDifficulty != 'Tất cả' || 
                      _quizStartDate != null || 
                      _quizEndDate != null ||
                      _searchQuery.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off : Icons.quiz_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            hasFilters 
                ? 'Không tìm thấy quiz phù hợp'
                : (isActiveTab ? 'Không tìm thấy quiz hoạt động' : 'Không có quiz bị tạm dừng'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                : (isActiveTab 
                    ? 'Tạo quiz đầu tiên để bắt đầu'
                    : 'Các quiz bị tạm dừng sẽ hiển thị ở đây'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (hasFilters)
            CustomButton(
              text: 'Đặt lại bộ lọc',
              onPressed: () {
                setState(() {
                  _resetQuizFilters();
                  _searchQuery = '';
                });
              },
              color: AppColors.warning,
              icon: Icons.refresh_rounded,
            )
          else if (isActiveTab)
            CustomButton(
              text: 'Tạo Quiz',
              onPressed: () => _showCreateQuizDialog(),
              color: AppColors.primary,
              icon: Icons.add_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(QuizModel quiz) {
    // Calculate total points from questions
    int totalPoints = quiz.questions.fold(0, (sum, q) => sum + q.points);
    
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(quiz.category),
                    color: Colors.white,
                    size: 20,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        quiz.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: quiz.isActive 
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quiz.isActive ? 'Hoạt động' : 'Tạm dừng',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: quiz.isActive ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quiz.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildQuizStat(
                        Icons.quiz_rounded,
                        '${quiz.questions.length} câu hỏi',
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildQuizStat(
                        Icons.schedule_rounded,
                        '${quiz.timeLimit} phút',
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildQuizStat(
                        Icons.signal_cellular_alt_rounded,
                        quiz.difficultyLevelName,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Sửa',
                        onPressed: () => _showEditQuizDialog(quiz),
                        color: AppColors.primary,
                        icon: Icons.edit_rounded,
                        height: 36,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: quiz.isActive ? 'Tạm dừng' : 'Kích hoạt',
                        onPressed: () => _toggleQuizStatus(quiz),
                        color: quiz.isActive ? AppColors.warning : AppColors.success,
                        icon: quiz.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        height: 36,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: 'Xóa',
                        onPressed: () => _showDeleteQuizDialog(quiz),
                        color: AppColors.error,
                        icon: Icons.delete_rounded,
                        height: 36,
                      ),
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

  Widget _buildQuizStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'grammar':
        return Colors.blue;
      case 'vocabulary':
        return Colors.green;
      case 'listening':
        return Colors.purple;
      case 'speaking':
        return Colors.orange;
      case 'writing':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grammar':
        return Icons.library_books_rounded;
      case 'vocabulary':
        return Icons.book_rounded;
      case 'listening':
        return Icons.headphones_rounded;
      case 'speaking':
        return Icons.mic_rounded;
      case 'writing':
        return Icons.edit_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  void _showQuizFormDialog({QuizModel? quiz}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Quiz Form',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: QuizFormDialog(
            quiz: quiz,
            onSaved: (saved) async {
              Navigator.of(context).pop();
              await _loadQuizzes();
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  void _showCreateQuizDialog() {
    _showQuizFormDialog();
  }

  void _showEditQuizDialog(QuizModel quiz) {
    _showQuizFormDialog(quiz: quiz);
  }

  void _toggleQuizStatus(QuizModel quiz) async {
    try {
      final updatedQuiz = quiz.copyWith(
        isActive: !quiz.isActive,
        updatedAt: DateTime.now(),
      );

      await QuizService.updateQuiz(updatedQuiz);
      await _loadQuizzes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz đã ${quiz.isActive ? 'tạm dừng' : 'kích hoạt'} thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật quiz: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteQuizDialog(QuizModel quiz) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xóa Quiz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${quiz.title}"? Hành động này không thể hoàn tác.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          CustomButton(
            text: 'Xóa',
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              
              try {
               final success = await QuizService.deleteQuiz(quiz.id);
               if (mounted) {
                 await _loadQuizzes();
                 
                 if (mounted && success) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('Xóa quiz thành công'),
                       backgroundColor: AppColors.success,
                     ),
                   );
                 } else if (mounted && !success) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('Không thể xóa quiz'),
                       backgroundColor: AppColors.error,
                     ),
                   );
                 }
               }
              } catch (e) {
                if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi xóa quiz: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            color: AppColors.error,
            width: 80,
            height: 36,
          ),
        ],
      ),
    );
  }
}

class QuizFormDialog extends StatefulWidget {
  final QuizModel? quiz;
  final Future<void> Function(QuizModel) onSaved;
  const QuizFormDialog({Key? key, this.quiz, required this.onSaved}) : super(key: key);

  @override
  State<QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends State<QuizFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _timeLimitController;
  late TextEditingController _passingScoreController;
  late int _difficultyLevel;
  late bool _isActive;
  late List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    _titleController = TextEditingController(text: quiz?.title ?? '');
    _descController = TextEditingController(text: quiz?.description ?? '');
    
    // Handle category with validation
    final validCategories = ['Grammar', 'Vocabulary', 'Listening', 'Speaking', 'Writing', 'Reading'];
    String category = quiz?.category ?? 'Grammar';
    
    if (!validCategories.contains(category)) {
      // Try to find a close match or default to first category
      final lowerQuizCategory = category.toLowerCase();
      String? matchedCategory;
      for (String validCategory in validCategories) {
        if (validCategory.toLowerCase() == lowerQuizCategory) {
          matchedCategory = validCategory;
          break;
        }
      }
      category = matchedCategory ?? validCategories.first;
    }
    
    _categoryController = TextEditingController(text: category);
    _timeLimitController = TextEditingController(text: quiz?.timeLimit.toString() ?? '10');
    _passingScoreController = TextEditingController(text: quiz?.passingScore.toString() ?? '50');
    _difficultyLevel = quiz?.difficultyLevel ?? 1;
    _isActive = quiz?.isActive ?? true;
    _questions = quiz?.questions.map((q) => q.copyWith()).toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _timeLimitController.dispose();
    _passingScoreController.dispose();
    super.dispose();
  }

  void _addQuestion() async {
    final newQuestion = await showDialog<QuizQuestion>(
      context: context,
      builder: (context) => QuestionFormDialog(),
    );
    if (newQuestion != null) {
      setState(() => _questions.add(newQuestion));
    }
  }

  void _editQuestion(int index) async {
    final edited = await showDialog<QuizQuestion>(
      context: context,
      builder: (context) => QuestionFormDialog(question: _questions[index]),
    );
    if (edited != null) {
      setState(() => _questions[index] = edited);
    }
  }

  void _removeQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _questions.removeAt(index));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _moveQuestionUp(int index) {
    if (index > 0) {
      setState(() {
        final question = _questions.removeAt(index);
        _questions.insert(index - 1, question);
      });
    }
  }

  void _moveQuestionDown(int index) {
    if (index < _questions.length - 1) {
      setState(() {
        final question = _questions.removeAt(index);
        _questions.insert(index + 1, question);
      });
    }
  }

  bool _isSaving = false;

  String? _getValidCategoryValue() {
    final validCategories = ['Grammar', 'Vocabulary', 'Listening', 'Speaking', 'Writing', 'Reading'];
    final currentValue = _categoryController.text.trim();
    
    // Check for exact match first
    if (validCategories.contains(currentValue)) {
      return currentValue;
    }
    
    // Check for case-insensitive match
    final lowerValue = currentValue.toLowerCase();
    for (String category in validCategories) {
      if (category.toLowerCase() == lowerValue) {
        return category;
      }
    }
    
    // Return null if no match found
    return null;
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate questions have correct answers
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if ((q.type == QuizQuestionType.multipleChoice || q.type == QuizQuestionType.multipleSelect) && 
          q.correctAnswers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1} must have at least one correct answer'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    
    try {
      final quiz = QuizModel(
        id: widget.quiz?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _categoryController.text.trim(),
        difficultyLevel: _difficultyLevel,
        timeLimit: int.tryParse(_timeLimitController.text) ?? 10,
        passingScore: int.tryParse(_passingScoreController.text) ?? 50,
        questions: _questions,
        isActive: _isActive,
        createdAt: widget.quiz?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.quiz?.createdBy ?? 'admin',
        metadata: widget.quiz?.metadata ?? {},
      );
      
      if (widget.quiz == null) {
        await QuizService.createQuiz(quiz);
      } else {
        await QuizService.updateQuiz(quiz);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quiz == null ? 'Quiz created successfully!' : 'Quiz updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await widget.onSaved(quiz);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving quiz: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(widget.quiz == null ? 'Tạo Quiz' : 'Chỉnh sửa Quiz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Đóng',
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width < 600 ? double.infinity : 800,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 32,
            vertical: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent, width: 2)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _getValidCategoryValue(),
                    decoration: InputDecoration(
                      labelText: 'Danh mục',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.success, width: 2)),
                    ),
                    items: ['Grammar', 'Vocabulary', 'Listening', 'Speaking', 'Writing', 'Reading']
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 16))))
                        .toList(),
                    onChanged: (value) => setState(() => _categoryController.text = value ?? ''),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _timeLimitController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Thời gian (phút)',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.warning, width: 2)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Bắt buộc' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _passingScoreController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Điểm đạt (%)',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.error, width: 2)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Bắt buộc' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _difficultyLevel,
                    decoration: InputDecoration(
                      labelText: 'Độ khó',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
                    ),
                    items: [1,2,3,4,5].map((d) => DropdownMenuItem(value: d, child: Text('Cấp $d', style: const TextStyle(fontSize: 16)))).toList(),
                    onChanged: (v) => setState(() => _difficultyLevel = v ?? 1),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: const Text('Hoạt động', style: TextStyle(fontSize: 16)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Danh sách câu hỏi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                            Text('${_questions.length} câu hỏi, ${_questions.fold(0, (sum, q) => sum + q.points)} điểm tổng', 
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.success, AppColors.accent]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.2), blurRadius: 8, offset: Offset(0,2))],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Thêm câu hỏi', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _addQuestion,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._questions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final q = entry.value;
                    Color avatarColor = [AppColors.primary, AppColors.success, AppColors.accent, AppColors.warning, AppColors.error][i % 5];
                    Color chipColor;
                    switch (q.type.toString().split('.').last) {
                      case 'multipleChoice': chipColor = Colors.blue; break;
                      case 'multipleSelect': chipColor = Colors.green; break;
                      case 'trueFalse': chipColor = Colors.orange; break;
                      case 'fillInBlank': chipColor = Colors.purple; break;
                      case 'shortAnswer': chipColor = Colors.teal; break;
                      case 'matching': chipColor = Colors.red; break;
                      case 'ordering': chipColor = Colors.brown; break;
                      default: chipColor = AppColors.primary;
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: avatarColor.withOpacity(0.2), width: 2)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: avatarColor,
                            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(q.question, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          subtitle: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Chip(
                                label: Text(q.type.toString().split('.').last, style: const TextStyle(fontSize: 12, color: Colors.white)),
                                backgroundColor: chipColor,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              Text('${q.points} điểm', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 0,
                            children: [
                              IconButton(
                                icon: Icon(Icons.keyboard_arrow_up, color: i > 0 ? AppColors.primary : Colors.grey),
                                onPressed: i > 0 ? () => _moveQuestionUp(i) : null,
                                tooltip: 'Di chuyển lên',
                              ),
                              IconButton(
                                icon: Icon(Icons.keyboard_arrow_down, color: i < _questions.length - 1 ? AppColors.primary : Colors.grey),
                                onPressed: i < _questions.length - 1 ? () => _moveQuestionDown(i) : null,
                                tooltip: 'Di chuyển xuống',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.primary),
                                onPressed: () => _editQuestion(i),
                                tooltip: 'Sửa câu hỏi',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeQuestion(i),
                                tooltip: 'Xóa câu hỏi',
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (q.options.isNotEmpty) ...[
                                    const Text('Đáp án:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ...q.options.map((opt) => Padding(
                                      padding: const EdgeInsets.only(left: 16, top: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            q.correctAnswers.contains(opt) ? Icons.check_circle : Icons.radio_button_unchecked,
                                            size: 16,
                                            color: q.correctAnswers.contains(opt) ? Colors.green : Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(opt)),
                                        ],
                                      ),
                                    )),
                                  ] else if (q.correctAnswers.isNotEmpty) ...[
                                    const Text('Đáp án đúng:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 16, top: 4),
                                      child: Text(q.correctAnswers.first, style: const TextStyle(color: Colors.green)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_questions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Chưa có câu hỏi nào.', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            CustomButton(
              text: _isSaving ? 'Đang lưu...' : 'Lưu',
              color: AppColors.primary,
              onPressed: _isSaving ? null : _saveQuiz,
              width: 120,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionFormDialog extends StatefulWidget {
  final QuizQuestion? question;
  const QuestionFormDialog({Key? key, this.question}) : super(key: key);

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _pointsController;
  late QuizQuestionType _type;
  List<String> _options = [];
  List<String> _correctAnswers = [];

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _questionController = TextEditingController(text: q?.question ?? '');
    _pointsController = TextEditingController(text: q?.points.toString() ?? '10');
    _type = q?.type ?? QuizQuestionType.multipleChoice;
    _options = List<String>.from(q?.options ?? []);
    _correctAnswers = List<String>.from(q?.correctAnswers ?? []);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() => _options.add(''));
  }

  void _removeOption(int i) {
    setState(() => _options.removeAt(i));
  }

  String _getQuestionTypeLabel(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuizQuestionType.multipleSelect:
        return 'Multiple Select';
      case QuizQuestionType.trueFalse:
        return 'True/False';
      case QuizQuestionType.fillInBlank:
        return 'Fill in the Blank';
      case QuizQuestionType.shortAnswer:
        return 'Short Answer';
      case QuizQuestionType.matching:
        return 'Matching';
      case QuizQuestionType.ordering:
        return 'Ordering';
      default:
        return type.toString().split('.').last;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate based on question type
    if ((_type == QuizQuestionType.multipleChoice || _type == QuizQuestionType.multipleSelect) && 
        _options.where((opt) => opt.trim().isNotEmpty).length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 options'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_correctAnswers.isEmpty || _correctAnswers.every((ans) => ans.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select/enter at least one correct answer'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final question = QuizQuestion(
      id: widget.question?.id ?? UniqueKey().toString(),
      question: _questionController.text.trim(),
      type: _type,
      options: _options.where((opt) => opt.trim().isNotEmpty).toList(),
      correctAnswer: _correctAnswers.isNotEmpty ? _correctAnswers.first : '',
      correctAnswers: _correctAnswers.where((ans) => ans.trim().isNotEmpty).toList(),
      explanation: '',
      points: int.tryParse(_pointsController.text) ?? 10,
      metadata: {},
    );
    Navigator.of(context).pop(question);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _pointsController,
                  decoration: const InputDecoration(labelText: 'Points'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null ? 'Required' : null,
                ),
                DropdownButtonFormField<QuizQuestionType>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Question Type'),
                  items: QuizQuestionType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_getQuestionTypeLabel(t)),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _type = v ?? QuizQuestionType.multipleChoice;
                      // Auto-setup for True/False
                      if (_type == QuizQuestionType.trueFalse) {
                        _options = ['True', 'False'];
                        _correctAnswers = [];
                      } else if (_type == QuizQuestionType.fillInBlank || _type == QuizQuestionType.shortAnswer) {
                        _options = [];
                        _correctAnswers = [];
                      }
                    });
                  },
                ),
                if (_type == QuizQuestionType.multipleChoice || _type == QuizQuestionType.multipleSelect)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._options.asMap().entries.map((entry) {
                        final i = entry.key;
                        return Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _options[i],
                                onChanged: (v) => _options[i] = v,
                                decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeOption(i),
                            ),
                          ],
                        );
                      }),
                      CustomButton(
                        text: 'Add Option',
                        icon: Icons.add,
                        color: AppColors.success,
                        height: 32,
                        width: 120,
                        onPressed: _addOption,
                      ),
                    ],
                  ),
                if (_type == QuizQuestionType.trueFalse)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('True/False questions automatically have "True" and "False" options. Just select the correct answer below.', 
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                if (_type == QuizQuestionType.multipleChoice || _type == QuizQuestionType.multipleSelect || _type == QuizQuestionType.trueFalse)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text('Correct Answer(s)', style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8,
                        children: _options.map((opt) => FilterChip(
                          label: Text(opt),
                          selected: _correctAnswers.contains(opt),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (_type == QuizQuestionType.multipleChoice || _type == QuizQuestionType.trueFalse) {
                                  _correctAnswers = [opt];
                                } else {
                                  _correctAnswers.add(opt);
                                }
                              } else {
                                _correctAnswers.remove(opt);
                              }
                            });
                          },
                        )).toList(),
                      ),
                    ],
                  ),
                if (_type == QuizQuestionType.fillInBlank || _type == QuizQuestionType.shortAnswer)
                  TextFormField(
                    initialValue: _correctAnswers.isNotEmpty ? _correctAnswers.first : '',
                    decoration: const InputDecoration(labelText: 'Correct Answer'),
                    onChanged: (v) => _correctAnswers = [v],
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Save',
          color: AppColors.primary,
          onPressed: _save,
          width: 100,
          height: 36,
        ),
      ],
    );
  }
} 
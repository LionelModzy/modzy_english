import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/challenge_exercise_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../../models/challenge_exercise_model.dart';
import '../../../models/quiz_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChallengeExerciseManagementScreen extends StatefulWidget {
  const ChallengeExerciseManagementScreen({super.key});

  @override
  State<ChallengeExerciseManagementScreen> createState() => _ChallengeExerciseManagementScreenState();
}

class _ChallengeExerciseManagementScreenState extends State<ChallengeExerciseManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChallengeExerciseModel> _exercises = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedChallengeType = 'Tất cả';
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExercises();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await ChallengeExerciseService.getAllExercisesForAdmin();
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách bài tập: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<ChallengeExerciseModel> get _activeExercises {
    List<ChallengeExerciseModel> active = _exercises.where((e) => e.isActive).toList();
    active = _applyFilters(active);
    return active;
  }

  List<ChallengeExerciseModel> get _inactiveExercises {
    List<ChallengeExerciseModel> inactive = _exercises.where((e) => !e.isActive).toList();
    inactive = _applyFilters(inactive);
    return inactive;
  }

  List<ChallengeExerciseModel> _applyFilters(List<ChallengeExerciseModel> exercises) {
    List<ChallengeExerciseModel> filtered = exercises;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedChallengeType != 'Tất cả') {
      filtered = filtered.where((e) => e.challengeType == _selectedChallengeType).toList();
    }

    if (_selectedCategory != 'Tất cả') {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    return filtered;
  }

  List<String> get _challengeTypes => [
    'Tất cả',
    'quiz_rush',
    'vocab_duel',
    'lesson_sprint',
    'speed_challenge',
    'accuracy_master',
    'grammar_battle',
  ];
  
  List<String> get _categories {
    final categories = _exercises.map((e) => e.category).toSet().toList();
    categories.sort();
    return ['Tất cả', ...categories];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quản lý Bài tập Challenge',
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
              text: 'Đang hoạt động',
            ),
            Tab(
              icon: Icon(Icons.pause_circle),
              text: 'Tạm dừng',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadExercises,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bài tập...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedChallengeType,
                        decoration: InputDecoration(
                          labelText: 'Loại thách đấu',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _challengeTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getChallengeTypeName(type), style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedChallengeType = value ?? 'Tất cả'),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Tạo Bài tập Mới',
                    onPressed: () => _showCreateExerciseDialog(),
                    color: AppColors.success,
                    icon: Icons.add_rounded,
                  ),
                ),
              ],
            ),
          ),

          // Exercises List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExercisesList(_activeExercises),
                      _buildExercisesList(_inactiveExercises),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(List<ChallengeExerciseModel> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài tập nào',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(ChallengeExerciseModel exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          exercise.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(exercise.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(_getChallengeTypeName(exercise.challengeType)),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
                Chip(
                  label: Text(exercise.category),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
                Chip(
                  label: Text('Cấp ${exercise.difficultyLevel}'),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
                Chip(
                  label: Text('${exercise.totalQuestions} câu'),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.green),
                ),
                Chip(
                  label: Text(exercise.formattedTimeLimit),
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12, color: Colors.purple),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 100),
                () => _showCreateExerciseDialog(exercise: exercise),
              ),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(
                    exercise.isActive ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(exercise.isActive ? 'Tạm dừng' : 'Kích hoạt'),
                ],
              ),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 100),
                () => _toggleActiveStatus(exercise),
              ),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 100),
                () => _deleteExercise(exercise),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChallengeTypeName(String type) {
    switch (type) {
      case 'quiz_rush':
        return 'Quiz Rush';
      case 'vocab_duel':
        return 'Vocabulary Duel';
      case 'lesson_sprint':
        return 'Lesson Sprint';
      case 'speed_challenge':
        return 'Speed Challenge';
      case 'accuracy_master':
        return 'Accuracy Master';
      case 'grammar_battle':
        return 'Grammar Battle';
      default:
        return type;
    }
  }

  Future<void> _toggleActiveStatus(ChallengeExerciseModel exercise) async {
    final success = await ChallengeExerciseService.toggleActiveStatus(
      exercise.id,
      !exercise.isActive,
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exercise.isActive ? 'Đã tạm dừng bài tập' : 'Đã kích hoạt bài tập'),
            backgroundColor: Colors.green,
          ),
        );
        _loadExercises();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật trạng thái'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteExercise(ChallengeExerciseModel exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bài tập "${exercise.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ChallengeExerciseService.deleteChallengeExercise(exercise.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa bài tập'),
              backgroundColor: Colors.green,
            ),
          );
          _loadExercises();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa bài tập'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCreateExerciseDialog({ChallengeExerciseModel? exercise}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CreateChallengeExerciseScreen(
          exercise: exercise,
          onSaved: () {
            _loadExercises();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// Create/Edit Challenge Exercise Screen
class _CreateChallengeExerciseScreen extends StatefulWidget {
  final ChallengeExerciseModel? exercise;
  final VoidCallback onSaved;

  const _CreateChallengeExerciseScreen({
    required this.exercise,
    required this.onSaved,
  });

  @override
  State<_CreateChallengeExerciseScreen> createState() => _CreateChallengeExerciseScreenState();
}

class _CreateChallengeExerciseScreenState extends State<_CreateChallengeExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _timeLimitController = TextEditingController();
  
  String _challengeType = 'quiz_rush';
  int _difficultyLevel = 1;
  bool _isActive = true;
  List<QuizQuestion> _questions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      _titleController.text = widget.exercise!.title;
      _descController.text = widget.exercise!.description;
      _categoryController.text = widget.exercise!.category;
      _timeLimitController.text = widget.exercise!.timeLimit.toString();
      _challengeType = widget.exercise!.challengeType;
      _difficultyLevel = widget.exercise!.difficultyLevel;
      _isActive = widget.exercise!.isActive;
      _questions = List.from(widget.exercise!.questions);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một câu hỏi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final exercise = ChallengeExerciseModel(
        id: widget.exercise?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        challengeType: _challengeType,
        questions: _questions,
        timeLimit: int.tryParse(_timeLimitController.text) ?? 60,
        isActive: _isActive,
        category: _categoryController.text.trim(),
        difficultyLevel: _difficultyLevel,
        createdAt: widget.exercise?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.exercise?.createdBy ?? FirebaseAuth.instance.currentUser?.uid ?? '',
        metadata: widget.exercise?.metadata ?? {},
      );

      if (widget.exercise == null) {
        await ChallengeExerciseService.createChallengeExercise(exercise);
      } else {
        await ChallengeExerciseService.updateChallengeExercise(exercise);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.exercise == null ? 'Đã tạo bài tập!' : 'Đã cập nhật bài tập!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addQuestion() async {
    final newQuestion = await showDialog<QuizQuestion>(
      context: context,
      builder: (context) => _QuestionFormDialog(),
    );
    if (newQuestion != null && mounted) {
      setState(() => _questions.add(newQuestion));
    }
  }

  void _editQuestion(int index) async {
    final edited = await showDialog<QuizQuestion>(
      context: context,
      builder: (context) => _QuestionFormDialog(question: _questions[index]),
    );
    if (edited != null && mounted) {
      setState(() => _questions[index] = edited);
    }
  }

  void _removeQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa câu hỏi'),
        content: const Text('Bạn có chắc muốn xóa câu hỏi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _questions.removeAt(index));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
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

  Future<void> _importFromQuiz() async {
    try {
      final quizzes = await QuizService.getAllQuizzes();
      if (quizzes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có quiz nào để import'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final selectedQuiz = await showDialog<QuizModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn Quiz để Import'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return ListTile(
                  title: Text(quiz.title),
                  subtitle: Text('${quiz.totalQuestions} câu hỏi'),
                  onTap: () => Navigator.pop(context, quiz),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ],
        ),
      );

      if (selectedQuiz != null && mounted) {
        setState(() {
          _questions.addAll(selectedQuiz.questions);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã import ${selectedQuiz.questions.length} câu hỏi từ "${selectedQuiz.title}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi import quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise == null ? 'Tạo Bài tập Mới' : 'Chỉnh sửa Bài tập'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin cơ bản',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _challengeType,
                      decoration: const InputDecoration(
                        labelText: 'Loại thách đấu *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'quiz_rush', child: Text('⚡️ Quiz Rush')),
                        DropdownMenuItem(value: 'vocab_duel', child: Text('🧠 Vocabulary Duel')),
                        DropdownMenuItem(value: 'lesson_sprint', child: Text('🏃‍♂️ Lesson Sprint')),
                        DropdownMenuItem(value: 'speed_challenge', child: Text('⏱️ Speed Challenge')),
                        DropdownMenuItem(value: 'accuracy_master', child: Text('🎯 Accuracy Master')),
                        DropdownMenuItem(value: 'grammar_battle', child: Text('📚 Grammar Battle')),
                      ],
                      onChanged: (value) => setState(() => _challengeType = value ?? 'quiz_rush'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục *',
                        border: OutlineInputBorder(),
                        hintText: 'Ví dụ: Grammar, Vocabulary, Listening...',
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập danh mục' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _difficultyLevel,
                            decoration: const InputDecoration(
                              labelText: 'Độ khó *',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(5, (i) => i + 1).map((level) => DropdownMenuItem(
                              value: level,
                              child: Text('Cấp $level'),
                            )).toList(),
                            onChanged: (value) => setState(() => _difficultyLevel = value ?? 1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _timeLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Thời gian (giây) *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Vui lòng nhập thời gian';
                              final time = int.tryParse(value);
                              if (time == null || time <= 0) return 'Thời gian phải > 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Kích hoạt'),
                      subtitle: const Text('Bài tập sẽ hiển thị cho người dùng'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Questions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Câu hỏi (${_questions.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _importFromQuiz,
                              icon: const Icon(Icons.import_export),
                              label: const Text('Import từ Quiz'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _addQuestion,
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm câu hỏi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_questions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Chưa có câu hỏi nào. Hãy thêm câu hỏi hoặc import từ quiz.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._questions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final question = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              question.question,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${_getQuestionTypeName(question.type)} • ${question.points} điểm',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward, size: 20),
                                  onPressed: index > 0 ? () => _moveQuestionUp(index) : null,
                                  tooltip: 'Di chuyển lên',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward, size: 20),
                                  onPressed: index < _questions.length - 1
                                      ? () => _moveQuestionDown(index)
                                      : null,
                                  tooltip: 'Di chuyển xuống',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editQuestion(index),
                                  tooltip: 'Chỉnh sửa',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _removeQuestion(index),
                                  tooltip: 'Xóa',
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.exercise == null ? 'Tạo Bài tập' : 'Cập nhật Bài tập',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeName(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.multipleChoice:
        return 'Trắc nghiệm';
      case QuizQuestionType.multipleSelect:
        return 'Chọn nhiều';
      case QuizQuestionType.trueFalse:
        return 'Đúng/Sai';
      case QuizQuestionType.fillInBlank:
        return 'Điền từ';
      case QuizQuestionType.shortAnswer:
        return 'Tự luận';
      default:
        return type.toString();
    }
  }
}

// Question Form Dialog
class _QuestionFormDialog extends StatefulWidget {
  final QuizQuestion? question;
  const _QuestionFormDialog({this.question});

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _pointsController;
  late TextEditingController _explanationController;
  late QuizQuestionType _type;
  List<String> _options = [];
  List<String> _correctAnswers = [];
  String? _imageUrl;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _questionController = TextEditingController(text: q?.question ?? '');
    _pointsController = TextEditingController(text: q?.points.toString() ?? '10');
    _explanationController = TextEditingController(text: q?.explanation ?? '');
    _type = q?.type ?? QuizQuestionType.multipleChoice;
    _options = List<String>.from(q?.options ?? []);
    _correctAnswers = List<String>.from(q?.correctAnswers ?? []);
    _imageUrl = q?.imageUrl;
    _audioUrl = q?.audioUrl;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _pointsController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() => _options.add(''));
  }

  void _removeOption(int i) {
    setState(() {
      _options.removeAt(i);
      _correctAnswers.removeWhere((ans) => ans == _options[i]);
    });
  }

  void _updateOption(int index, String value) {
    setState(() {
      final oldValue = _options[index];
      _options[index] = value;
      // Update correct answers if they reference this option
      final correctIndex = _correctAnswers.indexOf(oldValue);
      if (correctIndex != -1) {
        _correctAnswers[correctIndex] = value;
      }
    });
  }

  String _getQuestionTypeLabel(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.multipleChoice:
        return 'Trắc nghiệm';
      case QuizQuestionType.multipleSelect:
        return 'Chọn nhiều';
      case QuizQuestionType.trueFalse:
        return 'Đúng/Sai';
      case QuizQuestionType.fillInBlank:
        return 'Điền từ';
      case QuizQuestionType.shortAnswer:
        return 'Tự luận';
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
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 2 lựa chọn'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_correctAnswers.isEmpty || _correctAnswers.every((ans) => ans.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn/nhập ít nhất một đáp án đúng'),
          backgroundColor: Colors.red,
        ),
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
      explanation: _explanationController.text.trim().isEmpty ? null : _explanationController.text.trim(),
      imageUrl: _imageUrl?.isEmpty ?? true ? null : _imageUrl,
      audioUrl: _audioUrl?.isEmpty ?? true ? null : _audioUrl,
      points: int.tryParse(_pointsController.text) ?? 10,
      metadata: {},
    );
    Navigator.of(context).pop(question);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.question == null ? 'Thêm câu hỏi' : 'Chỉnh sửa câu hỏi'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Câu hỏi *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pointsController,
                        decoration: const InputDecoration(
                          labelText: 'Điểm *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || int.tryParse(v) == null ? 'Bắt buộc' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<QuizQuestionType>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Loại câu hỏi *',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          QuizQuestionType.multipleChoice,
                          QuizQuestionType.multipleSelect,
                          QuizQuestionType.trueFalse,
                          QuizQuestionType.fillInBlank,
                          QuizQuestionType.shortAnswer,
                        ].map((t) => DropdownMenuItem(
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
                            } else if (_type == QuizQuestionType.fillInBlank || 
                                       _type == QuizQuestionType.shortAnswer) {
                              _options = [];
                              _correctAnswers = [];
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_type == QuizQuestionType.multipleChoice || _type == QuizQuestionType.multipleSelect)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Lựa chọn', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: _addOption,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Thêm lựa chọn'),
                          ),
                        ],
                      ),
                      ..._options.asMap().entries.map((entry) {
                        final i = entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _options[i],
                                  onChanged: (v) => _updateOption(i, v),
                                  decoration: InputDecoration(
                                    labelText: 'Lựa chọn ${i + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: _options.length > 2 ? () => _removeOption(i) : null,
                                tooltip: 'Xóa',
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                if (_type == QuizQuestionType.trueFalse)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Câu hỏi Đúng/Sai tự động có 2 lựa chọn "True" và "False". Chọn đáp án đúng bên dưới.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                if (_type == QuizQuestionType.multipleChoice || 
                    _type == QuizQuestionType.multipleSelect || 
                    _type == QuizQuestionType.trueFalse)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text('Đáp án đúng *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _options.where((opt) => opt.trim().isNotEmpty).map((opt) {
                          return FilterChip(
                            label: Text(opt),
                            selected: _correctAnswers.contains(opt),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (_type == QuizQuestionType.multipleChoice || 
                                      _type == QuizQuestionType.trueFalse) {
                                    _correctAnswers = [opt];
                                  } else {
                                    _correctAnswers.add(opt);
                                  }
                                } else {
                                  _correctAnswers.remove(opt);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                if (_type == QuizQuestionType.fillInBlank || _type == QuizQuestionType.shortAnswer)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _correctAnswers.isNotEmpty ? _correctAnswers.first : '',
                        decoration: const InputDecoration(
                          labelText: 'Đáp án đúng *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => _correctAnswers = [v],
                        validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _explanationController,
                  decoration: const InputDecoration(
                    labelText: 'Giải thích (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Lưu', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

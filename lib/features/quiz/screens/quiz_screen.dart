import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/quiz_service.dart';
import '../../../models/quiz_model.dart';

class QuizScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentQuestionIndex = 0;
  List<QuizAnswer> _answers = [];
  Timer? _quizTimer;
  Duration _timeRemaining = Duration.zero;
  Duration _timeElapsed = Duration.zero;
  bool _isQuizCompleted = false;
  bool _showResults = false;
  
  // For current question
  List<String> _selectedAnswers = [];
  String _textAnswer = '';
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _initializeQuiz();
    _animationController.forward();
  }

  void _initializeQuiz() {
    // Initialize answers list
    _answers = List.generate(
      widget.quiz.questions.length,
      (index) => QuizAnswer(
        questionId: widget.quiz.questions[index].id,
        selectedAnswers: [],
        textAnswer: '',
        isCorrect: false,
        pointsEarned: 0,
      ),
    );
    
    // Set timer if quiz has time limit
    if (widget.quiz.timeLimit > 0) {
      _timeRemaining = Duration(minutes: widget.quiz.timeLimit);
      _startTimer();
    }
  }

  void _startTimer() {
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _timeElapsed = _timeElapsed + const Duration(seconds: 1);

        if (widget.quiz.timeLimit > 0) {
          _timeRemaining = Duration(minutes: widget.quiz.timeLimit) - _timeElapsed;

          if (_timeRemaining.inSeconds <= 0) {
            _submitQuiz();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quizTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.quiz.timeLimit > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeRemaining.inSeconds < 300 ? Colors.red : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: _timeRemaining.inSeconds < 300 ? Colors.white : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_timeRemaining),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _timeRemaining.inSeconds < 300 ? Colors.white : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Progress bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Câu hỏi ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${((_currentQuestionIndex + 1) / widget.quiz.questions.length * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ],
              ),
            ),
            
            // Question content
            Expanded(
              child: _buildQuestionContent(),
            ),
            
            // Navigation buttons
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent() {
    final question = widget.quiz.questions[_currentQuestionIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                // Question type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getQuestionTypeText(question.type),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Question text
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                
                if (question.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      question.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Answer options
                _buildAnswerOptions(question),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(QuizQuestion question) {
    switch (question.type) {
      case QuizQuestionType.multipleChoice:
      case QuizQuestionType.trueFalse:
        return _buildMultipleChoiceOptions(question);
      
      case QuizQuestionType.multipleSelect:
        return _buildMultipleSelectOptions(question);
      
      case QuizQuestionType.fillInBlank:
      case QuizQuestionType.shortAnswer:
        return _buildTextInputOption(question);
      
      default:
        return const Text('Loại câu hỏi không được hỗ trợ');
    }
  }

  Widget _buildMultipleChoiceOptions(QuizQuestion question) {
    return Column(
      children: question.options.asMap().entries.map((entry) {
        int index = entry.key;
        String option = entry.value;
        bool isSelected = _selectedAnswers.contains(option);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedAnswers = [option]; // Single selection
                _textAnswer = '';
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
        child: Text(
                      '${String.fromCharCode(65 + index)}. $option',
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleSelectOptions(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn nhiều đáp án đúng:',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        ...question.options.asMap().entries.map((entry) {
          int index = entry.key;
          String option = entry.value;
          bool isSelected = _selectedAnswers.contains(option);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAnswers.remove(option);
                  } else {
                    _selectedAnswers.add(option);
                  }
                  _textAnswer = '';
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + index)}. $option',
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTextInputOption(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.type == QuizQuestionType.fillInBlank
              ? 'Điền vào chỗ trống:'
              : 'Nhập câu trả lời của bạn:',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          onChanged: (value) {
            setState(() {
              _textAnswer = value;
              _selectedAnswers = [];
            });
          },
          maxLines: question.type == QuizQuestionType.shortAnswer ? 3 : 1,
          decoration: InputDecoration(
            hintText: question.type == QuizQuestionType.fillInBlank
                ? 'Nhập từ hoặc cụm từ...'
                : 'Nhập câu trả lời...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    bool canProceed = _hasAnswer();
    
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
            // Previous button
            if (_currentQuestionIndex > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousQuestion,
                  child: const Text('Câu trước'),
                ),
              ),
            
            if (_currentQuestionIndex > 0) const SizedBox(width: 16),
            
            // Next/Submit button
            Expanded(
              flex: _currentQuestionIndex > 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: canProceed ? _nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isLastQuestion() ? 'Hoàn thành' : 'Câu tiếp',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final result = QuizService.gradeQuiz(
      widget.quiz,
      _answers,
      _timeElapsed,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kết quả Quiz'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Result summary
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                 colors: [
                   _getPerformanceColor(result.percentage),
                   _getPerformanceColor(result.percentage).withOpacity(0.8),
                 ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                   result.percentage >= 50 ? Icons.check_circle : Icons.cancel,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                   _getPerformanceLevel(result.percentage),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.score}/${result.totalPoints} điểm (${result.percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thời gian: ${_formatDuration(_timeElapsed)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Trở về'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _retakeQuiz,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeText(QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.multipleChoice:
        return 'Trắc nghiệm';
      case QuizQuestionType.multipleSelect:
        return 'Chọn nhiều đáp án';
      case QuizQuestionType.trueFalse:
        return 'Đúng/Sai';
      case QuizQuestionType.fillInBlank:
        return 'Điền từ';
      case QuizQuestionType.shortAnswer:
        return 'Tự luận ngắn';
      default:
        return 'Câu hỏi';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  String _getPerformanceLevel(double percentage) {
    if (percentage >= 95) {
      return 'Xuất sắc';
    } else if (percentage >= 80) {
      return 'Giỏi';
    } else if (percentage >= 70) {
      return 'Khá';
    } else if (percentage >= 50) {
      return 'Trung bình';
    } else {
      return 'Cần cải thiện';
    }
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 95) {
      return Colors.deepPurple;
    } else if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 70) {
      return Colors.blue;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  bool _hasAnswer() {
    return _selectedAnswers.isNotEmpty || _textAnswer.trim().isNotEmpty;
  }

  bool _isLastQuestion() {
    return _currentQuestionIndex == widget.quiz.questions.length - 1;
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _saveCurrentAnswer();
      setState(() {
        _currentQuestionIndex--;
        _loadAnswerForCurrentQuestion();
      });
    }
  }

  void _nextQuestion() {
    _saveCurrentAnswer();
    
    if (_isLastQuestion()) {
      _submitQuiz();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _loadAnswerForCurrentQuestion();
      });
    }
  }

  void _saveCurrentAnswer() {
    _answers[_currentQuestionIndex] = QuizAnswer(
      questionId: widget.quiz.questions[_currentQuestionIndex].id,
      selectedAnswers: List.from(_selectedAnswers),
      textAnswer: _textAnswer.trim(),
      isCorrect: false, // Will be determined during grading
      pointsEarned: 0, // Will be determined during grading
    );
  }

  void _loadAnswerForCurrentQuestion() {
    final answer = _answers[_currentQuestionIndex];
    setState(() {
      _selectedAnswers = List.from(answer.selectedAnswers);
      _textAnswer = answer.textAnswer ?? '';
      _textController.text = _textAnswer;
    });
  }

  void _submitQuiz() {
    _saveCurrentAnswer();
    _quizTimer?.cancel();
    
    setState(() {
      _isQuizCompleted = true;
      _showResults = true;
    });

    // Submit result to Firebase
    _saveQuizResult();
  }

  Future<void> _saveQuizResult() async {
    try {
      final result = QuizService.gradeQuiz(
        widget.quiz,
        _answers,
        _timeElapsed,
      );

      await QuizService.submitQuizResult(result);
    } catch (e) {
      print('Error saving quiz result: $e');
      // Show error dialog if needed
    }
  }

  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers = [];
      _textAnswer = '';
      _textController.clear();
      _timeElapsed = Duration.zero;
      _timeRemaining = Duration(minutes: widget.quiz.timeLimit);
      _isQuizCompleted = false;
      _showResults = false;
    });
    
    _initializeQuiz();
    if (widget.quiz.timeLimit > 0) {
      _startTimer();
    }
  }
} 
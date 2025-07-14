import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../core/services/learning_progress_service.dart';
import '../../../models/vocab_model.dart';
import 'vocabulary_practice_session.dart';

class VocabularyPracticeScreen extends StatefulWidget {
  final VocabularyModel? initialVocabulary;
  final String? category;
  final int? difficultyLevel;

  const VocabularyPracticeScreen({
    super.key,
    this.initialVocabulary,
    this.category,
    this.difficultyLevel,
  });

  @override
  State<VocabularyPracticeScreen> createState() => _VocabularyPracticeScreenState();
}

class _VocabularyPracticeScreenState extends State<VocabularyPracticeScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  List<VocabularyModel> _vocabularies = [];
  List<VocabularyModel> _practiceSet = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  
  // Quiz state
  String _selectedQuizType = 'flashcard';
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  bool _showAnswer = false;
  List<String> _multipleChoiceOptions = [];
  String? _selectedAnswer;
  bool _isAnswerCorrect = false;
  
  // Typing practice
  final TextEditingController _typingController = TextEditingController();
  
  // Progress tracking
  DateTime? _practiceStartTime;
  final List<String> _practicedVocabularyIds = [];
  
  final List<String> _quizTypes = ['flashcard', 'multiple_choice', 'typing', 'listening'];
  final Map<String, String> _quizTypeNames = {
    'flashcard': 'Thẻ từ',
    'multiple_choice': 'Trắc nghiệm',
    'typing': 'Điền từ',
    'listening': 'Nghe và chọn',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _loadVocabularies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabularies() async {
    try {
      setState(() => _isLoading = true);
      
      List<VocabularyModel> vocabularies;
      
      if (widget.initialVocabulary != null) {
        // Practice specific vocabulary + related ones
        vocabularies = await VocabularyService.searchVocabulary(widget.initialVocabulary!.word);
        final relatedVocabs = await VocabularyService.getVocabulariesByCategory(
          widget.initialVocabulary!.category,
          limit: 10,
        );
        vocabularies.addAll(relatedVocabs);
        
        // Remove duplicates
        final seen = <String>{};
        vocabularies = vocabularies.where((vocab) => seen.add(vocab.id)).toList();
      } else {
        // Load by category or difficulty
        if (widget.category != null) {
          vocabularies = await VocabularyService.getVocabulariesByCategory(widget.category!);
        } else {
          vocabularies = await VocabularyService.getAllVocabulary();
        }
        
        // Filter by difficulty if specified
        if (widget.difficultyLevel != null) {
          vocabularies = vocabularies.where((v) => v.difficultyLevel == widget.difficultyLevel).toList();
        }
      }
      
      // Shuffle and create practice set
      vocabularies.shuffle();
      _practiceSet = vocabularies.take(20).toList();
      
      setState(() {
        _vocabularies = vocabularies;
        _isLoading = false;
      });
      
      if (_practiceSet.isNotEmpty) {
        _generateQuizContent();
        _animationController.forward();
        _practiceStartTime = DateTime.now(); // Start tracking time
      }
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

  void _generateQuizContent() {
    if (_currentIndex >= _practiceSet.length) return;
    
    final currentVocab = _practiceSet[_currentIndex];
    
    setState(() {
      _showAnswer = false;
      _selectedAnswer = null;
      _isAnswerCorrect = false;
      _typingController.clear(); // Clear typing input
      
      if (_selectedQuizType == 'multiple_choice') {
        _generateMultipleChoice(currentVocab);
      }
    });
  }

  void _generateMultipleChoice(VocabularyModel correct) {
    final options = <String>[correct.meaning];
    final otherVocabs = _vocabularies.where((v) => v.id != correct.id).toList();
    otherVocabs.shuffle();
    
    // Add 3 random incorrect options
    for (int i = 0; i < 3 && i < otherVocabs.length; i++) {
      options.add(otherVocabs[i].meaning);
    }
    
    options.shuffle();
    _multipleChoiceOptions = options;
  }

  void _nextQuestion() {
    // Track vocabulary practice
    if (_currentIndex < _practiceSet.length) {
      final currentVocab = _practiceSet[_currentIndex];
      if (!_practicedVocabularyIds.contains(currentVocab.id)) {
        _practicedVocabularyIds.add(currentVocab.id);
      }
    }
    
    if (_currentIndex < _practiceSet.length - 1) {
      setState(() {
        _currentIndex++;
        _totalQuestions++;
      });
      _generateQuizContent();
      _animationController.reset();
      _animationController.forward();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    final percentage = (_correctAnswers / (_totalQuestions + 1) * 100).round();
    
    // Track progress for each practiced vocabulary
    _trackVocabularyProgress();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: percentage >= 80 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                percentage >= 80 ? Icons.star : Icons.thumb_up,
                color: percentage >= 80 ? Colors.green : Colors.orange,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              percentage >= 80 ? 'Xuất sắc!' : 'Tốt lắm!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã trả lời đúng $_correctAnswers/${_totalQuestions + 1} câu',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Điểm số: $percentage%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: percentage >= 80 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Hoàn thành'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetPractice();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Luyện lại', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetPractice() {
    setState(() {
      _currentIndex = 0;
      _correctAnswers = 0;
      _totalQuestions = 0;
      _showAnswer = false;
      _selectedAnswer = null;
      _isAnswerCorrect = false;
    });
    _practiceSet.shuffle();
    _generateQuizContent();
    _animationController.reset();
    _animationController.forward();
    _practiceStartTime = DateTime.now(); // Reset practice start time
    _practicedVocabularyIds.clear(); // Clear practiced vocabulary list
  }

  Future<void> _trackVocabularyProgress() async {
    if (_practiceStartTime == null || _practicedVocabularyIds.isEmpty) return;
    
    final practiceEndTime = DateTime.now();
    final timeSpent = practiceEndTime.difference(_practiceStartTime!).inSeconds;
    
    // Track progress for each vocabulary practiced
    for (String vocabularyId in _practicedVocabularyIds) {
      try {
        await LearningProgressService.trackVocabularyProgress(
          vocabularyId: vocabularyId,
          correctAnswers: _correctAnswers,
          totalQuestions: _totalQuestions + 1,
          practiceType: _selectedQuizType,
          timeSpent: timeSpent,
        );
      } catch (e) {
        print('Error tracking vocabulary progress for $vocabularyId: $e');
      }
    }
  }

  void _checkTypingAnswer() {
    if (_currentIndex >= _practiceSet.length) return;
    
    final vocabulary = _practiceSet[_currentIndex];
    final userInput = _typingController.text.trim().toLowerCase();
    final correctAnswer = vocabulary.word.toLowerCase();
    
    final isCorrect = userInput == correctAnswer;
    
    setState(() {
      _selectedAnswer = _typingController.text.trim();
      _isAnswerCorrect = isCorrect;
      if (isCorrect) {
        _correctAnswers++;
      }
    });
    
    // Auto advance after showing result
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Luyện Tập Từ Vựng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _practiceSet.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1}/${_practiceSet.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _practiceSet.isEmpty
              ? _buildEmptyState()
              : _buildPracticeModeSelection(),
    );
  }

  Widget _buildEmptyState() {
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
            'Không có từ vựng để luyện tập',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm từ vựng vào hệ thống trước',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Quay lại',
            onPressed: () => Navigator.pop(context),
            icon: Icons.arrow_back,
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeModeSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Mode selection buttons
          Expanded(
            flex: 2,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildModeButton(
                  'flashcard',
                  'Thẻ Từ',
                  Icons.flip_camera_android,
                  Colors.blue,
                  'Học thuộc lòng với flashcard',
                ),
                _buildModeButton(
                  'multiple_choice',
                  'Trắc Nghiệm',
                  Icons.quiz,
                  Colors.green,
                  'Chọn đáp án đúng',
                ),
                _buildModeButton(
                  'typing',
                  'Điền Từ',
                  Icons.keyboard,
                  Colors.orange,
                  'Gõ từ vựng chính xác',
                ),
                _buildModeButton(
                  'listening',
                  'Nghe & Chọn',
                  Icons.headphones,
                  Colors.purple,
                  'Nghe và chọn từ đúng',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Finish button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () => _showFinishDialog(),
              icon: const Icon(Icons.done_all, color: Colors.white),
              label: const Text(
                'Hoàn Thành Luyện Tập',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Progress summary
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Tiến Độ Học Tập',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProgressItem('Đúng', '$_correctAnswers', Colors.green),
                      _buildProgressItem('Sai', '${_totalQuestions - _correctAnswers}', Colors.red),
                      _buildProgressItem('Tổng', '$_totalQuestions', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String title, IconData icon, Color color, String description) {
    bool isSelected = _selectedQuizType == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedQuizType = mode;
        });
        _showPracticeModeDialog(mode, title, description);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? color : Colors.black).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected ? color : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _startPracticeMode(String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VocabularyPracticeSession(
          vocabularies: _practiceSet,
          mode: mode,
          onComplete: (correct, total) {
            setState(() {
              _correctAnswers += correct.toInt();
              _totalQuestions += total.toInt();
            });
          },
        ),
      ),
    );
  }

  void _showPracticeModeDialog(String mode, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _getModeIcon(mode),
              color: _getModeColor(mode),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bắt đầu $title',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getModeColor(mode).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getModeColor(mode).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _getModeColor(mode),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sẽ luyện tập với ${_practiceSet.length} từ vựng',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getModeColor(mode),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedQuizType = 'flashcard'; // Reset selection
              });
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startPracticeMode(mode);
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Bắt Đầu', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getModeColor(mode),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'flashcard':
        return Icons.flip_camera_android;
      case 'multiple_choice':
        return Icons.quiz;
      case 'typing':
        return Icons.keyboard;
      case 'listening':
        return Icons.headphones;
      default:
        return Icons.quiz;
    }
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'flashcard':
        return Colors.blue;
      case 'multiple_choice':
        return Colors.green;
      case 'typing':
        return Colors.orange;
      case 'listening':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hoàn thành luyện tập?'),
        content: const Text('Bạn có muốn kết thúc phiên luyện tập và lưu tiến độ không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _trackVocabularyProgress();
              Navigator.pop(context); // Go back to vocabulary screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Hoàn thành', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardTab() {
    if (_practiceSet.isEmpty) return Container();
    
    final vocabulary = _practiceSet[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress bar
          _buildProgressBar(),
          
          const SizedBox(height: 20),
          
          // Flashcard
          Expanded(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAnswer = !_showAnswer;
                  });
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(vocabulary.category),
                        _getCategoryColor(vocabulary.category).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(vocabulary.category).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_showAnswer) ...[
                          // Question side
                          Icon(
                            Icons.help_outline,
                            color: Colors.white.withOpacity(0.8),
                            size: 32,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            vocabulary.word,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (vocabulary.pronunciation.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              vocabulary.pronunciation,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.9),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (vocabulary.hasAudio)
                                GestureDetector(
                                  onTap: () => _playAudio(vocabulary.audioUrl!),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.volume_up,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'Chạm để xem nghĩa',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ] else ...[
                          // Answer side
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white.withOpacity(0.8),
                            size: 32,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            vocabulary.meaning,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (vocabulary.partOfSpeech.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                vocabulary.partOfSpeech,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (vocabulary.examples.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                vocabulary.examples.first,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          if (_showAnswer) ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Khó',
                    onPressed: () {
                      // Mark as difficult and move to next
                      _nextQuestion();
                    },
                    color: Colors.red,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Dễ',
                    onPressed: () {
                      setState(() {
                        _correctAnswers++;
                      });
                      _nextQuestion();
                    },
                    color: Colors.green,
                    height: 48,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceTab() {
    if (_practiceSet.isEmpty || _multipleChoiceOptions.isEmpty) return Container();
    
    final vocabulary = _practiceSet[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProgressBar(),
          
          const SizedBox(height: 20),
          
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Nghĩa của từ sau đây là gì?',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vocabulary.word,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(vocabulary.category),
                      ),
                    ),
                    if (vocabulary.hasAudio) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _playAudio(vocabulary.audioUrl!),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volume_up,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Options
          Expanded(
            child: ListView.builder(
              itemCount: _multipleChoiceOptions.length,
              itemBuilder: (context, index) {
                final option = _multipleChoiceOptions[index];
                final isSelected = _selectedAnswer == option;
                final isCorrect = option == vocabulary.meaning;
                
                Color? backgroundColor;
                Color? borderColor;
                Color? textColor;
                
                if (_selectedAnswer != null) {
                  if (isCorrect) {
                    backgroundColor = Colors.green.withOpacity(0.1);
                    borderColor = Colors.green;
                    textColor = Colors.green;
                  } else if (isSelected) {
                    backgroundColor = Colors.red.withOpacity(0.1);
                    borderColor = Colors.red;
                    textColor = Colors.red;
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _selectedAnswer == null ? () {
                        setState(() {
                          _selectedAnswer = option;
                          _isAnswerCorrect = isCorrect;
                          if (isCorrect) {
                            _correctAnswers++;
                          }
                        });
                        
                        // Auto advance after showing result
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) _nextQuestion();
                        });
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundColor ?? Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor ?? AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: textColor ?? AppColors.textSecondary,
                                  width: 2,
                                ),
                                color: isSelected && _selectedAnswer != null
                                    ? (isCorrect ? Colors.green : Colors.red)
                                    : Colors.transparent,
                              ),
                              child: isSelected && _selectedAnswer != null
                                  ? Icon(
                                      isCorrect ? Icons.check : Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : Text(
                                      String.fromCharCode(65 + index),
                                      style: TextStyle(
                                        color: textColor ?? AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor ?? AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingTab() {
    if (_practiceSet.isEmpty) return Container();
    
    final vocabulary = _practiceSet[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProgressBar(),
          
          const SizedBox(height: 20),
          
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Nhập từ tiếng Anh cho nghĩa sau:',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  vocabulary.meaning,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(vocabulary.category),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (vocabulary.definition != null && vocabulary.definition!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    vocabulary.definition!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _typingController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nhập từ tiếng Anh...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  onSubmitted: (value) => _checkTypingAnswer(),
                ),
                
                const SizedBox(height: 16),
                
                if (_selectedAnswer != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isAnswerCorrect 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isAnswerCorrect ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAnswerCorrect ? Icons.check_circle : Icons.cancel,
                          color: _isAnswerCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isAnswerCorrect 
                                ? 'Chính xác!'
                                : 'Sai rồi. Đáp án đúng: ${vocabulary.word}',
                            style: TextStyle(
                              color: _isAnswerCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  CustomButton(
                    text: 'Kiểm tra',
                    onPressed: _typingController.text.trim().isNotEmpty 
                        ? _checkTypingAnswer 
                        : null,
                    height: 48,
                  ),
                ],
                
                if (_selectedAnswer != null) ...[
                  CustomButton(
                    text: 'Tiếp theo',
                    onPressed: _nextQuestion,
                    height: 48,
                  ),
                ],
              ],
            ),
          ),
          
          const Spacer(),
          
          // Hint section
          if (_selectedAnswer == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Gợi ý:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${vocabulary.word.length} chữ cái • ${vocabulary.partOfSpeech}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                  if (vocabulary.pronunciation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Phát âm: ${vocabulary.pronunciation}',
                      style: TextStyle(
                        color: Colors.blue.withOpacity(0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListeningTab() {
    if (_practiceSet.isEmpty) return Container();
    
    final vocabulary = _practiceSet[_currentIndex];
    
    // Only show listening practice for words with audio
    if (!vocabulary.hasAudio) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Từ này không có âm thanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn tiếp theo để chuyển từ khác',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Tiếp theo',
              onPressed: _nextQuestion,
              height: 48,
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProgressBar(),
          
          const SizedBox(height: 20),
          
          // Audio player section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.8),
                  Colors.deepPurple.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.headphones,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nghe và chọn nghĩa đúng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _playAudio(vocabulary.audioUrl!),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chạm để nghe lại',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Multiple choice options
          Expanded(
            child: _multipleChoiceOptions.isEmpty 
                ? Container()
                : ListView.builder(
                    itemCount: _multipleChoiceOptions.length,
                    itemBuilder: (context, index) {
                      final option = _multipleChoiceOptions[index];
                      final isSelected = _selectedAnswer == option;
                      final isCorrect = option == vocabulary.meaning;
                      
                      Color? backgroundColor;
                      Color? borderColor;
                      Color? textColor;
                      
                      if (_selectedAnswer != null) {
                        if (isCorrect) {
                          backgroundColor = Colors.green.withOpacity(0.1);
                          borderColor = Colors.green;
                          textColor = Colors.green;
                        } else if (isSelected) {
                          backgroundColor = Colors.red.withOpacity(0.1);
                          borderColor = Colors.red;
                          textColor = Colors.red;
                        }
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _selectedAnswer == null ? () {
                              setState(() {
                                _selectedAnswer = option;
                                _isAnswerCorrect = isCorrect;
                                if (isCorrect) {
                                  _correctAnswers++;
                                }
                              });
                              
                              // Auto advance after showing result
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) _nextQuestion();
                              });
                            } : null,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: backgroundColor ?? Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor ?? AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: textColor ?? AppColors.textSecondary,
                                        width: 2,
                                      ),
                                      color: isSelected && _selectedAnswer != null
                                          ? (isCorrect ? Colors.green : Colors.red)
                                          : Colors.transparent,
                                    ),
                                    child: isSelected && _selectedAnswer != null
                                        ? Icon(
                                            isCorrect ? Icons.check : Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : Text(
                                            String.fromCharCode(65 + index),
                                            style: TextStyle(
                                              color: textColor ?? AppColors.textSecondary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: textColor ?? AppColors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _practiceSet.isNotEmpty ? (_currentIndex + 1) / _practiceSet.length : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Câu ${_currentIndex + 1}/${_practiceSet.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Đúng: $_correctAnswers',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ),
      ],
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

  Future<void> _playAudio(String audioUrl) async {
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
} 
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/bookmark_service.dart';
import '../../../core/services/learning_progress_service.dart';
import '../../../models/vocab_model.dart';

class VocabularyPracticeSession extends StatefulWidget {
  final List<VocabularyModel> vocabularies;
  final String mode;
  final Function(int correct, int total) onComplete;

  const VocabularyPracticeSession({
    super.key,
    required this.vocabularies,
    required this.mode,
    required this.onComplete,
  });

  @override
  State<VocabularyPracticeSession> createState() => _VocabularyPracticeSessionState();
}

class _VocabularyPracticeSessionState extends State<VocabularyPracticeSession> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  int _currentIndex = 0;
  int _correctAnswers = 0;
  bool _showAnswer = false;
  
  // Quiz state
  List<String> _multipleChoiceOptions = [];
  String? _selectedAnswer;
  bool _isAnswerCorrect = false;
  
  // Typing practice
  final TextEditingController _typingController = TextEditingController();
  
  // Audio
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _audioPlayer = AudioPlayer();
    _generateQuizContent();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _typingController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _generateQuizContent() {
    if (_currentIndex >= widget.vocabularies.length) return;
    
    final currentVocab = widget.vocabularies[_currentIndex];
    
    setState(() {
      _showAnswer = false;
      _selectedAnswer = null;
      _isAnswerCorrect = false;
      _typingController.clear();
      
      if (widget.mode == 'multiple_choice' || widget.mode == 'listening') {
        _generateMultipleChoice(currentVocab);
      }
    });
  }

  void _generateMultipleChoice(VocabularyModel correct) {
    final options = <String>[correct.meaning];
    final otherVocabs = widget.vocabularies.where((v) => v.id != correct.id).toList();
    otherVocabs.shuffle();
    
    // Add 3 random incorrect options
    for (int i = 0; i < 3 && i < otherVocabs.length; i++) {
      options.add(otherVocabs[i].meaning);
    }
    
    options.shuffle();
    _multipleChoiceOptions = options;
  }

  void _nextQuestion() {
    if (_currentIndex < widget.vocabularies.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _generateQuizContent();
      _animationController.reset();
      _animationController.forward();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    widget.onComplete(_correctAnswers, widget.vocabularies.length);
    
    // Track progress for each vocabulary practiced
    _trackPracticeProgress();
    
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
                color: _correctAnswers >= widget.vocabularies.length * 0.8 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _correctAnswers >= widget.vocabularies.length * 0.8 
                    ? Icons.star 
                    : Icons.thumb_up,
                color: _correctAnswers >= widget.vocabularies.length * 0.8 
                    ? Colors.green 
                    : Colors.orange,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _correctAnswers >= widget.vocabularies.length * 0.8 
                  ? 'Xuất sắc!' 
                  : 'Tốt lắm!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã trả lời đúng $_correctAnswers/${widget.vocabularies.length} câu',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
      _showAnswer = false;
      _selectedAnswer = null;
      _isAnswerCorrect = false;
    });
    widget.vocabularies.shuffle();
    _generateQuizContent();
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _trackPracticeProgress() async {
    try {
      final accuracy = (_correctAnswers / widget.vocabularies.length * 100).round();
      
      // Track only ONE practice session record (not for each vocabulary)
      await LearningProgressService.trackGeneralProgress(
        activityType: 'vocabulary_practice',
        details: {
          'mode': widget.mode,
          'vocabulariesCount': widget.vocabularies.length,
          'correctAnswers': _correctAnswers,
          'accuracy': accuracy,
          'timeSpent': 300, // Estimated 5 minutes per session
          'completedAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      // Track individual vocabulary mastery (simplified)
      for (var vocab in widget.vocabularies) {
        await LearningProgressService.trackVocabularyProgress(
          vocabularyId: vocab.id,
          correctAnswers: 1, // Each vocab gets 1 point if session completed
          totalQuestions: 1,
          practiceType: widget.mode,
          timeSpent: (300 / widget.vocabularies.length).round(), // Distribute time
        );
      }
    } catch (e) {
      print('Error tracking practice progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _getModeTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.vocabularies.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: widget.vocabularies.isEmpty
          ? const Center(child: Text('Không có từ vựng'))
          : _buildModeContent(),
    );
  }

  String _getModeTitle() {
    switch (widget.mode) {
      case 'flashcard':
        return 'Thẻ Từ';
      case 'multiple_choice':
        return 'Trắc Nghiệm';
      case 'typing':
        return 'Điền Từ';
      case 'listening':
        return 'Nghe & Chọn';
      default:
        return 'Luyện Tập';
    }
  }

  Widget _buildModeContent() {
    switch (widget.mode) {
      case 'flashcard':
        return _buildFlashcardMode();
      case 'multiple_choice':
        return _buildMultipleChoiceMode();
      case 'typing':
        return _buildTypingMode();
      case 'listening':
        return _buildListeningMode();
      default:
        return const Center(child: Text('Mode không hỗ trợ'));
    }
  }

  Widget _buildFlashcardMode() {
    final vocabulary = widget.vocabularies[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.vocabularies.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          
          const SizedBox(height: 30),
          
          // Flashcard with image support
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
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
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
                          // Question side with image
                          if (vocabulary.imageUrl != null && vocabulary.imageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                vocabulary.imageUrl!,
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                  Icon(Icons.image_not_supported, size: 100, color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ] else ...[
                            Icon(
                              Icons.help_outline,
                              color: Colors.white.withOpacity(0.8),
                              size: 64,
                            ),
                            const SizedBox(height: 20),
                          ],
                          Text(
                            vocabulary.word,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (vocabulary.pronunciation.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              vocabulary.pronunciation,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ] else ...[
                          // Answer side
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white.withOpacity(0.8),
                            size: 48,
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
                          if (vocabulary.definition != null && vocabulary.definition!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              vocabulary.definition!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                        const SizedBox(height: 20),
                        Text(
                          _showAnswer ? 'Nhấn để xem từ' : 'Nhấn để xem nghĩa',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Bottom buttons: Remember/Forget/Bookmark
          if (_showAnswer) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _correctAnswers++);
                      _nextQuestion();
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Nhớ', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _nextQuestion(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Quên', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final vocabulary = widget.vocabularies[_currentIndex];
                      final success = await BookmarkService.addVocabularyBookmark(
                        vocabulary.id,
                        practiceType: widget.mode,
                        notes: 'Bookmarked during ${widget.mode} practice',
                      );
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📌 Đã bookmark "${vocabulary.word}" để ôn lại'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Không thể bookmark từ này'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      _nextQuestion();
                    },
                    icon: const Icon(Icons.bookmark_add, color: Colors.white),
                    label: const Text('Bookmark', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceMode() {
    final vocabulary = widget.vocabularies[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.vocabularies.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 30),
          
          // Question
          Container(
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
                if (vocabulary.imageUrl != null && vocabulary.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      vocabulary.imageUrl!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  vocabulary.word,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (vocabulary.pronunciation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    vocabulary.pronunciation,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
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
                
                if (_selectedAnswer != null) {
                  if (isSelected && isCorrect) {
                    backgroundColor = Colors.green.withOpacity(0.1);
                    borderColor = Colors.green;
                  } else if (isSelected && !isCorrect) {
                    backgroundColor = Colors.red.withOpacity(0.1);
                    borderColor = Colors.red;
                  } else if (isCorrect) {
                    backgroundColor = Colors.green.withOpacity(0.1);
                    borderColor = Colors.green;
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _selectedAnswer != null ? null : () {
                        setState(() {
                          _selectedAnswer = option;
                          _isAnswerCorrect = isCorrect;
                          if (isCorrect) _correctAnswers++;
                        });
                        
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) _nextQuestion();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundColor ?? Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor ?? Colors.grey[300]!,
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
                                  color: borderColor ?? Colors.grey[400]!,
                                  width: 2,
                                ),
                                color: isSelected ? (borderColor ?? Colors.grey[400]) : null,
                              ),
                              child: isSelected
                                  ? Icon(
                                      isCorrect ? Icons.check : Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
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

  Widget _buildTypingMode() {
    final vocabulary = widget.vocabularies[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.vocabularies.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 30),
          
          // Question
          Container(
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
                if (vocabulary.imageUrl != null && vocabulary.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      vocabulary.imageUrl!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  vocabulary.meaning,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (vocabulary.definition != null && vocabulary.definition!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    vocabulary.definition!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Typing input
          TextField(
            controller: _typingController,
            decoration: InputDecoration(
              hintText: 'Nhập từ tiếng Anh...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              prefixIcon: Icon(Icons.edit, color: AppColors.primary),
            ),
            style: const TextStyle(fontSize: 18),
            onSubmitted: (_) => _checkTypingAnswer(),
          ),
          
          const SizedBox(height: 20),
          
          // Check button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkTypingAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Kiểm tra',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          
          // Show result
          if (_selectedAnswer != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isAnswerCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAnswerCorrect ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isAnswerCorrect ? Icons.check_circle : Icons.cancel,
                    color: _isAnswerCorrect ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAnswerCorrect ? 'Chính xác!' : 'Sai rồi!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isAnswerCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  if (!_isAnswerCorrect) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Đáp án đúng: ${vocabulary.word}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildListeningMode() {
    final vocabulary = widget.vocabularies[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.vocabularies.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 30),
          
          // Audio play section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
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
                Icon(
                  Icons.headphones,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  'Nghe và chọn từ đúng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _playAudio(vocabulary.audioUrl),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isPlaying ? 'Đang phát...' : 'Nhấn để nghe',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
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
                
                if (_selectedAnswer != null) {
                  if (isSelected && isCorrect) {
                    backgroundColor = Colors.green.withOpacity(0.1);
                    borderColor = Colors.green;
                  } else if (isSelected && !isCorrect) {
                    backgroundColor = Colors.red.withOpacity(0.1);
                    borderColor = Colors.red;
                  } else if (isCorrect) {
                    backgroundColor = Colors.green.withOpacity(0.1);
                    borderColor = Colors.green;
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _selectedAnswer != null ? null : () {
                        setState(() {
                          _selectedAnswer = option;
                          _isAnswerCorrect = isCorrect;
                          if (isCorrect) _correctAnswers++;
                        });
                        
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) _nextQuestion();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundColor ?? Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor ?? Colors.grey[300]!,
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
                                  color: borderColor ?? Colors.grey[400]!,
                                  width: 2,
                                ),
                                color: isSelected ? (borderColor ?? Colors.grey[400]) : null,
                              ),
                              child: isSelected
                                  ? Icon(
                                      isCorrect ? Icons.check : Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
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

  void _checkTypingAnswer() {
    if (_typingController.text.trim().isEmpty) return;
    
    final vocabulary = widget.vocabularies[_currentIndex];
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

  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có file âm thanh')),
      );
      return;
    }
    
    try {
      setState(() => _isPlaying = true);
      await _audioPlayer!.play(UrlSource(audioUrl));
      
      // Stop playing after audio finishes
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      setState(() => _isPlaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phát âm thanh: $e')),
      );
    }
  }
} 
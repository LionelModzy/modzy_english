import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/mini_game_model.dart';
import '../../../models/vocab_model.dart';
import '../../../core/services/mini_game_service.dart';
import '../../auth/data/auth_repository.dart';

class WordScrambleGameScreen extends StatefulWidget {
  final MiniGameModel game;
  final List<VocabularyModel> vocabularies;

  const WordScrambleGameScreen({
    super.key,
    required this.game,
    required this.vocabularies,
  });

  @override
  State<WordScrambleGameScreen> createState() => _WordScrambleGameScreenState();
}

class _WordScrambleGameScreenState extends State<WordScrambleGameScreen> {
  List<VocabularyModel> _gameWords = [];
  int _currentWordIndex = 0;
  List<String> _scrambledLetters = [];
  List<String> _userAnswer = [];
  List<String> _availableLetters = [];
  
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _hintsUsed = 0;
  Timer? _gameTimer;
  int _secondsElapsed = 0;
  bool _gameCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }

  void _initializeGame() {
    final random = Random();
    final selectedWords = List<VocabularyModel>.from(widget.vocabularies)
      ..shuffle(random);
    
    setState(() {
      _gameWords = selectedWords.take(10).toList();
      _loadNextWord();
    });
  }

  void _loadNextWord() {
    if (_currentWordIndex >= _gameWords.length) {
      _completeGame();
      return;
    }

    final word = _gameWords[_currentWordIndex].word.toUpperCase();
    final letters = word.split('');
    letters.shuffle(Random());

    setState(() {
      _scrambledLetters = letters;
      _availableLetters = List.from(letters);
      _userAnswer = [];
    });
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _onLetterTap(String letter, int index) {
    setState(() {
      _userAnswer.add(letter);
      _availableLetters[index] = '';
    });

    // Check if answer is complete
    if (_userAnswer.join() == _gameWords[_currentWordIndex].word.toUpperCase()) {
      _onCorrectAnswer();
    } else if (_userAnswer.length == _scrambledLetters.length) {
      _onWrongAnswer();
    }
  }

  void _onAnswerLetterTap(int index) {
    final letter = _userAnswer[index];
    final originalIndex = _scrambledLetters.indexOf(letter);
    
    setState(() {
      _userAnswer.removeAt(index);
      _availableLetters[originalIndex] = letter;
    });
  }

  void _onCorrectAnswer() {
    setState(() {
      _score += 100 - (_hintsUsed * 20);
      _correctAnswers++;
      _currentWordIndex++;
    });

    _showFeedback(true);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _hintsUsed = 0;
        _loadNextWord();
      }
    });
  }

  void _onWrongAnswer() {
    setState(() {
      _wrongAnswers++;
    });

    _showFeedback(false);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _userAnswer = [];
          _availableLetters = List.from(_scrambledLetters);
        });
      }
    });
  }

  void _showFeedback(bool isCorrect) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? '✅ Chính xác!' : '❌ Sai rồi, thử lại!'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _useHint() {
    if (_hintsUsed >= 2 || _userAnswer.length >= _scrambledLetters.length) return;

    final correctWord = _gameWords[_currentWordIndex].word.toUpperCase();
    final nextLetter = correctWord[_userAnswer.length];
    final index = _availableLetters.indexOf(nextLetter);

    if (index != -1) {
      setState(() {
        _hintsUsed++;
        _userAnswer.add(nextLetter);
        _availableLetters[index] = '';
      });

      if (_userAnswer.join() == correctWord) {
        _onCorrectAnswer();
      }
    }
  }

  void _skipWord() {
    setState(() {
      _wrongAnswers++;
      _currentWordIndex++;
    });
    _loadNextWord();
  }

  Future<void> _completeGame() async {
    _gameTimer?.cancel();
    setState(() {
      _gameCompleted = true;
    });

    // Save score
    final currentUser = await AuthRepository.getCurrentUserData();
    if (currentUser != null) {
      final maxScore = _gameWords.length * 100;
      final scoreModel = GameScoreModel(
        id: '',
        userId: currentUser.uid,
        gameId: widget.game.id,
        gameType: widget.game.gameType,
        score: _score,
        maxScore: maxScore,
        timeSeconds: _secondsElapsed,
        correctAnswers: _correctAnswers,
        wrongAnswers: _wrongAnswers,
        accuracy: (_correctAnswers / _gameWords.length) * 100,
        playedAt: DateTime.now(),
        gameDetails: {
          'hints_used': _hintsUsed,
          'total_words': _gameWords.length,
        },
      );

      await MiniGameService.saveGameScore(scoreModel);
    }

    if (mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Text('Hoàn thành!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResultRow('Điểm số:', '$_score'),
            _buildResultRow('Đúng:', '$_correctAnswers/${_gameWords.length}'),
            _buildResultRow('Sai:', '$_wrongAnswers'),
            _buildResultRow('Thời gian:', _formatTime(_secondsElapsed)),
            _buildResultRow(
              'Độ chính xác:',
              '${((_correctAnswers / _gameWords.length) * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quay Lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Chơi Lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _currentWordIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _wrongAnswers = 0;
      _hintsUsed = 0;
      _secondsElapsed = 0;
      _gameCompleted = false;
    });
    _initializeGame();
    _gameTimer?.cancel();
    _startTimer();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_gameWords.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentWord = _currentWordIndex < _gameWords.length
        ? _gameWords[_currentWordIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.game.title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetGame,
            tooltip: 'Chơi lại',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score Board
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF8B5CF6), const Color(0xFF8B5CF6).withOpacity(0.8)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Điểm', _score.toString(), Icons.stars_rounded),
                  _buildStatItem(
                    'Từ',
                    '${_currentWordIndex + 1}/${_gameWords.length}',
                    Icons.text_fields_rounded,
                  ),
                  _buildStatItem('Thời gian', _formatTime(_secondsElapsed), Icons.timer_rounded),
                  _buildStatItem('Đúng', '$_correctAnswers', Icons.check_circle_rounded),
                ],
              ),
            ),

            if (currentWord != null) ...[
              const SizedBox(height: 24),

              // Meaning hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                    children: [
                      const Text(
                        'Nghĩa của từ:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentWord.meaning,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // User Answer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _userAnswer.isEmpty
                        ? [
                            Text(
                              'Sắp xếp các chữ cái...',
                              style: TextStyle(
                                fontSize: 20,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                            )
                          ]
                        : _userAnswer.asMap().entries.map((entry) {
                            return GestureDetector(
                              onTap: () => _onAnswerLetterTap(entry.key),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Available Letters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableLetters.asMap().entries.map((entry) {
                    final letter = entry.value;
                    if (letter.isEmpty) {
                      return const SizedBox(width: 50, height: 50);
                    }
                    return GestureDetector(
                      onTap: () => _onLetterTap(letter, entry.key),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _hintsUsed >= 2 ? null : _useHint,
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: Text('Gợi ý (${2 - _hintsUsed})'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _skipWord,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Bỏ qua'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}


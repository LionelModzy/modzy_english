import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/mini_game_model.dart';
import '../../../models/vocab_model.dart';
import '../../../core/services/mini_game_service.dart';
import '../../auth/data/auth_repository.dart';

class WordMatchGameScreen extends StatefulWidget {
  final MiniGameModel game;
  final List<VocabularyModel> vocabularies;

  const WordMatchGameScreen({
    super.key,
    required this.game,
    required this.vocabularies,
  });

  @override
  State<WordMatchGameScreen> createState() => _WordMatchGameScreenState();
}

class _WordMatchGameScreenState extends State<WordMatchGameScreen> with TickerProviderStateMixin {
  List<MatchCard> _cards = [];
  MatchCard? _firstSelectedCard;
  MatchCard? _secondSelectedCard;
  bool _canSelect = true;
  int _score = 0;
  int _moves = 0;
  int _matchedPairs = 0;
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
    // Take 6 random words (12 cards total)
    final random = Random();
    final selectedVocabs = List<VocabularyModel>.from(widget.vocabularies)
      ..shuffle(random);
    final gameVocabs = selectedVocabs.take(6).toList();

    // Create cards (word + meaning pairs)
    final cards = <MatchCard>[];
    for (var i = 0; i < gameVocabs.length; i++) {
      final vocab = gameVocabs[i];
      cards.add(MatchCard(
        id: 'word_$i',
        pairId: i,
        text: vocab.word,
        isWord: true,
      ));
      cards.add(MatchCard(
        id: 'meaning_$i',
        pairId: i,
        text: vocab.meaning,
        isWord: false,
      ));
    }

    setState(() {
      _cards = cards..shuffle(random);
    });
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _onCardTap(MatchCard card) {
    if (!_canSelect || card.isMatched || card.isFlipped) return;

    setState(() {
      card.isFlipped = true;

      if (_firstSelectedCard == null) {
        _firstSelectedCard = card;
      } else if (_secondSelectedCard == null) {
        _secondSelectedCard = card;
        _moves++;
        _canSelect = false;

        // Check for match
        _checkForMatch();
      }
    });
  }

  void _checkForMatch() {
    if (_firstSelectedCard!.pairId == _secondSelectedCard!.pairId) {
      // Match found!
      setState(() {
        _firstSelectedCard!.isMatched = true;
        _secondSelectedCard!.isMatched = true;
        _matchedPairs++;
        _score += 100;
      });

      _resetSelection();

      // Check if game is completed
      if (_matchedPairs == 6) {
        _completeGame();
      }
    } else {
      // No match - flip back after delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _firstSelectedCard!.isFlipped = false;
            _secondSelectedCard!.isFlipped = false;
            _resetSelection();
          });
        }
      });
    }
  }

  void _resetSelection() {
    _firstSelectedCard = null;
    _secondSelectedCard = null;
    _canSelect = true;
  }

  Future<void> _completeGame() async {
    _gameTimer?.cancel();
    setState(() {
      _gameCompleted = true;
    });

    // Save score
    final currentUser = await AuthRepository.getCurrentUserData();
    if (currentUser != null) {
      final scoreModel = GameScoreModel(
        id: '',
        userId: currentUser.uid,
        gameId: widget.game.id,
        gameType: widget.game.gameType,
        score: _score,
        maxScore: 600, // 6 pairs × 100 points
        timeSeconds: _secondsElapsed,
        correctAnswers: 6,
        wrongAnswers: _moves - 6,
        accuracy: (6 / _moves) * 100,
        playedAt: DateTime.now(),
        gameDetails: {
          'moves': _moves,
          'time': _secondsElapsed,
        },
      );

      await MiniGameService.saveGameScore(scoreModel);
    }

    // Show completion dialog
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
            Text('Chúc mừng!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn đã hoàn thành!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildResultRow('Điểm số:', '$_score'),
            _buildResultRow('Số nước:', '$_moves'),
            _buildResultRow('Thời gian:', _formatTime(_secondsElapsed)),
            _buildResultRow(
              'Độ chính xác:',
              '${((6 / _moves) * 100).toStringAsFixed(1)}%',
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
              backgroundColor: AppColors.primary,
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
      _score = 0;
      _moves = 0;
      _matchedPairs = 0;
      _secondsElapsed = 0;
      _gameCompleted = false;
      _firstSelectedCard = null;
      _secondSelectedCard = null;
      _canSelect = true;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.game.title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEC4899),
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
                  colors: [const Color(0xFFEC4899), const Color(0xFFEC4899).withOpacity(0.8)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Điểm', _score.toString(), Icons.stars_rounded),
                  _buildStatItem('Nước', _moves.toString(), Icons.touch_app_rounded),
                  _buildStatItem('Thời gian', _formatTime(_secondsElapsed), Icons.timer_rounded),
                  _buildStatItem('Cặp', '$_matchedPairs/6', Icons.extension_rounded),
                ],
              ),
            ),

            // Game Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return _buildCard(_cards[index]);
                  },
                ),
              ),
            ),
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

  Widget _buildCard(MatchCard card) {
    return GestureDetector(
      onTap: () => _onCardTap(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched
              ? Colors.green.withOpacity(0.3)
              : (card.isFlipped ? Colors.white : const Color(0xFFEC4899)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: card.isFlipped ? const Color(0xFFEC4899) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: card.isFlipped || card.isMatched
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    card.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: card.isWord ? 16 : 13,
                      fontWeight: card.isWord ? FontWeight.bold : FontWeight.normal,
                      color: card.isMatched ? Colors.green : const Color(0xFFEC4899),
                    ),
                  ),
                )
              : Icon(
                  Icons.question_mark_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 32,
                ),
        ),
      ),
    );
  }
}

class MatchCard {
  final String id;
  final int pairId;
  final String text;
  final bool isWord;
  bool isFlipped;
  bool isMatched;

  MatchCard({
    required this.id,
    required this.pairId,
    required this.text,
    required this.isWord,
    this.isFlipped = false,
    this.isMatched = false,
  });
}


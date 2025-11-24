import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/mini_game_model.dart';
import '../../../models/vocab_model.dart';
import '../../../core/services/mini_game_service.dart';
import '../../auth/data/auth_repository.dart';

class WordSearchGameScreen extends StatefulWidget {
  final MiniGameModel game;
  final List<VocabularyModel> vocabularies;

  const WordSearchGameScreen({
    super.key,
    required this.game,
    required this.vocabularies,
  });

  @override
  State<WordSearchGameScreen> createState() => _WordSearchGameScreenState();
}

class _WordSearchGameScreenState extends State<WordSearchGameScreen> {
  List<String> _wordsToFind = [];
  List<String> _foundWords = [];
  List<List<String>> _grid = [];
  List<GridCell> _selectedCells = [];
  int _gridSize = 10;
  
  int _score = 0;
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
    final selectedVocabs = List<VocabularyModel>.from(widget.vocabularies)
      ..shuffle(random);
    
    // Select 8 words
    final gameVocabs = selectedVocabs.take(8).toList();
    _wordsToFind = gameVocabs.map((v) => v.word.toUpperCase()).toList();

    // Create grid
    _grid = _createWordSearchGrid(_wordsToFind);
    
    setState(() {});
  }

  List<List<String>> _createWordSearchGrid(List<String> words) {
    final random = Random();
    final grid = List.generate(
      _gridSize,
      (_) => List.generate(_gridSize, (_) => ''),
    );

    // Place words
    for (final word in words) {
      bool placed = false;
      int attempts = 0;
      
      while (!placed && attempts < 100) {
        final direction = random.nextInt(3); // 0: horizontal, 1: vertical, 2: diagonal
        int row = random.nextInt(_gridSize);
        int col = random.nextInt(_gridSize);

        if (_canPlaceWord(grid, word, row, col, direction)) {
          _placeWord(grid, word, row, col, direction);
          placed = true;
        }
        attempts++;
      }
    }

    // Fill empty cells with random letters
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (grid[i][j].isEmpty) {
          grid[i][j] = letters[random.nextInt(letters.length)];
        }
      }
    }

    return grid;
  }

  bool _canPlaceWord(List<List<String>> grid, String word, int row, int col, int direction) {
    if (direction == 0) {
      // Horizontal
      if (col + word.length > _gridSize) return false;
      for (int i = 0; i < word.length; i++) {
        if (grid[row][col + i].isNotEmpty && grid[row][col + i] != word[i]) {
          return false;
        }
      }
      return true;
    } else if (direction == 1) {
      // Vertical
      if (row + word.length > _gridSize) return false;
      for (int i = 0; i < word.length; i++) {
        if (grid[row + i][col].isNotEmpty && grid[row + i][col] != word[i]) {
          return false;
        }
      }
      return true;
    } else {
      // Diagonal
      if (row + word.length > _gridSize || col + word.length > _gridSize) return false;
      for (int i = 0; i < word.length; i++) {
        if (grid[row + i][col + i].isNotEmpty && grid[row + i][col + i] != word[i]) {
          return false;
        }
      }
      return true;
    }
  }

  void _placeWord(List<List<String>> grid, String word, int row, int col, int direction) {
    for (int i = 0; i < word.length; i++) {
      if (direction == 0) {
        grid[row][col + i] = word[i];
      } else if (direction == 1) {
        grid[row + i][col] = word[i];
      } else {
        grid[row + i][col + i] = word[i];
      }
    }
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

  void _onCellTap(int row, int col) {
    final cell = GridCell(row, col, _grid[row][col]);
    
    setState(() {
      if (_selectedCells.contains(cell)) {
        _selectedCells.remove(cell);
      } else {
        _selectedCells.add(cell);
      }
    });

    _checkForWord();
  }

  void _checkForWord() {
    if (_selectedCells.length < 3) return;

    final selectedWord = _selectedCells.map((c) => c.letter).join();
    
    if (_wordsToFind.contains(selectedWord) && !_foundWords.contains(selectedWord)) {
      setState(() {
        _foundWords.add(selectedWord);
        _score += 100;
        _selectedCells.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tìm thấy từ!'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 800),
        ),
      );

      if (_foundWords.length == _wordsToFind.length) {
        _completeGame();
      }
    }
  }

  Future<void> _completeGame() async {
    _gameTimer?.cancel();
    setState(() {
      _gameCompleted = true;
    });

    // Save score
    final currentUser = await AuthRepository.getCurrentUserData();
    if (currentUser != null) {
      final maxScore = _wordsToFind.length * 100;
      final scoreModel = GameScoreModel(
        id: '',
        userId: currentUser.uid,
        gameId: widget.game.id,
        gameType: widget.game.gameType,
        score: _score,
        maxScore: maxScore,
        timeSeconds: _secondsElapsed,
        correctAnswers: _foundWords.length,
        wrongAnswers: 0,
        accuracy: (_foundWords.length / _wordsToFind.length) * 100,
        playedAt: DateTime.now(),
        gameDetails: {
          'total_words': _wordsToFind.length,
          'found_words': _foundWords.length,
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
            _buildResultRow('Tìm thấy:', '${_foundWords.length}/${_wordsToFind.length}'),
            _buildResultRow('Thời gian:', _formatTime(_secondsElapsed)),
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
              backgroundColor: const Color(0xFF10B981),
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
      _foundWords = [];
      _selectedCells = [];
      _score = 0;
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

  void _clearSelection() {
    setState(() {
      _selectedCells.clear();
    });
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
        backgroundColor: const Color(0xFF10B981),
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
                  colors: [const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.8)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Điểm', _score.toString(), Icons.stars_rounded),
                  _buildStatItem(
                    'Tìm thấy',
                    '${_foundWords.length}/${_wordsToFind.length}',
                    Icons.search_rounded,
                  ),
                  _buildStatItem('Thời gian', _formatTime(_secondsElapsed), Icons.timer_rounded),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Words to find
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tìm các từ:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _wordsToFind.map((word) {
                      final found = _foundWords.contains(word);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: found ? Colors.green.withOpacity(0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: found ? Colors.green : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (found)
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            if (found) const SizedBox(width: 4),
                            Text(
                              word,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: found ? Colors.green : AppColors.textPrimary,
                                decoration: found ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Grid
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(8),
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
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridSize,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      itemCount: _gridSize * _gridSize,
                      itemBuilder: (context, index) {
                        final row = index ~/ _gridSize;
                        final col = index % _gridSize;
                        final cell = GridCell(row, col, _grid[row][col]);
                        final isSelected = _selectedCells.contains(cell);

                        return GestureDetector(
                          onTap: () => _onCellTap(row, col),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                _grid[row][col],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Clear Selection Button
            if (_selectedCells.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.clear_rounded),
                  label: const Text('Xóa Lựa Chọn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
}

class GridCell {
  final int row;
  final int col;
  final String letter;

  GridCell(this.row, this.col, this.letter);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCell &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}


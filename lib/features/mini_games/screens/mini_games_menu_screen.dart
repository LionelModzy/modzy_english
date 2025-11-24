import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/mini_game_service.dart';
import '../../../core/services/sample_data_service.dart';
import '../../../models/mini_game_model.dart';
import 'word_match_game_screen.dart';
import 'word_scramble_game_screen.dart';
import 'word_search_game_screen.dart';

class MiniGamesMenuScreen extends StatefulWidget {
  const MiniGamesMenuScreen({super.key});

  @override
  State<MiniGamesMenuScreen> createState() => _MiniGamesMenuScreenState();
}

class _MiniGamesMenuScreenState extends State<MiniGamesMenuScreen> {
  List<MiniGameModel> _games = [];
  bool _isLoading = true;
  String _selectedFilter = 'Tất cả';

  final Map<String, String> _gameTypeNames = {
    'word_match': 'Ghép Cặp Từ',
    'word_scramble': 'Xếp Chữ',
    'word_search': 'Tìm Từ',
  };

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize sample data if needed
      await SampleDataService.initializeSampleData();
      
      final games = await MiniGameService.getAllGames();
      setState(() {
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải games: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<MiniGameModel> get _filteredGames {
    if (_selectedFilter == 'Tất cả') {
      return _games;
    }
    return _games.where((game) => game.gameType == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mini Games',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chơi Game Học Tiếng Anh',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vừa chơi vừa học, cải thiện vốn từ vựng!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Tabs
            Container(
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', 'Tất cả'),
                    const SizedBox(width: 8),
                    _buildFilterChip('word_match', 'Ghép Cặp'),
                    const SizedBox(width: 8),
                    _buildFilterChip('word_scramble', 'Xếp Chữ'),
                    const SizedBox(width: 8),
                    _buildFilterChip('word_search', 'Tìm Từ'),
                  ],
                ),
              ),
            ),

            // Games List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredGames.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredGames.length,
                          itemBuilder: (context, index) {
                            return _buildGameCard(_filteredGames[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(MiniGameModel game) {
    final color = _getGameTypeColor(game.gameType);
    final icon = _getGameTypeIcon(game.gameType);

    return GestureDetector(
      onTap: () => _playGame(game),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.stars_rounded,
                          'Cấp ${game.difficultyLevel}',
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.play_arrow_rounded,
                          '${game.playCount} lượt',
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Play Button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videogame_asset_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có game nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các mini game sẽ sớm được cập nhật!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGameTypeColor(String gameType) {
    switch (gameType) {
      case 'word_match':
        return const Color(0xFFEC4899);
      case 'word_scramble':
        return const Color(0xFF8B5CF6);
      case 'word_search':
        return const Color(0xFF10B981);
      default:
        return AppColors.primary;
    }
  }

  IconData _getGameTypeIcon(String gameType) {
    switch (gameType) {
      case 'word_match':
        return Icons.extension_rounded;
      case 'word_scramble':
        return Icons.shuffle_rounded;
      case 'word_search':
        return Icons.search_rounded;
      default:
        return Icons.videogame_asset_rounded;
    }
  }

  Future<void> _playGame(MiniGameModel game) async {
    // Load game vocabulary
    final vocabularies = await MiniGameService.getGameVocabulary(game);
    
    if (vocabularies.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy từ vựng cho game này'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Navigate to appropriate game screen
    Widget gameScreen;
    switch (game.gameType) {
      case 'word_match':
        gameScreen = WordMatchGameScreen(game: game, vocabularies: vocabularies);
        break;
      case 'word_scramble':
        gameScreen = WordScrambleGameScreen(game: game, vocabularies: vocabularies);
        break;
      case 'word_search':
        gameScreen = WordSearchGameScreen(game: game, vocabularies: vocabularies);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loại game không được hỗ trợ'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => gameScreen),
    );
  }
}


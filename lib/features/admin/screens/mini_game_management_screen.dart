import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/mini_game_service.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../models/mini_game_model.dart';
import '../../../models/vocab_model.dart';
import '../../auth/data/auth_repository.dart';

class MiniGameManagementScreen extends StatefulWidget {
  const MiniGameManagementScreen({super.key});

  @override
  State<MiniGameManagementScreen> createState() => _MiniGameManagementScreenState();
}

class _MiniGameManagementScreenState extends State<MiniGameManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<MiniGameModel> _games = [];
  List<MiniGameModel> _filteredGames = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedGameType = 'Tất cả';
  String _selectedDifficulty = 'Tất cả';
  String _sortOption = 'Mới nhất';
  
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _gameTypes = ['Tất cả', 'word_match', 'word_scramble', 'word_search'];
  final Map<String, String> _gameTypeNames = {
    'word_match': 'Ghép Cặp Từ',
    'word_scramble': 'Xếp Chữ',
    'word_search': 'Tìm Từ',
  };
  final List<String> _difficultyLevels = ['Tất cả', '1', '2', '3', '4', '5'];
  final List<String> _sortOptions = ['Mới nhất', 'Cũ nhất', 'Nhiều lượt chơi', 'Ít lượt chơi'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    
    try {
      final games = await MiniGameService.getAllGames();
      setState(() {
        _games = games;
        _filteredGames = games;
        _isLoading = false;
      });
      _filterGames();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải mini games: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterGames() {
    List<MiniGameModel> filtered = List.from(_games);
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((game) =>
        game.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        game.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Game type filter
    if (_selectedGameType != 'Tất cả') {
      filtered = filtered.where((game) => game.gameType == _selectedGameType).toList();
    }

    // Difficulty filter
    if (_selectedDifficulty != 'Tất cả') {
      filtered = filtered.where((game) => game.difficultyLevel == int.parse(_selectedDifficulty)).toList();
    }

    // Sorting
    switch (_sortOption) {
      case 'Mới nhất':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Cũ nhất':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Nhiều lượt chơi':
        filtered.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case 'Ít lượt chơi':
        filtered.sort((a, b) => a.playCount.compareTo(b.playCount));
        break;
    }
    
    setState(() {
      _filteredGames = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      appBar: AppBar(
        title: const Text(
          'Quản Lý Mini Games',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Games Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.list_rounded), text: 'Danh Sách'),
            Tab(icon: Icon(Icons.add_rounded), text: 'Thêm Mới'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Thống Kê'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab(),
          _buildCreateTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildListTab() {
    return Column(
      children: [
        // Search and filter section
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm mini game...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _filterGames();
                                },
                                icon: const Icon(Icons.clear_rounded),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _filterGames();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedGameType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Loại game',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      items: _gameTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == 'Tất cả' ? type : _gameTypeNames[type] ?? type,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _selectedGameType = value ?? 'Tất cả');
                        _filterGames();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Độ khó',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      items: _difficultyLevels.map((diff) => DropdownMenuItem(
                        value: diff,
                        child: Text(
                          diff == 'Tất cả' ? diff : 'Cấp $diff',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDifficulty = value ?? 'Tất cả');
                        _filterGames();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _sortOption,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Sắp xếp',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      items: _sortOptions.map((opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(
                          opt,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _sortOption = value ?? 'Mới nhất');
                        _filterGames();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Games list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredGames.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredGames.length,
                      itemBuilder: (context, index) {
                        return _buildGameCard(_filteredGames[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildGameCard(MiniGameModel game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getGameTypeColor(game.gameType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getGameTypeIcon(game.gameType),
            color: _getGameTypeColor(game.gameType),
            size: 24,
          ),
        ),
        title: Text(
          game.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              game.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip(
                  _gameTypeNames[game.gameType] ?? game.gameType,
                  _getGameTypeColor(game.gameType),
                ),
                const SizedBox(width: 8),
                _buildChip(
                  'Cấp ${game.difficultyLevel}',
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  '${game.playCount} lượt',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editGame(game);
                break;
              case 'delete':
                _deleteGame(game);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có mini game nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn tab "Thêm Mới" để tạo mini game đầu tiên',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return MiniGameFormWidget(
      onSaved: () {
        _loadGames();
        _tabController.animateTo(0);
      },
    );
  }

  Widget _buildStatsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: MiniGameService.getGameStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = snapshot.data ?? {};
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tổng Games',
                      '${stats['total_games'] ?? 0}',
                      Icons.videogame_asset_rounded,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Đang Hoạt Động',
                      '${stats['active_games'] ?? 0}',
                      Icons.check_circle_rounded,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tổng Lượt Chơi',
                      '${stats['total_plays'] ?? 0}',
                      Icons.play_arrow_rounded,
                      AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Điểm TB',
                      '${(stats['average_score'] ?? 0.0).toStringAsFixed(1)}',
                      Icons.stars_rounded,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Phổ Biến Nhất',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                stats['most_played'] ?? 'N/A',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
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

  void _editGame(MiniGameModel game) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chỉnh Sửa Mini Game',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: MiniGameFormWidget(
                  game: game,
                  onSaved: () {
                    Navigator.pop(context);
                    _loadGames();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteGame(MiniGameModel game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa game "${game.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await MiniGameService.deleteGame(game.id);
              if (success) {
                _loadGames();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa game "${game.title}"'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class MiniGameFormWidget extends StatefulWidget {
  final MiniGameModel? game;
  final VoidCallback onSaved;
  
  const MiniGameFormWidget({
    super.key,
    this.game,
    required this.onSaved,
  });

  @override
  State<MiniGameFormWidget> createState() => _MiniGameFormWidgetState();
}

class _MiniGameFormWidgetState extends State<MiniGameFormWidget> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedGameType = 'word_match';
  int _difficultyLevel = 1;
  String _selectedCategory = 'Vocabulary';
  List<VocabularyModel> _selectedVocabularies = [];
  List<VocabularyModel> _availableVocabularies = [];
  bool _isLoading = false;
  bool _loadingVocabularies = false;

  final Map<String, String> _gameTypeNames = {
    'word_match': 'Ghép Cặp Từ (Word Match)',
    'word_scramble': 'Xếp Chữ (Word Scramble)',
    'word_search': 'Tìm Từ (Word Search)',
  };
  
  final List<String> _categories = ['Vocabulary', 'Grammar', 'Speaking', 'Listening', 'Writing'];

  @override
  void initState() {
    super.initState();
    if (widget.game != null) {
      _populateFields(widget.game!);
    }
    _loadVocabularies();
  }

  void _populateFields(MiniGameModel game) {
    _titleController.text = game.title;
    _descriptionController.text = game.description;
    _selectedGameType = game.gameType;
    _difficultyLevel = game.difficultyLevel;
    _selectedCategory = game.category;
  }

  Future<void> _loadVocabularies() async {
    setState(() => _loadingVocabularies = true);
    try {
      final vocabs = await VocabularyService.getAllVocabulary();
      setState(() {
        _availableVocabularies = vocabs;
        _loadingVocabularies = false;
      });
      
      // Load selected vocabularies if editing
      if (widget.game != null) {
        final gameVocabs = await MiniGameService.getGameVocabulary(widget.game!);
        setState(() {
          _selectedVocabularies = gameVocabs;
        });
      }
    } catch (e) {
      setState(() => _loadingVocabularies = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.game != null ? 'Chỉnh Sửa Mini Game' : 'Tạo Mini Game Mới',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên Game *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên game';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô Tả *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_rounded),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Game Type
            DropdownButtonFormField<String>(
              value: _selectedGameType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Loại Game *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.videogame_asset_rounded),
                isDense: true,
              ),
              items: _gameTypeNames.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedGameType = value!);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Danh Mục *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Difficulty Level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Độ Khó *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final level = index + 1;
                    final isSelected = _difficultyLevel == level;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _difficultyLevel = level),
                        child: Container(
                          margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            '$level',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Vocabulary Selection
            const Text(
              'Chọn Từ Vựng (tối thiểu 8 từ) *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            
            if (_loadingVocabularies)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                height: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Đã chọn: ${_selectedVocabularies.length} từ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _availableVocabularies.length,
                        itemBuilder: (context, index) {
                          final vocab = _availableVocabularies[index];
                          final isSelected = _selectedVocabularies.contains(vocab);
                          
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(vocab.word),
                            subtitle: Text(vocab.meaning),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedVocabularies.add(vocab);
                                } else {
                                  _selectedVocabularies.remove(vocab);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isLoading 
                      ? 'Đang Lưu...' 
                      : (widget.game != null ? 'Cập Nhật' : 'Tạo Mini Game'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGame() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedVocabularies.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 8 từ vựng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final currentUser = await AuthRepository.getCurrentUserData();
      
      final game = MiniGameModel(
        id: widget.game?.id ?? '',
        gameType: _selectedGameType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        difficultyLevel: _difficultyLevel,
        category: _selectedCategory,
        vocabularyIds: _selectedVocabularies.map((v) => v.id).toList(),
        gameData: {},
        createdAt: widget.game?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        createdBy: currentUser?.uid ?? '',
        playCount: widget.game?.playCount ?? 0,
        averageScore: widget.game?.averageScore ?? 0.0,
        metadata: widget.game?.metadata ?? {},
      );
      
      final result = await MiniGameService.saveGame(game);
      
      if (result['success'] == true) {
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.success,
            ),
          );
        }
        
        // Clear form if creating new
        if (widget.game == null) {
          _formKey.currentState!.reset();
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedVocabularies = [];
            _difficultyLevel = 1;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi không xác định'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu game: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}


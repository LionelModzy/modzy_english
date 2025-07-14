import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/vocabulary_service.dart';
import '../../models/vocab_model.dart';
import 'package:audioplayers/audioplayers.dart';

class VocabularySelector extends StatefulWidget {
  final List<String> selectedVocabularyWords;
  final Function(List<String>) onVocabularyChanged;
  final String? lessonCategory;
  final int? difficultyLevel;

  const VocabularySelector({
    super.key,
    required this.selectedVocabularyWords,
    required this.onVocabularyChanged,
    this.lessonCategory,
    this.difficultyLevel,
  });

  @override
  State<VocabularySelector> createState() => _VocabularySelectorState();
}

class _VocabularySelectorState extends State<VocabularySelector> {
  final TextEditingController _searchController = TextEditingController();
  List<VocabularyModel> _allVocabulary = [];
  List<VocabularyModel> _filteredVocabulary = [];
  List<VocabularyModel> _selectedVocabulary = [];
  bool _isLoading = true;
  bool _isSearching = false;
  Timer? _searchDebouncer;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    setState(() => _isLoading = true);
    
    try {
      final vocabulary = await VocabularyService.getAllVocabulary();
      
      setState(() {
        _allVocabulary = vocabulary;
        _filteredVocabulary = _getFilteredVocabulary(vocabulary);
        _selectedVocabulary = vocabulary
            .where((vocab) => widget.selectedVocabularyWords.contains(vocab.word))
            .toList();
        _isLoading = false;
      });
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

  List<VocabularyModel> _getFilteredVocabulary(List<VocabularyModel> vocabulary) {
    List<VocabularyModel> filtered = List.from(vocabulary);
    
    // Filter by lesson category if provided
    if (widget.lessonCategory != null && widget.lessonCategory!.isNotEmpty) {
      filtered = filtered.where((vocab) => 
        vocab.category.toLowerCase() == widget.lessonCategory!.toLowerCase() ||
        vocab.category.toLowerCase() == 'vocabulary' // Always include general vocabulary
      ).toList();
    }
    
    // Filter by difficulty level if provided (±1 level tolerance)
    if (widget.difficultyLevel != null) {
      filtered = filtered.where((vocab) => 
        (vocab.difficultyLevel - widget.difficultyLevel!).abs() <= 1
      ).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((vocab) =>
        vocab.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        vocab.meaning.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        vocab.pronunciation.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Sort by word
    filtered.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    
    return filtered;
  }

  void _onSearchChanged() {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
          _filteredVocabulary = _getFilteredVocabulary(_allVocabulary);
        });
      }
    });
  }

  void _toggleVocabularySelection(VocabularyModel vocabulary) {
    setState(() {
      if (_selectedVocabulary.any((v) => v.id == vocabulary.id)) {
        _selectedVocabulary.removeWhere((v) => v.id == vocabulary.id);
      } else {
        _selectedVocabulary.add(vocabulary);
      }
    });

    final selectedWords = _selectedVocabulary.map((v) => v.word).toList();
    widget.onVocabularyChanged(selectedWords);
  }

  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) return;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.book_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Từ Vựng Bài Học',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (_selectedVocabulary.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_selectedVocabulary.length} từ đã chọn',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Search Bar
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm từ vựng (word, meaning, pronunciation)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _filteredVocabulary = _getFilteredVocabulary(_allVocabulary);
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Filter Info
        if (widget.lessonCategory != null || widget.difficultyLevel != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: AppColors.secondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Đã lọc theo: ${widget.lessonCategory ?? ''} ${widget.difficultyLevel != null ? 'Level ${widget.difficultyLevel}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Selected Vocabulary (if any)
        if (_selectedVocabulary.isNotEmpty) ...[
          const Text(
            'Từ Vựng Đã Chọn:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedVocabulary.length,
              itemBuilder: (context, index) {
                return _buildSelectedVocabularyChip(_selectedVocabulary[index]);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Available Vocabulary List
        const Text(
          'Từ Vựng Có Sẵn:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Vocabulary List
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredVocabulary.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _filteredVocabulary.length,
                      itemBuilder: (context, index) {
                        return _buildVocabularyItem(_filteredVocabulary[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSelectedVocabularyChip(VocabularyModel vocabulary) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vocabulary.word,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vocabulary.meaning,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _toggleVocabularySelection(vocabulary),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyItem(VocabularyModel vocabulary) {
    final isSelected = _selectedVocabulary.any((v) => v.id == vocabulary.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(vocabulary.category).withOpacity(0.2),
          child: Text(
            vocabulary.word.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getCategoryColor(vocabulary.category),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                vocabulary.word,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (vocabulary.hasAudio)
              GestureDetector(
                onTap: () => _playAudio(vocabulary.audioUrl),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.volume_up,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vocabulary.meaning,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (vocabulary.pronunciation.isNotEmpty)
              Text(
                vocabulary.pronunciation,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getCategoryColor(vocabulary.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vocabulary.category,
                style: TextStyle(
                  fontSize: 10,
                  color: _getCategoryColor(vocabulary.category),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
        onTap: () => _toggleVocabularySelection(vocabulary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy từ vựng nào',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử điều chỉnh từ khóa tìm kiếm',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
} 
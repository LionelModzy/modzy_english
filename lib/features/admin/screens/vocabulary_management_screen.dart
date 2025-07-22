import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/media_upload_widget.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/dictionary_api_service.dart';
import '../../../core/services/pexels_api_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../models/vocab_model.dart';
import '../../auth/data/auth_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../vocabulary/screens/vocabulary_detail_screen.dart';

class VocabularyManagementScreen extends StatefulWidget {
  const VocabularyManagementScreen({super.key});

  @override
  State<VocabularyManagementScreen> createState() => _VocabularyManagementScreenState();
}

class _VocabularyManagementScreenState extends State<VocabularyManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<VocabularyModel> _vocabularies = [];
  List<VocabularyModel> _filteredVocabularies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  String _selectedPartOfSpeech = 'Tất cả';
  String _selectedDifficulty = 'Tất cả';
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortOption = 'Mới nhất';
  bool _showFilters = false;
  
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = ['Tất cả', 'Grammar', 'Vocabulary', 'Speaking', 'Listening', 'Writing'];
  final Map<String, String> _categoryVietnamese = {
    'Grammar': 'Ngữ pháp',
    'Vocabulary': 'Từ vựng', 
    'Speaking': 'Nói',
    'Listening': 'Nghe',
    'Writing': 'Viết',
  };
  final List<String> _partsOfSpeech = [
    'Tất cả',
    'noun', 'verb', 'adjective', 'adverb', 'preposition', 'conjunction', 'interjection', 'pronoun'
  ];
  final Map<String, String> _partOfSpeechVietnamese = {
    'noun': 'Danh từ',
    'verb': 'Động từ',
    'adjective': 'Tính từ',
    'adverb': 'Trạng từ',
    'preposition': 'Giới từ',
    'conjunction': 'Liên từ',
    'interjection': 'Thán từ',
    'pronoun': 'Đại từ',
  };
  final List<String> _difficultyLevels = ['Tất cả', '1', '2', '3', '4', '5'];
  final List<String> _difficultyNames = ['Cơ bản', 'Sơ cấp', 'Trung cấp', 'Trung cấp cao', 'Nâng cao'];
  final List<String> _sortOptions = [
    'Mới nhất', 'Cũ nhất', 'A-Z', 'Z-A', 'Độ khó tăng', 'Độ khó giảm', 'Sử dụng nhiều', 'Sử dụng ít'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVocabularies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabularies() async {
    setState(() => _isLoading = true);
    
    try {
      final vocabularies = await VocabularyService.getAllVocabulary();
      setState(() {
        _vocabularies = vocabularies;
        _filteredVocabularies = vocabularies;
        _isLoading = false;
      });
      print('✅ Loaded ${_vocabularies.length} vocabulary words');
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading vocabularies: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải từ vựng: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _filterVocabularies() {
    List<VocabularyModel> filtered = List.from(_vocabularies);
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((vocab) =>
        vocab.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        vocab.meaning.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        vocab.pronunciation.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Category filter
    if (_selectedCategory != 'Tất cả') {
      filtered = filtered.where((vocab) => vocab.category == _selectedCategory).toList();
    }

    // Part of Speech filter
    if (_selectedPartOfSpeech != 'Tất cả') {
      filtered = filtered.where((vocab) => vocab.partOfSpeech == _selectedPartOfSpeech).toList();
    }

    // Difficulty filter
    if (_selectedDifficulty != 'Tất cả') {
      filtered = filtered.where((vocab) => vocab.difficultyLevel == int.parse(_selectedDifficulty)).toList();
    }

    // Date range filter
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((vocab) {
        final createdAt = vocab.createdAt;
        final isAfterStart = _startDate == null || !createdAt.isBefore(_startDate!);
        final isBeforeEnd = _endDate == null || !createdAt.isAfter(_endDate!);
        return isAfterStart && isBeforeEnd;
      }).toList();
    }

    // Sorting
    switch (_sortOption) {
      case 'Mới nhất':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Cũ nhất':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'A-Z':
        filtered.sort((a, b) => a.word.compareTo(b.word));
        break;
      case 'Z-A':
        filtered.sort((a, b) => b.word.compareTo(a.word));
        break;
      case 'Độ khó tăng':
        filtered.sort((a, b) => a.difficultyLevel.compareTo(b.difficultyLevel));
        break;
      case 'Độ khó giảm':
        filtered.sort((a, b) => b.difficultyLevel.compareTo(a.difficultyLevel));
        break;
      case 'Sử dụng nhiều':
        filtered.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case 'Sử dụng ít':
        filtered.sort((a, b) => a.usageCount.compareTo(b.usageCount));
        break;
    }
    
    setState(() {
      _filteredVocabularies = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      appBar: AppBar(
        title: const Text(
          'Quản Lý Từ Vựng',
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.book_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Vocab Admin',
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
            Tab(
              icon: Icon(Icons.list_rounded),
              text: 'Danh Sách',
            ),
            Tab(
              icon: Icon(Icons.add_rounded),
              text: 'Thêm Mới',
            ),
            Tab(
              icon: Icon(Icons.bar_chart_rounded),
              text: 'Thống Kê',
            ),
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
              // Search and Filter Row (like quiz management)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm từ vựng...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _filterVocabularies();
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
                        _filterVocabularies();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                    icon: Icon(
                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                      color: _showFilters ? AppColors.primary : Colors.grey,
                    ),
                    tooltip: 'Bộ lọc',
                  ),
                ],
              ),
              if (_showFilters) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Bộ lọc Từ Vựng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Đặt lại'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
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
                                child: Text(cat == 'Tất cả' ? cat : _categoryVietnamese[cat] ?? cat, style: const TextStyle(fontSize: 14)),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCategory = value ?? 'Tất cả');
                                _filterVocabularies();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPartOfSpeech,
                              decoration: InputDecoration(
                                labelText: 'Từ loại',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _partsOfSpeech.map((pos) => DropdownMenuItem(
                                value: pos,
                                child: Text(pos == 'Tất cả' ? pos : _partOfSpeechVietnamese[pos] ?? pos, style: const TextStyle(fontSize: 14)),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => _selectedPartOfSpeech = value ?? 'Tất cả');
                                _filterVocabularies();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedDifficulty,
                              decoration: InputDecoration(
                                labelText: 'Độ khó',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _difficultyLevels.map((diff) => DropdownMenuItem(
                                value: diff,
                                child: Text(diff == 'Tất cả' ? diff : 'Cấp $diff', style: const TextStyle(fontSize: 14)),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => _selectedDifficulty = value ?? 'Tất cả');
                                _filterVocabularies();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortOption,
                              decoration: InputDecoration(
                                labelText: 'Sắp xếp',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _sortOptions.map((opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt, style: const TextStyle(fontSize: 14)),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => _sortOption = value ?? 'Mới nhất');
                                _filterVocabularies();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _startDate = date);
                                  _filterVocabularies();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      _startDate != null 
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                          : 'Từ ngày',
                                      style: TextStyle(
                                        color: _startDate != null ? AppColors.textPrimary : Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _endDate = date);
                                  _filterVocabularies();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      _endDate != null 
                                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                          : 'Đến ngày',
                                      style: TextStyle(
                                        color: _endDate != null ? AppColors.textPrimary : Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Vocabularies list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredVocabularies.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredVocabularies.length,
                      itemBuilder: (context, index) {
                        return _buildVocabularyCard(_filteredVocabularies[index]);
                      },
                    ),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Tất cả';
      _selectedPartOfSpeech = 'Tất cả';
      _selectedDifficulty = 'Tất cả';
      _startDate = null;
      _endDate = null;
      _sortOption = 'Mới nhất';
    });
    _filterVocabularies();
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyCard(VocabularyModel vocabulary) {
    return GestureDetector(
      onTap: () =>
          VocabularyDetailScreen.open(context, vocabulary),
      child: Container(
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
          isThreeLine: true, // Cho phép ListTile có nhiều dòng
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getCategoryColor(vocabulary.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    vocabulary.word.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(vocabulary.category),
                    ),
                  ),
                ),
                if (vocabulary.hasAudio)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vocabulary.word,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(vocabulary.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _categoryVietnamese[vocabulary.category] ?? vocabulary.category,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(vocabulary.category),
                      ),
                    ),
                  ),
                ],
              ),
              if (vocabulary.pronunciation.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  vocabulary.pronunciation,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text(
                vocabulary.meaning,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (vocabulary.partOfSpeech.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  vocabulary.vietnamesePartOfSpeech,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editVocabulary(vocabulary);
                  break;
                case 'delete':
                  _deleteVocabulary(vocabulary);
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
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _selectedCategory != 'Tất cả' ||
        _selectedPartOfSpeech != 'Tất cả' ||
        _selectedDifficulty != 'Tất cả' ||
        _startDate != null ||
        _endDate != null ||
        _searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off : Icons.library_books_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'Không tìm thấy từ vựng phù hợp'
                : 'Chưa có từ vựng nào',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
                : 'Nhấn tab "Thêm Mới" để tạo từ vựng đầu tiên',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (hasFilters)
            CustomButton(
              text: 'Đặt lại bộ lọc',
              onPressed: () {
                setState(() {
                  _resetFilters();
                  _searchQuery = '';
                });
              },
              color: AppColors.warning,
              icon: Icons.refresh_rounded,
            )
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return VocabularyFormWidget(
      onSaved: () {
        _loadVocabularies(); // Reload list
        _tabController.animateTo(0); // Switch to list tab
      },
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

  void _editVocabulary(VocabularyModel vocabulary) {
    showDialog(
      context: context,
      builder: (context) => VocabularyFormDialog(
        vocabulary: vocabulary,
        onSaved: _loadVocabularies,
      ),
    );
  }

  void _deleteVocabulary(VocabularyModel vocabulary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa từ vựng "${vocabulary.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await VocabularyService.deleteVocabulary(vocabulary.id);
              if (success) {
                _loadVocabularies();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa từ vựng "${vocabulary.word}"'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    // Prepare statistics
    final total = _vocabularies.length;
    final active = _vocabularies.where((v) => v.isActive).length;
    final withAudio = _vocabularies.where((v) => v.hasAudio).length;
    final withImage = _vocabularies.where((v) => v.hasImage).length;
    final byCategory = <String, int>{};
    final byPartOfSpeech = <String, int>{};
    final byDifficulty = <int, int>{};
    final byDate = <String, int>{};
    final byUsage = _vocabularies.toList()..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    for (final v in _vocabularies) {
      byCategory[v.category] = (byCategory[v.category] ?? 0) + 1;
      byPartOfSpeech[v.partOfSpeech] = (byPartOfSpeech[v.partOfSpeech] ?? 0) + 1;
      byDifficulty[v.difficultyLevel] = (byDifficulty[v.difficultyLevel] ?? 0) + 1;
      final dateStr = '${v.createdAt.year}-${v.createdAt.month.toString().padLeft(2, '0')}';
      byDate[dateStr] = (byDate[dateStr] ?? 0) + 1;
    }
    final topUsed = byUsage.take(5).toList();
    final leastUsed = byUsage.reversed.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Tổng Từ Vựng', '$total', Icons.library_books_rounded, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Kích Hoạt', '$active', Icons.check_circle_rounded, AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Có Âm Thanh', '$withAudio', Icons.volume_up_rounded, AppColors.secondary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Có Hình Ảnh', '$withImage', Icons.image_rounded, Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Thống kê theo Danh mục', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: byCategory.entries.map((e) => Chip(
              label: Text('${_categoryVietnamese[e.key] ?? e.key}: ${e.value}'),
              backgroundColor: AppColors.primary.withOpacity(0.08),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Text('Thống kê theo Từ loại', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: byPartOfSpeech.entries.map((e) => Chip(
              label: Text('${_partOfSpeechVietnamese[e.key] ?? e.key}: ${e.value}'),
              backgroundColor: Colors.blue.withOpacity(0.08),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Text('Thống kê theo Độ khó', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: byDifficulty.entries.map((e) => Chip(
              label: Text('Cấp ${e.key} (${_difficultyNames[e.key-1]}): ${e.value}'),
              backgroundColor: Colors.green.withOpacity(0.08),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Text('Thống kê theo Tháng tạo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: byDate.entries.map((e) => Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${e.value} từ', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Từ vựng sử dụng nhiều nhất', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...topUsed.map((v) => ListTile(
            leading: CircleAvatar(child: Text(v.word.substring(0,1).toUpperCase())),
            title: Text(v.word),
            subtitle: Text('Số lần sử dụng: ${v.usageCount}'),
          )),
          const SizedBox(height: 20),
          Text('Từ vựng sử dụng ít nhất', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...leastUsed.map((v) => ListTile(
            leading: CircleAvatar(child: Text(v.word.substring(0,1).toUpperCase())),
            title: Text(v.word),
            subtitle: Text('Số lần sử dụng: ${v.usageCount}'),
          )),
        ],
      ),
    );
  }
}

class VocabularyFormWidget extends StatefulWidget {
  final VocabularyModel? vocabulary;
  final VoidCallback onSaved;
  
  const VocabularyFormWidget({
    super.key,
    this.vocabulary,
    required this.onSaved,
  });

  @override
  State<VocabularyFormWidget> createState() => _VocabularyFormWidgetState();
}

class _VocabularyFormWidgetState extends State<VocabularyFormWidget> {
  final _formKey = GlobalKey<FormState>();
  
  final _wordController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _meaningController = TextEditingController();
  final _definitionController = TextEditingController();
  final _examplesController = TextEditingController();
  final _synonymsController = TextEditingController();
  final _antonymsController = TextEditingController();
  
  String _selectedCategory = 'Grammar';
  String _selectedPartOfSpeech = 'noun';
  int _difficultyLevel = 1;
  String? _audioUrl;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isAutoFetching = false;
  Timer? _debounceTimer;
  
  // Auto-fetch controls
  String? _autoFetchedImageUrl;
  String? _autoFetchedAudioUrl;
  bool _useAutoImage = false;
  bool _useAutoAudio = false;

  final List<String> _categories = ['Grammar', 'Vocabulary', 'Speaking', 'Listening', 'Writing'];
  final List<String> _partsOfSpeech = ['noun', 'verb', 'adjective', 'adverb', 'preposition', 'conjunction', 'interjection', 'pronoun'];
  final List<String> _difficultyNames = ['Cơ bản', 'Sơ cấp', 'Trung cấp', 'Trung cấp cao', 'Nâng cao'];

  @override
  void initState() {
    super.initState();
    if (widget.vocabulary != null) {
      _populateFields(widget.vocabulary!);
    }
  }

  void _populateFields(VocabularyModel vocabulary) {
    _wordController.text = vocabulary.word;
    _pronunciationController.text = vocabulary.pronunciation;
    _meaningController.text = vocabulary.meaning;
    _definitionController.text = vocabulary.definition ?? '';
    _examplesController.text = vocabulary.examples.join('\n');
    _synonymsController.text = vocabulary.synonyms.join(', ');
    _antonymsController.text = vocabulary.antonyms.join(', ');
    _selectedCategory = vocabulary.category;
    _selectedPartOfSpeech = vocabulary.partOfSpeech.isNotEmpty ? vocabulary.partOfSpeech : 'noun';
    _difficultyLevel = vocabulary.difficultyLevel;
    _audioUrl = vocabulary.audioUrl;
    _imageUrl = vocabulary.imageUrl;
    
    // Reset auto-fetch states when editing existing word
    _autoFetchedImageUrl = null;
    _autoFetchedAudioUrl = null;
    _useAutoImage = false;
    _useAutoAudio = false;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _wordController.dispose();
    _pronunciationController.dispose();
    _meaningController.dispose();
    _definitionController.dispose();
    _examplesController.dispose();
    _synonymsController.dispose();
    _antonymsController.dispose();
    super.dispose();
  }

  void _debounceAutoFetch(String word) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _autoFetchWordData(word);
    });
  }

  Future<void> _autoFetchWordData(String word) async {
    if (_isAutoFetching || word.trim().isEmpty) return;
    
    setState(() => _isAutoFetching = true);

    try {
      // Only check for duplicates if we're creating a new word (not editing)
      if (widget.vocabulary == null) {
        final existingWord = await VocabularyService.checkWordExists(word);
        if (existingWord != null && existingWord.meaning.isNotEmpty) {
          setState(() => _isAutoFetching = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Từ "${word}" đã tồn tại. Nhấn để chỉnh sửa.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Xem',
                textColor: Colors.white,
                onPressed: () => _showExistingWordDialog(existingWord),
              ),
            ),
          );
          return;
        }
      }

      // Fetch from Dictionary API and Pexels in parallel
      final List<dynamic> results = await Future.wait([
        DictionaryApiService.fetchWordData(word),
        PexelsApiService.searchImageForWord(word),
      ]);

      final DictionaryWordData? dictData = results[0];
      final String? imageUrl = results[1];

      if (dictData != null) {
        // Auto-translate definition to Vietnamese
        String? vietnameseMeaning;
        try {
          vietnameseMeaning = await TranslationService.translateToVietnamese(dictData.primaryDefinition);
        } catch (e) {
          if (kDebugMode) print('Translation failed: $e');
        }

        // Auto-detect category from part of speech and definition
        final detectedCategory = TranslationService.detectCategory(
          dictData.primaryPartOfSpeech, 
          word, 
          dictData.primaryDefinition
        );

        // Auto-fill form with fetched data
        _pronunciationController.text = dictData.bestPhonetic;
        _definitionController.text = dictData.primaryDefinition;
        _examplesController.text = dictData.allExamples.join('\n');
        _synonymsController.text = dictData.allSynonyms.join(', ');
        _antonymsController.text = dictData.allAntonyms.join(', ');
        
        // Fill Vietnamese meaning if translation succeeded
        if (vietnameseMeaning != null && vietnameseMeaning.isNotEmpty) {
          _meaningController.text = vietnameseMeaning;
        }
        
        // Set part of speech, category, and URLs
        setState(() {
          _selectedPartOfSpeech = dictData.primaryPartOfSpeech.toLowerCase();
          _selectedCategory = detectedCategory;
          _autoFetchedAudioUrl = dictData.bestAudioUrl;
          _autoFetchedImageUrl = imageUrl;
          _useAutoAudio = dictData.bestAudioUrl != null;
          _useAutoImage = imageUrl != null;
          
          // Set final URLs based on user choice
          _audioUrl = _useAutoAudio ? _autoFetchedAudioUrl : null;
          _imageUrl = _useAutoImage ? _autoFetchedImageUrl : null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tìm thấy dữ liệu cho từ "${word}"'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // If dictionary API fails, just set image
        if (imageUrl != null) {
          setState(() {
            _imageUrl = imageUrl;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Không tìm thấy từ "${word}" trong từ điển. Vui lòng nhập thủ công.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi tìm kiếm từ điển: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isAutoFetching = false);
    }
  }

  String _generateAudioFileName() {
    final word = _wordController.text.trim().replaceAll(' ', '_').toLowerCase();
    final category = _selectedCategory.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${category}_vocab_${word}_audio_$timestamp';
  }

  void _showExistingWordDialog(VocabularyModel existingWord) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ Đã Tồn Tại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Từ "${existingWord.word}" đã có trong hệ thống:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nghĩa: ${existingWord.meaning}'),
                  if (existingWord.pronunciation.isNotEmpty)
                    Text('Phát âm: ${existingWord.pronunciation}'),
                  Text('Danh mục: ${existingWord.category}'),
                  Text('Độ khó: ${existingWord.vietnameseDifficultyName}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Populate form with existing word data for editing
              _populateFields(existingWord);
            },
            child: const Text('Chỉnh Sửa'),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoImageControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ảnh minh họa:',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary), // Giảm font size
            ),
            const Spacer(),
            Switch(
              value: _useAutoImage,
              onChanged: (value) {
                setState(() {
                  _useAutoImage = value;
                  _imageUrl = value ? _autoFetchedImageUrl : null;
                });
              },
              activeColor: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 2), // Giảm spacing
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.network(
                _autoFetchedImageUrl!,
                height: 70, // Giảm từ 80
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 18), // Giảm icon size
                  );
                },
              ),
              if (!_useAutoImage)
                Container(
                  height: 70,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.6),
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18, // Giảm icon size
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoAudioControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Âm thanh phát âm:',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary), // Giảm font size
            ),
            const Spacer(),
            Switch(
              value: _useAutoAudio,
              onChanged: (value) {
                setState(() {
                  _useAutoAudio = value;
                  _audioUrl = value ? _autoFetchedAudioUrl : null;
                });
              },
              activeColor: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 2), // Giảm spacing
        GestureDetector(
          onTap: () => _playAutoAudio(),
          child: Container(
            height: 56, // Giảm từ 80
            padding: const EdgeInsets.all(10), // Giảm padding
            decoration: BoxDecoration(
              color: _useAutoAudio 
                  ? Colors.blue.withOpacity(0.1) 
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _useAutoAudio 
                    ? Colors.blue.withOpacity(0.3) 
                    : Colors.grey.withOpacity(0.3)
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _useAutoAudio ? Icons.volume_up : Icons.volume_off,
                  color: _useAutoAudio ? Colors.blue : Colors.grey,
                  size: 18, // Giảm icon size
                ),
                const SizedBox(height: 2), // Giảm spacing
                Text(
                  _useAutoAudio ? 'Nhấn để nghe' : 'Đã tắt',
                  style: TextStyle(
                    fontSize: 9, // Giảm font size
                    color: _useAutoAudio ? Colors.blue[700] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _playAutoAudio() async {
    if (_autoFetchedAudioUrl == null) return;

    try {
      final audioPlayer = AudioPlayer();
      await audioPlayer.play(UrlSource(_autoFetchedAudioUrl!));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔊 Đang phát âm thanh...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Không thể phát âm thanh: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
              widget.vocabulary != null ? 'Chỉnh Sửa Từ Vựng' : 'Thêm Từ Vựng Mới',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Word and pronunciation
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _wordController,
                        label: 'Từ Vựng *',
                        hint: 'Nhập từ vựng tiếng Anh',
                        prefixIcon: Icons.text_fields_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập từ vựng';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Auto fetch when user stops typing for 1 second
                          if (value.trim().isNotEmpty && widget.vocabulary == null) {
                            _debounceAutoFetch(value.trim());
                          }
                        },
                      ),
                      if (_isAutoFetching)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Tìm kiếm...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: _pronunciationController,
                    label: 'Phát Âm',
                    hint: '/ˈhæpɪ/',
                    prefixIcon: Icons.record_voice_over_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                // Auto-fetch button
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Auto',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: ElevatedButton(
                          onPressed: _isAutoFetching 
                              ? null 
                              : () => _autoFetchWordData(_wordController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: _isAutoFetching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.auto_fix_high_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Meaning
            CustomTextField(
              controller: _meaningController,
              label: 'Nghĩa Tiếng Việt *',
              hint: 'Nhập nghĩa tiếng Việt',
              prefixIcon: Icons.translate_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập nghĩa tiếng Việt';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Definition
            CustomTextField(
              controller: _definitionController,
              label: 'Định Nghĩa (Tiếng Anh)',
              hint: 'English definition (optional)',
              prefixIcon: Icons.description_rounded,
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Category and Part of Speech
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPartOfSpeech,
                    decoration: const InputDecoration(
                      labelText: 'Từ Loại',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_rounded),
                    ),
                    items: _partsOfSpeech.map((pos) {
                      return DropdownMenuItem(
                        value: pos,
                        child: Text(pos),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPartOfSpeech = value!);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Difficulty Level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Độ Khó',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(5, (index) {
                      final level = index + 1;
                      final isSelected = _difficultyLevel == level;
                      return GestureDetector(
                        onTap: () => setState(() => _difficultyLevel = level),
                        child: Container(
                          width: 60,
                          margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$level',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _difficultyNames[index],
                                style: TextStyle(
                                  fontSize: 8,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Auto-fetched content preview
            if (_autoFetchedImageUrl != null || _autoFetchedAudioUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Nội dung tự động tìm thấy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_autoFetchedImageUrl != null) ...[
                          Expanded(
                            child: _buildAutoImageControl(),
                          ),
                          if (_autoFetchedAudioUrl != null) const SizedBox(width: 8), // Giảm spacing
                        ],
                        if (_autoFetchedAudioUrl != null) ...[
                          Expanded(
                            child: _buildAutoAudioControl(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Audio Upload (only show if not using auto audio)
            if (!_useAutoAudio) ...[
              MediaUploadWidget(
                title: 'Âm Thanh Phát Âm',
                description: 'Tải lên file âm thanh phát âm cho từ vựng này (MP3, WAV, M4A)',
                mediaType: MediaType.audio,
                folder: CloudinaryFolder.lessonAudio,
                maxSizeMB: 10,
                allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
                customFileNamePrefix: _generateAudioFileName(),
                customIcon: const Icon(Icons.mic_rounded, color: Colors.blue),
                primaryColor: Colors.blue,
                onUploadComplete: (result) {
                  setState(() {
                    _audioUrl = result.optimizedUrl;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎵 Âm thanh đã được tải lên thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tải lên âm thanh thất bại: $error'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Examples
            CustomTextField(
              controller: _examplesController,
              label: 'Ví Dụ',
              hint: 'Mỗi ví dụ một dòng',
              prefixIcon: Icons.format_quote_rounded,
              maxLines: 3,
              helperText: 'Nhập mỗi ví dụ trên một dòng riêng',
            ),
            
            const SizedBox(height: 16),
            
            // Synonyms and Antonyms
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _synonymsController,
                    label: 'Từ Đồng Nghĩa',
                    hint: 'word1, word2, word3',
                    prefixIcon: Icons.add_rounded,
                    helperText: 'Phân cách bằng dấu phẩy',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _antonymsController,
                    label: 'Từ Trái Nghĩa',
                    hint: 'word1, word2, word3',
                    prefixIcon: Icons.remove_rounded,
                    helperText: 'Phân cách bằng dấu phẩy',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: CustomButton(
                text: _isLoading 
                    ? 'Đang Lưu...' 
                    : (widget.vocabulary != null ? 'Cập Nhật' : 'Lưu Từ Vựng'),
                                 onPressed: _isLoading ? null : _saveVocabulary,
                 color: AppColors.primary,
                 textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveVocabulary() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final examples = _examplesController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final synonyms = _synonymsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final antonyms = _antonymsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final vocabulary = VocabularyModel(
        id: widget.vocabulary?.id ?? '',
        word: _wordController.text.trim(),
        pronunciation: _pronunciationController.text.trim(),
        meaning: _meaningController.text.trim(),
        definition: _definitionController.text.trim().isEmpty 
            ? null 
            : _definitionController.text.trim(),
        examples: examples,
        imageUrl: _imageUrl,
        audioUrl: _audioUrl,
        category: _selectedCategory,
        difficultyLevel: _difficultyLevel,
        synonyms: synonyms,
        antonyms: antonyms,
        partOfSpeech: _selectedPartOfSpeech,
        lessonIds: widget.vocabulary?.lessonIds ?? [],
        createdAt: widget.vocabulary?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        usageCount: widget.vocabulary?.usageCount ?? 0,
        metadata: widget.vocabulary?.metadata ?? {},
      );
      
      final result = await VocabularyService.saveVocabulary(vocabulary);
      
      if (result['success'] == true) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Clear form if creating new
        if (widget.vocabulary == null) {
          _formKey.currentState!.reset();
          _wordController.clear();
          _pronunciationController.clear();
          _meaningController.clear();
          _definitionController.clear();
          _examplesController.clear();
          _synonymsController.clear();
          _antonymsController.clear();
          setState(() {
            _audioUrl = null;
            _imageUrl = null;
            _difficultyLevel = 1;
            
            // Reset auto-fetch states
            _autoFetchedImageUrl = null;
            _autoFetchedAudioUrl = null;
            _useAutoImage = false;
            _useAutoAudio = false;
          });
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Lỗi không xác định'),
            backgroundColor: AppColors.error,
          ),
        );
        
        // If word exists, offer to view/edit existing word
        if (result['existingWord'] != null) {
          _showExistingWordDialog(result['existingWord']);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu từ vựng: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class VocabularyFormDialog extends StatelessWidget {
  final VocabularyModel vocabulary;
  final VoidCallback onSaved;
  
  const VocabularyFormDialog({
    super.key,
    required this.vocabulary,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    if (isSmallScreen) {
      // Full screen dialog for mobile
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Chỉnh Sửa Từ Vựng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        body: SafeArea(
          child: VocabularyFormWidget(
            vocabulary: vocabulary,
            onSaved: () {
              Navigator.pop(context);
              onSaved();
            },
          ),
        ),
      );
    } else {
      // Dialog for larger screens
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      'Chỉnh Sửa Từ Vựng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
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
                child: VocabularyFormWidget(
                  vocabulary: vocabulary,
                  onSaved: () {
                    Navigator.pop(context);
                    onSaved();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
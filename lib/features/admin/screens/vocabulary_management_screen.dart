import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/media_upload_widget.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../models/vocab_model.dart';
import '../../auth/data/auth_repository.dart';

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
  
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = ['Tất cả', 'Grammar', 'Vocabulary', 'Speaking', 'Listening', 'Writing'];
  final Map<String, String> _categoryVietnamese = {
    'Grammar': 'Ngữ pháp',
    'Vocabulary': 'Từ vựng', 
    'Speaking': 'Nói',
    'Listening': 'Nghe',
    'Writing': 'Viết',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab(),
          _buildCreateTab(),
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
              // Statistics cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tổng Từ Vựng',
                      '${_vocabularies.length}',
                      Icons.library_books_rounded,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Có Âm Thanh',
                      '${_vocabularies.where((v) => v.hasAudio).length}',
                      Icons.volume_up_rounded,
                      AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Kích Hoạt',
                      '${_vocabularies.where((v) => v.isActive).length}',
                      Icons.check_circle_rounded,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Search bar
              TextField(
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
              
              const SizedBox(height: 16),
              
              // Category filter
              Row(
                children: [
                  const Text(
                    'Danh mục:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category == 'Tất cả' ? category : _categoryVietnamese[category] ?? category,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                        _filterVocabularies();
                      },
                    ),
                  ),
                ],
              ),
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
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vocabulary.word,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (vocabulary.pronunciation.isNotEmpty)
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
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(vocabulary.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _categoryVietnamese[vocabulary.category] ?? vocabulary.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(vocabulary.category),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              vocabulary.meaning,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (vocabulary.partOfSpeech.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                vocabulary.vietnamesePartOfSpeech,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có từ vựng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn tab "Thêm Mới" để tạo từ vựng đầu tiên',
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
  }

  @override
  void dispose() {
    _wordController.dispose();
    _pronunciationController.dispose();
    _meaningController.dispose();
    _definitionController.dispose();
    _examplesController.dispose();
    _synonymsController.dispose();
    _antonymsController.dispose();
    super.dispose();
  }

  String _generateAudioFileName() {
    final word = _wordController.text.trim().replaceAll(' ', '_').toLowerCase();
    final category = _selectedCategory.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${category}_vocab_${word}_audio_$timestamp';
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
                  child: CustomTextField(
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
                Row(
                  children: List.generate(5, (index) {
                    final level = index + 1;
                    final isSelected = _difficultyLevel == level;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _difficultyLevel = level),
                        child: Container(
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  _difficultyNames[index],
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Audio Upload
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
      
      final success = await VocabularyService.saveVocabulary(vocabulary);
      
      if (success) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vocabulary != null 
                ? '✅ Đã cập nhật từ vựng "${vocabulary.word}"'
                : '✅ Đã thêm từ vựng "${vocabulary.word}"'),
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
          });
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
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
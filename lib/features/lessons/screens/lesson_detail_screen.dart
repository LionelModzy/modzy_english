import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../models/lesson_model.dart';
import '../../../models/vocab_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final LessonModel lesson;
  
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentSectionIndex = 0;
  bool _isPlaying = false;
  bool _isFavorite = false;
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getVietnameseCategory(String englishCategory) {
    switch (englishCategory) {
      case 'Grammar': return 'Ngữ pháp';
      case 'Vocabulary': return 'Từ vựng';
      case 'Speaking': return 'Nói';
      case 'Listening': return 'Nghe';
      case 'Writing': return 'Viết';
      default: return englishCategory;
    }
  }

  String _getVietnameseDifficulty(String englishDifficulty) {
    switch (englishDifficulty) {
      case 'Beginner': return 'Cơ bản';
      case 'Elementary': return 'Sơ cấp';
      case 'Intermediate': return 'Trung cấp';
      case 'Upper Intermediate': return 'Trung cấp cao';
      case 'Advanced': return 'Nâng cao';
      default: return 'Cơ bản';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Grammar': return const Color(0xFF8B5CF6);
      case 'Vocabulary': return const Color(0xFF06B6D4);
      case 'Speaking': return const Color(0xFF10B981);
      case 'Listening': return const Color(0xFFF59E0B);
      case 'Writing': return const Color(0xFFEF4444);
      default: return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Grammar': return Icons.menu_book_rounded;
      case 'Vocabulary': return Icons.library_books_rounded;
      case 'Speaking': return Icons.record_voice_over_rounded;
      case 'Listening': return Icons.headphones_rounded;
      case 'Writing': return Icons.edit_rounded;
      default: return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                backgroundColor: _getCategoryColor(widget.lesson.category),
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFavorite ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chia sẻ bài học')),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getCategoryColor(widget.lesson.category),
                          _getCategoryColor(widget.lesson.category).withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PatternPainter(),
                          ),
                        ),
                        
                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryIcon(widget.lesson.category),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getVietnameseCategory(widget.lesson.category),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Title
                              Text(
                                widget.lesson.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Stats row
                              Row(
                                children: [
                                  _buildStatBadge(
                                    Icons.schedule,
                                    widget.lesson.formattedDuration,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatBadge(
                                    Icons.signal_cellular_alt,
                                    _getVietnameseDifficulty(widget.lesson.difficultyLevelName),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatBadge(
                                    Icons.menu_book,
                                    '${widget.lesson.sections.length} phần',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Nội Dung'),
                    Tab(text: 'Từ Vựng'),
                    Tab(text: 'Mục Tiêu'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildContentTab(),
                _buildVocabularyTab(),
                _buildObjectivesTab(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Container(
            padding: const EdgeInsets.all(20),
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
                  'Mô Tả Bài Học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.lesson.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Progress tracking
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                  _getCategoryColor(widget.lesson.category).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getCategoryColor(widget.lesson.category).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: _getCategoryColor(widget.lesson.category),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tiến Độ Học Tập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCategoryColor(widget.lesson.category),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toInt()}% hoàn thành',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getCategoryColor(widget.lesson.category),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sections
          const Text(
            'Nội Dung Chi Tiết',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          
          ...widget.lesson.sections.asMap().entries.map((entry) {
            int index = entry.key;
            LessonSection section = entry.value;
            bool isActive = _currentSectionIndex == index;
            bool isCompleted = index < _currentSectionIndex;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive 
                    ? _getCategoryColor(widget.lesson.category)
                    : const Color(0xFFE2E8F0),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive 
                      ? _getCategoryColor(widget.lesson.category).withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                    blurRadius: isActive ? 15 : 5,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted 
                      ? const Color(0xFF10B981)
                      : isActive
                        ? _getCategoryColor(widget.lesson.category)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted 
                      ? Icons.check_rounded
                      : isActive
                        ? Icons.play_arrow_rounded
                        : Icons.lock_rounded,
                    color: isCompleted || isActive ? Colors.white : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                title: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActive ? _getCategoryColor(widget.lesson.category) : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      section.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSectionTypeColor(section.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getSectionTypeText(section.type),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getSectionTypeColor(section.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (index <= _currentSectionIndex) {
                    _openSection(index);
                  }
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVocabularyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Từ Vựng Trong Bài',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (widget.lesson.vocabulary.isNotEmpty)
                      Text(
                        '${widget.lesson.vocabulary.length} từ vựng quan trọng',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.lesson.vocabulary.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getVietnameseCategory(widget.lesson.category),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(widget.lesson.category),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (widget.lesson.vocabulary.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
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
              child: const Column(
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 60,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có từ vựng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Từ vựng sẽ được cập nhật sớm',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            ...widget.lesson.vocabulary.asMap().entries.map((entry) {
              int index = entry.key;
              String word = entry.value;
              
              return _buildVocabularyCard(word, index);
            }),
        ],
      ),
    );
  }

  Widget _buildVocabularyCard(String word, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor(widget.lesson.category).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor(widget.lesson.category).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Index number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(widget.lesson.category),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Word details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            word,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(widget.lesson.category),
                            ),
                          ),
                        ),
                        _buildVocabularyAudioButton(word),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Từ vựng trong bài học ${widget.lesson.title}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              // Learn button
              Expanded(
                child: _buildVocabularyActionButton(
                  icon: Icons.school_outlined,
                  label: 'Học Từ Này',
                  color: AppColors.primary,
                  onTap: () => _showVocabularyDetail(word),
                ),
              ),
              const SizedBox(width: 8),
              // Add to favorites
              Expanded(
                child: _buildVocabularyActionButton(
                  icon: Icons.favorite_outline,
                  label: 'Yêu Thích',
                  color: Colors.red,
                  onTap: () => _addToFavorites(word),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyAudioButton(String word) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _playVocabularyAudio(word),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.volume_up_rounded,
            size: 16,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildVocabularyActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playVocabularyAudio(String word) async {
    try {
      // Try to find vocabulary with audio
      final vocabularies = await VocabularyService.searchVocabulary(word);
      final vocabWithAudio = vocabularies.firstWhere(
        (vocab) => vocab.word.toLowerCase() == word.toLowerCase() && vocab.hasAudio,
        orElse: () => vocabularies.isNotEmpty ? vocabularies.first : VocabularyModel(
          id: '',
          word: word,
          pronunciation: '',
          meaning: '',
          examples: [],
          category: '',
          difficultyLevel: 1,
          synonyms: [],
          antonyms: [],
          partOfSpeech: '',
          lessonIds: [],
          createdAt: DateTime.now(),
          isActive: true,
          usageCount: 0,
          metadata: {},
        ),
      );
      
      if (vocabWithAudio.hasAudio) {
        // Play real audio from vocabulary
        final audioPlayer = AudioPlayer();
        await audioPlayer.play(UrlSource(vocabWithAudio.audioUrl!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔊 Phát âm: ${vocabWithAudio.word}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Fallback to TTS or mock
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔊 Phát âm: $word (Mock TTS)'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Fallback to mock TTS
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔊 Phát âm: $word (TTS)'),
          backgroundColor: Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showVocabularyDetail(String word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVocabularyDetailSheet(word),
    );
  }

  Widget _buildVocabularyDetailSheet(String word) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(widget.lesson.category),
                        ),
                      ),
                      const Text(
                        'Chi tiết từ vựng',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mock vocabulary details
                  _buildDetailSection('Nghĩa', 'Nghĩa tiếng Việt của từ $word'),
                  _buildDetailSection('Phát âm', '/$word/'),
                  _buildDetailSection('Từ loại', 'Danh từ'),
                  _buildDetailSection('Ví dụ', 'This is an example sentence with $word.'),
                  _buildDetailSection('Từ đồng nghĩa', 'synonym1, synonym2'),
                  _buildDetailSection('Từ trái nghĩa', 'antonym1, antonym2'),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addToFavorites(word),
                          icon: const Icon(Icons.favorite_outline),
                          label: const Text('Thêm vào yêu thích'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addToStudyList(word),
                          icon: const Icon(Icons.library_add_outlined),
                          label: const Text('Thêm vào danh sách học'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _addToFavorites(String word) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❤️ Đã thêm "$word" vào danh sách yêu thích'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addToStudyList(String word) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📚 Đã thêm "$word" vào danh sách cần học'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildObjectivesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mục Tiêu Học Tập',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          
          ...widget.lesson.objectives.asMap().entries.map((entry) {
            int index = entry.key;
            String objective = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.lesson.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      objective,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 24),
          
          // Tags section
          if (widget.lesson.tags.isNotEmpty) ...[
            const Text(
              'Thẻ Từ Khóa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.lesson.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.lesson.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getCategoryColor(widget.lesson.category).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getCategoryColor(widget.lesson.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous section button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _currentSectionIndex > 0 
                  ? const Color(0xFFF1F5F9) 
                  : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                onPressed: _currentSectionIndex > 0 ? () {
                  setState(() {
                    _currentSectionIndex--;
                    _progress = _currentSectionIndex / widget.lesson.sections.length;
                  });
                } : null,
                icon: Icon(
                  Icons.skip_previous_rounded,
                  color: _currentSectionIndex > 0 
                    ? const Color(0xFF64748B) 
                    : const Color(0xFFCBD5E1),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Play/Continue button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                    if (_isPlaying && _currentSectionIndex < widget.lesson.sections.length - 1) {
                      _currentSectionIndex++;
                      _progress = _currentSectionIndex / widget.lesson.sections.length;
                    }
                  });
                },
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow_rounded),
                label: Text(
                  _isPlaying ? 'Tạm Dừng' : 'Bắt Đầu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(widget.lesson.category),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Next section button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _currentSectionIndex < widget.lesson.sections.length - 1 
                  ? const Color(0xFFF1F5F9) 
                  : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                onPressed: _currentSectionIndex < widget.lesson.sections.length - 1 ? () {
                  setState(() {
                    _currentSectionIndex++;
                    _progress = _currentSectionIndex / widget.lesson.sections.length;
                  });
                } : null,
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: _currentSectionIndex < widget.lesson.sections.length - 1 
                    ? const Color(0xFF64748B) 
                    : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSectionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video': return const Color(0xFFEF4444);
      case 'audio': return const Color(0xFF06B6D4);
      case 'exercise': return const Color(0xFF10B981);
      case 'text':
      default: return const Color(0xFF8B5CF6);
    }
  }

  String _getSectionTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'video': return 'Video';
      case 'audio': return 'Âm thanh';
      case 'exercise': return 'Bài tập';
      case 'text':
      default: return 'Văn bản';
    }
  }

  void _openSection(int index) {
    setState(() {
      _currentSectionIndex = index;
      _progress = _currentSectionIndex / widget.lesson.sections.length;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang mở phần ${index + 1}: ${widget.lesson.sections[index].title}'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// Custom pattern painter for background decoration
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 0; i < size.width; i += 30) {
      for (int j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/lesson_service.dart';
import '../../../models/lesson_model.dart';
import '../../auth/data/auth_repository.dart';
import 'create_lesson_screen.dart';

class LessonManagementScreen extends StatefulWidget {
  const LessonManagementScreen({super.key});

  @override
  State<LessonManagementScreen> createState() => _LessonManagementScreenState();
}

class _LessonManagementScreenState extends State<LessonManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LessonModel> _allLessons = [];
  List<LessonModel> _filteredLessons = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  String _sortBy = 'order';
  
  final List<String> _categories = ['Tất cả', 'Ngữ pháp', 'Từ vựng', 'Nói', 'Nghe', 'Viết'];
  final List<String> _statusOptions = ['Tất cả', 'Hoạt động', 'Tạm dừng', 'Trả phí', 'Miễn phí'];
  final List<String> _sortOptions = ['order', 'title', 'createdAt', 'difficultyLevel'];

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterLessons();
  }

  Future<void> _loadLessons() async {
    try {
      setState(() => _isLoading = true);
      final lessons = await LessonService.getAllLessons();
      setState(() {
        _allLessons = lessons;
        _filteredLessons = lessons;
        _isLoading = false;
      });
      _filterLessons();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải bài học: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterLessons() {
    List<LessonModel> filtered = List.from(_allLessons);
    
    // Search filter
    String searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((lesson) =>
        lesson.title.toLowerCase().contains(searchQuery) ||
        lesson.description.toLowerCase().contains(searchQuery) ||
        lesson.tags.any((tag) => tag.toLowerCase().contains(searchQuery))
      ).toList();
    }
    
    // Category filter
    if (_selectedCategory != 'Tất cả') {
      String englishCategory = _getEnglishCategory(_selectedCategory);
      filtered = filtered.where((lesson) => lesson.category == englishCategory).toList();
    }
    
    // Status filter
    if (_selectedStatus != 'Tất cả') {
      switch (_selectedStatus) {
        case 'Hoạt động':
          filtered = filtered.where((lesson) => lesson.isActive).toList();
          break;
        case 'Tạm dừng':
          filtered = filtered.where((lesson) => !lesson.isActive).toList();
          break;
        case 'Trả phí':
          filtered = filtered.where((lesson) => lesson.isPremium).toList();
          break;
        case 'Miễn phí':
          filtered = filtered.where((lesson) => !lesson.isPremium).toList();
          break;
      }
    }
    
    // Sort
    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'createdAt':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'difficultyLevel':
        filtered.sort((a, b) => a.difficultyLevel.compareTo(b.difficultyLevel));
        break;
      case 'order':
      default:
        filtered.sort((a, b) => a.order.compareTo(b.order));
        break;
    }
    
    setState(() {
      _filteredLessons = filtered;
    });
  }

  String _getEnglishCategory(String vietnameseCategory) {
    switch (vietnameseCategory) {
      case 'Ngữ pháp': return 'Grammar';
      case 'Từ vựng': return 'Vocabulary';
      case 'Nói': return 'Speaking';
      case 'Nghe': return 'Listening';
      case 'Viết': return 'Writing';
      default: return vietnameseCategory;
    }
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
      default: return englishDifficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quản Lý Bài Học',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLessons,
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng thống kê sắp ra mắt!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with stats and actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Statistics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Tổng Bài Học',
                        _allLessons.length.toString(),
                        Icons.library_books,
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Hoạt Động',
                        _allLessons.where((l) => l.isActive).length.toString(),
                        Icons.check_circle,
                        Colors.green.shade300,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Trả Phí',
                        _allLessons.where((l) => l.isPremium).length.toString(),
                        Icons.star,
                        Colors.amber.shade300,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Create Lesson Button
                SizedBox(
                  width: double.infinity,
                  height: 52, // Tăng chiều cao từ 48
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateLessonScreen(),
                        ),
                      ).then((_) => _loadLessons());
                    },
                    icon: const Icon(Icons.add, color: AppColors.primary, size: 22), // Giảm size icon
                    label: const Text(
                      'Tạo Bài Học Mới',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 17, // Tăng font size
                        fontWeight: FontWeight.w700, // Đậm hơn
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14), // Tăng bo góc
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Giảm padding tổng thể
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                CustomTextField(
                  controller: _searchController,
                  label: 'Tìm Kiếm Bài Học',
                  hint: 'Tìm theo tiêu đề, mô tả hoặc thẻ...',
                  prefixIcon: Icons.search,
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                ),
                
                const SizedBox(height: 16),
                
                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Danh Mục', _selectedCategory, _categories, (value) {
                        setState(() => _selectedCategory = value);
                        _filterLessons();
                      }),
                      const SizedBox(width: 12),
                      _buildFilterChip('Trạng Thái', _selectedStatus, _statusOptions, (value) {
                        setState(() => _selectedStatus = value);
                        _filterLessons();
                      }),
                      const SizedBox(width: 12),
                      _buildFilterChip('Sắp Xếp', _getSortDisplayName(_sortBy), ['Thứ tự', 'Tiêu đề', 'Ngày tạo', 'Độ khó'], (value) {
                        setState(() => _sortBy = _getSortValue(value));
                        _filterLessons();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lessons List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLessons.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredLessons.length,
                        itemBuilder: (context, index) {
                          return _buildLessonCard(_filteredLessons[index], index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _getSortDisplayName(String sortValue) {
    switch (sortValue) {
      case 'order': return 'Thứ tự';
      case 'title': return 'Tiêu đề';
      case 'createdAt': return 'Ngày tạo';
      case 'difficultyLevel': return 'Độ khó';
      default: return 'Thứ tự';
    }
  }

  String _getSortValue(String displayName) {
    switch (displayName) {
      case 'Thứ tự': return 'order';
      case 'Tiêu đề': return 'title';
      case 'Ngày tạo': return 'createdAt';
      case 'Độ khó': return 'difficultyLevel';
      default: return 'order';
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, List<String> options, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: (newValue) => onChanged(newValue!),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          hint: Text(label),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildLessonCard(LessonModel lesson, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lesson.isActive 
                ? AppColors.success.withOpacity(0.1) 
                : AppColors.error.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Order Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${lesson.order}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Status and Premium badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: lesson.isActive ? AppColors.success : AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            lesson.isActive ? 'Hoạt động' : 'Tạm dừng',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        if (lesson.isPremium) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Trả phí',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      _getVietnameseCategory(lesson.category),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Quick Actions
                PopupMenuButton<String>(
                  onSelected: (action) => _handleLessonAction(action, lesson),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                    const PopupMenuItem(value: 'preview', child: Text('Xem trước')),
                    const PopupMenuItem(value: 'clone', child: Text('Sao chép')),
                    const PopupMenuItem(value: 'analytics', child: Text('Thống kê')),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Text(lesson.isActive ? 'Tạm dừng' : 'Kích hoạt'),
                    ),
                    PopupMenuItem(
                      value: 'toggle_premium',
                      child: Text(lesson.isPremium ? 'Chuyển miễn phí' : 'Chuyển trả phí'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Description
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  lesson.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Meta Info Row
                Row(
                  children: [
                    _buildMetaInfo(Icons.schedule, lesson.formattedDuration),
                    const SizedBox(width: 16),
                    _buildMetaInfo(Icons.signal_cellular_alt, _getVietnameseDifficulty(lesson.difficultyLevelName)),
                    const SizedBox(width: 16),
                    _buildMetaInfo(Icons.list, '${lesson.sections.length} phần'),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Tags
                Wrap(
                  spacing: 8,
                  children: lesson.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
            'Không tìm thấy bài học nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo bài học đầu tiên hoặc điều chỉnh bộ lọc',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Tạo Bài Học',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateLessonScreen(),
                ),
              ).then((_) => _loadLessons());
            },
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  void _handleLessonAction(String action, LessonModel lesson) async {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateLessonScreen(lessonToEdit: lesson),
          ),
        ).then((_) => _loadLessons());
        break;
        
      case 'preview':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LessonPreviewScreen(lesson: lesson),
          ),
        );
        break;
        
      case 'clone':
        _cloneLesson(lesson);
        break;
        
      case 'analytics':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LessonAnalyticsScreen(lesson: lesson),
          ),
        );
        break;
        
      case 'toggle_status':
        await _toggleLessonStatus(lesson);
        break;
        
      case 'toggle_premium':
        await _togglePremiumStatus(lesson);
        break;
        
      case 'delete':
        _deleteLesson(lesson);
        break;
    }
  }

  Future<void> _toggleLessonStatus(LessonModel lesson) async {
    try {
      await LessonService.toggleLessonStatus(lesson.id, !lesson.isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bài học đã ${lesson.isActive ? 'tạm dừng' : 'kích hoạt'} thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadLessons();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật bài học: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _togglePremiumStatus(LessonModel lesson) async {
    try {
      await LessonService.togglePremiumStatus(lesson.id, !lesson.isPremium);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bài học đã chuyển thành ${lesson.isPremium ? 'miễn phí' : 'trả phí'} thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadLessons();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật bài học: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _cloneLesson(LessonModel lesson) async {
    try {
      final user = await AuthRepository.getCurrentUserData();
      final clonedLesson = lesson.copyWith(
        id: '', // Will be generated by Firestore
        title: '${lesson.title} (Bản sao)',
        order: _allLessons.length + 1,
        createdAt: DateTime.now(),
        createdBy: user?.uid ?? 'admin',
        isActive: false, // Start as inactive
      );
      
      await LessonService.createLesson(clonedLesson);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sao chép bài học thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadLessons();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi sao chép bài học: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _deleteLesson(LessonModel lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Bài Học'),
        content: Text('Bạn có chắc chắn muốn xóa "${lesson.title}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await LessonService.deleteLesson(lesson.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xóa bài học thành công'),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadLessons();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi khi xóa bài học: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class EditLessonScreen extends StatelessWidget {
  final LessonModel lesson;
  
  const EditLessonScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Bài Học'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('Màn hình chỉnh sửa bài học: ${lesson.title}'),
      ),
    );
  }
}

class LessonPreviewScreen extends StatelessWidget {
  final LessonModel lesson;
  
  const LessonPreviewScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem Trước Bài Học'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('Xem trước bài học: ${lesson.title}'),
      ),
    );
  }
}

class LessonAnalyticsScreen extends StatelessWidget {
  final LessonModel lesson;
  
  const LessonAnalyticsScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê Bài Học'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('Thống kê cho bài học: ${lesson.title}'),
      ),
    );
  }
} 
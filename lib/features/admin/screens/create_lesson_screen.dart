import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/media_upload_widget.dart';
import '../../../core/services/lesson_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../models/lesson_model.dart';
import '../../auth/data/auth_repository.dart';

class CreateLessonScreen extends StatefulWidget {
  final LessonModel? lessonToEdit; // For editing existing lessons
  
  const CreateLessonScreen({super.key, this.lessonToEdit});

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Form keys for validation
  final _basicInfoFormKey = GlobalKey<FormState>();
  final _contentFormKey = GlobalKey<FormState>();
  
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _vocabularyController = TextEditingController();
  final _tagsController = TextEditingController();
  
  // Lesson data
  String _selectedCategory = 'Grammar';
  int _difficultyLevel = 1;
  int _estimatedDuration = 15;
  bool _isPremium = false;
  bool _isActive = true;
  String? _imageUrl;
  String? _audioUrl;
  String? _videoUrl; // Main lesson video
  List<LessonSection> _sections = [];
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  final List<String> _categories = ['Grammar', 'Vocabulary', 'Speaking', 'Listening', 'Writing'];
  final List<String> _categoriesVietnamese = ['Ngữ pháp', 'Từ vựng', 'Nói', 'Nghe', 'Viết'];
  final List<String> _difficultyNames = ['Cơ bản', 'Sơ cấp', 'Trung cấp', 'Trung cấp cao', 'Nâng cao'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // If editing, populate fields
    if (widget.lessonToEdit != null) {
      _populateFields(widget.lessonToEdit!);
    }
    
    // Add default section
    _sections = [
      LessonSection(
        title: 'Giới thiệu',
        content: '',
        type: 'text',
        metadata: {},
      ),
    ];
  }

  void _populateFields(LessonModel lesson) {
    _titleController.text = lesson.title;
    _descriptionController.text = lesson.description;
    _contentController.text = lesson.content;
    _objectivesController.text = lesson.objectives.join(', ');
    _vocabularyController.text = lesson.vocabulary.join(', ');
    _tagsController.text = lesson.tags.join(', ');
    _selectedCategory = lesson.category;
    _difficultyLevel = lesson.difficultyLevel;
    _estimatedDuration = lesson.estimatedDuration;
    _isPremium = lesson.isPremium;
    _isActive = lesson.isActive;
    _imageUrl = lesson.imageUrl;
    _audioUrl = lesson.audioUrl;
    _videoUrl = lesson.videoUrl;
    _sections = List.from(lesson.sections);
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

  // Generate custom filename based on function
  String _generateCustomFileName(String type, {String? sectionTitle}) {
    final lessonTitle = _titleController.text.trim().replaceAll(' ', '_').toLowerCase();
    final category = _selectedCategory.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    switch (type) {
      case 'thumbnail':
        return '${category}_${lessonTitle}_thumbnail_$timestamp';
      case 'main_audio':
        return '${category}_${lessonTitle}_main_audio_$timestamp';
      case 'main_video':
        return '${category}_${lessonTitle}_main_video_$timestamp';
      case 'section_audio':
        final sectionName = sectionTitle?.replaceAll(' ', '_').toLowerCase() ?? 'section';
        return '${category}_${lessonTitle}_${sectionName}_audio_$timestamp';
      case 'section_video':
        final sectionName = sectionTitle?.replaceAll(' ', '_').toLowerCase() ?? 'section';
        return '${category}_${lessonTitle}_${sectionName}_video_$timestamp';
      default:
        return '${category}_${lessonTitle}_$type}_$timestamp';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _objectivesController.dispose();
    _vocabularyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.lessonToEdit != null ? 'Chỉnh Sửa Bài Học' : 'Tạo Bài Học',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Thông Tin Cơ Bản'),
            Tab(text: 'Nội Dung'),
            Tab(text: 'Phương Tiện'),
            Tab(text: 'Xem Lại'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(),
                _buildContentTab(),
                _buildMediaTab(),
                _buildReviewTab(),
              ],
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Quay Lại'),
                    ),
                  ),
                
                if (_currentStep > 0) const SizedBox(width: 16),
                
                Expanded(
                  child: CustomButton(
                    text: _currentStep == 3 
                        ? (widget.lessonToEdit != null ? 'Cập Nhật Bài Học' : 'Tạo Bài Học')
                        : 'Tiếp Theo',
                    onPressed: _isLoading ? null : _nextStep,
                    isLoading: _isLoading,
                    icon: _currentStep == 3 ? Icons.save : Icons.arrow_forward,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _basicInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông Tin Cơ Bản',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            CustomTextField(
              controller: _titleController,
              label: 'Tiêu Đề Bài Học *',
              hint: 'Nhập tiêu đề hấp dẫn cho bài học',
              prefixIcon: Icons.title,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề bài học';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Mô Tả *',
              hint: 'Mô tả những gì học viên sẽ học được',
              prefixIcon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Category and Difficulty Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh Mục *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            onChanged: (value) {
                              setState(() => _selectedCategory = value!);
                            },
                            items: _categories.asMap().entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.value,
                                child: Text(_categoriesVietnamese[entry.key]),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Độ Khó *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _difficultyLevel,
                            isExpanded: true,
                            onChanged: (value) {
                              setState(() => _difficultyLevel = value!);
                            },
                            items: List.generate(5, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text('${index + 1} - ${_difficultyNames[index]}'),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Duration Slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời Gian Ước Tính: $_estimatedDuration phút',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Slider(
                  value: _estimatedDuration.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() => _estimatedDuration = value.round());
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('5 phút', style: TextStyle(color: AppColors.textSecondary)),
                    Text('120 phút', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Tags
            CustomTextField(
              controller: _tagsController,
              label: 'Thẻ',
              hint: 'Nhập thẻ cách nhau bởi dấu phẩy (ví dụ: cơ bản, ngữ pháp, giao tiếp)',
              prefixIcon: Icons.label,
              helperText: 'Thẻ giúp học viên tìm thấy bài học của bạn',
            ),
            
            const SizedBox(height: 16),
            
            // Objectives
            CustomTextField(
              controller: _objectivesController,
              label: 'Mục Tiêu Học Tập',
              hint: 'Nhập mục tiêu cách nhau bởi dấu phẩy',
              prefixIcon: Icons.assignment,
              maxLines: 2,
              helperText: 'Học viên sẽ có thể làm gì sau bài học này?',
            ),
            
            const SizedBox(height: 16),
            
            // Vocabulary
            CustomTextField(
              controller: _vocabularyController,
              label: 'Từ Vựng Chính',
              hint: 'Nhập từ vựng cách nhau bởi dấu phẩy',
              prefixIcon: Icons.school,
              maxLines: 2,
              helperText: 'Những từ quan trọng học viên sẽ học',
            ),
            
            const SizedBox(height: 24),
            
            // Switches
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Bài Học Trả Phí'),
                    subtitle: const Text('Yêu cầu đăng ký'),
                    value: _isPremium,
                    onChanged: (value) {
                      setState(() => _isPremium = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Kích Hoạt'),
                    subtitle: const Text('Hiển thị với học viên'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _contentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nội Dung Bài Học',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Main Content
            CustomTextField(
              controller: _contentController,
              label: 'Nội Dung Chính *',
              hint: 'Nhập nội dung chính của bài học...',
              prefixIcon: Icons.article,
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập nội dung bài học';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Sections
            Row(
              children: [
                Text(
                  'Các Phần Của Bài Học',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addSection,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm Phần'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sections List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                return _buildSectionCard(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(int index) {
    final section = _sections[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSectionIcon(section.type),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Phần ${index + 1}: ${_getSectionTypeVietnamese(section.type)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      _editSection(index);
                      break;
                    case 'delete':
                      _deleteSection(index);
                      break;
                    case 'move_up':
                      _moveSectionUp(index);
                      break;
                    case 'move_down':
                      _moveSectionDown(index);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                  if (index > 0) const PopupMenuItem(value: 'move_up', child: Text('Di chuyển lên')),
                  if (index < _sections.length - 1) const PopupMenuItem(value: 'move_down', child: Text('Di chuyển xuống')),
                  const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            section.content.isEmpty ? 'Chưa có nội dung' : section.content,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (section.hasMedia) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Có nội dung phương tiện',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSectionTypeVietnamese(String type) {
    switch (type) {
      case 'text': return 'Văn bản';
      case 'audio': return 'Âm thanh';
      case 'video': return 'Video';
      case 'exercise': return 'Bài tập';
      default: return type.toUpperCase();
    }
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nội Dung Phương Tiện',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tải lên hình ảnh, video và âm thanh cho bài học của bạn',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Lesson Thumbnail Image
          MediaUploadWidget(
            title: 'Ảnh Đại Diện Bài Học',
            description: 'Tải lên ảnh bìa cho bài học của bạn (khuyến nghị: 1280x720px)',
            mediaType: MediaType.image,
            folder: CloudinaryFolder.lessonImages,
            maxSizeMB: 5,
            allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
            currentImagePublicId: _extractPublicIdFromUrl(_imageUrl),
            customFileNamePrefix: _generateCustomFileName('thumbnail'),
            customIcon: const Icon(Icons.image, color: AppColors.primary),
            onUploadComplete: (result) {
              setState(() {
                _imageUrl = result.optimizedUrl;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ảnh đại diện đã được tải lên thành công!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tải lên ảnh thất bại: $error'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Main Lesson Video
          MediaUploadWidget(
            title: 'Video Bài Học Chính',
            description: 'Tải lên video chính cho bài học (tối đa 100MB, định dạng: MP4, MOV)',
            mediaType: MediaType.video,
            folder: CloudinaryFolder.lessonVideos,
            maxSizeMB: 100,
            allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
            currentImagePublicId: _extractPublicIdFromUrl(_videoUrl),
            customFileNamePrefix: _generateCustomFileName('main_video'),
            customIcon: const Icon(Icons.videocam, color: Colors.red),
            primaryColor: Colors.red,
            onUploadComplete: (result) {
              setState(() {
                _videoUrl = result.optimizedUrl;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video bài học đã được tải lên thành công!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tải lên video thất bại: $error'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Main Audio Content
          MediaUploadWidget(
            title: 'Âm Thanh Bài Học Chính',
            description: 'Tải lên tệp âm thanh chính cho bài học (phát âm, nghe hiểu)',
            mediaType: MediaType.audio,
            folder: CloudinaryFolder.lessonAudio,
            maxSizeMB: 20,
            allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
            currentImagePublicId: _extractPublicIdFromUrl(_audioUrl),
            customFileNamePrefix: _generateCustomFileName('main_audio'),
            customIcon: const Icon(Icons.audiotrack, color: Colors.blue),
            primaryColor: Colors.blue,
            onUploadComplete: (result) {
              setState(() {
                _audioUrl = result.optimizedUrl;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Âm thanh bài học đã được tải lên thành công!'),
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
          
          const SizedBox(height: 32),
          
          // Section Media Upload Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Phương Tiện Cho Từng Phần',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Để tải lên audio/video cho từng phần cụ thể của bài học, vui lòng chọn loại "Âm thanh" hoặc "Video" khi thêm/chỉnh sửa phần ở tab "Nội Dung".',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xem Lại & Xuất Bản',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Xem lại bài học trước khi xuất bản',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Lesson Preview Card
          Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and badges
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _titleController.text.isEmpty ? 'Bài học chưa có tiêu đề' : _titleController.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _descriptionController.text.isEmpty ? 'Chưa có mô tả' : _descriptionController.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Meta info
                Wrap(
                  spacing: 16,
                  children: [
                    _buildMetaChip(Icons.category, _getVietnameseCategory(_selectedCategory)),
                    _buildMetaChip(Icons.signal_cellular_alt, _difficultyNames[_difficultyLevel - 1]),
                    _buildMetaChip(Icons.schedule, '$_estimatedDuration phút'),
                    _buildMetaChip(Icons.list, '${_sections.length} phần'),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Content preview
                if (_contentController.text.isNotEmpty) ...[
                  Text(
                    'Xem Trước Nội Dung:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _contentController.text,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                
                // Media preview
                if (_imageUrl != null || _audioUrl != null || _videoUrl != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Tệp Phương Tiện:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_imageUrl != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image, size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Ảnh đại diện',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_videoUrl != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam, size: 12, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                'Video bài học',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_audioUrl != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.audiotrack, size: 12, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'Âm thanh',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String type) {
    switch (type) {
      case 'text': return Icons.text_fields;
      case 'audio': return Icons.audiotrack;
      case 'video': return Icons.videocam;
      case 'exercise': return Icons.quiz;
      default: return Icons.article;
    }
  }

  String? _extractPublicIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      int uploadIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'upload') {
          uploadIndex = i;
          break;
        }
      }
      
      if (uploadIndex != -1 && pathSegments.length > uploadIndex + 1) {
        String pathAfterUpload = pathSegments.sublist(uploadIndex + 1).join('/');
        final lastDotIndex = pathAfterUpload.lastIndexOf('.');
        if (lastDotIndex != -1) {
          pathAfterUpload = pathAfterUpload.substring(0, lastDotIndex);
        }
        return pathAfterUpload;
      }
    } catch (e) {
      if (kDebugMode) print('Error extracting public ID: $e');
    }
    
    return null;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_basicInfoFormKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
        _tabController.animateTo(1);
      }
    } else if (_currentStep == 1) {
      if (_contentFormKey.currentState!.validate()) {
        setState(() => _currentStep = 2);
        _tabController.animateTo(2);
      }
    } else if (_currentStep == 2) {
      setState(() => _currentStep = 3);
      _tabController.animateTo(3);
    } else if (_currentStep == 3) {
      _saveLesson();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
      _tabController.animateTo(_currentStep);
    }
  }

  void _addSection() {
    showDialog(
      context: context,
      builder: (context) => _SectionDialog(
        onSave: (section) {
          setState(() {
            _sections.add(section);
          });
        },
        lessonTitle: _titleController.text,
        category: _selectedCategory,
      ),
    );
  }

  void _editSection(int index) {
    showDialog(
      context: context,
      builder: (context) => _SectionDialog(
        section: _sections[index],
        onSave: (section) {
          setState(() {
            _sections[index] = section;
          });
        },
        lessonTitle: _titleController.text,
        category: _selectedCategory,
      ),
    );
  }

  void _deleteSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  void _moveSectionUp(int index) {
    if (index > 0) {
      setState(() {
        final section = _sections.removeAt(index);
        _sections.insert(index - 1, section);
      });
    }
  }

  void _moveSectionDown(int index) {
    if (index < _sections.length - 1) {
      setState(() {
        final section = _sections.removeAt(index);
        _sections.insert(index + 1, section);
      });
    }
  }

  Future<void> _saveLesson() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await AuthRepository.getCurrentUserData();
      
      // Parse lists from comma-separated strings
      final objectives = _objectivesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final vocabulary = _vocabularyController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      final tags = _tagsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      // Create lesson model
      final lesson = LessonModel(
        id: widget.lessonToEdit?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        difficultyLevel: _difficultyLevel,
        estimatedDuration: _estimatedDuration,
        tags: tags,
        objectives: objectives,
        audioUrl: _audioUrl,
        imageUrl: _imageUrl,
        videoUrl: _videoUrl,
        sections: _sections,
        vocabulary: vocabulary,
        createdAt: widget.lessonToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: _isActive,
        isPremium: _isPremium,
        order: widget.lessonToEdit?.order ?? 0, // Will be set by service
        createdBy: widget.lessonToEdit?.createdBy ?? user?.uid ?? 'admin',
        metadata: {},
      );
      
      if (widget.lessonToEdit != null) {
        // Update existing lesson
        await LessonService.updateLesson(widget.lessonToEdit!.id, lesson);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật bài học thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Create new lesson
        await LessonService.createLesson(lesson);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo bài học thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu bài học: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Section Dialog for adding/editing sections
class _SectionDialog extends StatefulWidget {
  final LessonSection? section;
  final Function(LessonSection) onSave;
  final String lessonTitle; // For custom filename
  final String category;
  
  const _SectionDialog({
    required this.onSave, 
    this.section,
    required this.lessonTitle,
    required this.category,
  });

  @override
  State<_SectionDialog> createState() => __SectionDialogState();
}

class __SectionDialogState extends State<_SectionDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'text';
  String? _mediaUrl;
  
  final List<String> _sectionTypes = ['text', 'audio', 'video', 'exercise'];
  final List<String> _sectionTypesVietnamese = ['Văn bản', 'Âm thanh', 'Video', 'Bài tập'];

  @override
  void initState() {
    super.initState();
    if (widget.section != null) {
      _titleController.text = widget.section!.title;
      _contentController.text = widget.section!.content;
      _selectedType = widget.section!.type;
      _mediaUrl = widget.section!.mediaUrl;
    }
  }

  String _generateSectionFileName(String type) {
    final lessonTitle = widget.lessonTitle.replaceAll(' ', '_').toLowerCase();
    final category = widget.category.toLowerCase();
    final sectionTitle = _titleController.text.trim().replaceAll(' ', '_').toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    if (type == 'audio') {
      return '${category}_${lessonTitle}_${sectionTitle}_section_audio_$timestamp';
    } else if (type == 'video') {
      return '${category}_${lessonTitle}_${sectionTitle}_section_video_$timestamp';
    }
    return '${category}_${lessonTitle}_${sectionTitle}_$type}_$timestamp';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.section != null ? 'Chỉnh Sửa Phần' : 'Thêm Phần'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Tiêu Đề Phần',
                hint: 'Nhập tiêu đề phần',
                prefixIcon: Icons.title,
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Loại Phần',
                  border: OutlineInputBorder(),
                ),
                items: _sectionTypes.asMap().entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.value,
                    child: Text(_sectionTypesVietnamese[entry.key]),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _contentController,
                label: 'Nội Dung',
                hint: 'Nhập nội dung phần',
                prefixIcon: Icons.edit,
                maxLines: 4,
              ),
              
              // Media upload for audio/video sections
              if (_selectedType == 'audio' || _selectedType == 'video') ...[
                const SizedBox(height: 24),
                MediaUploadWidget(
                  title: _selectedType == 'audio' ? 'Tệp Âm Thanh Cho Phần' : 'Tệp Video Cho Phần',
                  description: _selectedType == 'audio' 
                    ? 'Tải lên tệp âm thanh cho phần này'
                    : 'Tải lên tệp video cho phần này',
                  mediaType: _selectedType == 'audio' ? MediaType.audio : MediaType.video,
                  folder: _selectedType == 'audio' ? CloudinaryFolder.lessonAudio : CloudinaryFolder.lessonVideos,
                  maxSizeMB: _selectedType == 'audio' ? 20 : 100,
                  allowedExtensions: _selectedType == 'audio' 
                    ? ['mp3', 'wav', 'm4a', 'aac']
                    : ['mp4', 'mov', 'avi', 'mkv'],
                  customFileNamePrefix: _generateSectionFileName(_selectedType),
                  customIcon: Icon(
                    _selectedType == 'audio' ? Icons.audiotrack : Icons.videocam,
                    color: _selectedType == 'audio' ? Colors.blue : Colors.red,
                  ),
                  primaryColor: _selectedType == 'audio' ? Colors.blue : Colors.red,
                  onUploadComplete: (result) {
                    setState(() {
                      _mediaUrl = result.optimizedUrl;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_selectedType == 'audio' 
                          ? 'Âm thanh đã được tải lên thành công!'
                          : 'Video đã được tải lên thành công!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tải lên thất bại: $error'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vui lòng nhập tiêu đề phần'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            
            final section = LessonSection(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              type: _selectedType,
              mediaUrl: _mediaUrl,
              metadata: {},
            );
            widget.onSave(section);
            Navigator.of(context).pop();
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
} 
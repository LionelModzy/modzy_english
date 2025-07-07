import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/lesson_service.dart';
import '../../../models/lesson_model.dart';
import '../widgets/lesson_media_widget.dart';

class FirebaseLessonsTestScreen extends StatefulWidget {
  const FirebaseLessonsTestScreen({super.key});

  @override
  State<FirebaseLessonsTestScreen> createState() => _FirebaseLessonsTestScreenState();
}

class _FirebaseLessonsTestScreenState extends State<FirebaseLessonsTestScreen> {
  List<LessonModel> _lessons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final lessons = await LessonService.getAllLessons();
      
      setState(() {
        _lessons = lessons.where((lesson) => lesson.isActive).toList();
        _isLoading = false;
      });
      
      print('✅ Loaded ${_lessons.length} lessons from Firebase');
      for (var lesson in _lessons) {
        print('📚 Lesson: ${lesson.title}');
        print('  - Image: ${lesson.imageUrl ?? "None"}');
        print('  - Video: ${lesson.videoUrl ?? "None"}');
        print('  - Audio: ${lesson.audioUrl ?? "None"}');
        print('  - Sections: ${lesson.sections.length}');
        print('  - Category: ${lesson.category}');
        print('  - Tags: ${lesson.tags.join(", ")}');
      }
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading lessons: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Firebase Data Test',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLessons,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Đang tải dữ liệu từ Firebase...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Lỗi khi tải dữ liệu Firebase',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadLessons,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có bài học nào trong Firebase',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy tạo bài học đầu tiên từ Admin Panel',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLessons,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats header
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard('Tổng Bài Học', '${_lessons.length}', Icons.school, AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Có Media', '${_lessons.where((l) => l.hasImage || l.hasVideo || l.hasAudio).length}', Icons.perm_media, AppColors.secondary),
              ),
            ],
          ),
        ),
        
        // Lessons list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _lessons.length,
            itemBuilder: (context, index) {
              return _buildLessonCard(_lessons[index]);
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(LessonModel lesson) {
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
      child: Column(
        children: [
          // Media Section
          LessonMediaWidget(
            imageUrl: lesson.imageUrl,
            videoUrl: lesson.videoUrl,
            audioUrl: lesson.audioUrl,
            height: 160,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            onTap: () {
              print('🎯 Tapped lesson: ${lesson.title}');
            },
          ),
          
          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(lesson.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getVietnameseCategory(lesson.category),
                        style: TextStyle(
                          color: _getCategoryColor(lesson.category),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (lesson.isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Title
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  lesson.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Stats
                Row(
                  children: [
                    _buildMiniStat(Icons.schedule, lesson.formattedDuration),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.signal_cellular_alt, _getVietnameseDifficulty(lesson.difficultyLevelName)),
                    const SizedBox(width: 12),
                    _buildMiniStat(Icons.list, '${lesson.sections.length}'),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Media indicators
                if (lesson.hasImage || lesson.hasVideo || lesson.hasAudio)
                  Row(
                    children: [
                      if (lesson.hasImage) _buildMediaIndicator('📷', 'Ảnh'),
                      if (lesson.hasVideo) _buildMediaIndicator('🎥', 'Video'),
                      if (lesson.hasAudio) _buildMediaIndicator('🎵', 'Audio'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaIndicator(String emoji, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$emoji $text',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
} 
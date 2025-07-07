import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/lesson_model.dart';

class LessonPlayerScreen extends StatefulWidget {
  final LessonModel lesson;
  final LessonSection section;
  final int sectionIndex;
  
  const LessonPlayerScreen({
    super.key, 
    required this.lesson,
    required this.section,
    required this.sectionIndex,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isPlaying = false;
  bool _isLoading = false;
  double _progress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = const Duration(minutes: 5); // Mock duration
  
  @override
  void initState() {
    super.initState();
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
    
    // Mock loading
    _loadMedia();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Media player area
                  Expanded(
                    child: _buildMediaPlayer(),
                  ),
                  
                  // Controls area
                  _buildControlsArea(),
                ],
              ),
              
              // Top overlay with back button and info
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopOverlay(),
              ),
              
              // Loading overlay
              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 
        MediaQuery.of(context).padding.top + 10, 
        20, 
        20
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.section.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSectionTypeColor(widget.section.type).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getSectionTypeText(widget.section.type),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.sectionIndex + 1}/${widget.lesson.sections.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tùy chọn thêm')),
              );
            },
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPlayer() {
    if (widget.section.type.toLowerCase() == 'video') {
      return _buildVideoPlayer();
    } else if (widget.section.type.toLowerCase() == 'audio') {
      return _buildAudioPlayer();
    } else {
      return _buildTextContent();
    }
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCategoryColor(widget.lesson.category).withOpacity(0.3),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
            child: Icon(
              Icons.play_circle_fill_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          
          // Play/Pause button
          GestureDetector(
            onTap: () {
              setState(() => _isPlaying = !_isPlaying);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          
          // Progress indicator
          if (_isPlaying)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCategoryColor(widget.lesson.category),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        _formatDuration(_totalDuration),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getCategoryColor(widget.lesson.category).withOpacity(0.8),
            _getCategoryColor(widget.lesson.category),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio visualization
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing animation when playing
                if (_isPlaying)
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                
                Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Title and description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  widget.section.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.section.content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: _progress,
                    onChanged: (value) {
                      setState(() => _progress = value);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.6),
          ),
          
          const SizedBox(height: 30),
          
          Text(
            widget.section.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              widget.section.content,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous section
                IconButton(
                  onPressed: widget.sectionIndex > 0 ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phần trước')),
                    );
                  } : null,
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: widget.sectionIndex > 0 ? Colors.white : Colors.grey,
                    size: 32,
                  ),
                ),
                
                // Rewind
                IconButton(
                  onPressed: () {
                    setState(() {
                      _progress = (_progress - 0.1).clamp(0.0, 1.0);
                    });
                  },
                  icon: const Icon(
                    Icons.replay_10_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                
                // Play/Pause
                GestureDetector(
                  onTap: () {
                    setState(() => _isPlaying = !_isPlaying);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.lesson.category),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(widget.lesson.category).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                
                // Forward
                IconButton(
                  onPressed: () {
                    setState(() {
                      _progress = (_progress + 0.1).clamp(0.0, 1.0);
                    });
                  },
                  icon: const Icon(
                    Icons.forward_10_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                
                // Next section
                IconButton(
                  onPressed: widget.sectionIndex < widget.lesson.sections.length - 1 ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phần tiếp theo')),
                    );
                  } : null,
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: widget.sectionIndex < widget.lesson.sections.length - 1 ? Colors.white : Colors.grey,
                    size: 32,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Additional controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Speed control
                IconButton(
                  onPressed: () {
                    _showSpeedDialog();
                  },
                  icon: const Icon(
                    Icons.speed_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
                
                // Subtitle
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phụ đề')),
                    );
                  },
                  icon: const Icon(
                    Icons.closed_caption_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
                
                // Notes
                IconButton(
                  onPressed: () {
                    _showNotesDialog();
                  },
                  icon: const Icon(
                    Icons.note_add_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
                
                // Bookmark
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đánh dấu')),
                    );
                  },
                  icon: const Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCategoryColor(widget.lesson.category),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Đang tải nội dung...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Tốc Độ Phát',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (double speed in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
              ListTile(
                title: Text(
                  '${speed}x',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tốc độ: ${speed}x')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showNotesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Thêm Ghi Chú',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú của bạn...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _getCategoryColor(widget.lesson.category)),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu ghi chú')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCategoryColor(widget.lesson.category),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
} 
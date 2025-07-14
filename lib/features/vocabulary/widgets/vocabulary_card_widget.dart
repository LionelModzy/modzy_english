import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/vocab_model.dart';

class VocabularyCardWidget extends StatefulWidget {
  final VocabularyModel vocabulary;
  final VoidCallback? onTap;
  final VoidCallback? onAddToStudyList;
  final VoidCallback? onRemoveFromStudyList;
  final VoidCallback? onPractice;
  final bool isInStudyList;
  final bool showAudio;
  final bool showActions;
  
  const VocabularyCardWidget({
    super.key,
    required this.vocabulary,
    this.onTap,
    this.onAddToStudyList,
    this.onRemoveFromStudyList,
    this.onPractice,
    this.isInStudyList = false,
    this.showAudio = true,
    this.showActions = true,
  });

  @override
  State<VocabularyCardWidget> createState() => _VocabularyCardWidgetState();
}

class _VocabularyCardWidgetState extends State<VocabularyCardWidget> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (widget.vocabulary.hasAudio) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_audioPlayer == null || !widget.vocabulary.hasAudio) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play(UrlSource(widget.vocabulary.audioUrl!));
      }
    } catch (e) {
      print('Error playing vocabulary audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể phát âm thanh: ${widget.vocabulary.word}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCardTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  Color _getDifficultyColor() {
    switch (widget.vocabulary.difficultyLevel) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  Color _getCategoryColor() {
    switch (widget.vocabulary.category.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTap: _onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getCategoryColor().withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _getCategoryColor().withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header with word and audio button (audio moved outside)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Word only
                      Text(
                        widget.vocabulary.word,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(),
                        ),
                      ),
                      
                      if (widget.vocabulary.pronunciation.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.vocabulary.pronunciation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Audio button moved to outside corner
                if (widget.showAudio && widget.vocabulary.hasAudio)
                  _buildAudioButton(),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Meaning
            Text(
              widget.vocabulary.meaning,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Definition (limited to save space)
            if (widget.vocabulary.definition != null && widget.vocabulary.definition!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.vocabulary.definition!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            // Part of speech
            if (widget.vocabulary.partOfSpeech.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.vocabulary.vietnamesePartOfSpeech,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
            
            // Examples (limited to save space)
            if (widget.vocabulary.examples.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ví dụ:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• ${widget.vocabulary.examples.first}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            
            // Actions
            if (widget.showActions) ...[
              const SizedBox(height: 8),
              Column(
                children: [
                  // Category and difficulty indicators
                  Row(
                    children: [
                      // Category
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.vocabulary.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getCategoryColor(),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Difficulty badge (moved inside)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getDifficultyColor().withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.vocabulary.vietnameseDifficultyName,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _getDifficultyColor(),
                          ),
                        ),
                      ),
                      
                      if (widget.vocabulary.lessonCount > 0) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.book_outlined,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.vocabulary.lessonCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Practice button
                      if (widget.onPractice != null) 
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: widget.onPractice,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.accent.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.quiz,
                                      size: 12,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Luyện',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      if (widget.onPractice != null) const SizedBox(width: 8),
                      
                      // Study list button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: widget.isInStudyList 
                                ? widget.onRemoveFromStudyList 
                                : widget.onAddToStudyList,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.isInStudyList 
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: widget.isInStudyList 
                                      ? AppColors.success.withOpacity(0.3)
                                      : AppColors.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.isInStudyList 
                                        ? Icons.check_circle_outline 
                                        : Icons.add_circle_outline,
                                    size: 12,
                                    color: widget.isInStudyList 
                                        ? AppColors.success 
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.isInStudyList ? 'Đã thêm' : 'Học',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: widget.isInStudyList 
                                          ? AppColors.success 
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
        ),
    );
  }

  Widget _buildAudioButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _playAudio,
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
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                  size: 16,
                  color: Colors.blue,
                ),
        ),
      ),
    );
  }
} 
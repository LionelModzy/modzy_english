import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../services/firebase_storage_service.dart';

class AdvancedMediaUploadWidget extends StatefulWidget {
  final MediaType mediaType;
  final String? initialUrl;
  final Function(UploadResult result) onMediaUploaded;
  final String label;
  final bool isRequired;
  final MediaFolder folder;
  final int maxSizeMB;
  final List<String> allowedExtensions;

  const AdvancedMediaUploadWidget({
    super.key,
    required this.mediaType,
    this.initialUrl,
    required this.onMediaUploaded,
    required this.label,
    this.isRequired = false,
    required this.folder,
    this.maxSizeMB = 100,
    this.allowedExtensions = const [],
  });

  @override
  State<AdvancedMediaUploadWidget> createState() => _AdvancedMediaUploadWidgetState();
}

enum MediaType { image, video, audio }

class _AdvancedMediaUploadWidgetState extends State<AdvancedMediaUploadWidget>
    with TickerProviderStateMixin {
  String? _uploadedUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _selectedFilePath;
  int? _fileSizeBytes;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _uploadedUrl = widget.initialUrl;
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? file;

      switch (widget.mediaType) {
        case MediaType.image:
          file = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
          break;
        case MediaType.video:
          file = await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10),
          );
          break;
        case MediaType.audio:
          // For audio, you would use file_picker package
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio upload coming soon!')),
          );
          return;
      }

      if (file != null) {
        // Check file size
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);
        
        if (fileSizeMB > widget.maxSizeMB) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File size (${fileSizeMB.toStringAsFixed(1)}MB) exceeds limit of ${widget.maxSizeMB}MB'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Check file extension
        if (widget.allowedExtensions.isNotEmpty) {
          final extension = file.path.split('.').last.toLowerCase();
          if (!widget.allowedExtensions.contains(extension)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File type .$extension is not allowed. Allowed: ${widget.allowedExtensions.join(', ')}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
        }

        setState(() {
          _selectedFilePath = file!.path;
          _fileSizeBytes = fileSize;
          _isUploading = true;
          _uploadProgress = 0.0;
        });

        _progressAnimationController.forward();
        await _uploadToFirebaseStorage(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking media: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadToFirebaseStorage(XFile file) async {
    try {
      if (!kIsWeb) {
        File mediaFile = File(file.path);
        UploadResult result;
        
        switch (widget.mediaType) {
          case MediaType.image:
            result = await FirebaseStorageService.uploadImage(
              imageFile: mediaFile,
              folder: widget.folder,
              syncWithCloudinary: true,
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = progress;
                });
              },
            );
            break;
          case MediaType.video:
            result = await FirebaseStorageService.uploadVideo(
              videoFile: mediaFile,
              folder: widget.folder,
              syncWithCloudinary: true,
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = progress;
                });
              },
            );
            break;
          case MediaType.audio:
            result = await FirebaseStorageService.uploadAudio(
              audioFile: mediaFile,
              folder: widget.folder,
              syncWithCloudinary: true,
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = progress;
                });
              },
            );
            break;
        }

        setState(() => _isUploading = false);
        _progressAnimationController.reverse();
        
        if (result.success) {
          setState(() {
            _uploadedUrl = result.optimizedUrl ?? result.firebaseUrl;
          });
          widget.onMediaUploaded(result);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.mediaType.name.toUpperCase()} uploaded successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          throw Exception(result.error ?? 'Upload failed');
        }
      } else {
        // For web implementation
        final result = UploadResult(
          success: true,
          firebaseUrl: file.path,
          fileName: file.name,
        );
        
        setState(() {
          _uploadedUrl = file.path;
          _isUploading = false;
        });
        _progressAnimationController.reverse();
        widget.onMediaUploaded(result);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _progressAnimationController.reverse();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeMedia() {
    setState(() {
      _uploadedUrl = null;
      _selectedFilePath = null;
      _fileSizeBytes = null;
      _uploadProgress = 0.0;
    });
    widget.onMediaUploaded(UploadResult(success: false));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        if (_uploadedUrl != null)
          _buildMediaPreview()
        else
          _buildUploadArea(),

        if (_isUploading) ...[
          const SizedBox(height: 16),
          _buildProgressIndicator(),
        ],
      ],
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickMedia,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isUploading ? AppColors.border : AppColors.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
          color: _isUploading 
              ? AppColors.border.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isUploading 
                    ? AppColors.textSecondary.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getMediaIcon(),
                size: 32,
                color: _isUploading ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isUploading ? 'Uploading...' : 'Tap to upload ${widget.mediaType.name}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isUploading ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getFileTypeHint(),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (widget.maxSizeMB > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Max size: ${widget.maxSizeMB}MB',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.success, width: 2),
        borderRadius: BorderRadius.circular(16),
        color: AppColors.success.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getMediaIcon(),
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.mediaType.name.toUpperCase()} uploaded successfully',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (_fileSizeBytes != null) ...[
                  Text(
                    'Size: ${_formatFileSize(_fileSizeBytes!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  _uploadedUrl!.split('/').last,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removeMedia,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
            ),
            tooltip: 'Remove ${widget.mediaType.name}',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Uploading ${widget.mediaType.name}...',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            );
          },
        ),
        const SizedBox(height: 8),
        if (_fileSizeBytes != null) ...[
          Text(
            'File size: ${_formatFileSize(_fileSizeBytes!)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getMediaIcon() {
    switch (widget.mediaType) {
      case MediaType.image:
        return Icons.image_rounded;
      case MediaType.video:
        return Icons.video_library_rounded;
      case MediaType.audio:
        return Icons.audio_file_rounded;
    }
  }

  String _getFileTypeHint() {
    switch (widget.mediaType) {
      case MediaType.image:
        return widget.allowedExtensions.isNotEmpty 
            ? widget.allowedExtensions.join(', ').toUpperCase()
            : 'JPG, PNG, WebP';
      case MediaType.video:
        return widget.allowedExtensions.isNotEmpty 
            ? widget.allowedExtensions.join(', ').toUpperCase()
            : 'MP4, MOV, AVI';
      case MediaType.audio:
        return widget.allowedExtensions.isNotEmpty 
            ? widget.allowedExtensions.join(', ').toUpperCase()
            : 'MP3, WAV, AAC';
    }
  }
} 
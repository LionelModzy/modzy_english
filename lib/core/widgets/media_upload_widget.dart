import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../services/cloudinary_service.dart';
import '../../features/auth/data/auth_repository.dart';

enum MediaType { image, video, audio, any }

class MediaUploadWidget extends StatefulWidget {
  final String title;
  final String description;
  final MediaType mediaType;
  final CloudinaryFolder folder;
  final Function(CloudinaryUploadResult result) onUploadComplete;
  final Function(String error)? onError;
  final List<String>? allowedExtensions;
  final int maxSizeMB;
  final Widget? customIcon;
  final Color? primaryColor;
  final String? customFileNamePrefix; // For custom naming
  final String? currentImagePublicId; // Track current image for deletion

  const MediaUploadWidget({
    super.key,
    required this.title,
    required this.description,
    required this.folder,
    required this.onUploadComplete,
    this.mediaType = MediaType.image,
    this.onError,
    this.allowedExtensions,
    this.maxSizeMB = 50,
    this.customIcon,
    this.primaryColor,
    this.customFileNamePrefix,
    this.currentImagePublicId, // Add this parameter
  });

  @override
  State<MediaUploadWidget> createState() => _MediaUploadWidgetState();
}

class _MediaUploadWidgetState extends State<MediaUploadWidget> {
  XFile? _selectedFile;
  PlatformFile? _selectedAudioFile;
  Uint8List? _selectedImageBytes; // For storing image bytes temporarily
  bool _isUploading = false;
  bool _isSelecting = false; // Add lock to prevent multiple picker instances
  double _uploadProgress = 0.0;
  String? _uploadedUrl;
  String? _errorMessage;
  String? _previousImagePublicId; // Track previous image for deletion

  @override
  void initState() {
    super.initState();
    // Initialize with current image public ID if provided
    _previousImagePublicId = widget.currentImagePublicId;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? AppColors.primary;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _errorMessage != null ? AppColors.error : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.customIcon ?? Icon(
                  _getMediaIcon(),
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Upload Status
          if (_uploadedUrl != null) ...[
            _buildSuccessState(),
          ] else if (_isUploading) ...[
            _buildUploadingState(),
          ] else if (_selectedFile != null || _selectedAudioFile != null) ...[
            _buildSelectedState(),
          ] else ...[
            _buildInitialState(),
          ],
          
          // Error Message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Column(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
            ),
          ),
          child: InkWell(
            onTap: _isSelecting ? null : _selectFile,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn ${_getMediaTypeText()}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getAllowedFormatsText(),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedState() {
    final fileName = _selectedFile?.name ?? _selectedAudioFile?.name ?? '';
    final isAudio = _selectedAudioFile != null || widget.mediaType == MediaType.audio;
    
    return Column(
      children: [
        // Preview Container
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            children: [
              // Content Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: widget.mediaType == MediaType.image && _selectedImageBytes != null
                      ? Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                        )
                      : widget.mediaType == MediaType.image && !kIsWeb && _selectedFile != null
                          ? Image.file(
                              File(_selectedFile!.path),
                              fit: BoxFit.cover,
                            )
                          : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getMediaIcon(),
                                  size: 48,
                                  color: widget.primaryColor ?? AppColors.primary,
                    ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    fileName,
                      style: const TextStyle(
                                      fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                                ),
                                if (isAudio) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Tệp âm thanh',
                              style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
                              ),
                                    ),
                      ),
                    ],
                  ],
                            ),
                ),
              ),
              // Remove Button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFile = null;
                      _selectedAudioFile = null;
                      _selectedImageBytes = null;
                      _errorMessage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // File Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedAudioFile != null) ...[
                      Text(
                        _formatFileSize(_selectedAudioFile!.size),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ] else if (!kIsWeb && _selectedFile != null) ...[
                      FutureBuilder<int>(
                        future: File(_selectedFile!.path).length(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              _formatFileSize(snapshot.data!),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Upload Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _uploadFile,
            icon: const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
            label: const Text(
              'Tải Lên',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int sizeInBytes) {
    final sizeKB = sizeInBytes / 1024;
    if (sizeKB > 1024) {
      return '${(sizeKB / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${sizeKB.toStringAsFixed(1)} KB';
    }
  }

  Widget _buildUploadingState() {
    return Column(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đang tải lên...',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_uploadProgress > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${(_uploadProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 32,
                color: AppColors.success,
              ),
              const SizedBox(height: 8),
              Text(
                'Tải lên thành công!',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tệp đã được tải lên',
                style: TextStyle(
                  color: AppColors.success.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Change File Button
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedFile = null;
                _selectedAudioFile = null;
                _selectedImageBytes = null;
                _uploadedUrl = null;
                _errorMessage = null;
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thay đổi',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
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

  Future<void> _selectFile() async {
    if (_isSelecting) return; // Prevent multiple calls
    
    setState(() {
      _isSelecting = true;
      _errorMessage = null;
    });
    
    try {
      if (widget.mediaType == MediaType.audio) {
        // Use file picker for audio files
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: widget.allowedExtensions ?? ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          final isValid = await _validateAudioFile(file);
          if (isValid) {
      setState(() {
              _selectedAudioFile = file;
              _selectedFile = null;
        _errorMessage = null;
      });
          }
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      XFile? file;

      if (widget.mediaType == MediaType.image) {
        file = await picker.pickImage(source: ImageSource.gallery);
      } else if (widget.mediaType == MediaType.video) {
        file = await picker.pickVideo(source: ImageSource.gallery);
      } else if (widget.mediaType == MediaType.any) {
        // Show options for any type
        final result = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Chọn loại tệp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.image, color: Colors.green),
                  title: const Text('Hình ảnh'),
                  subtitle: const Text('JPG, PNG, WEBP'),
                  onTap: () => Navigator.pop(context, 'image'),
                ),
                ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.red),
                  title: const Text('Video'),
                  subtitle: const Text('MP4, MOV, AVI'),
                  onTap: () => Navigator.pop(context, 'video'),
                ),
                ListTile(
                  leading: const Icon(Icons.audiotrack, color: Colors.blue),
                  title: const Text('Âm thanh'),
                  subtitle: const Text('MP3, WAV, M4A'),
                  onTap: () => Navigator.pop(context, 'audio'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );

        if (result == 'image') {
          file = await picker.pickImage(source: ImageSource.gallery);
        } else if (result == 'video') {
          file = await picker.pickVideo(source: ImageSource.gallery);
        } else if (result == 'audio') {
          final audioResult = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
            allowMultiple: false,
          );

          if (audioResult != null && audioResult.files.isNotEmpty) {
            final audioFile = audioResult.files.first;
            final isValid = await _validateAudioFile(audioFile);
            if (isValid) {
              setState(() {
                _selectedAudioFile = audioFile;
                _selectedFile = null;
                _errorMessage = null;
              });
            }
          }
          return;
        }
      }

      if (file != null) {
        // Validate file
        final isValid = await _validateFile(file);
        if (isValid) {
          setState(() {
            _selectedFile = file;
            _selectedAudioFile = null;
            _errorMessage = null;
          });

          // Load image bytes for immediate preview
          if (widget.mediaType == MediaType.image) {
            final bytes = await file.readAsBytes();
            setState(() {
              _selectedImageBytes = bytes;
          });
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi chọn tệp: $e';
      });
    } finally {
      setState(() {
        _isSelecting = false;
      });
    }
  }

  Future<bool> _validateAudioFile(PlatformFile file) async {
    try {
      // Check file extension
      final extension = file.extension?.toLowerCase() ?? '';
      final allowedExts = widget.allowedExtensions ?? ['mp3', 'wav', 'm4a', 'aac', 'ogg'];
      
      if (!allowedExts.contains(extension)) {
        setState(() {
          _errorMessage = 'Định dạng tệp không hợp lệ. Cho phép: ${allowedExts.join(', ')}';
        });
        return false;
      }

      // Check file size
      final sizeMB = file.size / (1024 * 1024);
      if (sizeMB > widget.maxSizeMB) {
        setState(() {
          _errorMessage = 'Tệp quá lớn. Kích thước tối đa: ${widget.maxSizeMB}MB';
        });
        return false;
      }

      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi kiểm tra tệp: $e';
      });
      return false;
    }
  }

  Future<bool> _validateFile(XFile file) async {
    try {
      // Check file extension
      final extension = file.name.toLowerCase().split('.').last;
      final allowedExts = widget.allowedExtensions ?? _getDefaultExtensions();
      
      if (!allowedExts.contains(extension)) {
        setState(() {
          _errorMessage = 'Định dạng tệp không hợp lệ. Cho phép: ${allowedExts.join(', ')}';
        });
        return false;
      }

      // Check file size (only for mobile)
      if (!kIsWeb) {
        final file_dart = File(file.path);
        final sizeBytes = await file_dart.length();
        final sizeMB = sizeBytes / (1024 * 1024);
        
        if (sizeMB > widget.maxSizeMB) {
          setState(() {
            _errorMessage = 'Tệp quá lớn. Kích thước tối đa: ${widget.maxSizeMB}MB';
          });
          return false;
        }
      }

      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi kiểm tra tệp: $e';
      });
      return false;
    }
  }

  Future<String> _generateCustomFileName() async {
    try {
      // If custom prefix is provided, use it
      if (widget.customFileNamePrefix != null && widget.customFileNamePrefix!.isNotEmpty) {
        String extension;
        if (_selectedAudioFile != null) {
          extension = _selectedAudioFile!.extension ?? 'mp3';
        } else if (_selectedFile != null) {
          extension = _selectedFile!.name.toLowerCase().split('.').last;
        } else {
          extension = 'file';
        }
        return '${widget.customFileNamePrefix}.$extension';
      }
      
      // Fallback to user-based naming for backward compatibility
      final userData = await AuthRepository.getCurrentUserData();
      
      // Use displayName or fallback to "user"
      String username = userData?.displayName ?? "user";
      // Remove spaces and special characters from username
      username = username.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      
      // Get current date in yyyy-MM-dd format
      final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Get file extension
      String extension;
      if (_selectedAudioFile != null) {
        extension = _selectedAudioFile!.extension ?? 'mp3';
      } else if (_selectedFile != null) {
        extension = _selectedFile!.name.toLowerCase().split('.').last;
      } else {
        extension = 'file';
      }
      
      // Create filename: username_date_profile_image.extension
      return '${username}_${currentDate}_profile_image.$extension';
    } catch (e) {
      // Fallback to default naming if something goes wrong
      final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String extension;
      if (_selectedAudioFile != null) {
        extension = _selectedAudioFile!.extension ?? 'mp3';
      } else if (_selectedFile != null) {
        extension = _selectedFile!.name.toLowerCase().split('.').last;
      } else {
        extension = 'file';
      }
      return 'user_${currentDate}_profile_image.$extension';
    }
  }

  /// Delete previous image before uploading new one
  Future<void> _deletePreviousImage() async {
    if (_previousImagePublicId != null && _previousImagePublicId!.isNotEmpty) {
      try {
        if (kDebugMode) {
          print('Deleting previous image: $_previousImagePublicId');
        }
        
        final success = await CloudinaryService.deleteFile(
          publicId: _previousImagePublicId!,
          resourceType: widget.mediaType == MediaType.video ? 'video' : 'auto',
        );
        
        if (kDebugMode) {
          print('Previous image deletion ${success ? 'successful' : 'failed'}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting previous image: $e');
        }
        // Don't throw error here as it shouldn't stop the new upload
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null && _selectedAudioFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      // Delete previous image first (if exists)
      await _deletePreviousImage();
      
      // Generate custom filename
      final customFileName = await _generateCustomFileName();
      
      CloudinaryUploadResult result;

      if (_selectedAudioFile != null) {
        // Upload audio file
        if (!kIsWeb && _selectedAudioFile!.path != null) {
          result = await CloudinaryService.uploadAudio(
            audioFile: File(_selectedAudioFile!.path!),
            fileName: customFileName,
            folder: widget.folder,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
        } else if (_selectedAudioFile!.bytes != null) {
          result = await CloudinaryService.uploadAudio(
            audioBytes: _selectedAudioFile!.bytes,
            fileName: customFileName,
            folder: widget.folder,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
        } else {
          throw Exception('Audio file data not available');
        }
      } else if (widget.mediaType == MediaType.video || _selectedFile!.name.contains('.mp4')) {
        // Upload video
        if (kIsWeb) {
          final bytes = await _selectedFile!.readAsBytes();
          result = await CloudinaryService.uploadVideo(
            videoBytes: bytes,
            fileName: customFileName,
            folder: widget.folder,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
        } else {
          result = await CloudinaryService.uploadVideo(
            videoFile: File(_selectedFile!.path),
            fileName: customFileName,
            folder: widget.folder,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
        }
      } else {
        // Upload image
        if (kIsWeb) {
          result = await CloudinaryService.uploadImage(
            imageBytes: _selectedImageBytes,
            fileName: customFileName,
            folder: widget.folder,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
        } else {
          result = await CloudinaryService.uploadImage(
            imageFile: File(_selectedFile!.path),
            fileName: customFileName,
            folder: widget.folder,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
        }
      }

      setState(() {
        _isUploading = false;
      });

      if (result.success) {
        setState(() {
          _uploadedUrl = result.optimizedUrl;
          // Update previous image ID for future deletion
          _previousImagePublicId = result.publicId;
        });
        widget.onUploadComplete(result);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Tải lên thất bại';
        });
        if (widget.onError != null) {
          widget.onError!(result.error ?? 'Tải lên thất bại');
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Lỗi tải lên: $e';
      });
      if (widget.onError != null) {
        widget.onError!('Lỗi tải lên: $e');
      }
    }
  }

  IconData _getMediaIcon() {
    switch (widget.mediaType) {
      case MediaType.image:
        return Icons.image;
      case MediaType.video:
        return Icons.videocam;
      case MediaType.audio:
        return Icons.audiotrack;
      case MediaType.any:
        return Icons.attachment;
    }
  }

  String _getMediaTypeText() {
    switch (widget.mediaType) {
      case MediaType.image:
        return 'hình ảnh';
      case MediaType.video:
        return 'video';
      case MediaType.audio:
        return 'âm thanh';
      case MediaType.any:
        return 'tệp';
    }
  }

  List<String> _getDefaultExtensions() {
    switch (widget.mediaType) {
      case MediaType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      case MediaType.video:
        return ['mp4', 'mov', 'avi', 'mkv'];
      case MediaType.audio:
        return ['mp3', 'wav', 'm4a', 'aac', 'ogg'];
      case MediaType.any:
        return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'avi', 'mkv', 'mp3', 'wav', 'm4a', 'aac', 'ogg'];
    }
  }

  String _getAllowedFormatsText() {
    final extensions = widget.allowedExtensions ?? _getDefaultExtensions();
    final maxSize = 'Tối đa ${widget.maxSizeMB}MB';
    return '${extensions.join(', ').toUpperCase()} • $maxSize';
  }
} 
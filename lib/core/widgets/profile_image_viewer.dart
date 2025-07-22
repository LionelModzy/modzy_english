import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../services/cloudinary_service.dart';

class ProfileImageViewer extends StatefulWidget {
  final String? imageUrl;
  final Function(String imageUrl) onImageSelected;
  final double size;
  final bool showEditButton;
  final String? currentImagePublicId; // For deleting old image
  final String? userName; // For generating better file names

  const ProfileImageViewer({
    super.key,
    this.imageUrl,
    required this.onImageSelected,
    this.size = 100,
    this.showEditButton = true,
    this.currentImagePublicId,
    this.userName,
  });

  @override
  State<ProfileImageViewer> createState() => _ProfileImageViewerState();
}

class _ProfileImageViewerState extends State<ProfileImageViewer> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUploading = false;
  XFile? _selectedImage;
  Uint8List? _previewBytes;

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (widget.imageUrl != null) ...[
                ListTile(
                  leading: const Icon(Icons.visibility, color: AppColors.primary),
                  title: const Text('Xem ảnh'),
                  onTap: () {
                    Navigator.pop(context);
                    _showFullScreenImage();
                  },
                ),
                const Divider(),
              ],
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Chụp ảnh'),
                subtitle: kIsWeb ? const Text('Có thể bị hạn chế trên web') : null,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Ảnh đại diện'),
            actions: [
              if (widget.showEditButton)
                IconButton(
                  onPressed: _showImageOptions,
                  icon: const Icon(Icons.edit),
                ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      // Check if camera is available on web
      if (kIsWeb && source == ImageSource.camera) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chức năng camera trên web có thể bị hạn chế. Vui lòng thử chọn từ thư viện.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Store selected image and show preview
        setState(() {
          _selectedImage = image;
          _isLoading = false;
        });
        
        // Load preview bytes
        final bytes = await image.readAsBytes();
        setState(() {
          _previewBytes = bytes;
        });
        
        // Show preview dialog
        _showPreviewDialog();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi: $e';
        
        if (kIsWeb) {
          if (e.toString().contains('camera') || e.toString().contains('permission')) {
            errorMessage = 'Không thể truy cập camera. Vui lòng thử chọn ảnh từ thư viện.';
          } else if (e.toString().contains('network')) {
            errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xem trước ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_previewBytes != null)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _previewBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Bạn có muốn sử dụng ảnh này làm ảnh đại diện không?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearSelection();
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _uploadImage,
            child: const Text('Sử dụng'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    try {
      setState(() => _isUploading = true);
      Navigator.pop(context); // Close preview dialog

      // Delete old image if exists
      if (widget.currentImagePublicId != null && widget.currentImagePublicId!.isNotEmpty) {
        try {
          print('Deleting old image: ${widget.currentImagePublicId}');
          final deleteSuccess = await CloudinaryService.deleteFile(
            publicId: widget.currentImagePublicId!,
            resourceType: 'image',
          );
          if (deleteSuccess) {
            print('Old image deleted successfully');
          } else {
            print('Failed to delete old image');
          }
        } catch (e) {
          print('Error deleting old image: $e');
          // Continue with upload even if deletion fails
        }
      }

      // Generate better file name
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final userName = widget.userName?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'user';
      final fileName = '${userName}_${dateStr}_${timeStr}';

      // Upload new image
      CloudinaryUploadResult result;
      
      if (kIsWeb) {
        result = await CloudinaryService.uploadImage(
          imageBytes: _previewBytes!,
          folder: CloudinaryFolder.profileImages,
          fileName: '${fileName}.jpg',
          customPublicId: fileName,
        );
      } else {
        result = await CloudinaryService.uploadImage(
          imageFile: File(_selectedImage!.path),
          folder: CloudinaryFolder.profileImages,
          customPublicId: fileName,
        );
      }

      if (mounted && result.success && result.optimizedUrl != null) {
        widget.onImageSelected(result.optimizedUrl!);
        _clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ảnh đã được cập nhật thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload: ${result.error ?? 'Unknown error'}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedImage = null;
      _previewBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile Image
        GestureDetector(
          onTap: widget.imageUrl != null ? _showFullScreenImage : _showImageOptions,
          child: Container(
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _isLoading || _isUploading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : widget.imageUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: Colors.grey,
                      ),
          ),
        ),
        
        // Edit Button
        if (widget.showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageOptions,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 
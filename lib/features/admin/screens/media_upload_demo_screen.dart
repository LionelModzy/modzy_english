import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/media_upload_widget.dart';
import '../../../core/services/cloudinary_service.dart';

class MediaUploadDemoScreen extends StatefulWidget {
  const MediaUploadDemoScreen({super.key});

  @override
  State<MediaUploadDemoScreen> createState() => _MediaUploadDemoScreenState();
}

class _MediaUploadDemoScreenState extends State<MediaUploadDemoScreen> {
  final List<CloudinaryUploadResult> _uploadedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Media Upload Demo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Direct Cloudinary Upload',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload images and videos directly to Cloudinary with organized folder structure',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Profile Image Upload
            MediaUploadWidget(
              title: 'Profile Image',
              description: 'Upload your profile picture (optimized for 512x512)',
              mediaType: MediaType.image,
              folder: CloudinaryFolder.profileImages,
              maxSizeMB: 5,
              allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
              customIcon: Icon(
                Icons.account_circle,
                color: AppColors.primary,
                size: 24,
              ),
              onUploadComplete: (result) {
                setState(() {
                  _uploadedFiles.add(result);
                });
                _showSuccessMessage('Profile image uploaded successfully!');
              },
              onError: (error) {
                _showErrorMessage('Profile upload failed: $error');
              },
            ),
            
            const SizedBox(height: 24),
            
            // Lesson Content Upload
            MediaUploadWidget(
              title: 'Lesson Content',
              description: 'Upload images for lesson materials and presentations',
              mediaType: MediaType.image,
              folder: CloudinaryFolder.lessonImages,
              maxSizeMB: 20,
              allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
              customIcon: Icon(
                Icons.school,
                color: Colors.blue,
                size: 24,
              ),
              primaryColor: Colors.blue,
              onUploadComplete: (result) {
                setState(() {
                  _uploadedFiles.add(result);
                });
                _showSuccessMessage('Lesson content uploaded successfully!');
              },
              onError: (error) {
                _showErrorMessage('Lesson upload failed: $error');
              },
            ),
            
            const SizedBox(height: 24),
            
            // Video Upload
            MediaUploadWidget(
              title: 'Educational Video',
              description: 'Upload video content for lessons and tutorials',
              mediaType: MediaType.video,
              folder: CloudinaryFolder.lessonVideos,
              maxSizeMB: 100,
              allowedExtensions: ['mp4', 'mov', 'avi'],
              customIcon: Icon(
                Icons.videocam,
                color: Colors.red,
                size: 24,
              ),
              primaryColor: Colors.red,
              onUploadComplete: (result) {
                setState(() {
                  _uploadedFiles.add(result);
                });
                _showSuccessMessage('Video uploaded successfully!');
              },
              onError: (error) {
                _showErrorMessage('Video upload failed: $error');
              },
            ),
            
            const SizedBox(height: 24),
            
            // User Content Upload
            MediaUploadWidget(
              title: 'General Content',
              description: 'Upload any images or videos for user-generated content',
              mediaType: MediaType.any,
              folder: CloudinaryFolder.userContent,
              maxSizeMB: 50,
              customIcon: Icon(
                Icons.attachment,
                color: Colors.green,
                size: 24,
              ),
              primaryColor: Colors.green,
              onUploadComplete: (result) {
                setState(() {
                  _uploadedFiles.add(result);
                });
                _showSuccessMessage('Content uploaded successfully!');
              },
              onError: (error) {
                _showErrorMessage('Content upload failed: $error');
              },
            ),
            
            const SizedBox(height: 32),
            
            // Uploaded Files List
            if (_uploadedFiles.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Uploaded Files',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_uploadedFiles.length}',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._uploadedFiles.map((file) => _buildFileItem(file)),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(CloudinaryUploadResult file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              file.url?.contains('video') == true 
                  ? Icons.videocam 
                  : Icons.image,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.publicId ?? 'Unknown file',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Folder: ${file.folder ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showUrlDialog(file),
            icon: Icon(
              Icons.link,
              color: AppColors.primary,
              size: 20,
            ),
            tooltip: 'View URL',
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUrlDialog(CloudinaryUploadResult file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Public ID: ${file.publicId}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Folder: ${file.folder}'),
            const SizedBox(height: 8),
            const Text(
              'Cloudinary URL:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            SelectableText(
              file.optimizedUrl ?? 'No URL available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 
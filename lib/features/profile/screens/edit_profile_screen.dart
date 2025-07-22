import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/profile_image_viewer.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../models/user_model.dart';
import '../../auth/data/auth_repository.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? user;

  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _displayNameController.text = widget.user!.displayName;
      _emailController.text = widget.user!.email;
      _uploadedImageUrl = widget.user!.profileImageUrl;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Extract public ID from Cloudinary URL for deletion
  String? _extractPublicIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    try {
      if (kDebugMode) {
        print('Extracting public ID from URL: $url');
      }
      
      // Cloudinary URL format: https://res.cloudinary.com/[cloud]/image/upload/[transformations]/[folder]/[public_id].[extension]
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      if (kDebugMode) {
        print('Path segments: $pathSegments');
      }
      
      // Find the upload segment index
      int uploadIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'upload') {
          uploadIndex = i;
          break;
        }
      }
      
      if (uploadIndex != -1 && pathSegments.length > uploadIndex + 1) {
        // Get the part after upload, skipping transformations if any
        String pathAfterUpload = pathSegments.sublist(uploadIndex + 1).join('/');
        
        if (kDebugMode) {
          print('Path after upload: $pathAfterUpload');
        }
        
        // Remove file extension
        final lastDotIndex = pathAfterUpload.lastIndexOf('.');
        if (lastDotIndex != -1) {
          pathAfterUpload = pathAfterUpload.substring(0, lastDotIndex);
        }
        
        if (kDebugMode) {
          print('Path after removing extension: $pathAfterUpload');
        }
        
        // Handle transformations (e.g., w_300,h_300,c_fill)
        // If the path contains transformation parameters, we need to extract the actual public ID
        if (pathAfterUpload.contains('/')) {
          final parts = pathAfterUpload.split('/');
          if (kDebugMode) {
            print('Parts after splitting: $parts');
          }
          
          // Find the folder name (profile_images) and get everything after it
          for (int i = 0; i < parts.length; i++) {
            if (parts[i] == 'profile_images' && i + 1 < parts.length) {
              final publicId = parts.sublist(i + 1).join('/');
              if (kDebugMode) {
                print('Extracted public ID: $publicId');
              }
              return publicId;
            }
          }
          
          // If no profile_images folder found, return the last part
          final publicId = parts.last;
          if (kDebugMode) {
            print('Using last part as public ID: $publicId');
          }
          return publicId;
        }
        
        if (kDebugMode) {
          print('Final public ID: $pathAfterUpload');
        }
        return pathAfterUpload;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting public ID from URL: $e');
      }
    }
    
    return null;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthRepository.updateUserProfile(
        uid: widget.user!.uid,
        displayName: _displayNameController.text.trim(),
        profileImageUrl: _uploadedImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hồ sơ đã được cập nhật thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật hồ sơ: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa hồ sơ',
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Picture Section
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
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ảnh đại diện',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Chụp ảnh hoặc chọn từ thư viện',
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
                  const SizedBox(height: 20),
                  Center(
                    child: ProfileImageViewer(
                      imageUrl: _uploadedImageUrl,
                      size: 120,
                      showEditButton: true,
                      currentImagePublicId: _extractPublicIdFromUrl(_uploadedImageUrl),
                      userName: _displayNameController.text.isNotEmpty 
                          ? _displayNameController.text 
                          : widget.user?.displayName,
                      onImageSelected: (String imageUrl) {
                        setState(() {
                          _uploadedImageUrl = imageUrl;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),



            // Form Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin cá nhân',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Display Name Field
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        hintText: 'Nhập họ và tên của bạn',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.error),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.name,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ỹ\s]')),
                        LengthLimitingTextInputFormatter(50),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        if (value.trim().length < 2) {
                          return 'Họ và tên phải có ít nhất 2 ký tự';
                        }
                        if (value.trim().length > 50) {
                          return 'Họ và tên không được quá 50 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email Field (Read-only)
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ email',
                        hintText: 'Email của bạn',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        helperText: 'Email không thể thay đổi',
                        helperStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isLoading ? 'Đang cập nhật...' : 'Cập nhật hồ sơ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
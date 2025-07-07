import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/media_upload_widget.dart';
import '../../../core/utils/validators.dart';
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
      // Cloudinary URL format: https://res.cloudinary.com/[cloud]/image/upload/[transformations]/[folder]/[public_id].[extension]
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
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
        
        // Remove file extension
        final lastDotIndex = pathAfterUpload.lastIndexOf('.');
        if (lastDotIndex != -1) {
          pathAfterUpload = pathAfterUpload.substring(0, lastDotIndex);
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
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
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
          'Edit Profile',
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
            // Profile Picture Upload Section
            MediaUploadWidget(
              title: 'Profile Picture',
              description: 'Upload your profile image to personalize your account',
              mediaType: MediaType.image,
              folder: CloudinaryFolder.profileImages,
              maxSizeMB: 10,
              allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
              currentImagePublicId: _extractPublicIdFromUrl(_uploadedImageUrl), // Pass current image public ID
              customIcon: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              onUploadComplete: (result) {
                setState(() {
                  _uploadedImageUrl = result.optimizedUrl;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image uploaded successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upload failed: $error'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),

            // Current Profile Picture Preview
            if (_uploadedImageUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
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
                    Text(
                      'Current Profile Picture',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipOval(
                      child: Image.network(
                        _uploadedImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

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
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Display Name Field
                    CustomTextField(
                      controller: _displayNameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 20),

                    // Email Field (Read-only)
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'Your email address',
                      prefixIcon: Icons.email_outlined,
                      readOnly: true,
                      enabled: false,
                      helperText: 'Email cannot be changed',
                    ),
                    const SizedBox(height: 32),

                    // Update Button
                    CustomButton(
                      text: 'Update Profile',
                      onPressed: _isLoading ? null : _updateProfile,
                      isLoading: _isLoading,
                      icon: Icons.save_outlined,
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
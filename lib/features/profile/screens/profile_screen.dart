import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/profile_image_viewer.dart';
import '../../../core/services/preferences_service.dart';
import '../../../models/user_model.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/screens/login_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'learning_history_screen.dart';
import 'favorites_screen.dart';
import '../../../core/services/user_progress_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthRepository.getCurrentUserData();
      if (mounted) {
        setState(() {
          currentUser = user;
          isLoading = false;
        });
      }
      // Sync progress after loading user
      await UserProgressUtils.syncUserProgressWithStats();
      // Reload user data to get updated progress
      final updatedUser = await AuthRepository.getCurrentUserData();
      if (mounted) {
        setState(() {
          currentUser = updatedUser;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Extract public ID from Cloudinary URL for deletion
  String? _extractPublicIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    try {
      print('Extracting public ID from URL: $url');
      
      // Cloudinary URL format: https://res.cloudinary.com/[cloud]/image/upload/[transformations]/[folder]/[public_id].[extension]
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      print('Path segments: $pathSegments');
      
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
        
        print('Path after upload: $pathAfterUpload');
        
        // Remove file extension
        final lastDotIndex = pathAfterUpload.lastIndexOf('.');
        if (lastDotIndex != -1) {
          pathAfterUpload = pathAfterUpload.substring(0, lastDotIndex);
        }
        
        print('Path after removing extension: $pathAfterUpload');
        
        // Handle transformations (e.g., w_300,h_300,c_fill)
        // If the path contains transformation parameters, we need to extract the actual public ID
        if (pathAfterUpload.contains('/')) {
          final parts = pathAfterUpload.split('/');
          print('Parts after splitting: $parts');
          
          // Find the folder name (profile_images) and get everything after it
          for (int i = 0; i < parts.length; i++) {
            if (parts[i] == 'profile_images' && i + 1 < parts.length) {
              final publicId = parts.sublist(i + 1).join('/');
              print('Extracted public ID: $publicId');
              return publicId;
            }
          }
          
          // If no profile_images folder found, return the last part
          final publicId = parts.last;
          print('Using last part as public ID: $publicId');
          return publicId;
        }
        
        print('Final public ID: $pathAfterUpload');
        return pathAfterUpload;
      }
    } catch (e) {
      print('Error extracting public ID from URL: $e');
    }
    
    return null;
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          CustomButton(
            text: 'Sign Out',
            onPressed: () async {
              Navigator.of(context).pop();
              // Only clear credentials if remember me is not enabled
              final rememberMe = await PreferencesService.getRememberMe();
              if (!rememberMe) {
                await PreferencesService.clearCredentials();
              }
              await AuthRepository.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            width: 120,
            height: 40,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Avatar
                  ProfileImageViewer(
                    imageUrl: currentUser?.profileImageUrl,
                    size: 100,
                    showEditButton: true,
                    currentImagePublicId: _extractPublicIdFromUrl(currentUser?.profileImageUrl),
                    userName: currentUser?.displayName,
                    onImageSelected: (String imageUrl) async {
                      try {
                        await AuthRepository.updateUserProfile(
                          uid: currentUser!.uid,
                          displayName: currentUser!.displayName,
                          profileImageUrl: imageUrl,
                        );
                        // Reload user data
                        _loadUserData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi cập nhật ảnh: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          currentUser?.isAdmin == true 
                              ? Icons.admin_panel_settings_rounded 
                              : Icons.school_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentUser?.isAdmin == true ? 'Administrator' : currentUser?.levelName ?? 'Beginner',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.book_rounded,
                    title: 'Lessons',
                    value: '${currentUser?.totalLessonsCompleted ?? 0}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.language_rounded,
                    title: 'Vocabulary',
                    value: '${currentUser?.totalVocabularyLearned ?? 0}',
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Level',
                    value: '${currentUser?.currentLevel ?? 1}',
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.percent_rounded,
                    title: 'Progress',
                    value: '${(currentUser?.progressPercentage ?? 0.0).toInt()}%',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action Cards
            _buildActionCard(
              icon: Icons.edit_rounded,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: currentUser),
                  ),
                ).then((_) => _loadUserData());
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.history_rounded,
              title: 'Learning History',
              subtitle: 'View your progress and achievements',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LearningHistoryScreen(user: currentUser),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.favorite_rounded,
              title: 'Favorites',
              subtitle: 'Your saved lessons and vocabulary',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FavoritesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.help_rounded,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () {
                // TODO: Navigate to help
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support - Coming Soon!')),
                );
              },
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            CustomButton(
              text: 'Sign Out',
              onPressed: _signOut,
              icon: Icons.logout_rounded,
              color: AppColors.error,
              isOutlined: true,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 
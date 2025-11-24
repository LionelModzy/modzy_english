import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/preferences_service.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'system';
  String _selectedLanguage = 'en';
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _autoBackup = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await PreferencesService.getThemeMode();
    final language = await PreferencesService.getLanguage();
    
    setState(() {
      _selectedTheme = theme;
      _selectedLanguage = language;
    });
  }

  Future<void> _saveTheme(String theme) async {
    await PreferencesService.setThemeMode(theme);
    setState(() {
      _selectedTheme = theme;
    });
  }

  Future<void> _saveLanguage(String language) async {
    await PreferencesService.setLanguage(language);
    setState(() {
      _selectedLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
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
            // Appearance Section
            _buildSectionCard(
              title: 'Appearance',
              icon: Icons.palette_rounded,
              children: [
                _buildDropdownTile(
                  icon: Icons.brightness_6_rounded,
                  title: 'Theme',
                  subtitle: 'Choose your preferred theme',
                  value: _selectedTheme,
                  items: const [
                    {'value': 'light', 'label': 'Light'},
                    {'value': 'dark', 'label': 'Dark'},
                    {'value': 'system', 'label': 'System'},
                  ],
                  onChanged: _saveTheme,
                ),
                _buildDropdownTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'Select your language',
                  value: _selectedLanguage,
                  items: const [
                    {'value': 'en', 'label': 'English'},
                    {'value': 'es', 'label': 'Español'},
                    {'value': 'fr', 'label': 'Français'},
                    {'value': 'de', 'label': 'Deutsch'},
                    {'value': 'zh', 'label': '中文'},
                  ],
                  onChanged: _saveLanguage,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notifications Section
            _buildSectionCard(
              title: 'Notifications',
              icon: Icons.notifications_rounded,
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Receive learning reminders',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.volume_up_rounded,
                  title: 'Sound Effects',
                  subtitle: 'Play sounds for interactions',
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Data & Privacy Section
            _buildSectionCard(
              title: 'Data & Privacy',
              icon: Icons.security_rounded,
              children: [
                _buildSwitchTile(
                  icon: Icons.backup_rounded,
                  title: 'Auto Backup',
                  subtitle: 'Automatically backup your progress',
                  value: _autoBackup,
                  onChanged: (value) {
                    setState(() {
                      _autoBackup = value;
                    });
                  },
                ),
                _buildActionTile(
                  icon: Icons.download_rounded,
                  title: 'Download Data',
                  subtitle: 'Export your learning data',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data export - Coming Soon!')),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  isDestructive: true,
                  onTap: () {
                    _showDeleteAccountDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // About Section
            _buildSectionCard(
              title: 'About',
              icon: Icons.info_rounded,
              children: [
                _buildActionTile(
                  icon: Icons.help_rounded,
                  title: 'Help & Support',
                  subtitle: 'Get help with the app',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support - Coming Soon!')),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.article_rounded,
                  title: 'Terms of Service',
                  subtitle: 'Read our terms and conditions',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of Service - Coming Soon!')),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Privacy Policy',
                  subtitle: 'Learn about our privacy practices',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Policy - Coming Soon!')),
                    );
                  },
                ),
                _buildInfoTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0 (Build 1)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(item['label']!),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isDestructive ? AppColors.error : AppColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: isDestructive ? AppColors.error : AppColors.primary,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: AppColors.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
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
            text: 'Delete',
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            width: 100,
            height: 40,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      // Show final confirmation dialog
      final bool? shouldDelete = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppColors.error),
              SizedBox(width: 8),
              Text('Final Confirmation'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action is irreversible!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              SizedBox(height: 8),
              Text('Are you absolutely sure you want to delete your account?'),
              SizedBox(height: 16),
              Text(
                'All your data will be permanently deleted:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Learning progress and history'),
              Text('• Favorite lessons and vocabulary'),
              Text('• Quiz results and achievements'),
              Text('• Profile information'),
              Text('• Account settings'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('DELETE ACCOUNT'),
            ),
          ],
        ),
      );

      if (shouldDelete == true && mounted) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting account...'),
              ],
            ),
          ),
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userId = user.uid;

          // Delete user data from Firestore
          await _deleteUserData(userId);

          // Delete Firebase Auth account
          await user.delete();

          if (mounted) {
            // Close loading dialog
            Navigator.of(context).pop();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );

            // Navigate to sign-in screen and clear navigation stack
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if it's open
        Navigator.of(context).pop();

        String errorMessage = 'Failed to delete account';
        
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'requires-recent-login':
              errorMessage = 'Please sign in again before deleting your account for security reasons.';
              break;
            case 'user-not-found':
              errorMessage = 'User account not found.';
              break;
            default:
              errorMessage = 'Authentication error: ${e.message}';
          }
        }

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: AppColors.error),
                SizedBox(width: 8),
                Text('Deletion Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                if (e is FirebaseAuthException && e.code == 'requires-recent-login') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: AppColors.info, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sign out and sign in again, then try deleting your account.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              if (e is FirebaseAuthException && e.code == 'requires-recent-login')
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _signOutUser();
                  },
                  child: const Text('Sign Out'),
                ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteUserData(String userId) async {
    final firestore = FirebaseFirestore.instance;
    
    try {
      // Delete user document and subcollections
      final batch = firestore.batch();
      
      // Delete main user document
      batch.delete(firestore.collection('users').doc(userId));
      
      // Delete subcollections (Firebase doesn't auto-delete subcollections)
      final subcollections = [
        'lesson_progress',
        'quiz_results',
        'vocabulary_progress',
        'vocabulary_mastery',
        'general_progress',
        'lesson_media_progress',
        'favorites',
        'notes',
      ];
      
      for (String subcollection in subcollections) {
        final docs = await firestore
            .collection('users')
            .doc(userId)
            .collection(subcollection)
            .get();
        
        for (var doc in docs.docs) {
          batch.delete(doc.reference);
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error deleting user data: $e');
      // Continue with account deletion even if some data deletion fails
    }
  }

  Future<void> _signOutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
} 
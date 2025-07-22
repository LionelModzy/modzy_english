import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/analytics_service.dart';
import '../../../models/user_model.dart';
import '../../auth/data/auth_repository.dart';
import 'lesson_management_screen.dart';
import 'media_upload_demo_screen.dart';
import 'quiz_management_screen.dart';
import 'vocabulary_management_screen.dart';
import 'user_management_screen.dart';
import 'analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  UserModel? currentUser;
  bool isLoading = true;
  Map<String, dynamic> _platformStats = {};
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPlatformStatistics();
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
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPlatformStatistics() async {
    try {
      final stats = await AnalyticsService.getPlatformStatistics();
      if (mounted) {
        setState(() {
          _platformStats = stats;
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bảng điều khiển Quản trị'),
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check if user is admin
    if (currentUser?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Truy cập bị từ chối'),
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 64,
                color: AppColors.error,
              ),
              SizedBox(height: 16),
              Text(
                'Truy cập bị từ chối',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Bạn không có quyền truy cập khu vực này.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      appBar: AppBar(
        title: const Text(
          'Bảng điều khiển Quản trị',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPlatformStatistics();
            },
            tooltip: 'Làm mới thống kê',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Quản trị',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.adminGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.adminPrimary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào mừng, ${currentUser?.displayName ?? 'Quản trị viên'}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Quản lý nền tảng học tiếng Anh của bạn',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Statistics Cards
              Text(
                'Thống kê Nền tảng',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _statsLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStatisticsGrid(),
              const SizedBox(height: 32),

              // Management Actions
              Text(
                'Hành động Quản lý',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 1,
                mainAxisSpacing: 8, // Further reduced spacing
                childAspectRatio: 6.0, // Increased aspect ratio for more space
                children: [
                  _buildActionCard(
                    icon: Icons.people_rounded,
                    title: 'Quản lý Người dùng',
                    subtitle: 'Xem, chỉnh sửa và quản lý tài khoản người dùng',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UserManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.library_books_rounded,
                    title: 'Quản lý Bài học',
                    subtitle: 'Tạo, chỉnh sửa bài học',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LessonManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.book_rounded,
                    title: 'Quản lý Từ vựng',
                    subtitle: 'Quản lý từ vựng với phát âm bằng giọng nói',
                    color: const Color(0xFF06B6D4),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const VocabularyManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.quiz_rounded,
                    title: 'Quản lý Quiz',
                    subtitle: 'Tạo và quản lý bài kiểm tra',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QuizManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.video_library_rounded,
                    title: 'Tải lên Media',
                    subtitle: 'Demo Firebase Storage + Cloudinary',
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MediaUploadDemoScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.analytics_rounded,
                    title: 'Phân tích & Thống kê',
                    subtitle: 'Xem thống kê nền tảng',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.settings_rounded,
                    title: 'Cài đặt Hệ thống',
                    subtitle: 'Cấu hình ứng dụng',
                    color: AppColors.adminPrimary,
                    onTap: () {
                      _showComingSoonDialog('Cài đặt Hệ thống');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final users = _platformStats['users'] as Map<String, dynamic>? ?? {};
    final lessons = _platformStats['lessons'] as Map<String, dynamic>? ?? {};
    final quizzes = _platformStats['quizzes'] as Map<String, dynamic>? ?? {};
    final vocabulary = _platformStats['vocabulary'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8, // Reduced from 12
      crossAxisSpacing: 8, // Reduced from 12
      childAspectRatio: 1.8, // Increased from 1.6 to give even more space
      children: [
        _buildStatCard(
          icon: Icons.people_rounded,
          title: 'Tổng Người dùng',
          value: '${users['total'] ?? 0}',
          color: AppColors.primary,
          subtitle: '+${users['newThisMonth'] ?? 0} tháng này',
        ),
        _buildStatCard(
          icon: Icons.verified_user_rounded,
          title: 'Đang hoạt động',
          value: '${users['active'] ?? 0}',
          color: AppColors.success,
          subtitle: '${_calculateActivePercentage(users)}% tổng số',
        ),
        _buildStatCard(
          icon: Icons.book_rounded,
          title: 'Bài học',
          value: '${lessons['total'] ?? 0}',
          color: AppColors.secondary,
          subtitle: '${lessons['totalCompletions'] ?? 0} lượt hoàn thành',
        ),
        _buildStatCard(
          icon: Icons.quiz_rounded,
          title: 'Quiz',
          value: '${quizzes['total'] ?? 0}',
          color: const Color(0xFF8B5CF6),
          subtitle: 'Tỉ lệ đạt: ${(quizzes['passRate'] ?? 0.0).toStringAsFixed(1)}%',
        ),
        _buildStatCard(
          icon: Icons.library_books_rounded,
          title: 'Từ vựng',
          value: '${vocabulary['total'] ?? 0}',
          color: AppColors.accent,
          subtitle: '+${vocabulary['newThisMonth'] ?? 0} tháng này',
        ),
        _buildStatCard(
          icon: Icons.trending_up_rounded,
          title: 'Tiến độ TB',
          value: '${(users['averageProgress'] ?? 0.0).toStringAsFixed(1)}%',
          color: AppColors.warning,
          subtitle: 'Của tất cả người dùng',
        ),
      ],
    );
  }

  String _calculateActivePercentage(Map<String, dynamic> users) {
    final total = users['total'] ?? 0;
    final active = users['active'] ?? 0;
    if (total == 0) return '0';
    return ((active / total) * 100).toStringAsFixed(0);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced from 10
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduced from 16
        border: Border.all(color: color.withOpacity(0.2), width: 1), // Reduced border width
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06), // Reduced opacity
            blurRadius: 6, // Reduced from 8
            offset: const Offset(0, 2), // Reduced from 4
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible( // Added Flexible wrapper
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4), // Reduced from 5
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4), // Reduced from 6
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 12, // Reduced from 14
                  ),
                ),
                const SizedBox(width: 4), // Reduced from 6
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12, // Reduced from 14
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2), // Reduced from 3
          Flexible( // Added Flexible wrapper
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9, // Reduced from 10
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 1), // Keep at 1
          Flexible( // Added Flexible wrapper
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 7, // Reduced from 8
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10), // Further reduced padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10), // Reduced from 12
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 6, // Reduced from 8
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reduced from 8
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // Reduced from 8
              ),
              child: Icon(
                icon,
                color: color,
                size: 16, // Reduced from 18
              ),
            ),
            const SizedBox(width: 8), // Reduced from 10
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13, // Reduced from 14
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Flexible(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10, // Reduced from 11
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary,
              size: 12, // Reduced from 14
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.construction_rounded,
                color: AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Sắp ra mắt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            '$feature hiện đang được phát triển. Tính năng này sẽ có sẵn trong bản cập nhật tương lai.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                'Đồng ý',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
} 
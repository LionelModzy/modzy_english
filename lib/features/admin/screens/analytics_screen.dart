import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _platformStats = {};
  Map<String, dynamic> _engagementStats = {};
  bool _isLoading = true;
  String _selectedTimeRange = '30 ngày';

  final List<String> _timeRangeOptions = ['7 ngày', '30 ngày', '90 ngày', '1 năm'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AnalyticsService.getPlatformStatistics(),
        AnalyticsService.getEngagementMetrics(),
      ]);

      setState(() {
        _platformStats = results[0];
        _engagementStats = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu phân tích: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Phân tích & Thống kê',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.people), text: 'Người dùng'),
            Tab(icon: Icon(Icons.trending_up), text: 'Tăng trưởng'),
            Tab(icon: Icon(Icons.insights), text: 'Tương tác'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.access_time),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
              _loadAnalytics(); // Reload data for new time range
            },
            itemBuilder: (context) => _timeRangeOptions.map((option) {
              return PopupMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildGrowthTab(),
                _buildEngagementTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final users = _platformStats['users'] as Map<String, dynamic>? ?? {};
    final lessons = _platformStats['lessons'] as Map<String, dynamic>? ?? {};
    final quizzes = _platformStats['quizzes'] as Map<String, dynamic>? ?? {};
    final vocabulary = _platformStats['vocabulary'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with time range
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tổng quan nền tảng - $_selectedTimeRange',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Key metrics grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              double cardWidth = (constraints.maxWidth - 24 - (crossAxisCount - 1) * 12) / crossAxisCount;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                children: [
                  _buildMetricCard(
                    title: 'Tổng người dùng',
                    value: '${users['total'] ?? 0}',
                    subtitle: '+${users['newThisMonth'] ?? 0} tháng này',
                    icon: Icons.people_rounded,
                    color: AppColors.primary,
                    trend: _calculateTrend(users['newThisMonth'] ?? 0, users['total'] ?? 1),
                  ),
                  _buildMetricCard(
                    title: 'Người dùng hoạt động',
                    value: '${users['active'] ?? 0}',
                    subtitle: '${_calculatePercentage(users['active'] ?? 0, users['total'] ?? 1).toStringAsFixed(1)}% tổng số',
                    icon: Icons.verified_user_rounded,
                    color: AppColors.success,
                    trend: 0.0,
                  ),
                  _buildMetricCard(
                    title: 'Tổng bài học',
                    value: '${lessons['total'] ?? 0}',
                    subtitle: '+${lessons['newThisMonth'] ?? 0} tháng này',
                    icon: Icons.book_rounded,
                    color: AppColors.secondary,
                    trend: _calculateTrend(lessons['newThisMonth'] ?? 0, lessons['total'] ?? 1),
                  ),
                  _buildMetricCard(
                    title: 'Lượt hoàn thành',
                    value: '${lessons['totalCompletions'] ?? 0}',
                    subtitle: '${lessons['recentCompletions'] ?? 0} gần đây',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.accent,
                    trend: 0.0,
                  ),
                  _buildMetricCard(
                    title: 'Tổng Quiz',
                    value: '${quizzes['total'] ?? 0}',
                    subtitle: 'Tỉ lệ đạt: ${(quizzes['passRate'] ?? 0.0).toStringAsFixed(1)}%',
                    icon: Icons.quiz_rounded,
                    color: AppColors.warning,
                    trend: 0.0,
                  ),
                  _buildMetricCard(
                    title: 'Lượt thi',
                    value: '${quizzes['totalAttempts'] ?? 0}',
                    subtitle: 'Điểm TB: ${(quizzes['averageScore'] ?? 0.0).toStringAsFixed(1)}%',
                    icon: Icons.assignment_turned_in_rounded,
                    color: Colors.purple,
                    trend: 0.0,
                  ),
                  _buildMetricCard(
                    title: 'Từ vựng',
                    value: '${vocabulary['total'] ?? 0}',
                    subtitle: '+${vocabulary['newThisMonth'] ?? 0} tháng này',
                    icon: Icons.library_books_rounded,
                    color: Colors.teal,
                    trend: _calculateTrend(vocabulary['newThisMonth'] ?? 0, vocabulary['total'] ?? 1),
                  ),
                  _buildMetricCard(
                    title: 'Tiến độ TB',
                    value: '${(users['averageProgress'] ?? 0.0).toStringAsFixed(1)}%',
                    subtitle: 'Của tất cả người dùng',
                    icon: Icons.trending_up_rounded,
                    color: Colors.orange,
                    trend: 0.0,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Platform health section
          _buildHealthSection(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final users = _platformStats['users'] as Map<String, dynamic>? ?? {};
    final levelDistribution = users['levelDistribution'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân tích Người dùng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // User stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12, // Reduced from 16
            crossAxisSpacing: 12, // Reduced from 16
            childAspectRatio: 2.2, // Increased from 2 to give more space
            children: [
              _buildUserStatCard('Tổng số', '${users['total'] ?? 0}', Icons.people, AppColors.primary),
              _buildUserStatCard('Hoạt động', '${users['active'] ?? 0}', Icons.verified_user, AppColors.success),
              _buildUserStatCard('Quản trị', '${users['admins'] ?? 0}', Icons.admin_panel_settings, AppColors.warning),
              _buildUserStatCard('Mới tuần này', '${users['newThisWeek'] ?? 0}', Icons.person_add, AppColors.accent),
            ],
          ),

          const SizedBox(height: 24),

          // Level distribution
          _buildLevelDistributionSection(levelDistribution),
        ],
      ),
    );
  }

  Widget _buildGrowthTab() {
    final growth = _platformStats['growth'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân tích Tăng trưởng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Growth metrics
          Row(
            children: [
              Expanded(
                child: _buildGrowthCard(
                  'Tăng trưởng tuần',
                  '${(growth['weeklyGrowthRate'] ?? 0.0).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppColors.success,
                  growth['weeklyGrowthRate'] ?? 0.0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGrowthCard(
                  'Tăng trưởng tháng',
                  '${(growth['monthlyGrowthRate'] ?? 0.0).toStringAsFixed(1)}%',
                  Icons.show_chart,
                  AppColors.primary,
                  growth['monthlyGrowthRate'] ?? 0.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Growth comparison
          _buildGrowthComparisonSection(growth),
        ],
      ),
    );
  }

  Widget _buildEngagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân tích Tương tác',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Engagement metrics
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12, // Reduced from 16
            crossAxisSpacing: 12, // Reduced from 16
            childAspectRatio: 1.8, // Increased from 1.5 to give more space
            children: [
              _buildEngagementCard(
                'Người dùng hoạt động hàng ngày',
                '${_engagementStats['dailyActiveUsers'] ?? 0}',
                Icons.today,
                AppColors.primary,
              ),
              _buildEngagementCard(
                'Thời gian phiên TB',
                '${(_engagementStats['averageSessionDuration'] ?? 0.0).toStringAsFixed(1)} phút',
                Icons.access_time,
                AppColors.accent,
              ),
              _buildEngagementCard(
                'Tỉ lệ giữ chân',
                '${(_engagementStats['retentionRate'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.psychology,
                AppColors.success,
              ),
              _buildEngagementCard(
                'Người dùng quay lại',
                '${_engagementStats['retainedUsers'] ?? 0}',
                Icons.replay,
                AppColors.warning,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Engagement tips
          _buildEngagementTipsSection(),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Flexible( // Added Flexible wrapper
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced from 8
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6), // Reduced from 8
                  ),
                  child: Icon(icon, color: color, size: 16), // Reduced from 20
                ),
                const Spacer(),
                if (trend != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced padding
                    decoration: BoxDecoration(
                      color: trend > 0 ? AppColors.success : AppColors.error,
                      borderRadius: BorderRadius.circular(8), // Reduced from 10
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 10, // Reduced from 12
                          color: Colors.white,
                        ),
                        Text(
                          '${trend.abs().toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 8, // Reduced from 10
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6), // Reduced from 8
          Flexible( // Added Flexible wrapper
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20, // Reduced from 24
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Flexible( // Added Flexible wrapper
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11, // Reduced from 12
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduced from 4
          Flexible( // Added Flexible wrapper
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9, // Reduced from 10
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

  Widget _buildUserStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
            child: Icon(icon, color: color, size: 20), // Reduced from 24
          ),
          const SizedBox(width: 10), // Reduced from 12
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Added to prevent overflow
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18, // Reduced from 20
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11, // Reduced from 12
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthCard(String title, String value, IconData icon, Color color, double rate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: rate >= 0 ? AppColors.success : AppColors.error,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Icon(icon, color: color, size: 24), // Reduced from 28
          const SizedBox(height: 6), // Reduced from 8
          Flexible( // Added Flexible wrapper
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18, // Reduced from 20
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2), // Added small spacing
          Flexible( // Added Flexible wrapper
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10, // Reduced from 11
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Allow 2 lines for long text
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSection() {
    final users = _platformStats['users'] as Map<String, dynamic>? ?? {};
    final lessons = _platformStats['lessons'] as Map<String, dynamic>? ?? {};
    final quizzes = _platformStats['quizzes'] as Map<String, dynamic>? ?? {};

    final userHealthScore = _calculateHealthScore(users);
    final contentHealthScore = _calculateContentHealthScore(lessons, quizzes);
    final overallHealth = (userHealthScore + contentHealthScore) / 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sức khỏe Nền tảng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHealthIndicator('Tổng thể', overallHealth),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHealthIndicator('Người dùng', userHealthScore),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHealthIndicator('Nội dung', contentHealthScore),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String label, double score) {
    Color color;
    String status;
    
    if (score >= 80) {
      color = AppColors.success;
      status = 'Tốt';
    } else if (score >= 60) {
      color = AppColors.warning;
      status = 'Khá';
    } else {
      color = AppColors.error;
      status = 'Cần cải thiện';
    }

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${score.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelDistributionSection(Map<String, dynamic> levelDistribution) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bố Cấp độ Người dùng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...levelDistribution.entries.map((entry) {
            final level = int.tryParse(entry.key.toString()) ?? 1;
            final count = entry.value as int;
            final levelName = _getLevelName(level);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getLevelColor(level),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          levelName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$count người dùng',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGrowthComparisonSection(Map<String, dynamic> growth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'So sánh Giai đoạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildComparisonRow('Tuần này', '${growth['usersThisWeek'] ?? 0}', 'người dùng mới'),
          _buildComparisonRow('Tuần trước', '${growth['usersLastWeek'] ?? 0}', 'người dùng mới'),
          const Divider(),
          _buildComparisonRow('Tháng này', '${growth['usersThisMonth'] ?? 0}', 'người dùng mới'),
          _buildComparisonRow('Tháng trước', '${growth['usersLastMonth'] ?? 0}', 'người dùng mới'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String period, String value, String metric) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            period,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '$value $metric',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý Cải thiện Tương tác',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTipItem('📚', 'Thêm nội dung tương tác mới để giữ chân người dùng'),
          _buildTipItem('🎯', 'Tạo thử thách hàng ngày để tăng sự tham gia'),
          _buildTipItem('🏆', 'Xây dựng hệ thống phần thưởng cho người học tích cực'),
          _buildTipItem('📊', 'Theo dõi tiến độ cá nhân để động viên người dùng'),
          _buildTipItem('👥', 'Khuyến khích tương tác xã hội giữa người học'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _calculateTrend(int current, int total) {
    if (total <= 0) return 0.0;
    return (current / total) * 100;
  }

  double _calculatePercentage(int part, int total) {
    if (total <= 0) return 0.0;
    return (part / total) * 100;
  }

  double _calculateHealthScore(Map<String, dynamic> users) {
    final total = users['total'] ?? 0;
    final active = users['active'] ?? 0;
    final newThisMonth = users['newThisMonth'] ?? 0;
    
    if (total == 0) return 0.0;
    
    final activeRate = (active / total) * 100;
    final growthRate = (newThisMonth / total) * 100;
    
    return (activeRate * 0.7 + growthRate * 0.3).clamp(0.0, 100.0);
  }

  double _calculateContentHealthScore(Map<String, dynamic> lessons, Map<String, dynamic> quizzes) {
    final totalLessons = lessons['total'] ?? 0;
    final activeLessons = lessons['active'] ?? 0;
    final totalQuizzes = quizzes['total'] ?? 0;
    final activeQuizzes = quizzes['active'] ?? 0;
    
    if (totalLessons == 0 && totalQuizzes == 0) return 0.0;
    
    final lessonActiveRate = totalLessons > 0 ? (activeLessons / totalLessons) * 100 : 0.0;
    final quizActiveRate = totalQuizzes > 0 ? (activeQuizzes / totalQuizzes) * 100 : 0.0;
    
    return ((lessonActiveRate + quizActiveRate) / 2).clamp(0.0, 100.0);
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1: return 'Mới bắt đầu';
      case 2: return 'Sơ cấp';
      case 3: return 'Trung cấp';
      case 4: return 'Trung cấp cao';
      case 5: return 'Nâng cao';
      default: return 'Cấp độ $level';
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.purple;
      case 5: return Colors.red;
      default: return AppColors.primary;
    }
  }
} 
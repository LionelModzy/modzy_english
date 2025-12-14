import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Phân tích & Thống kê',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
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
          isScrollable: isMobile,
          labelStyle: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.dashboard, size: 20),
              text: isMobile ? 'Tổng quan' : 'Tổng quan',
            ),
            Tab(
              icon: const Icon(Icons.people, size: 20),
              text: isMobile ? 'Người dùng' : 'Người dùng',
            ),
            Tab(
              icon: const Icon(Icons.trending_up, size: 20),
              text: isMobile ? 'Tăng trưởng' : 'Tăng trưởng',
            ),
            Tab(
              icon: const Icon(Icons.insights, size: 20),
              text: isMobile ? 'Tương tác' : 'Tương tác',
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.access_time),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
              _loadAnalytics();
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
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.adminPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải dữ liệu...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
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
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeaderSection(),
          const SizedBox(height: 24),

          // Key Metrics Grid with improved design
          _buildMetricsGrid(users, lessons, quizzes, vocabulary),
          
          const SizedBox(height: 24),

          // Charts Section
          _buildOverviewCharts(users, lessons, quizzes, vocabulary),
          
          const SizedBox(height: 24),

          // Platform Health Section
          _buildHealthSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.adminPrimary, AppColors.adminSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng quan Nền tảng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Khoảng thời gian: $_selectedTimeRange',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    Map<String, dynamic> users,
    Map<String, dynamic> lessons,
    Map<String, dynamic> quizzes,
    Map<String, dynamic> vocabulary,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
    
    int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.1 : 1.2,
      children: [
        _buildModernMetricCard(
          title: 'Tổng người dùng',
          value: '${users['total'] ?? 0}',
          subtitle: '+${users['newThisMonth'] ?? 0} tháng này',
          icon: Icons.people_rounded,
          gradient: [AppColors.primary, AppColors.primaryLight],
          trend: _calculateTrend(users['newThisMonth'] ?? 0, users['total'] ?? 1),
        ),
        _buildModernMetricCard(
          title: 'Người dùng hoạt động',
          value: '${users['active'] ?? 0}',
          subtitle: '${_calculatePercentage(users['active'] ?? 0, users['total'] ?? 1).toStringAsFixed(1)}% tổng số',
          icon: Icons.verified_user_rounded,
          gradient: [AppColors.success, const Color(0xFF34D399)],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Tổng bài học',
          value: '${lessons['total'] ?? 0}',
          subtitle: '+${lessons['newThisMonth'] ?? 0} tháng này',
          icon: Icons.book_rounded,
          gradient: [AppColors.secondary, AppColors.secondaryLight],
          trend: _calculateTrend(lessons['newThisMonth'] ?? 0, lessons['total'] ?? 1),
        ),
        _buildModernMetricCard(
          title: 'Lượt hoàn thành',
          value: '${lessons['totalCompletions'] ?? 0}',
          subtitle: '${lessons['recentCompletions'] ?? 0} gần đây',
          icon: Icons.check_circle_rounded,
          gradient: [AppColors.accent, AppColors.accentLight],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Tổng Quiz',
          value: '${quizzes['total'] ?? 0}',
          subtitle: 'Tỉ lệ đạt: ${(quizzes['passRate'] ?? 0.0).toStringAsFixed(1)}%',
          icon: Icons.quiz_rounded,
          gradient: [AppColors.warning, const Color(0xFFFBBF24)],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Lượt thi',
          value: '${quizzes['totalAttempts'] ?? 0}',
          subtitle: 'Điểm TB: ${(quizzes['averageScore'] ?? 0.0).toStringAsFixed(1)}%',
          icon: Icons.assignment_turned_in_rounded,
          gradient: [Colors.purple, Colors.purpleAccent],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Từ vựng',
          value: '${vocabulary['total'] ?? 0}',
          subtitle: '+${vocabulary['newThisMonth'] ?? 0} tháng này',
          icon: Icons.library_books_rounded,
          gradient: [Colors.teal, Colors.tealAccent],
          trend: _calculateTrend(vocabulary['newThisMonth'] ?? 0, vocabulary['total'] ?? 1),
        ),
        _buildModernMetricCard(
          title: 'Tiến độ TB',
          value: '${(users['averageProgress'] ?? 0.0).toStringAsFixed(1)}%',
          subtitle: 'Của tất cả người dùng',
          icon: Icons.trending_up_rounded,
          gradient: [Colors.orange, Colors.deepOrange],
          trend: 0.0,
        ),
      ],
    );
  }

  Widget _buildModernMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required double trend,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                if (trend != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trend.abs().toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCharts(
    Map<String, dynamic> users,
    Map<String, dynamic> lessons,
    Map<String, dynamic> quizzes,
    Map<String, dynamic> vocabulary,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Column(
      children: [
        // Content Distribution Pie Chart
        _buildChartCard(
          title: 'Phân bố Nội dung',
          child: SizedBox(
            height: isMobile ? 250 : 300,
            child: _buildContentDistributionChart(lessons, quizzes, vocabulary),
          ),
        ),
        const SizedBox(height: 16),
        
        // Quick Stats Bar Chart
        _buildChartCard(
          title: 'Thống kê Nhanh',
          child: SizedBox(
            height: isMobile ? 200 : 250,
            child: _buildQuickStatsBarChart(users, lessons, quizzes),
          ),
        ),
      ],
    );
  }

  Widget _buildContentDistributionChart(
    Map<String, dynamic> lessons,
    Map<String, dynamic> quizzes,
    Map<String, dynamic> vocabulary,
  ) {
    final lessonsTotal = lessons['total'] ?? 0;
    final quizzesTotal = quizzes['total'] ?? 0;
    final vocabTotal = vocabulary['total'] ?? 0;
    final total = lessonsTotal + quizzesTotal + vocabTotal;

    if (total == 0) {
      return Center(
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: [
          PieChartSectionData(
            value: lessonsTotal.toDouble(),
            title: '${((lessonsTotal / total) * 100).toStringAsFixed(1)}%',
            color: AppColors.secondary,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: quizzesTotal.toDouble(),
            title: '${((quizzesTotal / total) * 100).toStringAsFixed(1)}%',
            color: AppColors.warning,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: vocabTotal.toDouble(),
            title: '${((vocabTotal / total) * 100).toStringAsFixed(1)}%',
            color: Colors.teal,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsBarChart(
    Map<String, dynamic> users,
    Map<String, dynamic> lessons,
    Map<String, dynamic> quizzes,
  ) {
    final maxValue = [
      users['total'] ?? 0,
      lessons['total'] ?? 0,
      quizzes['total'] ?? 0,
    ].reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue > 0 ? maxValue * 1.2 : 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toInt().toString(),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Người dùng', 'Bài học', 'Quiz'];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: (users['total'] ?? 0).toDouble(),
                color: AppColors.primary,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: (lessons['total'] ?? 0).toDouble(),
                color: AppColors.secondary,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: (quizzes['total'] ?? 0).toDouble(),
                color: AppColors.warning,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final users = _platformStats['users'] as Map<String, dynamic>? ?? {};
    final levelDistribution = users['levelDistribution'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Phân tích Người dùng', Icons.people),
          const SizedBox(height: 20),

          // User Stats Grid
          _buildUserStatsGrid(users),
          const SizedBox(height: 24),

          // Level Distribution Chart
          _buildChartCard(
            title: 'Phân bố Cấp độ Người dùng',
            child: SizedBox(
              height: MediaQuery.of(context).size.width < 600 ? 250 : 300,
              child: _buildLevelDistributionChart(levelDistribution),
            ),
          ),
          const SizedBox(height: 16),

          // Level Distribution List
          _buildLevelDistributionList(levelDistribution),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.adminPrimary, AppColors.adminSecondary],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatsGrid(Map<String, dynamic> users) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.1 : 1.3,
      children: [
        _buildModernMetricCard(
          title: 'Tổng số',
          value: '${users['total'] ?? 0}',
          subtitle: 'Người dùng',
          icon: Icons.people,
          gradient: [AppColors.primary, AppColors.primaryLight],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Hoạt động',
          value: '${users['active'] ?? 0}',
          subtitle: 'Đang sử dụng',
          icon: Icons.verified_user,
          gradient: [AppColors.success, const Color(0xFF34D399)],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Quản trị',
          value: '${users['admins'] ?? 0}',
          subtitle: 'Admin',
          icon: Icons.admin_panel_settings,
          gradient: [AppColors.warning, const Color(0xFFFBBF24)],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Mới tuần này',
          value: '${users['newThisWeek'] ?? 0}',
          subtitle: 'Người dùng mới',
          icon: Icons.person_add,
          gradient: [AppColors.accent, AppColors.accentLight],
          trend: 0.0,
        ),
      ],
    );
  }

  Widget _buildLevelDistributionChart(Map<String, dynamic> levelDistribution) {
    if (levelDistribution.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dữ liệu phân bố cấp độ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final entries = levelDistribution.entries.toList();
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      AppColors.primary,
    ];

    final total = entries
        .map((e) => (e.value as num).toInt())
        .reduce((a, b) => a + b);

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 50,
        sections: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final levelEntry = entry.value;
          final count = (levelEntry.value as num).toInt();
          
          return PieChartSectionData(
            value: count.toDouble(),
            title: total > 0 ? '${((count / total) * 100).toStringAsFixed(1)}%' : '0%',
            color: colors[index % colors.length],
            radius: 70,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLevelDistributionList(Map<String, dynamic> levelDistribution) {
    if (levelDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = levelDistribution.entries.toList();
    final total = entries
        .map((e) => (e.value as num).toInt())
        .reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết Phân bố',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...entries.map((entry) {
            final level = int.tryParse(entry.key.toString()) ?? 1;
            final count = (entry.value as num).toInt();
            final percentage = total > 0 ? (count / total) * 100 : 0.0;
            final levelName = _getLevelName(level);
            final levelColor = _getLevelColor(level);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: levelColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$level',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          levelName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGrowthTab() {
    final growth = _platformStats['growth'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Phân tích Tăng trưởng', Icons.trending_up),
          const SizedBox(height: 20),

          // Growth Rate Cards
          _buildGrowthRateCards(growth),
          const SizedBox(height: 24),

          // Growth Line Chart
          _buildChartCard(
            title: 'Tăng trưởng Người dùng theo Tháng',
            child: SizedBox(
              height: MediaQuery.of(context).size.width < 600 ? 250 : 300,
              child: RepaintBoundary(
                child: _buildGrowthLineChart(growth),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Growth Comparison
          _buildGrowthComparisonSection(growth),
        ],
      ),
    );
  }

  Widget _buildGrowthRateCards(Map<String, dynamic> growth) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Row(
      children: [
        Expanded(
          child: _buildModernMetricCard(
            title: 'Tăng trưởng tuần',
            value: '${(growth['weeklyGrowthRate'] ?? 0.0).toStringAsFixed(1)}%',
            subtitle: growth['weeklyGrowthRate'] != null && (growth['weeklyGrowthRate'] as num) >= 0
                ? 'Tăng trưởng tích cực'
                : 'Cần cải thiện',
            icon: Icons.trending_up,
            gradient: (growth['weeklyGrowthRate'] ?? 0.0) >= 0
                ? [AppColors.success, const Color(0xFF34D399)]
                : [AppColors.error, const Color(0xFFF87171)],
            trend: 0.0,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: _buildModernMetricCard(
            title: 'Tăng trưởng tháng',
            value: '${(growth['monthlyGrowthRate'] ?? 0.0).toStringAsFixed(1)}%',
            subtitle: growth['monthlyGrowthRate'] != null && (growth['monthlyGrowthRate'] as num) >= 0
                ? 'Xu hướng tốt'
                : 'Cần chú ý',
            icon: Icons.show_chart,
            gradient: (growth['monthlyGrowthRate'] ?? 0.0) >= 0
                ? [AppColors.primary, AppColors.primaryLight]
                : [AppColors.warning, const Color(0xFFFBBF24)],
            trend: 0.0,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthLineChart(Map<String, dynamic> growth) {
    final userGrowth = growth['userGrowth'] as Map<String, dynamic>? ?? {};
    
    if (userGrowth.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dữ liệu tăng trưởng',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final entries = userGrowth.entries.toList();
    entries.sort((a, b) {
      final aKey = a.key.split('/');
      final bKey = b.key.split('/');
      final aMonth = int.parse(aKey[0]);
      final aYear = int.parse(aKey[1]);
      final bMonth = int.parse(bKey[0]);
      final bYear = int.parse(bKey[1]);
      
      if (aYear != bYear) return aYear.compareTo(bYear);
      return aMonth.compareTo(bMonth);
    });

    // Giới hạn số điểm để tránh lag
    final maxPoints = 12; // Chỉ hiển thị tối đa 12 tháng
    final displayEntries = entries.length > maxPoints 
        ? entries.sublist(entries.length - maxPoints)
        : entries;

    final spots = displayEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value.value as int).toDouble());
    }).toList();

    final maxY = spots.isNotEmpty
        ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2
        : 100.0;

    // Cache FlLine để tránh tạo mới mỗi lần
    final gridLine = FlLine(
      color: AppColors.border,
      strokeWidth: 1,
    );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => gridLine,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: displayEntries.length > 6 ? 2.0 : 1.0, // Giảm số label nếu quá nhiều
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < displayEntries.length) {
                  // Chỉ hiển thị label cho một số điểm nhất định
                  if (displayEntries.length > 6 && index % 2 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      displayEntries[index].key,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 5, // Giảm số label
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
            left: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        minX: 0,
        maxX: (displayEntries.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.adminPrimary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 12, // Chỉ hiển thị dots nếu ít điểm
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.adminPrimary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.adminPrimary.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: displayEntries.length <= 12, // Chỉ bật touch khi ít điểm
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index >= 0 && index < displayEntries.length) {
                  return LineTooltipItem(
                    '${displayEntries[index].key}\n${touchedSpot.y.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthComparisonSection(Map<String, dynamic> growth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'So sánh Giai đoạn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildComparisonRow(
            'Tuần này',
            '${growth['usersThisWeek'] ?? 0}',
            'người dùng mới',
            AppColors.success,
          ),
          _buildComparisonRow(
            'Tuần trước',
            '${growth['usersLastWeek'] ?? 0}',
            'người dùng mới',
            AppColors.textSecondary,
          ),
          const Divider(height: 32),
          _buildComparisonRow(
            'Tháng này',
            '${growth['usersThisMonth'] ?? 0}',
            'người dùng mới',
            AppColors.primary,
          ),
          _buildComparisonRow(
            'Tháng trước',
            '${growth['usersLastMonth'] ?? 0}',
            'người dùng mới',
            AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String period, String value, String metric, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                period,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            '$value $metric',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Phân tích Tương tác', Icons.insights),
          const SizedBox(height: 20),

          // Engagement Metrics Grid
          _buildEngagementMetricsGrid(),
          const SizedBox(height: 24),

          // Engagement Chart
          _buildChartCard(
            title: 'Tương tác Người dùng',
            child: SizedBox(
              height: MediaQuery.of(context).size.width < 600 ? 250 : 300,
              child: _buildEngagementChart(),
            ),
          ),
          const SizedBox(height: 16),

          // Engagement Tips
          _buildEngagementTipsSection(),
        ],
      ),
    );
  }

  Widget _buildEngagementMetricsGrid() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.1 : 1.3,
      children: [
        _buildModernMetricCard(
          title: 'Người dùng hoạt động hàng ngày',
          value: '${_engagementStats['dailyActiveUsers'] ?? 0}',
          subtitle: 'DAU',
          icon: Icons.today,
          gradient: [AppColors.primary, AppColors.primaryLight],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Thời gian phiên TB',
          value: '${(_engagementStats['averageSessionDuration'] ?? 0.0).toStringAsFixed(1)}',
          subtitle: 'phút',
          icon: Icons.access_time,
          gradient: [AppColors.accent, AppColors.accentLight],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Tỉ lệ giữ chân',
          value: '${(_engagementStats['retentionRate'] ?? 0.0).toStringAsFixed(1)}%',
          subtitle: 'Retention',
          icon: Icons.psychology,
          gradient: [AppColors.success, const Color(0xFF34D399)],
          trend: 0.0,
        ),
        _buildModernMetricCard(
          title: 'Người dùng quay lại',
          value: '${_engagementStats['retainedUsers'] ?? 0}',
          subtitle: 'Retained',
          icon: Icons.replay,
          gradient: [AppColors.warning, const Color(0xFFFBBF24)],
          trend: 0.0,
        ),
      ],
    );
  }

  Widget _buildEngagementChart() {
    final dailyActiveUsers = _engagementStats['dailyActiveUsers'] ?? 0;
    final retainedUsers = _engagementStats['retainedUsers'] ?? 0;
    final previousActiveUsers = _engagementStats['previousActiveUsers'] ?? 1;
    
    final maxValue = [dailyActiveUsers, retainedUsers, previousActiveUsers]
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue > 0 ? maxValue * 1.2 : 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toInt().toString(),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['DAU', 'Retained', 'Previous'];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: dailyActiveUsers.toDouble(),
                color: AppColors.primary,
                width: 50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: retainedUsers.toDouble(),
                color: AppColors.success,
                width: 50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: previousActiveUsers.toDouble(),
                color: AppColors.warning,
                width: 50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.adminPrimary.withOpacity(0.1), AppColors.adminSecondary.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.adminPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.adminPrimary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Gợi ý Cải thiện Tương tác',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sức khỏe Nền tảng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
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
    IconData icon;
    
    if (score >= 80) {
      color = AppColors.success;
      status = 'Tốt';
      icon = Icons.check_circle;
    } else if (score >= 60) {
      color = AppColors.warning;
      status = 'Khá';
      icon = Icons.info;
    } else {
      color = AppColors.error;
      status = 'Cần cải thiện';
      icon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
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

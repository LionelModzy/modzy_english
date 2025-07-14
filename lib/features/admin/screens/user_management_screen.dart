import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/user_management_service.dart';
import '../../../models/user_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  Map<String, dynamic> _userStats = {};

  final List<String> _roleOptions = ['Tất cả', 'Người dùng', 'Quản trị viên'];
  final List<String> _statusOptions = ['Tất cả', 'Hoạt động', 'Tạm dừng'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
    _loadUserStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await UserManagementService.getAllUsers();
      setState(() {
        _users = users;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách người dùng: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadUserStatistics() async {
    try {
      final stats = await UserManagementService.getUserStatistics();
      setState(() {
        _userStats = stats;
      });
    } catch (e) {
      print('Lỗi tải thống kê người dùng: $e');
    }
  }

  void _applyFilters() {
    _filteredUsers = _users.where((user) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());

      // Role filter
      final matchesRole = _selectedRole == 'Tất cả' ||
          (_selectedRole == 'Quản trị viên' && user.isAdmin) ||
          (_selectedRole == 'Người dùng' && user.isUser);

      // Status filter
      final matchesStatus = _selectedStatus == 'Tất cả' ||
          (_selectedStatus == 'Hoạt động' && user.isActive) ||
          (_selectedStatus == 'Tạm dừng' && !user.isActive);

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  List<UserModel> get _activeUsers => _users.where((user) => user.isActive).toList();
  List<UserModel> get _inactiveUsers => _users.where((user) => !user.isActive).toList();
  List<UserModel> get _adminUsers => _users.where((user) => user.isAdmin).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quản lý Người dùng',
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
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Tất cả',
            ),
            Tab(
              icon: Icon(Icons.verified_user),
              text: 'Hoạt động',
            ),
            Tab(
              icon: Icon(Icons.person_off),
              text: 'Tạm dừng',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadUsers();
              _loadUserStatistics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Filter row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Vai trò',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _roleOptions.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Statistics Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng số',
                    value: '${_users.length}',
                    icon: Icons.people_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Hoạt động',
                    value: '${_userStats['activeUsers'] ?? 0}',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Quản trị',
                    value: '${_userStats['adminUsers'] ?? 0}',
                    icon: Icons.admin_panel_settings_rounded,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Mới tháng này',
                    value: '${_userStats['newUsersThisMonth'] ?? 0}',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          
          // User Lists with Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Users
                _buildUserList(_filteredUsers),
                // Active Users
                _buildUserList(_activeUsers),
                // Inactive Users
                _buildUserList(_inactiveUsers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _buildUserCard(users[index]);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header with avatar and basic info
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: user.isActive ? AppColors.primary : AppColors.textSecondary,
                backgroundImage: user.profileImageUrl != null 
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.displayName.isNotEmpty 
                            ? user.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName.isNotEmpty ? user.displayName : 'Chưa có tên',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.isAdmin ? AppColors.warning : AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.isAdmin ? 'Quản trị' : 'Người dùng',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isActive ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.isActive ? 'Hoạt động' : 'Tạm dừng',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8), // Reduced from 12
          
          // User stats row
          Row(
            children: [
              Expanded(
                child: _buildUserStat(
                  'Cấp độ',
                  '${user.currentLevel}',
                  Icons.school_rounded,
                ),
              ),
              Expanded(
                child: _buildUserStat(
                  'Bài học',
                  '${user.totalLessonsCompleted}',
                  Icons.book_rounded,
                ),
              ),
              Expanded(
                child: _buildUserStat(
                  'Từ vựng',
                  '${user.totalVocabularyLearned}',
                  Icons.library_books_rounded,
                ),
              ),
              Expanded(
                child: _buildUserStat(
                  'Tiến độ',
                  '${user.progressPercentage.toStringAsFixed(0)}%',
                  Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8), // Reduced from 12
          
          // Registration date and last login
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đăng ký: ${DateFormat('dd/MM/yyyy').format(user.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11, // Reduced from 12
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (user.lastLoginAt != null)
                Text(
                  'Đăng nhập cuối: ${DateFormat('dd/MM/yyyy').format(user.lastLoginAt!)}',
                  style: const TextStyle(
                    fontSize: 11, // Reduced from 12
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8), // Reduced from 12
          
          // Action buttons
          Column(
            children: [
              // First row: Details and Status buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showUserDetails(user),
                      icon: const Icon(Icons.info_outline, size: 14),
                      label: const Text('Chi tiết', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleUserStatus(user),
                      icon: Icon(
                        user.isActive ? Icons.pause : Icons.play_arrow,
                        size: 14,
                      ),
                      label: Text(
                        user.isActive ? 'Tạm dừng' : 'Kích hoạt',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user.isActive ? AppColors.warning : AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Second row: Role change button (full width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCurrentUser(user) 
                    ? null  // Disable button if this is current user
                    : () => _showRoleChangeDialog(user),
                  icon: Icon(
                    Icons.admin_panel_settings, 
                    size: 14,
                    color: _isCurrentUser(user) ? Colors.grey : Colors.white,
                  ),
                  label: Text(
                    _isCurrentUser(user) 
                      ? 'Tài khoản hiện tại'
                      : (user.isAdmin ? 'Hủy Admin' : 'Đặt Admin'),
                    style: TextStyle(
                      fontSize: 11,
                      color: _isCurrentUser(user) ? Colors.grey : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCurrentUser(user) 
                      ? Colors.grey.shade300
                      : (user.isAdmin ? AppColors.error : AppColors.primary),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 14, color: AppColors.primary), // Reduced from 16
        const SizedBox(height: 1), // Reduced from 2
        Text(
          value,
          style: const TextStyle(
            fontSize: 12, // Reduced from 14
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9, // Reduced from 10
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết người dùng: ${user.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('UID', user.uid),
              _buildDetailRow('Vai trò', user.isAdmin ? 'Quản trị viên' : 'Người dùng'),
              _buildDetailRow('Trạng thái', user.isActive ? 'Hoạt động' : 'Tạm dừng'),
              _buildDetailRow('Cấp độ', '${user.currentLevel} (${user.levelName})'),
              _buildDetailRow('Tiến độ', '${user.progressPercentage.toStringAsFixed(1)}%'),
              _buildDetailRow('Bài học hoàn thành', '${user.totalLessonsCompleted}'),
              _buildDetailRow('Từ vựng đã học', '${user.totalVocabularyLearned}'),
              _buildDetailRow('Ngày đăng ký', DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt)),
              if (user.lastLoginAt != null)
                _buildDetailRow('Đăng nhập cuối', DateFormat('dd/MM/yyyy HH:mm').format(user.lastLoginAt!)),
              _buildDetailRow('Hoàn thiện hồ sơ', '${user.profileCompletionPercentage.toStringAsFixed(0)}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final newStatus = !user.isActive;
    final success = await UserManagementService.updateUserStatus(user.uid, newStatus);
    
    if (success) {
      await _loadUsers();
      await _loadUserStatistics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã ${newStatus ? "kích hoạt" : "tạm dừng"} tài khoản ${user.displayName}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi cập nhật trạng thái người dùng'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showRoleChangeDialog(UserModel user) {
    // Double check to prevent current user from changing their own role
    if (_isCurrentUser(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không thể thay đổi vai trò của chính mình'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final newRole = user.isAdmin ? 'user' : 'admin';
    final roleText = user.isAdmin ? 'người dùng thường' : 'quản trị viên';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi vai trò'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn đổi vai trò của ${user.displayName} thành $roleText?',
            ),
            const SizedBox(height: 8),
            if (newRole == 'admin')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cấp quyền admin sẽ cho phép người dùng này truy cập tất cả chức năng quản trị.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _changeUserRole(user, newRole);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole == 'admin' ? AppColors.warning : AppColors.error,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeUserRole(UserModel user, String newRole) async {
    // Final safety check to prevent current user from changing their own role
    if (_isCurrentUser(user)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Không thể thay đổi vai trò của chính mình'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final success = await UserManagementService.updateUserRole(user.uid, newRole);
    
    if (success) {
      await _loadUsers();
      await _loadUserStatistics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã cập nhật vai trò của ${user.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Lỗi khi cập nhật vai trò người dùng'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _isCurrentUser(UserModel user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && user.uid == currentUser.uid;
  }
} 
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/challenge_templates.dart';
import '../../../core/services/challenge_service.dart';
import '../../../core/services/friend_request_service.dart';
import '../../../core/services/friend_service.dart';
import '../../../core/services/leaderboard_service.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../features/social/widgets/challenge_template_sheet.dart';
import '../../../models/challenge_model.dart';
import '../../../models/friend_request_model.dart';
import '../../../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _categoryTabController;
  late TabController _periodTabController;
  String _currentCategory = 'overall';
  String _currentPeriod = 'all';
  bool _isLoading = true;
  String? _loadErrorMessage;
  String? _rankErrorMessage;
  bool _rankTemporarilyUnavailable = false;
  List<UserModel> _leaderboard = [];
  int _currentUserRank = -1;
  String? _currentUserId;
  UserModel? _currentUser;
  String? _addingFriendUserId;
  String? _creatingChallengeUserId;
  List<FriendRequestModel> _incomingRequests = [];
  List<FriendRequestModel> _sentRequests = [];
  StreamSubscription<List<FriendRequestModel>>? _friendRequestSubscription;
  Set<String> _friendIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Modern purple color scheme
  static const Color _purplePrimary = Color(0xFF7C3AED);
  static const Color _purpleDark = Color(0xFF5B21B6);
  static const Color _purpleLight = Color(0xFFA78BFA);
  static const Color _yellowHighlight = Color(0xFFFFD700);
  static const Color _goldStar = Color(0xFFFFD700);
  static const Color _silverStar = Color(0xFFC0C0C0);
  static const Color _bronzeStar = Color(0xFFCD7F32);

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(length: 5, vsync: this, initialIndex: 4);
    _periodTabController = TabController(length: 5, vsync: this, initialIndex: 0);
    _currentCategory = 'overall';
    _currentPeriod = 'daily';
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserData();
    
    _categoryTabController.addListener(() {
      if (!_categoryTabController.indexIsChanging) {
        final categories = ['lessons', 'vocabulary', 'progress', 'level', 'overall'];
        _currentCategory = categories[_categoryTabController.index];
        _loadLeaderboard();
      }
    });

    _periodTabController.addListener(() {
      if (!_periodTabController.indexIsChanging) {
        final periods = ['daily', 'weekly', 'monthly', 'yearly', 'all'];
        _currentPeriod = periods[_periodTabController.index];
        _loadLeaderboard();
      }
    });
  }

  @override
  void dispose() {
    _categoryTabController.dispose();
    _periodTabController.dispose();
    _searchController.dispose();
    _friendRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthRepository.getCurrentUserData();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _friendIds = (user?.friends ?? const <String>[]).toSet();
        });
        _listenToFriendRequests();
        _loadLeaderboard();
      }
    } catch (e) {
      if (mounted) {
        _friendIds = {};
        _loadLeaderboard();
      }
    }
  }

  void _listenToFriendRequests() {
    _friendRequestSubscription?.cancel();
    if (_currentUserId == null) return;

    _friendRequestSubscription =
        FriendRequestService.watchRequests(_currentUserId!).listen((requests) {
      if (!mounted) return;
      setState(() {
        _incomingRequests =
            requests.where((r) => r.receiverId == _currentUserId && r.isPending).toList();
        _sentRequests =
            requests.where((r) => r.senderId == _currentUserId && r.isPending).toList();
      });
    }, onError: (error) {
      if (kDebugMode) {
        print('❌ Error listening to leaderboard friend requests: $error');
      }
    });
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final leaderboard = await LeaderboardService.getLeaderboardByPeriod(
        sortBy: _currentCategory,
        timePeriod: _currentPeriod,
        limit: 100,
      );

      int rank = -1;
      String? rankError;
      if (_currentUserId != null && !_rankTemporarilyUnavailable) {
        try {
          rank = await LeaderboardService.getUserRank(
            userId: _currentUserId!,
            sortBy: _currentCategory,
          );
          _rankTemporarilyUnavailable = false;
        } on FirebaseException catch (e) {
          if (e.code == 'failed-precondition') {
            rankError = 'Hạng cá nhân sẽ hiển thị khi dữ liệu hoàn tất.';
          } else if (e.code == 'permission-denied') {
            rankError = 'Không thể lấy hạng cá nhân do quyền truy cập.';
          } else {
            rankError = 'Không thể lấy hạng cá nhân lúc này.';
          }
          _rankTemporarilyUnavailable = true;
        }
      } else if (_rankTemporarilyUnavailable) {
        rankError = _rankErrorMessage ??
            'Hạng cá nhân sẽ hiển thị khi dữ liệu hoàn tất.';
      }

      if (mounted) {
        setState(() {
          _leaderboard = leaderboard;
          _currentUserRank = rank;
          _isLoading = false;
          _rankErrorMessage = rankError;
          _loadErrorMessage = null;
        });
      }
    } on FirebaseException catch (e) {
      String? friendly;
      if (e.code == 'failed-precondition') {
        friendly =
            'Bảng xếp hạng đang được cập nhật. Vui lòng thử lại sau một chút khi dữ liệu đã sẵn sàng.';
      } else if (e.code == 'permission-denied') {
        friendly = 'Bạn không có quyền xem bảng này. Hãy đăng nhập lại hoặc liên hệ quản trị viên.';
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadErrorMessage =
              friendly ?? 'Không thể tải dữ liệu leaderboard. Vui lòng thử lại.';
          _leaderboard = [];
          _rankErrorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadErrorMessage = 'Có lỗi xảy ra khi tải bảng xếp hạng. Vui lòng thử lại.';
          _leaderboard = [];
          _rankErrorMessage = null;
        });
      }
    }
  }

  FriendRequestModel? _incomingRequestFrom(String userId) {
    for (final request in _incomingRequests) {
      if (request.senderId == userId) return request;
    }
    return null;
  }

  FriendRequestModel? _outgoingRequestTo(String userId) {
    for (final request in _sentRequests) {
      if (request.receiverId == userId) return request;
    }
    return null;
  }

  void _showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? _purplePrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleAddFriend(UserModel targetUser) async {
    if (_currentUserId == null) {
      _showSnack('Bạn cần đăng nhập để thêm bạn bè.');
      return;
    }

    if (targetUser.uid == _currentUserId) {
      _showSnack('Không thể tự thêm chính mình.');
      return;
    }

    if (_currentUser == null) {
      _showSnack('Không thể gửi lời mời khi chưa có thông tin người dùng.');
      return;
    }

    setState(() => _addingFriendUserId = targetUser.uid);

    final result = await FriendRequestService.sendRequest(
      sender: _currentUser!,
      receiver: targetUser,
    );

    if (!mounted) return;

    setState(() => _addingFriendUserId = null);

    switch (result) {
      case FriendRequestActionResult.sent:
        _showSnack('Đã gửi lời mời kết bạn đến ${targetUser.displayName}', color: Colors.green);
        break;
      case FriendRequestActionResult.alreadyFriends:
        _showSnack('Bạn và ${targetUser.displayName} đã là bạn bè.');
        break;
      case FriendRequestActionResult.alreadyPending:
        _showSnack('Bạn đã gửi lời mời và đang chờ ${targetUser.displayName} phản hồi.');
        break;
      case FriendRequestActionResult.incomingPending:
        _showSnack('${targetUser.displayName} đang chờ bạn chấp nhận lời mời.');
        break;
      case FriendRequestActionResult.userNotFound:
        _showSnack('Không tìm thấy người dùng này. Vui lòng thử lại.');
        break;
      case FriendRequestActionResult.selfNotAllowed:
        _showSnack('Không thể tự thêm chính mình.');
        break;
      case FriendRequestActionResult.failure:
        _showSnack('Không thể gửi lời mời lúc này. Vui lòng thử lại sau.');
        break;
    }
  }

  Future<void> _handleFriendRequestResponse(
    FriendRequestModel request, {
    required bool accept,
  }) async {
    if (_currentUserId == null) return;
    final success = await FriendRequestService.respondToRequest(
      request: request,
      userId: _currentUserId!,
      accept: accept,
    );
    if (!mounted) return;
    if (success) {
      if (accept) {
        _friendIds.add(request.senderId);
        if (_currentUser != null && !_currentUser!.friends.contains(request.senderId)) {
          final updated = List<String>.from(_currentUser!.friends)..add(request.senderId);
          _currentUser = _currentUser!.copyWith(friends: updated);
        }
        _showSnack('Đã kết bạn với ${request.senderName}!', color: Colors.green);
      } else {
        _showSnack('Đã từ chối lời mời của ${request.senderName}.', color: Colors.orange);
      }
    } else {
      _showSnack('Không thể cập nhật lời mời. Vui lòng thử lại.');
    }
  }

  Future<void> _handleCancelFriendRequest(FriendRequestModel request) async {
    if (_currentUserId == null) return;
    final success = await FriendRequestService.cancelRequest(request, userId: _currentUserId!);
    if (!mounted) return;
    if (success) {
      _showSnack('Đã hủy lời mời gửi cho ${request.receiverName}.', color: Colors.orange);
    } else {
      _showSnack('Không thể hủy lời mời lúc này.');
    }
  }

  Future<void> _openChallengeCreationSheet(UserModel opponent) async {
    if (_currentUser == null || _currentUserId == null) {
      _showSnack('Bạn cần đăng nhập để tạo thách đấu.');
      return;
    }
    if (opponent.uid == _currentUserId) {
      _showSnack('Không thể thách đấu chính bạn.');
      return;
    }
    if (!_friendIds.contains(opponent.uid)) {
      _showSnack('Bạn cần kết bạn với ${opponent.displayName} trước khi thách đấu.');
      return;
    }

    setState(() => _creatingChallengeUserId = opponent.uid);

    final result = await showChallengeTemplateSheet(
      context: context,
      challenger: _currentUser!,
      opponent: opponent,
    );

    if (!mounted) return;
    setState(() => _creatingChallengeUserId = null);

    if (result == true) {
      _showSnack('Đã gửi lời thách đấu đến ${opponent.displayName}', color: Colors.green);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _leaderboard;
    final query = _searchQuery.toLowerCase();
    return _leaderboard
        .where((user) => user.displayName.toLowerCase().contains(query))
        .toList();
  }

  List<UserModel> get _displayUsers {
    final baseUsers = List<UserModel>.from(_filteredUsers);
    final isCurrentUserMissing =
        _currentUserId != null && !baseUsers.any((user) => user.uid == _currentUserId);
    if (isCurrentUserMissing && _currentUser != null) {
      baseUsers.add(_currentUser!);
    }
    return baseUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Time Period Tabs
            _buildPeriodTabs(),
            
            // Category Tabs
            _buildCategoryTabs(),
            
            // Search + current user rank
            _buildSearchBar(),
            if (_currentUserRank > 0) _buildCurrentUserRankChip(),
            
            // Leaderboard Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _loadErrorMessage != null
                      ? _buildErrorState()
                      : _leaderboard.isEmpty
                          ? _buildEmptyState()
                      : _buildLeaderboardContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _purpleDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'LEADERBOARD',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _yellowHighlight,
                  letterSpacing: 1.5,
                  shadows: const [
                    Shadow(
                      color: Color(0xFFFF8C00),
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildPeriodTab('Daily', 0),
          const SizedBox(width: 12),
          _buildPeriodTab('Weekly', 1),
          const SizedBox(width: 12),
          _buildPeriodTab('Monthly', 2),
          const SizedBox(width: 12),
          _buildPeriodTab('Yearly', 3),
          const SizedBox(width: 12),
          _buildPeriodTab('All', 4),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, int index) {
    final isSelected = _periodTabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _periodTabController.animateTo(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _purpleLight : _purpleDark.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _purplePrimary : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _purplePrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : _purpleDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _categoryTabController,
        isScrollable: true,
        labelColor: _purplePrimary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _purplePrimary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: '📚 Lessons'),
          Tab(text: '📖 Vocabulary'),
          Tab(text: '📊 Progress'),
          Tab(text: '⭐ Level'),
          Tab(text: '🏆 Overall'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentUserRankChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _yellowHighlight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _yellowHighlight, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_rounded, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser != null
                        ? '${_currentUser!.displayName} đang ở hạng #${_currentUserRank > 0 ? _currentUserRank : '?'}'
                        : 'Hạng hiện tại của bạn: #${_currentUserRank > 0 ? _currentUserRank : '?'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if (_rankErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _rankErrorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.trending_up_rounded, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_purplePrimary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading leaderboard...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No leaderboard data',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 72, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              _loadErrorMessage ?? 'Không thể tải dữ liệu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadLeaderboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purplePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Thử lại'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    final baseFiltered = _filteredUsers;
    final isCurrentUserMissing =
        _currentUserId != null && !baseFiltered.any((user) => user.uid == _currentUserId);
    final users = _displayUsers;
    final topUsers = users.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          if (topUsers.isNotEmpty) _buildTopUsersSection(topUsers),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildListHeader(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isCurrentUser = user.uid == _currentUserId;
                    final bool isOutsideTopRange = isCurrentUser && isCurrentUserMissing;
                    final int rank = isOutsideTopRange && _currentUserRank > 0
                        ? _currentUserRank
                        : index + 1;
                    return GestureDetector(
                      onTap: () => _showUserDetails(user, rank),
                      child: _buildLeaderboardItem(
                        user,
                        rank,
                        isCurrentUser,
                        isOutsideTopRange: isOutsideTopRange,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
    UserModel user,
    int rank,
    bool isCurrentUser, {
    bool isOutsideTopRange = false,
  }) {
    final isTopThree = rank <= 3;
    Color rowColor;
    
    if (isCurrentUser) {
      rowColor = _yellowHighlight;
    } else if (rank % 2 == 0) {
      rowColor = _purpleLight.withOpacity(0.3);
    } else {
      rowColor = _purplePrimary.withOpacity(0.2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: _yellowHighlight, width: 2)
            : null,
        boxShadow: isCurrentUser
            ? [
                BoxShadow(
                  color: _yellowHighlight.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank Badge
          SizedBox(
            width: 60,
            child: _buildRankBadge(rank),
          ),
          
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.profileImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildDefaultAvatar(user),
                      errorWidget: (context, url, error) => _buildDefaultAvatar(user),
                    )
                  : _buildDefaultAvatar(user),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isCurrentUser ? Colors.black : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            color: _yellowHighlight,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isOutsideTopRange)
                  Text(
                    'Outside top ${_leaderboard.length} - showing personal rank',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (!isCurrentUser)
                  Text(
                    'Level ${user.currentLevel}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          
          // Score
          SizedBox(
            width: 100,
            child: Text(
              _getStatValue(user),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isCurrentUser ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsersSection(List<UserModel> topUsers) {
    final first = topUsers.isNotEmpty ? topUsers.first : null;
    final second = topUsers.length > 1 ? topUsers[1] : null;
    final third = topUsers.length > 2 ? topUsers[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Top Contributors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _purpleDark,
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (second != null)
                GestureDetector(
                  onTap: () => _showUserDetails(second, 2),
                  child: _buildPodiumUser(second, 2, 140, _silverStar),
                ),
              if (first != null)
                GestureDetector(
                  onTap: () => _showUserDetails(first, 1),
                  child: _buildPodiumUser(first, 1, 170, _goldStar, isChampion: true),
                ),
              if (third != null)
                GestureDetector(
                  onTap: () => _showUserDetails(third, 3),
                  child: _buildPodiumUser(third, 3, 120, _bronzeStar),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(UserModel user, int rank, double podiumHeight, Color badgeColor,
      {bool isChampion = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: isChampion ? 96 : 86,
              height: isChampion ? 96 : 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: badgeColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.profileImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: badgeColor),
                        errorWidget: (context, url, error) => _buildDefaultAvatar(user),
                      )
                    : _buildDefaultAvatar(user),
              ),
            ),
            if (isChampion)
              Positioned(
                top: -18,
                left: 0,
                right: 0,
                child: Icon(Icons.workspace_premium_rounded, color: _goldStar, size: 32),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          user.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: _purpleDark,
          ),
        ),
        Text(
          '${_getStatValue(user)} pts',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: isChampion ? 90 : 70,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                badgeColor.withOpacity(0.95),
                badgeColor.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: badgeColor.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Rank',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Name',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              _getScoreLabel(),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _goldStar,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _goldStar.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.star_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    } else if (rank == 2) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _silverStar,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _silverStar.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.star_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    } else if (rank == 3) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _bronzeStar,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _bronzeStar.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.star_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _purpleLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDefaultAvatar(UserModel user) {
    return Container(
      color: _purpleLight,
      child: Center(
        child: Text(
          user.displayName.isNotEmpty
              ? user.displayName[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _getStatValue(UserModel user) {
    switch (_currentCategory) {
      case 'lessons':
        return '${user.totalLessonsCompleted}';
      case 'vocabulary':
        return '${user.totalVocabularyLearned}';
      case 'progress':
        return '${user.progressPercentage.toInt()}%';
      case 'level':
        return 'Lv.${user.currentLevel}';
      case 'overall':
        final score = (user.totalLessonsCompleted * 0.3 +
                user.totalVocabularyLearned * 0.3 +
                user.progressPercentage * 0.2 +
                user.currentLevel * 20 * 0.2)
            .toInt();
        return '$score';
      default:
        return '${user.totalLessonsCompleted}';
    }
  }

  String _getScoreLabel() {
    switch (_currentCategory) {
      case 'lessons':
        return 'Lessons';
      case 'vocabulary':
        return 'Words';
      case 'progress':
        return 'Progress';
      case 'level':
        return 'Level';
      case 'overall':
        return 'Score';
      default:
        return 'Score';
    }
  }

  void _showUserDetails(UserModel user, int rank) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final bool isFriend = _friendIds.contains(user.uid);
        final bool isProcessing = _addingFriendUserId == user.uid;
        final bool isSelf = user.uid == _currentUserId;
        final bool isChallengeProcessing = _creatingChallengeUserId == user.uid;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 48,
                backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                backgroundColor: _purpleLight,
                child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                    ? Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rank #$rank · Level ${user.currentLevel}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatChip(Icons.play_lesson_rounded, 'Lessons', '${user.totalLessonsCompleted}'),
                  _buildStatChip(Icons.translate_rounded, 'Vocabulary', '${user.totalVocabularyLearned}'),
                  _buildStatChip(Icons.percent_rounded, 'Progress', '${user.progressPercentage.toInt()}%'),
                ],
              ),
              const SizedBox(height: 20),
              if (!isSelf) ...[
                _buildFriendActionButtons(
                  user: user,
                  isFriend: isFriend,
                  isProcessing: isProcessing,
                  incomingRequest: _incomingRequestFrom(user.uid),
                  outgoingRequest: _outgoingRequestTo(user.uid),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: (isSelf || isChallengeProcessing || !isFriend)
                    ? null
                    : () => _openChallengeCreationSheet(user),
                icon: isChallengeProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sports_kabaddi_rounded),
                label: Text(
                  isSelf
                      ? 'Đây là bạn'
                      : !isFriend
                          ? 'Cần kết bạn'
                          : isChallengeProcessing
                              ? 'Đang tạo...'
                              : 'Challenge',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _purplePrimary, width: 2),
                  foregroundColor: _purplePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _purplePrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: _purplePrimary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFriendActionButtons({
    required UserModel user,
    required bool isFriend,
    required bool isProcessing,
    FriendRequestModel? incomingRequest,
    FriendRequestModel? outgoingRequest,
  }) {
    if (isFriend) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Đã là bạn bè'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    if (incomingRequest != null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleFriendRequestResponse(incomingRequest, accept: true),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _purplePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('${incomingRequest.senderName} muốn kết bạn'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleFriendRequestResponse(incomingRequest, accept: false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Từ chối'),
            ),
          ),
        ],
      );
    }

    if (outgoingRequest != null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Đang chờ phản hồi'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleCancelFriendRequest(outgoingRequest),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Hủy lời mời'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : () => _handleAddFriend(user),
        icon: isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.person_add_alt_1_rounded),
        label: Text(isProcessing ? 'Đang gửi...' : 'Gửi lời mời kết bạn'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: _purplePrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

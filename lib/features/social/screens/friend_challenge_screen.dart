import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/challenge_templates.dart';
import '../../../core/services/challenge_service.dart';
import '../../../core/services/challenge_exercise_service.dart';
import '../../../core/services/friend_request_service.dart';
import '../../../core/services/friend_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../features/social/widgets/challenge_template_sheet.dart';
import '../../../models/challenge_exercise_model.dart';
import '../../../models/challenge_model.dart';
import '../../../models/friend_request_model.dart';
import '../../../models/quiz_model.dart';
import '../../../models/user_model.dart';
import '../../quiz/screens/quiz_screen.dart';

class FriendChallengeScreen extends ConsumerStatefulWidget {
  const FriendChallengeScreen({super.key});

  @override
  ConsumerState<FriendChallengeScreen> createState() => _FriendChallengeScreenState();
}

class _FriendChallengeScreenState extends ConsumerState<FriendChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _friendInputController = TextEditingController();
  UserModel? _currentUser;
  List<UserModel> _friends = [];
  bool _isSubmitting = false;
  bool _isLoadingFriends = true;
  bool _isLoadingChallenges = true;
  String? _creatingChallengeFriendId;
  String? _processingChallengeId;

  StreamSubscription<List<ChallengeModel>>? _challengeSubscription;
  List<ChallengeModel> _receivedChallenges = [];
  List<ChallengeModel> _sentChallenges = [];
  List<FriendRequestModel> _incomingRequests = [];
  List<FriendRequestModel> _sentRequests = [];
  StreamSubscription<List<FriendRequestModel>>? _friendRequestSubscription;
  Set<String> _friendIds = {};
  final Map<String, String> _requestStatusOverrides = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _friendInputController.dispose();
    _challengeSubscription?.cancel();
    _friendRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = await AuthRepository.getCurrentUserData();
    if (!mounted) return;

    setState(() {
      _currentUser = user;
    });

    if (user != null) {
      await _refreshFriends();
      _listenToFriendRequests();
      _listenToChallenges();
    } else {
      setState(() {
        _isLoadingFriends = false;
        _isLoadingChallenges = false;
      });
    }
  }

  Future<void> _refreshFriends() async {
    if (_currentUser == null) return;
    setState(() => _isLoadingFriends = true);
    final friends = await FriendService.getFriends(_currentUser!.uid);
    if (!mounted) return;
    setState(() {
      _friends = friends;
      _isLoadingFriends = false;
      _friendIds = friends.map((f) => f.uid).toSet();
    });
  }

  void _listenToChallenges() {
    _challengeSubscription?.cancel();
    if (_currentUser == null) return;

    setState(() => _isLoadingChallenges = true);
    
    // Test: Get challenges once to debug
    if (kDebugMode) {
      ChallengeService.getAllChallengesForUser(_currentUser!.uid).then((challenges) {
        print('🧪 TEST: getAllChallengesForUser returned ${challenges.length} challenges');
        for (var c in challenges) {
          print('  - ${c.id}: challengerId=${c.challengerId}, opponentId=${c.opponentId}');
        }
      });
    }

    _challengeSubscription = ChallengeService.watchChallenges(_currentUser!.uid).listen(
      (challenges) {
        if (!mounted) return;
        final myId = _currentUser!.uid;
        
        // Debug: Print challenges for troubleshooting
        if (kDebugMode) {
          print('📊 Total challenges: ${challenges.length}');
          for (var c in challenges) {
            print('  - Challenge ${c.id}: challengerId=${c.challengerId}, opponentId=${c.opponentId}, status=${c.status}');
            print('    My ID: $myId, Is challenger: ${c.challengerId == myId}, Is opponent: ${c.opponentId == myId}');
          }
        }
        
        setState(() {
          // Show pending and accepted challenges
          _receivedChallenges = challenges
              .where((c) {
                final isOpponent = c.opponentId == myId;
                final isValidStatus = c.status == ChallengeStatus.pending || 
                                     c.status == ChallengeStatus.accepted ||
                                     c.status == ChallengeStatus.completed;
                if (kDebugMode) {
                  print('🔍 Checking challenge ${c.id}:');
                  print('   opponentId="${c.opponentId}" (length: ${c.opponentId.length})');
                  print('   myId="$myId" (length: ${myId.length})');
                  print('   isOpponent=$isOpponent, isValidStatus=$isValidStatus');
                  if (isOpponent && isValidStatus) {
                    print('✅ Added to received challenges');
                  }
                }
                return isOpponent && isValidStatus;
              })
              .toList();
          _sentChallenges = challenges
              .where((c) {
                final isChallenger = c.challengerId == myId;
                final isValidStatus = c.status == ChallengeStatus.pending || 
                                     c.status == ChallengeStatus.accepted ||
                                     c.status == ChallengeStatus.completed;
                if (kDebugMode) {
                  print('🔍 Checking challenge ${c.id}:');
                  print('   challengerId="${c.challengerId}" (length: ${c.challengerId.length})');
                  print('   myId="$myId" (length: ${myId.length})');
                  print('   isChallenger=$isChallenger, isValidStatus=$isValidStatus');
                  if (isChallenger && isValidStatus) {
                    print('✅ Added to sent challenges');
                  }
                }
                return isChallenger && isValidStatus;
              })
              .toList();
          
          if (kDebugMode) {
            print('📥 Received challenges: ${_receivedChallenges.length}');
            for (var c in _receivedChallenges) {
              print('   - ${c.id}: ${c.challengerName} → ${c.opponentName}');
            }
            print('📤 Sent challenges: ${_sentChallenges.length}');
            for (var c in _sentChallenges) {
              print('   - ${c.id}: ${c.challengerName} → ${c.opponentName}');
            }
          }
          
          _isLoadingChallenges = false;
        });
      },
      onError: (error) {
        if (kDebugMode) print('❌ Error listening to challenges: $error');
        if (!mounted) return;
        setState(() => _isLoadingChallenges = false);
      },
    );
  }

  void _listenToFriendRequests() {
    _friendRequestSubscription?.cancel();
    if (_currentUser == null) return;

    _friendRequestSubscription =
        FriendRequestService.watchRequests(_currentUser!.uid).listen((requests) {
      if (!mounted) return;
      setState(() {
        _incomingRequests = requests
            .where((r) => r.receiverId == _currentUser!.uid && r.isPending)
            .toList();
        _sentRequests = requests
            .where((r) => r.senderId == _currentUser!.uid && r.isPending)
            .toList();
        final visibleIds = {
          ..._incomingRequests.map((e) => e.id),
          ..._sentRequests.map((e) => e.id),
        };
        _requestStatusOverrides.removeWhere((key, value) => !visibleIds.contains(key));
      });
    }, onError: (error) {
      if (kDebugMode) {
        print('❌ Error listening to friend requests: $error');
      }
    });
  }

  Future<void> _handleAddFriend() async {
    final input = _friendInputController.text.trim();
    if (input.isEmpty) {
      _showSnack('Nhập email hoặc mã bạn bè để tiếp tục.');
      return;
    }

    if (_currentUser == null) {
      _showSnack('Bạn cần đăng nhập để sử dụng tính năng này.');
      return;
    }

    if (input == _currentUser!.uid) {
      _showSnack('Đây là mã của bạn. Hãy gửi mã này cho bạn bè.');
      return;
    }

    setState(() => _isSubmitting = true);

    final targetUser = await FriendService.findUserByEmailOrId(input);
    if (!mounted) return;

    if (targetUser == null) {
      setState(() => _isSubmitting = false);
      _showSnack('Không tìm thấy người dùng phù hợp. Kiểm tra lại email hoặc mã bạn bè.');
      return;
    }

    final result = await FriendRequestService.sendRequest(
      sender: _currentUser!,
      receiver: targetUser,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    switch (result) {
      case FriendRequestActionResult.sent:
        _friendInputController.clear();
        _showSnack('Đã gửi lời mời kết bạn đến ${targetUser.displayName}', color: Colors.green);
        break;
      case FriendRequestActionResult.alreadyFriends:
        _showSnack('Bạn và ${targetUser.displayName} đã là bạn bè.');
        break;
      case FriendRequestActionResult.alreadyPending:
        _showSnack('Bạn đã gửi lời mời cho ${targetUser.displayName}. Hãy chờ họ phản hồi.');
        break;
      case FriendRequestActionResult.incomingPending:
        _showSnack('${targetUser.displayName} đang chờ bạn chấp nhận lời mời.');
        _tabController.animateTo(0);
        break;
      case FriendRequestActionResult.userNotFound:
        _showSnack('Không tìm thấy người dùng này.');
        break;
      case FriendRequestActionResult.selfNotAllowed:
        _showSnack('Không thể tự thêm chính mình.');
        break;
      case FriendRequestActionResult.failure:
        _showSnack('Không thể gửi lời mời lúc này. Hãy thử lại sau.');
        break;
    }
  }

  Future<void> _handleFriendRequestResponse(FriendRequestModel request, bool accept) async {
    if (_currentUser == null) return;
    final success = await FriendRequestService.respondToRequest(
      request: request,
      userId: _currentUser!.uid,
      accept: accept,
    );
    if (!mounted) return;
    if (success) {
      setState(() {
        _requestStatusOverrides[request.id] = accept ? 'accepted' : 'declined';
      });
      if (accept) {
        await _refreshFriends();
        _friendIds.add(request.senderId);
        _showSnack('Bạn và ${request.senderName} đã trở thành bạn bè!', color: Colors.green);
      } else {
        _showSnack('Đã từ chối lời mời của ${request.senderName}.', color: Colors.orange);
      }
    } else {
      _showSnack('Không thể cập nhật lời mời. Vui lòng thử lại.');
    }
  }

  Future<void> _handleCancelFriendRequest(FriendRequestModel request) async {
    if (_currentUser == null) return;
    final success = await FriendRequestService.cancelRequest(request, userId: _currentUser!.uid);
    if (!mounted) return;
    if (success) {
      setState(() {
        _requestStatusOverrides[request.id] = 'cancelled';
      });
      _showSnack('Đã hủy lời mời gửi cho ${request.receiverName}.', color: Colors.orange);
    } else {
      _showSnack('Không thể hủy lời mời. Vui lòng thử lại.');
    }
  }

  Future<void> _openChallengeSheet(UserModel friend) async {
    if (_currentUser == null) {
      _showSnack('Vui lòng đăng nhập để thách đấu bạn bè.');
      return;
    }

    setState(() => _creatingChallengeFriendId = friend.uid);

    final result = await showChallengeTemplateSheet(
      context: context,
      challenger: _currentUser!,
      opponent: friend,
    );

    if (!mounted) return;
    setState(() => _creatingChallengeFriendId = null);

    if (result == true) {
      _showSnack('Đã gửi thách đấu đến ${friend.displayName}', color: Colors.green);
    }
  }

  Future<void> _handleChallengeAction(ChallengeModel challenge, String status) async {
    if (status == ChallengeStatus.declined) {
      setState(() => _processingChallengeId = challenge.id);
      final success = await ChallengeService.updateChallengeStatus(
        challengeId: challenge.id,
        status: status,
      );
      if (!mounted) return;
      setState(() => _processingChallengeId = null);
      if (success) {
        _showSnack('Bạn đã từ chối lời thách đấu.', color: Colors.orange);
      } else {
        _showSnack('Không thể cập nhật thách đấu. Vui lòng thử lại.');
      }
      return;
    }

    // Accept challenge
    if (status == ChallengeStatus.accepted) {
      setState(() => _processingChallengeId = challenge.id);
      final success = await ChallengeService.updateChallengeStatus(
        challengeId: challenge.id,
        status: status,
      );
      if (!mounted) return;
      setState(() => _processingChallengeId = null);
      
      if (!success) {
        _showSnack('Không thể cập nhật thách đấu. Vui lòng thử lại.');
        return;
      }

      // Launch quiz based on challenge type
      await _launchChallengeQuiz(challenge);
    }
  }

  Future<void> _launchChallengeQuiz(ChallengeModel challenge) async {
    try {
      // Get a random challenge exercise for the challenge type
      final exercise = await ChallengeExerciseService.getRandomExerciseByType(challenge.challengeType);
      
      if (exercise == null) {
        _showSnack('Không tìm thấy bài tập thách đấu. Vui lòng thử lại sau.');
        return;
      }

      if (!mounted) return;

      // Convert challenge exercise to quiz model for compatibility
      final quiz = exercise.toQuizModel();

      // Navigate to quiz with challenge ID
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            quiz: quiz,
            challengeId: challenge.id,
          ),
        ),
      );

      // Refresh challenges after returning
      if (mounted) {
        _listenToChallenges();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Không thể khởi động thách đấu. Vui lòng thử lại.');
      }
    }
  }

  void _showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge with Friends'),
        centerTitle: true,
        bottom: _currentUser != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.people_rounded), text: 'Bạn bè'),
                  Tab(icon: Icon(Icons.mail_outline_rounded), text: 'Lời mời'),
                  Tab(icon: Icon(Icons.sports_kabaddi_rounded), text: 'Thách đấu'),
                ],
              )
            : null,
      ),
      body: _currentUser == null
          ? _buildLoggedOutState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
                _buildChallengesTab(),
              ],
            ),
    );
  }

  Widget _buildLoggedOutState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Đăng nhập để khám phá thử thách cùng bạn bè.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mã bạn bè',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            _currentUser?.uid ?? '-',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chia sẻ mã này với bạn bè để họ có thể kết nối cùng bạn.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriendCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gửi lời mời kết bạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập email hoặc mã bạn bè. Người kia sẽ nhận được lời mời và chọn đồng ý hoặc từ chối.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _friendInputController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleAddFriend(),
            decoration: InputDecoration(
              hintText: 'example@email.com hoặc mã UID',
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: _friendInputController.clear,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleAddFriend,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: Text(_isSubmitting ? 'Đang xử lý...' : 'Gửi lời mời'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return RefreshIndicator(
      onRefresh: _refreshFriends,
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildFriendCodeCard(),
          const SizedBox(height: 16),
          _buildAddFriendCard(),
          const SizedBox(height: 24),
          _buildFriendListHeader(),
          const SizedBox(height: 12),
          if (_isLoadingFriends)
            const Center(child: CircularProgressIndicator())
          else if (_friends.isEmpty)
            _buildEmptyFriendsState()
          else
            ..._friends.map(_buildFriendTile),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const TabBar(
                indicatorColor: Colors.indigo,
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.black54,
                tabs: [
                  Tab(text: 'Đã nhận'),
                  Tab(text: 'Đã gửi'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _buildRequestList(_incomingRequests, true),
                _buildRequestList(_sentRequests, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<FriendRequestModel> requests, bool isIncoming) {
    return RefreshIndicator(
      onRefresh: () async => _listenToFriendRequests(),
      child: requests.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Center(
                    child: Text(
                      isIncoming
                          ? 'Không có lời mời nào đang chờ.'
                          : 'Bạn chưa gửi lời mời nào.',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) =>
                  _buildFriendRequestCard(requests[index], isIncoming),
            ),
    );
  }

  Widget _buildChallengesTab() {
    return RefreshIndicator(
      onRefresh: () async => _listenToChallenges(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildChallengeInbox(),
        ],
      ),
    );
  }

  Widget _buildFriendRequestCard(FriendRequestModel request, bool isIncoming) {
    final otherName = isIncoming ? request.senderName : request.receiverName;
    final subtitle = isIncoming
        ? '$otherName muốn kết bạn với bạn.'
        : 'Đang chờ ${request.receiverName} phản hồi.';
    final overrideStatus = _requestStatusOverrides[request.id];
    final bool showAccepted = overrideStatus == 'accepted';
    final bool showDeclined = overrideStatus == 'declined';
    final bool showCancelled = overrideStatus == 'cancelled';
    final bool showPending = !showAccepted && !showDeclined && !showCancelled && request.isPending;
    final timeAgo = _getTimeAgo(request.createdAt);

    Widget _buildStatusChip(Color color, String text) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.indigo.shade50,
                child: Text(
                  otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (showAccepted)
            _buildStatusChip(Colors.green.shade700, 'Bạn và $otherName đã là bạn bè')
          else if (showDeclined)
            _buildStatusChip(Colors.orange.shade700, 'Bạn đã từ chối lời mời này')
          else if (showCancelled)
            _buildStatusChip(Colors.orange.shade700, 'Bạn đã hủy lời mời')
          else if (isIncoming && showPending)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleFriendRequestResponse(request, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đồng ý'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleFriendRequestResponse(request, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
              ],
            )
          else if (!isIncoming && showPending)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleCancelFriendRequest(request),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hủy lời mời'),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildFriendListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Danh sách bạn bè (${_friends.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: _refreshFriends,
          child: const Text('Làm mới'),
        ),
      ],
    );
  }

  Widget _buildEmptyFriendsState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: const [
          Icon(Icons.groups_2_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Chưa có bạn bè nào',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy thêm bạn bè để bắt đầu thách đấu học tập nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(UserModel friend) {
    final bool isProcessing = _creatingChallengeFriendId == friend.uid;
    final bool canChallenge = friend.totalLessonsCompleted > 0 || friend.totalVocabularyLearned > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.indigo.shade100,
            backgroundImage: friend.profileImageUrl != null && friend.profileImageUrl!.isNotEmpty
                ? NetworkImage(friend.profileImageUrl!)
                : null,
            child: friend.profileImageUrl == null || friend.profileImageUrl!.isEmpty
                ? Text(
                    friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${friend.currentLevel} · ${friend.progressPercentage.toInt()}% progress',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: isProcessing
                ? null
                : () => _openChallengeSheet(friend),
            icon: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    canChallenge ? Icons.sports_kabaddi_rounded : Icons.hourglass_bottom_rounded,
                    size: 18,
                  ),
            label: Text(isProcessing ? 'Đang gửi...' : 'Challenge'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeInbox() {
    if (_isLoadingChallenges) {
      return const Center(child: CircularProgressIndicator());
    }

    // Separate challenges by status
    final pendingReceived = _receivedChallenges.where((c) => c.isPending).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final acceptedReceived = _receivedChallenges.where((c) => c.isAccepted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final completedReceived = _receivedChallenges.where((c) => c.isCompleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    final pendingSent = _sentChallenges.where((c) => c.isPending).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final acceptedSent = _sentChallenges.where((c) => c.isAccepted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final completedSent = _sentChallenges.where((c) => c.isCompleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final hasAnyChallenges = pendingReceived.isNotEmpty || 
                            acceptedReceived.isNotEmpty || 
                            completedReceived.isNotEmpty ||
                            pendingSent.isNotEmpty ||
                            acceptedSent.isNotEmpty ||
                            completedSent.isNotEmpty;

    if (!hasAnyChallenges) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.blueGrey.withOpacity(0.05),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thách đấu nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy gửi lời thách đấu tới bạn bè để bắt đầu!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lời mời đến bạn
        if (pendingReceived.isNotEmpty || acceptedReceived.isNotEmpty || completedReceived.isNotEmpty) ...[
          _buildSectionHeader(
            '📥 Lời mời đến bạn',
            pendingReceived.length + acceptedReceived.length + completedReceived.length,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          if (pendingReceived.isNotEmpty) ...[
            _buildSubSectionHeader('Đang chờ phản hồi', pendingReceived.length),
            const SizedBox(height: 8),
            ...pendingReceived.map((c) => _buildChallengeCard(c, isReceived: true)),
            const SizedBox(height: 16),
          ],
          if (acceptedReceived.isNotEmpty) ...[
            _buildSubSectionHeader('Đã chấp nhận', acceptedReceived.length),
            const SizedBox(height: 8),
            ...acceptedReceived.map((c) => _buildChallengeCard(c, isReceived: true)),
            const SizedBox(height: 16),
          ],
          if (completedReceived.isNotEmpty) ...[
            _buildSubSectionHeader('Kết quả', completedReceived.length),
            const SizedBox(height: 8),
            ...completedReceived.map((c) => _buildChallengeCard(c, isReceived: true)),
            const SizedBox(height: 24),
          ],
        ],

        // Bạn đã gửi
        if (pendingSent.isNotEmpty || acceptedSent.isNotEmpty || completedSent.isNotEmpty) ...[
          _buildSectionHeader(
            '📤 Bạn đã gửi',
            pendingSent.length + acceptedSent.length + completedSent.length,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          if (pendingSent.isNotEmpty) ...[
            _buildSubSectionHeader('Đang chờ phản hồi', pendingSent.length),
            const SizedBox(height: 8),
            ...pendingSent.map((c) => _buildChallengeCard(c, isReceived: false)),
            const SizedBox(height: 16),
          ],
          if (acceptedSent.isNotEmpty) ...[
            _buildSubSectionHeader('Đã chấp nhận', acceptedSent.length),
            const SizedBox(height: 8),
            ...acceptedSent.map((c) => _buildChallengeCard(c, isReceived: false)),
            const SizedBox(height: 16),
          ],
          if (completedSent.isNotEmpty) ...[
            _buildSubSectionHeader('Kết quả', completedSent.length),
            const SizedBox(height: 8),
            ...completedSent.map((c) => _buildChallengeCard(c, isReceived: false)),
          ],
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    // Create a darker version of the color for text
    final darkerColor = Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      1.0,
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkerColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeModel challenge, {required bool isReceived}) {
    final opponentName = isReceived ? challenge.challengerName : challenge.opponentName;
    final timeAgo = _getTimeAgo(challenge.createdAt);
    final isNew = DateTime.now().difference(challenge.createdAt).inHours < 24;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Colors.grey.shade200,
          width: isNew ? 2 : 1,
        ),
        color: Colors.white,
        boxShadow: isNew ? [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            _initialsForName(opponentName),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        if (isNew)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
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
                                  opponentName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(challenge.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getChallengeIcon(challenge.challengeType),
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                challenge.friendlyLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challenge.metadata['description'] ??
                        'Hoàn thành thử thách để xem ai là người chiến thắng!',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons based on status
          if (challenge.isCompleted && challenge.results != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildChallengeResults(challenge),
            ),
          ] else if (challenge.isAccepted) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _processingChallengeId == challenge.id
                      ? null
                      : () => _launchChallengeQuiz(challenge),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Bắt đầu thách đấu'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ] else if (challenge.isPending) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: isReceived
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _processingChallengeId == challenge.id
                                ? null
                                : () => _handleChallengeAction(challenge, ChallengeStatus.accepted),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _processingChallengeId == challenge.id
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Chấp nhận'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _processingChallengeId == challenge.id
                                ? null
                                : () => _handleChallengeAction(challenge, ChallengeStatus.declined),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Từ chối'),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_empty, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đang chờ ${challenge.opponentName} phản hồi...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case ChallengeStatus.pending:
        color = Colors.orange;
        text = 'Chờ phản hồi';
        icon = Icons.pending;
        break;
      case ChallengeStatus.accepted:
        color = Colors.blue;
        text = 'Đã chấp nhận';
        icon = Icons.check_circle_outline;
        break;
      case ChallengeStatus.completed:
        color = Colors.green;
        text = 'Hoàn thành';
        icon = Icons.emoji_events;
        break;
      case ChallengeStatus.declined:
        color = Colors.red;
        text = 'Đã từ chối';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChallengeIcon(String challengeType) {
    switch (challengeType) {
      case 'quiz_rush':
        return Icons.flash_on;
      case 'vocab_duel':
        return Icons.psychology;
      case 'lesson_sprint':
        return Icons.directions_run;
      case 'speed_challenge':
        return Icons.timer;
      case 'accuracy_master':
        return Icons.gps_fixed;
      case 'grammar_battle':
        return Icons.menu_book;
      default:
        return Icons.sports_kabaddi;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String _initialsForName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Widget _buildChallengeResults(ChallengeModel challenge) {
    final myId = _currentUser?.uid ?? '';
    final myResult = myId == challenge.challengerId 
        ? challenge.challengerResult 
        : challenge.opponentResult;
    final opponentResult = myId == challenge.challengerId 
        ? challenge.opponentResult 
        : challenge.challengerResult;
    final opponentName = myId == challenge.challengerId 
        ? challenge.opponentName 
        : challenge.challengerName;

    final myScore = myResult?['score'] as int? ?? 0;
    final opponentScore = opponentResult?['score'] as int? ?? 0;
    final myPercentage = myResult?['percentage'] as double? ?? 0.0;
    final opponentPercentage = opponentResult?['percentage'] as double? ?? 0.0;
    final winnerId = challenge.winnerId;
    final isWinner = winnerId == myId;
    final isTie = winnerId == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner 
            ? Colors.green.shade50 
            : isTie 
                ? Colors.blue.shade50 
                : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner 
              ? Colors.green.shade200 
              : isTie 
                  ? Colors.blue.shade200 
                  : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isWinner 
                    ? Icons.emoji_events_rounded 
                    : isTie 
                        ? Icons.handshake_rounded 
                        : Icons.sentiment_dissatisfied_rounded,
                color: isWinner 
                    ? Colors.amber 
                    : isTie 
                        ? Colors.blue 
                        : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isWinner 
                      ? 'Bạn đã thắng! 🎉' 
                      : isTie 
                          ? 'Hòa! 🤝' 
                          : '$opponentName đã thắng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isWinner 
                        ? Colors.green.shade700 
                        : isTie 
                            ? Colors.blue.shade700 
                            : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$myScore điểm',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${myPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      opponentName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$opponentScore điểm',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${opponentPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


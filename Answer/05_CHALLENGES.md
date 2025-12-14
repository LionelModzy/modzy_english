# 🏆 Chức năng Thách đấu (Challenges) - Chi tiết Kỹ thuật

## 1. Tổng quan Nghiệp vụ

Chức năng Challenges cho phép người dùng:
- **Kết bạn** với người dùng khác qua email hoặc UID
- **Gửi/nhận lời mời kết bạn** (Friend Requests)
- **Gửi thách đấu** cho bạn bè với nhiều loại challenge
- **Nhận và phản hồi** thách đấu (Accept/Decline)
- **Làm bài quiz thách đấu** và so sánh điểm số
- **Xem kết quả** và xác định người thắng

**Các loại challenge:**
- Quiz Rush: Làm quiz nhanh nhất
- Vocab Duel: Thách đấu từ vựng
- Lesson Sprint: Hoàn thành lesson nhanh nhất
- Speed Challenge: Thách đấu tốc độ
- Accuracy Master: Thách đấu độ chính xác
- Grammar Battle: Thách đấu ngữ pháp

---

## 2. Cấu trúc Code và Tổ chức

### 2.1. File Structure

```
lib/features/social/
├── screens/
│   └── friend_challenge_screen.dart   # Màn hình chính
├── widgets/
│   └── challenge_template_sheet.dart  # BottomSheet chọn loại challenge
└── ...

lib/core/services/
├── challenge_service.dart              # Service quản lý challenges
├── challenge_exercise_service.dart     # Service tạo bài tập challenge
├── friend_service.dart                 # Service quản lý bạn bè
└── friend_request_service.dart         # Service quản lý lời mời kết bạn
```

### 2.2. Class Diagram

```
FriendChallengeScreen (ConsumerStatefulWidget)
├── TabController (3 tabs: Bạn bè, Lời mời, Thách đấu)
├── UserModel? _currentUser
├── List<UserModel> _friends
├── List<ChallengeModel> _receivedChallenges
├── List<ChallengeModel> _sentChallenges
├── List<FriendRequestModel> _incomingRequests
├── List<FriendRequestModel> _sentRequests
├── StreamSubscription _challengeSubscription
└── Methods:
    ├── _loadInitialData()
    ├── _refreshFriends()
    ├── _listenToChallenges()
    ├── _handleAddFriend()
    ├── _openChallengeSheet()
    ├── _handleChallengeAction()
    └── _launchChallengeQuiz()
```

---

## 3. UI Components

### 3.1. FriendChallengeScreen với 3 Tabs

**Tab 1: Bạn bè**
- Friend code card: Hiển thị UID của user
- Add friend card: Input email/UID để thêm bạn
- Friends list: Danh sách bạn bè với button "Challenge"

**Tab 2: Lời mời**
- Sub-tabs: "Đã nhận" và "Đã gửi"
- Friend request cards với action buttons:
  - Accept/Decline (cho incoming requests)
  - Cancel (cho sent requests)

**Tab 3: Thách đấu**
- Sections:
  - "📥 Lời mời đến bạn" (Received challenges)
  - "📤 Bạn đã gửi" (Sent challenges)
- Challenge cards với status badges và action buttons

### 3.2. ChallengeTemplateSheet - BottomSheet

**Vị trí code**: `challenge_template_sheet.dart`

**Chức năng:**
- Hiển thị danh sách các loại challenge
- User chọn loại challenge
- Tạo challenge và gửi đến opponent

**UI:**
```
Container (bottom sheet)
├── Text (title: "Chọn loại thách đấu")
├── ListView (challenge templates)
│   └── ListTile (mỗi template)
│       ├── Icon (challenge icon)
│       ├── Column
│       │   ├── Text (template name)
│       │   └── Text (description)
│       └── IconButton (select)
└── Button (Cancel)
```

### 3.3. ChallengeCard

**Vị trí code**: `friend_challenge_screen.dart` dòng 1150-1382

**Cấu trúc:**
```
Container (challenge card)
├── Padding (header)
│   ├── Row
│   │   ├── CircleAvatar (opponent avatar)
│   │   └── Column
│   │       ├── Text (opponent name)
│   │       ├── Text (challenge type)
│   │       └── Text (time ago)
│   └── StatusBadge (pending/accepted/completed)
├── Container (description)
└── Padding (actions)
    ├── Nếu pending (received):
    │   ├── ElevatedButton (Accept)
    │   └── OutlinedButton (Decline)
    ├── Nếu accepted:
    │   └── ElevatedButton (Bắt đầu thách đấu)
    └── Nếu completed:
        └── ChallengeResults (hiển thị kết quả)
```

---

## 4. Thuật toán Quan trọng

### 4.1. Thuật toán Real-time Challenge Updates

**Vị trí code**: `friend_challenge_screen.dart` dòng 98-187

```dart
void _listenToChallenges() {
  _challengeSubscription?.cancel();
  if (_currentUser == null) return;

  _challengeSubscription = ChallengeService.watchChallenges(
    _currentUser!.uid
  ).listen(
    (challenges) {
      if (!mounted) return;
      final myId = _currentUser!.uid;
      
      setState(() {
        // Received challenges: opponentId == myId
        _receivedChallenges = challenges
          .where((c) => 
            c.opponentId == myId &&
            (c.status == ChallengeStatus.pending ||
             c.status == ChallengeStatus.accepted ||
             c.status == ChallengeStatus.completed)
          )
          .toList();
        
        // Sent challenges: challengerId == myId
        _sentChallenges = challenges
          .where((c) => 
            c.challengerId == myId &&
            (c.status == ChallengeStatus.pending ||
             c.status == ChallengeStatus.accepted ||
             c.status == ChallengeStatus.completed)
          )
          .toList();
      });
    },
    onError: (error) {
      print('Error listening to challenges: $error');
    },
  );
}
```

**Độ phức tạp**: O(n) với n là số challenges

### 4.2. Thuật toán Tạo Challenge

**Vị trí code**: `challenge_service.dart`

```dart
static Future<ChallengeModel?> createChallenge({
  required String challengerId,
  required String opponentId,
  required String challengeType,
  Map<String, dynamic>? metadata,
}) async {
  try {
    // Tạo challenge document
    final challenge = ChallengeModel(
      id: '',
      challengerId: challengerId,
      opponentId: opponentId,
      challengeType: challengeType,
      status: ChallengeStatus.pending,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Lưu vào Firebase
    final docRef = await _firestore
      .collection('challenges')
      .add(challenge.toMap());
    
    // Update challenge ID
    await docRef.update({'id': docRef.id});
    
    return challenge.copyWith(id: docRef.id);
  } catch (e) {
    print('Error creating challenge: $e');
    return null;
  }
}
```

### 4.3. Thuật toán Xử lý Challenge Action

**Vị trí code**: `friend_challenge_screen.dart` dòng 340-375

```dart
Future<void> _handleChallengeAction(
  ChallengeModel challenge, 
  String status
) async {
  if (status == ChallengeStatus.declined) {
    // Từ chối challenge
    final success = await ChallengeService.updateChallengeStatus(
      challengeId: challenge.id,
      status: status,
    );
    if (success) {
      _showSnack('Bạn đã từ chối lời thách đấu.');
    }
    return;
  }

  // Accept challenge
  if (status == ChallengeStatus.accepted) {
    final success = await ChallengeService.updateChallengeStatus(
      challengeId: challenge.id,
      status: status,
    );
    
    if (success) {
      // Launch quiz
      await _launchChallengeQuiz(challenge);
    }
  }
}
```

### 4.4. Thuật toán Launch Challenge Quiz

**Vị trí code**: `friend_challenge_screen.dart` dòng 377-411

```dart
Future<void> _launchChallengeQuiz(ChallengeModel challenge) async {
  try {
    // Lấy random exercise theo challenge type
    final exercise = await ChallengeExerciseService.getRandomExerciseByType(
      challenge.challengeType
    );
    
    if (exercise == null) {
      _showSnack('Không tìm thấy bài tập thách đấu.');
      return;
    }

    // Convert exercise to quiz model
    final quiz = exercise.toQuizModel();

    // Navigate to quiz với challengeId
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          quiz: quiz,
          challengeId: challenge.id,  // Pass challenge ID
        ),
      ),
    );

    // Refresh challenges sau khi quay lại
    if (mounted) {
      _listenToChallenges();
    }
  } catch (e) {
    _showSnack('Không thể khởi động thách đấu.');
  }
}
```

### 4.5. Thuật toán Tính Winner

**Vị trí code**: `challenge_service.dart`

```dart
static Future<void> updateChallengeResult({
  required String challengeId,
  required String userId,
  required int score,
  required double percentage,
}) async {
  final challengeRef = _firestore.collection('challenges').doc(challengeId);
  final challengeDoc = await challengeRef.get();
  
  if (!challengeDoc.exists) return;
  
  final challengeData = challengeDoc.data()!;
  final isChallenger = challengeData['challengerId'] == userId;
  
  // Update result
  if (isChallenger) {
    await challengeRef.update({
      'challengerResult': {
        'score': score,
        'percentage': percentage,
        'completedAt': FieldValue.serverTimestamp(),
      },
    });
  } else {
    await challengeRef.update({
      'opponentResult': {
        'score': score,
        'percentage': percentage,
        'completedAt': FieldValue.serverTimestamp(),
      },
    });
  }
  
  // Check if both completed
  final updatedDoc = await challengeRef.get();
  final updatedData = updatedDoc.data()!;
  
  if (updatedData['challengerResult'] != null &&
      updatedData['opponentResult'] != null) {
    // Both completed - determine winner
    final challengerScore = updatedData['challengerResult']['score'] as int;
    final opponentScore = updatedData['opponentResult']['score'] as int;
    
    String? winnerId;
    if (challengerScore > opponentScore) {
      winnerId = challengeData['challengerId'] as String;
    } else if (opponentScore > challengerScore) {
      winnerId = challengeData['opponentId'] as String;
    } else {
      // Tie
      winnerId = null;
    }
    
    await challengeRef.update({
      'status': ChallengeStatus.completed,
      'winnerId': winnerId,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

**Logic:**
- So sánh điểm số của challenger và opponent
- Nếu challengerScore > opponentScore → challenger thắng
- Nếu opponentScore > challengerScore → opponent thắng
- Nếu bằng nhau → Hòa (winnerId = null)

---

## 5. Flow Hoạt động

### 5.1. Flow Kết bạn

```
User vào tab "Bạn bè"
  ↓
User nhập email/UID vào input
  ↓
_handleAddFriend()
  ↓
FriendService.findUserByEmailOrId(input)
  ↓
FriendRequestService.sendRequest(sender, receiver)
  ↓
Kiểm tra:
  - Đã là bạn bè? → Show message
  - Đã có request pending? → Show message
  - OK → Tạo friend request
  ↓
Receiver nhận notification
  ↓
Receiver vào tab "Lời mời"
  ↓
Receiver bấm "Đồng ý"
  ↓
FriendRequestService.respondToRequest(accept: true)
  ↓
Tạo friendship trong Firebase
  ↓
Cả 2 user đều có thể thấy nhau trong friends list
```

### 5.2. Flow Gửi Thách đấu

```
User vào tab "Bạn bè"
  ↓
User tap "Challenge" button của một friend
  ↓
_openChallengeSheet(friend)
  ↓
showChallengeTemplateSheet()
  ↓
User chọn loại challenge
  ↓
ChallengeService.createChallenge()
  ↓
Tạo challenge document trong Firebase
  ↓
Opponent nhận challenge (real-time update)
  ↓
Opponent vào tab "Thách đấu"
  ↓
Opponent thấy challenge trong "📥 Lời mời đến bạn"
```

### 5.3. Flow Làm bài Thách đấu

```
Opponent nhận challenge
  ↓
Opponent bấm "Chấp nhận"
  ↓
_handleChallengeAction(challenge, ChallengeStatus.accepted)
  ↓
ChallengeService.updateChallengeStatus(status: accepted)
  ↓
_launchChallengeQuiz(challenge)
  ↓
ChallengeExerciseService.getRandomExerciseByType()
  ↓
Convert exercise to QuizModel
  ↓
Navigate to QuizScreen với challengeId
  ↓
User làm quiz bình thường
  ↓
Khi submit quiz:
  - QuizScreen gọi ChallengeService.updateChallengeResult()
  - Lưu score và percentage
  - Check nếu cả 2 đã làm → Tính winner
  ↓
Navigate back
  ↓
Refresh challenges list
  ↓
Hiển thị kết quả trong challenge card
```

### 5.4. Flow Xem Kết quả

```
Challenge completed (cả 2 đã làm)
  ↓
ChallengeService tính winner
  ↓
Update challenge status = completed
  ↓
User vào tab "Thách đấu"
  ↓
Challenge card hiển thị results section
  ↓
_buildChallengeResults(challenge)
  ↓
Hiển thị:
  - Winner badge (nếu có)
  - Score của cả 2 người
  - Percentage của cả 2 người
```

---

## 6. Services và Data Flow

### 6.1. ChallengeService

**Chức năng:**
- `createChallenge()`: Tạo challenge mới
- `watchChallenges(userId)`: Stream real-time challenges
- `updateChallengeStatus()`: Cập nhật status (pending → accepted/declined)
- `updateChallengeResult()`: Lưu kết quả làm bài
- `getAllChallengesForUser(userId)`: Lấy tất cả challenges

**Firebase Query:**
```dart
// Watch challenges (real-time)
Stream<List<ChallengeModel>> watchChallenges(String userId) {
  return _firestore
    .collection('challenges')
    .where('challengerId', isEqualTo: userId)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => ChallengeModel.fromFirestore(doc))
      .toList()
    );
}
```

### 6.2. FriendRequestService

**Chức năng:**
- `sendRequest()`: Gửi lời mời kết bạn
- `watchRequests(userId)`: Stream real-time requests
- `respondToRequest()`: Phản hồi request (accept/decline)
- `cancelRequest()`: Hủy request đã gửi

**Data structure:**
```
friend_requests/{requestId}
{
  senderId: string,
  receiverId: string,
  status: string ('pending', 'accepted', 'declined'),
  createdAt: timestamp,
  respondedAt: timestamp?,
}
```

### 6.3. FriendService

**Chức năng:**
- `getFriends(userId)`: Lấy danh sách bạn bè
- `findUserByEmailOrId(input)`: Tìm user theo email hoặc UID
- `addFriend(userId, friendId)`: Thêm bạn bè

**Data structure:**
```
users/{userId}
{
  friends: [friendId1, friendId2, ...]
}
```

---

## 7. Best Practices

### 7.1. Real-time Updates
- **StreamSubscription**: Sử dụng để lắng nghe real-time changes
- **Cancel subscription**: Luôn cancel khi dispose để tránh memory leak
- **Error handling**: Handle onError trong stream

### 7.2. State Management
- **Riverpod**: Sử dụng ConsumerStatefulWidget cho state management
- **Local state**: setState() cho UI state
- **Server state**: Stream từ Firebase

### 7.3. Error Handling
```dart
try {
  final success = await ChallengeService.updateChallengeStatus(...);
  if (success) {
    _showSnack('Đã cập nhật thách đấu.');
  } else {
    _showSnack('Không thể cập nhật. Vui lòng thử lại.');
  }
} catch (e) {
  _showSnack('Lỗi: $e');
}
```

---

## 8. Tóm tắt

**Các điểm chính:**
1. **3 tabs**: Bạn bè, Lời mời, Thách đấu
2. **Real-time updates**: StreamSubscription cho challenges và requests
3. **Challenge flow**: Create → Accept → Complete → Determine winner
4. **Friend system**: Request → Accept → Friendship

**Các thuật toán quan trọng:**
- Real-time listening: O(n) - n là số challenges
- Winner calculation: O(1) - so sánh điểm số
- Challenge creation: O(1) - tạo document

**UI Components:**
- FriendChallengeScreen với TabController (3 tabs)
- ChallengeTemplateSheet (BottomSheet)
- ChallengeCard với status badges
- FriendRequestCard với action buttons



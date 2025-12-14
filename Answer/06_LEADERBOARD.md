# 🏅 Chức năng Bảng xếp hạng (Leaderboard) - Chi tiết Kỹ thuật

## 1. Tổng quan Nghiệp vụ

Chức năng Leaderboard cho phép người dùng:
- **Xem bảng xếp hạng** theo nhiều tiêu chí và thời gian
- **Tìm kiếm người dùng** trong leaderboard
- **Xem thứ hạng của mình** (current user rank)
- **Gửi lời mời kết bạn** trực tiếp từ leaderboard
- **Gửi thách đấu** cho người dùng khác

**Các tiêu chí xếp hạng:**
- Lessons: Số bài học đã hoàn thành
- Vocabulary: Số từ vựng đã học
- Progress: Tiến độ học tập tổng quát
- Level: Level hiện tại
- Overall: Tổng hợp tất cả

**Các khoảng thời gian:**
- Daily: Hôm nay
- Weekly: Tuần này
- Monthly: Tháng này
- Yearly: Năm nay
- All: Tất cả thời gian

---

## 2. Cấu trúc Code và Tổ chức

### 2.1. File Structure

```
lib/features/leaderboard/
├── screens/
│   └── leaderboard_screen.dart   # Màn hình chính
└── ...

lib/core/services/
├── leaderboard_service.dart      # Service tính toán và lấy leaderboard
└── friend_request_service.dart   # Service quản lý friend requests
```

### 2.2. Class Diagram

```
LeaderboardScreen (ConsumerStatefulWidget)
├── TabController _categoryTabController (5 tabs)
├── TabController _periodTabController (5 tabs)
├── String _currentCategory
├── String _currentPeriod
├── List<UserModel> _leaderboard
├── int _currentUserRank
├── UserModel? _currentUser
├── String _searchQuery
└── Methods:
    ├── _loadLeaderboard()
    ├── _loadUserData()
    ├── _buildLeaderboardItem()
    └── _buildRankBadge()
```

---

## 3. UI Components

### 3.1. LeaderboardScreen với Dual TabControllers

**Category Tabs:**
- Lessons
- Vocabulary
- Progress
- Level
- Overall

**Period Tabs:**
- Daily
- Weekly
- Monthly
- Yearly
- All

**Layout:**
```
Scaffold
├── AppBar
│   └── SearchButton
├── TabBar (Category tabs)
├── TabBar (Period tabs)
└── Body
    ├── SearchBar (nếu có search)
    ├── CurrentUserRankCard (nếu user có rank)
    └── ListView
        └── LeaderboardItem (mỗi user)
```

### 3.2. CurrentUserRankCard

**Vị trí code**: `leaderboard_screen.dart`

**Hiển thị:**
- Rank của current user
- User info (avatar, name, level)
- Score/statistics
- Highlight với màu đặc biệt

### 3.3. LeaderboardItem

**Vị trí code**: `leaderboard_screen.dart`

**Cấu trúc:**
```
Container (leaderboard item)
├── Row
│   ├── RankBadge (top 3 có icon đặc biệt)
│   ├── CircleAvatar (user avatar)
│   ├── Expanded
│   │   ├── Text (user name)
│   │   └── Text (statistics)
│   └── Row (actions)
│       ├── IconButton (Add friend)
│       └── IconButton (Challenge)
```

**Rank Badge:**
- Top 1: 🥇 Gold với gradient
- Top 2: 🥈 Silver
- Top 3: 🥉 Bronze
- Còn lại: Số thứ tự

---

## 4. Thuật toán Quan trọng

### 4.1. Thuật toán Tính Leaderboard

**Vị trí code**: `leaderboard_service.dart`

```dart
static Future<List<UserModel>> getLeaderboardByPeriod({
  required String sortBy,
  required String timePeriod,
  int limit = 100,
}) async {
  try {
    // Tính start date dựa trên timePeriod
    DateTime? startDate;
    final now = DateTime.now();
    
    switch (timePeriod) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'all':
      default:
        startDate = null;
    }
    
    // Query users
    Query query = _firestore.collection('users');
    
    // Filter active users
    query = query.where('isActive', isEqualTo: true);
    
    // Order by sortBy field
    switch (sortBy) {
      case 'lessons':
        query = query.orderBy('totalLessonsCompleted', descending: true);
        break;
      case 'vocabulary':
        query = query.orderBy('totalVocabularyLearned', descending: true);
        break;
      case 'progress':
        query = query.orderBy('progressPercentage', descending: true);
        break;
      case 'level':
        query = query.orderBy('currentLevel', descending: true);
        break;
      case 'overall':
        // Tính overall score
        // Có thể cần aggregation hoặc computed field
        query = query.orderBy('overallScore', descending: true);
        break;
    }
    
    query = query.limit(limit);
    
    final snapshot = await query.get();
    
    // Filter by time period nếu cần
    List<UserModel> users = snapshot.docs
      .map((doc) => UserModel.fromFirestore(doc))
      .toList();
    
    if (startDate != null) {
      // Filter users based on activity in time period
      // Cần check learning_progress collection
      users = await _filterByTimePeriod(users, startDate, sortBy);
    }
    
    return users;
  } catch (e) {
    print('Error getting leaderboard: $e');
    return [];
  }
}
```

**Độ phức tạp**: O(n log n) - sorting + O(n) - filtering

### 4.2. Thuật toán Tính User Rank

**Vị trí code**: `leaderboard_service.dart`

```dart
static Future<int> getUserRank({
  required String userId,
  required String sortBy,
  required String timePeriod,
}) async {
  try {
    final leaderboard = await getLeaderboardByPeriod(
      sortBy: sortBy,
      timePeriod: timePeriod,
      limit: 1000, // Lấy nhiều hơn để tìm rank
    );
    
    // Tìm index của user trong leaderboard
    final userIndex = leaderboard.indexWhere((user) => user.uid == userId);
    
    if (userIndex == -1) {
      // User không có trong top 1000
      return -1;
    }
    
    return userIndex + 1; // Rank bắt đầu từ 1
  } catch (e) {
    print('Error getting user rank: $e');
    return -1;
  }
}
```

**Độ phức tạp**: O(n) với n là số users trong leaderboard

### 4.3. Thuật toán Tìm kiếm

**Vị trí code**: `leaderboard_screen.dart`

```dart
List<UserModel> get _filteredLeaderboard {
  if (_searchQuery.isEmpty) {
    return _leaderboard;
  }
  
  return _leaderboard.where((user) {
    final query = _searchQuery.toLowerCase();
    return user.displayName.toLowerCase().contains(query) ||
           user.email.toLowerCase().contains(query);
  }).toList();
}
```

**Độ phức tạp**: O(n) với n là số users

---

## 5. Flow Hoạt động

### 5.1. Flow Xem Leaderboard

```
User mở LeaderboardScreen
  ↓
_loadUserData()
  ↓
Load current user info
  ↓
_loadLeaderboard()
  ↓
LeaderboardService.getLeaderboardByPeriod()
  ↓
Firebase query với sortBy và timePeriod
  ↓
setState() → Hiển thị ListView
  ↓
User có thể:
  - Thay đổi category tab → Reload với sortBy mới
  - Thay đổi period tab → Reload với timePeriod mới
  - Search → Filter leaderboard
```

### 5.2. Flow Xem Rank của Mình

```
User scroll leaderboard
  ↓
Nếu current user có trong leaderboard:
  - Highlight current user's item
  - Hiển thị rank badge
Nếu không:
  - Hiển thị CurrentUserRankCard ở đầu
  - Load rank từ LeaderboardService.getUserRank()
```

### 5.3. Flow Gửi Friend Request từ Leaderboard

```
User tap "Add friend" button trong leaderboard item
  ↓
_checkFriendStatus(user)
  ↓
Nếu chưa là bạn:
  - FriendRequestService.sendRequest()
  - Show snackbar "Đã gửi lời mời"
Nếu đã là bạn:
  - Show snackbar "Đã là bạn bè"
Nếu đã có request pending:
  - Show snackbar "Đã gửi lời mời trước đó"
```

### 5.4. Flow Gửi Challenge từ Leaderboard

```
User tap "Challenge" button trong leaderboard item
  ↓
_openChallengeSheet(user)
  ↓
showChallengeTemplateSheet()
  ↓
User chọn loại challenge
  ↓
ChallengeService.createChallenge()
  ↓
Tạo challenge và gửi đến opponent
```

---

## 6. Services và Data Flow

### 6.1. LeaderboardService

**Chức năng:**
- `getLeaderboardByPeriod()`: Lấy leaderboard theo tiêu chí và thời gian
- `getUserRank()`: Tính rank của một user
- `getTopUsers()`: Lấy top N users

**Firebase Query:**
```dart
// Query với sortBy
final query = _firestore
  .collection('users')
  .where('isActive', isEqualTo: true)
  .orderBy('totalLessonsCompleted', descending: true)
  .limit(100);
```

### 6.2. Data Structure

**User Model (cho leaderboard):**
```dart
{
  uid: string,
  displayName: string,
  email: string,
  profileImageUrl: string?,
  totalLessonsCompleted: number,
  totalVocabularyLearned: number,
  progressPercentage: number,
  currentLevel: number,
  overallScore: number? (computed),
}
```

---

## 7. Best Practices

### 7.1. Performance
- **Limit results**: Chỉ load top 100 users
- **Caching**: Cache leaderboard data nếu có thể
- **Lazy loading**: Load more khi scroll đến cuối

### 7.2. UX
- **Visual hierarchy**: Top 3 có design đặc biệt
- **Current user highlight**: Highlight user của mình
- **Smooth scrolling**: Optimize ListView performance

### 7.3. Error Handling
```dart
try {
  final leaderboard = await LeaderboardService.getLeaderboardByPeriod(...);
  setState(() {
    _leaderboard = leaderboard;
    _isLoading = false;
  });
} catch (e) {
  setState(() {
    _isLoading = false;
    _loadErrorMessage = 'Lỗi tải leaderboard: $e';
  });
}
```

---

## 8. Tóm tắt

**Các điểm chính:**
1. **Dual TabControllers**: Category và Period tabs
2. **Multiple sort criteria**: Lessons, Vocabulary, Progress, Level, Overall
3. **Time period filtering**: Daily, Weekly, Monthly, Yearly, All
4. **Social features**: Add friend và Challenge từ leaderboard

**Các thuật toán quan trọng:**
- Leaderboard calculation: O(n log n) - sorting
- Rank calculation: O(n) - linear search
- Search filtering: O(n) - linear filter

**UI Components:**
- LeaderboardScreen với dual TabControllers
- CurrentUserRankCard
- LeaderboardItem với rank badges
- Top 3 special design (Gold, Silver, Bronze)



# 📊 Chức năng Lịch sử Học tập (Learning History) - Chi tiết Kỹ thuật

## 1. Tổng quan Nghiệp vụ

Chức năng Learning History cho phép người dùng:
- **Xem lịch sử học tập** theo 3 loại: Lessons, Quizzes, Vocabulary Practice
- **Lọc và sắp xếp** theo ngày, điểm số, tiêu đề
- **Tìm kiếm** trong lịch sử
- **Xem chi tiết** từng hoạt động
- **Phân tích tiến độ** học tập theo thời gian

**3 tabs:**
1. **Lessons**: Lịch sử học bài
2. **Quizzes**: Lịch sử làm quiz
3. **Vocabulary**: Lịch sử luyện tập từ vựng

---

## 2. Cấu trúc Code và Tổ chức

### 2.1. File Structure

```
lib/features/profile/
├── screens/
│   └── learning_history_screen.dart  # Màn hình chính
└── ...

lib/core/services/
├── learning_progress_service.dart    # Service lấy lịch sử
├── quiz_service.dart                 # Service lấy quiz history
└── vocabulary_service.dart          # Service lấy vocabulary history
```

### 2.2. Class Diagram

```
LearningHistoryScreen (StatefulWidget)
├── TabController (3 tabs: Lessons, Quizzes, Vocabulary)
├── List<Map<String, dynamic>> _lessonHistory
├── List<Map<String, dynamic>> _quizHistory
├── List<Map<String, dynamic>> _vocabularyHistory
├── String _sortBy ('date', 'score', 'title')
├── bool _sortAscending
├── DateTime? _filterStartDate
├── DateTime? _filterEndDate
└── Methods:
    ├── _loadAllData()
    ├── _loadLessonHistory()
    ├── _loadQuizHistory()
    ├── _loadVocabularyHistory()
    ├── _filterAndSort()
    └── _buildHistoryItem()
```

---

## 3. UI Components

### 3.1. LearningHistoryScreen với 3 Tabs

**Tab 1: Lessons**
- ListView với lesson history items
- Mỗi item hiển thị:
  - Lesson title
  - Completion percentage
  - Time spent
  - Date completed

**Tab 2: Quizzes**
- ListView với quiz history items
- Mỗi item hiển thị:
  - Quiz title
  - Score và percentage
  - Pass/Fail badge
  - Date completed

**Tab 3: Vocabulary**
- ListView với vocabulary practice history items
- Mỗi item hiển thị:
  - Practice type (Flashcard, Multiple Choice, etc.)
  - Accuracy percentage
  - Words practiced count
  - Date completed

### 3.2. History Item Card

**Vị trí code**: `learning_history_screen.dart`

**Cấu trúc:**
```
Container (history item)
├── Row
│   ├── Icon (type icon với màu)
│   ├── Expanded
│   │   ├── Text (title)
│   │   ├── Text (subtitle/description)
│   │   └── Row (stats)
│   │       ├── Score/Percentage badge
│   │       └── Time badge
│   └── Column
│       ├── Text (date)
│       └── IconButton (view details)
```

### 3.3. Filter và Sort UI

**Filter:**
- Date range picker: Chọn start date và end date
- Clear filters button

**Sort:**
- Dropdown: Chọn sortBy (date, score, title)
- Toggle: Ascending/Descending

---

## 4. Thuật toán Quan trọng

### 4.1. Thuật toán Load Lesson History

**Vị trí code**: `learning_history_screen.dart` dòng 77-135

```dart
Future<void> _loadLessonHistory() async {
  try {
    setState(() {
      _isLoadingLessons = true;
      _lessonError = null;
    });

    // Get lesson progress từ Firebase
    final allHistory = await LearningProgressService.getDetailedLearningHistory(
      limit: 20
    );
    
    // Filter for lessons only
    final lessonHistory = allHistory
      .where((activity) => activity['type'] == 'lesson')
      .toList();

    // Fetch actual lesson titles từ lessons collection
    final lessonIds = lessonHistory
      .map((lesson) => lesson['lessonId'] as String)
      .where((id) => id.isNotEmpty)
      .toList();
    
    final lessonTitles = <String, String>{};
    
    if (lessonIds.isNotEmpty) {
      final lessonsSnapshot = await FirebaseFirestore.instance
        .collection('lessons')
        .where(FieldPath.documentId, whereIn: lessonIds)
        .get();
      
      for (var doc in lessonsSnapshot.docs) {
        final data = doc.data();
        lessonTitles[doc.id] = data['title'] ?? 'Unknown Lesson';
      }
    }

    // Update lesson titles
    for (var lesson in lessonHistory) {
      final lessonId = lesson['lessonId'] as String;
      if (lessonId.isNotEmpty && lessonTitles.containsKey(lessonId)) {
        lesson['title'] = lessonTitles[lessonId]!;
      }
    }

    setState(() {
      _lessonHistory = lessonHistory;
      _filteredLessonHistory = lessonHistory;
      _isLoadingLessons = false;
    });
  } catch (e) {
    setState(() {
      _lessonError = 'Failed to load lesson history: $e';
      _isLoadingLessons = false;
    });
  }
}
```

**Độ phức tạp**: O(n + m) với n là số history items, m là số lessons

### 4.2. Thuật toán Load Quiz History

**Vị trí code**: `learning_history_screen.dart` dòng 137-200

```dart
Future<void> _loadQuizHistory() async {
  try {
    setState(() {
      _isLoadingQuizzes = true;
      _quizError = null;
    });

    final userId = widget.user?.uid;
    if (userId == null) {
      setState(() {
        _quizHistory = [];
        _isLoadingQuizzes = false;
      });
      return;
    }

    // Get quiz results từ quiz_results collection
    final results = await QuizService.getUserQuizResults();
    
    // Fetch quiz titles
    final quizIds = results.map((r) => r.quizId).toSet().toList();
    final quizTitles = <String, String>{};
    
    if (quizIds.isNotEmpty) {
      final quizzesSnapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .where(FieldPath.documentId, whereIn: quizIds)
        .get();
      
      for (var doc in quizzesSnapshot.docs) {
        final data = doc.data();
        quizTitles[doc.id] = data['title'] ?? 'Unknown Quiz';
      }
    }

    // Convert results to history format
    final quizHistory = results.map((result) {
      return {
        'id': result.id,
        'quizId': result.quizId,
        'title': quizTitles[result.quizId] ?? 'Unknown Quiz',
        'score': result.score,
        'totalPoints': result.totalPoints,
        'percentage': result.percentage,
        'passed': result.passed,
        'timeTaken': result.timeTaken,
        'completedAt': result.completedAt,
        'type': 'quiz',
      };
    }).toList();

    setState(() {
      _quizHistory = quizHistory;
      _filteredQuizHistory = quizHistory;
      _isLoadingQuizzes = false;
    });
  } catch (e) {
    setState(() {
      _quizError = 'Failed to load quiz history: $e';
      _isLoadingQuizzes = false;
    });
  }
}
```

**Độ phức tạp**: O(n + m) với n là số results, m là số quizzes

### 4.3. Thuật toán Filter và Sort

**Vị trí code**: `learning_history_screen.dart`

```dart
void _filterAndSort() {
  List<Map<String, dynamic>> filtered = List.from(_lessonHistory); // hoặc _quizHistory, _vocabularyHistory
  
  // 1. Filter by date range
  if (_filterStartDate != null) {
    filtered = filtered.where((item) {
      final completedAt = item['completedAt'] as DateTime?;
      if (completedAt == null) return false;
      return completedAt.isAfter(_filterStartDate!) || 
             completedAt.isAtSameMomentAs(_filterStartDate!);
    }).toList();
  }
  
  if (_filterEndDate != null) {
    filtered = filtered.where((item) {
      final completedAt = item['completedAt'] as DateTime?;
      if (completedAt == null) return false;
      return completedAt.isBefore(_filterEndDate!) || 
             completedAt.isAtSameMomentAs(_filterEndDate!);
    }).toList();
  }
  
  // 2. Sort
  filtered.sort((a, b) {
    int comparison = 0;
    
    switch (_sortBy) {
      case 'date':
        final dateA = a['completedAt'] as DateTime? ?? DateTime(1970);
        final dateB = b['completedAt'] as DateTime? ?? DateTime(1970);
        comparison = dateA.compareTo(dateB);
        break;
        
      case 'score':
        final scoreA = a['percentage'] as double? ?? 0.0;
        final scoreB = b['percentage'] as double? ?? 0.0;
        comparison = scoreA.compareTo(scoreB);
        break;
        
      case 'title':
        final titleA = (a['title'] as String? ?? '').toLowerCase();
        final titleB = (b['title'] as String? ?? '').toLowerCase();
        comparison = titleA.compareTo(titleB);
        break;
    }
    
    return _sortAscending ? comparison : -comparison;
  });
  
  setState(() {
    _filteredLessonHistory = filtered; // hoặc _filteredQuizHistory, _filteredVocabularyHistory
  });
}
```

**Độ phức tạp**: O(n log n) - sorting + O(n) - filtering

### 4.4. Thuật toán Search

**Vị trí code**: `learning_history_screen.dart`

```dart
void _onSearchChanged(String query) {
  setState(() {
    _searchQuery = query;
  });
  
  _applySearch();
}

void _applySearch() {
  List<Map<String, dynamic>> filtered = List.from(_filteredLessonHistory); // hoặc quiz/vocab
  
  if (_searchQuery.isNotEmpty) {
    filtered = filtered.where((item) {
      final title = (item['title'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();
  }
  
  setState(() {
    _displayedHistory = filtered;
  });
}
```

**Độ phức tạp**: O(n) với n là số history items

---

## 5. Flow Hoạt động

### 5.1. Flow Xem Lịch sử

```
User mở LearningHistoryScreen
  ↓
initState() → _loadAllData()
  ↓
Parallel loading:
  - _loadLessonHistory()
  - _loadQuizHistory()
  - _loadVocabularyHistory()
  ↓
Mỗi method:
  - Query Firebase
  - Fetch titles từ collections
  - Convert to history format
  - setState() → Update UI
  ↓
User xem 3 tabs:
  - Lessons tab → Hiển thị _filteredLessonHistory
  - Quizzes tab → Hiển thị _filteredQuizHistory
  - Vocabulary tab → Hiển thị _filteredVocabularyHistory
```

### 5.2. Flow Filter và Sort

```
User chọn filter/sort options
  ↓
_filterAndSort()
  ↓
1. Filter by date range (nếu có)
2. Sort theo sortBy và sortAscending
  ↓
setState() → Update filtered list
  ↓
UI tự động rebuild với filtered data
```

### 5.3. Flow Tìm kiếm

```
User nhập vào search field
  ↓
_onSearchChanged(query)
  ↓
_applySearch()
  ↓
Filter history items theo title
  ↓
setState() → Update displayed list
```

### 5.4. Flow Xem Chi tiết

```
User tap vào history item
  ↓
Navigate to detail screen:
  - Lesson → LessonDetailScreen
  - Quiz → QuizScreen (review mode)
  - Vocabulary → VocabularyDetailScreen
  ↓
Hiển thị thông tin chi tiết
```

---

## 6. Services và Data Flow

### 6.1. LearningProgressService

**Chức năng:**
- `getDetailedLearningHistory(limit)`: Lấy lịch sử chi tiết
- `getLessonProgress(lessonId)`: Lấy tiến độ của một lesson
- `getLearningStats()`: Lấy thống kê tổng quát

**Firebase Query:**
```dart
// Get learning history
final querySnapshot = await _firestore
  .collection('users')
  .doc(userId)
  .collection('learning_progress')
  .orderBy('completedAt', descending: true)
  .limit(limit)
  .get();
```

### 6.2. QuizService

**Chức năng:**
- `getUserQuizResults()`: Lấy tất cả quiz results của user

**Firebase Query:**
```dart
final querySnapshot = await _firestore
  .collection('quiz_results')
  .where('userId', isEqualTo: userId)
  .orderBy('completedAt', descending: true)
  .get();
```

### 6.3. Data Structure

**Lesson History Item:**
```dart
{
  id: string,
  lessonId: string,
  title: string,
  type: 'lesson',
  completionPercentage: number,
  timeSpent: number (seconds),
  completedAt: timestamp,
}
```

**Quiz History Item:**
```dart
{
  id: string,
  quizId: string,
  title: string,
  type: 'quiz',
  score: number,
  totalPoints: number,
  percentage: number,
  passed: boolean,
  timeTaken: number (seconds),
  completedAt: timestamp,
}
```

**Vocabulary History Item:**
```dart
{
  id: string,
  type: 'vocabulary',
  practiceType: string ('flashcard', 'multiple_choice', etc.),
  accuracy: number,
  wordsPracticed: number,
  timeSpent: number (seconds),
  completedAt: timestamp,
}
```

---

## 7. Best Practices

### 7.1. Performance
- **Limit results**: Chỉ load 20-50 items đầu tiên
- **Lazy loading**: Load more khi scroll đến cuối
- **Caching**: Cache history data nếu có thể

### 7.2. UX
- **Loading states**: Hiển thị loading indicator
- **Empty states**: Hiển thị message khi không có data
- **Error handling**: Hiển thị error message và retry button

### 7.3. Data Consistency
- **Title fetching**: Fetch titles từ collections để đảm bảo accuracy
- **Date formatting**: Format date theo locale
- **Null safety**: Handle null values properly

---

## 8. Tóm tắt

**Các điểm chính:**
1. **3 tabs**: Lessons, Quizzes, Vocabulary
2. **Filter và Sort**: Theo date, score, title
3. **Search**: Tìm kiếm trong history
4. **Detail view**: Xem chi tiết từng hoạt động

**Các thuật toán quan trọng:**
- Load history: O(n + m) - n items + m titles
- Filter and sort: O(n log n)
- Search: O(n)

**UI Components:**
- LearningHistoryScreen với TabController (3 tabs)
- HistoryItemCard với stats và badges
- Filter và Sort UI
- SearchBar



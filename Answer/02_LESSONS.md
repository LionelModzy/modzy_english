# 📖 Chức năng Bài học (Lessons) - Chi tiết Kỹ thuật

## 1. Tổng quan Nghiệp vụ

Chức năng Lessons cho phép người dùng:
- **Xem danh sách bài học** với layout dạng List
- **Lọc bài học** theo category (Grammar, Vocabulary, Speaking, Listening, Writing) và difficulty (Beginner → Advanced)
- **Tìm kiếm bài học** qua SearchDelegate
- **Xem chi tiết bài học** (LessonDetailScreen) với 4 tabs: Overview, Content, Vocabulary, Quiz
- **Học bài** với media (video, audio, image)
- **Theo dõi tiến độ** học tập với progress bar và timer
- **Thêm vào yêu thích** để học lại dễ dàng
- **Xem tiến độ tổng quát** trong tab Progress

---

## 2. Cấu trúc Code và Tổ chức

### 2.1. File Structure

```
lib/features/lessons/
├── screens/
│   ├── lessons_screen.dart           # Màn hình danh sách bài học
│   ├── lesson_detail_screen.dart    # Màn hình chi tiết bài học
│   └── lesson_player_screen.dart    # Màn hình học bài (video/audio player)
├── widgets/
│   └── lesson_media_widget.dart     # Widget hiển thị media
└── ...

lib/core/services/
├── lesson_service.dart               # Service xử lý CRUD bài học
├── learning_progress_service.dart   # Service theo dõi tiến độ
└── favorites_service.dart            # Service quản lý yêu thích
```

### 2.2. Class Diagram

```
LessonsScreen (StatefulWidget)
├── TabController (3 tabs: All Lessons, Progress, Favorites)
├── List<LessonModel> _allLessons
├── List<LessonModel> _filteredLessons
├── Map<String, dynamic> _learningStats
└── Methods:
    ├── _loadLessons()
    ├── _filterLessons()
    ├── _openLesson() → Navigate to LessonDetailScreen
    └── _buildLessonCard()

LessonDetailScreen (StatefulWidget)
├── TabController (4 tabs: Overview, Content, Vocabulary, Quiz)
├── Timer _learningTimer (track thời gian học)
├── int _currentSectionIndex
├── double _progress
└── Methods:
    ├── _loadLessonProgress()
    ├── _startLesson()
    ├── _completeSection()
    └── _trackProgress()
```

---

## 3. UI Components và Navigation

### 3.1. LessonDetailScreen - Màn hình Chi tiết

**Vị trí code**: `lesson_detail_screen.dart`

**Cấu trúc với 4 Tabs:**

**Tab 1: Overview** (Tổng quan)
- Thông tin bài học: title, description, category, difficulty
- Media preview: image/video/audio
- Thống kê: duration, sections count, vocabulary count
- Action buttons: Start Lesson, Add to Favorites

**Tab 2: Content** (Nội dung)
- Danh sách sections với progress indicators
- Mỗi section có:
  - Title và description
  - Media (nếu có)
  - Completion checkbox
  - "Mark as Complete" button

**Tab 3: Vocabulary** (Từ vựng)
- Danh sách từ vựng trong bài học
- Load từ `VocabularyService.getVocabularyByLessonId(lessonId)`
- Hiển thị dạng list với meaning và examples

**Tab 4: Quiz** (Bài kiểm tra)
- Quiz liên quan đến bài học
- Load từ `QuizService.getQuizzesByLessonId(lessonId)`
- Button "Start Quiz" → Navigate to QuizScreen

### 3.2. LessonMediaWidget

**Vị trí code**: `lesson_media_widget.dart`

**Chức năng:**
- Hiển thị image nếu có `imageUrl`
- Hiển thị video player nếu có `videoUrl`
- Hiển thị audio player nếu có `audioUrl`
- Fallback: placeholder icon nếu không có media

**Code structure:**
```dart
Widget build(BuildContext context) {
  if (videoUrl != null && videoUrl!.isNotEmpty) {
    return VideoPlayerWidget(videoUrl: videoUrl!);
  } else if (audioUrl != null && audioUrl!.isNotEmpty) {
    return AudioPlayerWidget(audioUrl: audioUrl!);
  } else if (imageUrl != null && imageUrl!.isNotEmpty) {
    return Image.network(imageUrl!);
  } else {
    return PlaceholderWidget();
  }
}
```

### 3.3. LessonCard trong LessonsScreen

**Vị trí code**: `lessons_screen.dart` dòng 908-1123

**Cấu trúc Card:**
```
Container (lesson card)
├── LessonMediaWidget (image/video preview)
├── Padding (content)
│   ├── Row (header)
│   │   ├── Icon (category icon)
│   │   └── Column
│   │       ├── Text (title)
│   │       └── Text (description)
│   ├── Wrap (tags)
│   └── Row (info)
│       ├── Duration
│       ├── Difficulty
│       └── Category
└── Container (actions)
    ├── CustomButton (Start Lesson)
    └── IconButton (Favorite)
```

### 3.4. SearchDelegate - Tìm kiếm Bài học

**Vị trí code**: `lessons_screen.dart` dòng 1358-1607

**Class**: `LessonSearchDelegate extends SearchDelegate<LessonModel?>`

**Chức năng:**
- Tìm kiếm theo: title, description, category, tags
- Hiển thị suggestions khi chưa nhập
- Hiển thị results khi có query
- Navigate to LessonDetailScreen khi chọn

**Methods:**
- `buildSuggestions()`: Hiển thị gợi ý tìm kiếm
- `buildResults()`: Hiển thị kết quả
- `buildActions()`: Nút clear
- `buildLeading()`: Nút back

---

## 4. Thuật toán Quan trọng

### 4.1. Thuật toán Lọc Bài học

**Vị trí code**: `lessons_screen.dart` dòng 139-166

```dart
void _filterLessons() {
  List<LessonModel> filtered = List.from(_allLessons);
  
  // 1. Lọc theo search query
  if (_searchQuery.isNotEmpty) {
    filtered = filtered.where((lesson) =>
      lesson.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      lesson.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      lesson.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }
  
  // 2. Lọc theo category
  if (_selectedCategory != 'Tất cả') {
    String englishCategory = _categoryMapping[_selectedCategory] ?? '';
    filtered = filtered.where((lesson) => 
      lesson.category == englishCategory
    ).toList();
  }
  
  // 3. Lọc theo difficulty
  if (_selectedDifficulty != 'Tất cả') {
    String englishDifficulty = _difficultyMapping[_selectedDifficulty] ?? '';
    filtered = filtered.where((lesson) => 
      lesson.difficultyLevelName == englishDifficulty
    ).toList();
  }
  
  setState(() {
    _filteredLessons = filtered;
  });
}
```

**Độ phức tạp**: O(n) với n là số bài học

### 4.2. Thuật toán Tính Tiến độ Bài học

**Vị trí code**: `lesson_detail_screen.dart` dòng 74-100

```dart
Future<void> _loadLessonProgress() async {
  try {
    final progress = await LearningProgressService.getLessonProgress(
      widget.lesson.id
    );
    if (progress != null) {
      setState(() {
        _elapsedSeconds = progress['timeSpent'] ?? 0;
        _progress = (progress['completionPercentage'] ?? 0.0) / 100.0;
        
        if (_progress >= 1.0) {
          _isLessonCompleted = true;
          _sectionCompletionStatus = List.filled(
            widget.lesson.sections.length, 
            true
          );
        } else {
          // Tính section hiện tại dựa trên progress
          _currentSectionIndex = (_progress * widget.lesson.sections.length).floor();
          if (_currentSectionIndex >= widget.lesson.sections.length) {
            _currentSectionIndex = widget.lesson.sections.length - 1;
          }
          
          // Đánh dấu các section đã hoàn thành
          for (int i = 0; i < _currentSectionIndex; i++) {
            _sectionCompletionStatus[i] = true;
          }
        }
      });
    }
  } catch (e) {
    print('Error loading lesson progress: $e');
  }
}
```

**Công thức:**
- `progress = (số section đã hoàn thành / tổng số section) * 100`
- `currentSectionIndex = floor(progress * totalSections)`

### 4.3. Thuật toán Timer Học tập

**Vị trí code**: `lesson_detail_screen.dart`

**Logic:**
1. Bắt đầu timer khi user vào lesson player
2. Cập nhật mỗi giây: `_elapsedSeconds++`
3. Lưu vào Firebase khi:
   - User hoàn thành section
   - User rời màn hình (dispose)
   - User đánh dấu hoàn thành bài học

```dart
void _startLearningTimer() {
  _learningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }
    setState(() {
      _elapsedSeconds++;
    });
    
    // Auto-save mỗi 30 giây
    if (_elapsedSeconds % 30 == 0) {
      _saveProgress();
    }
  });
}

void _saveProgress() {
  LearningProgressService.trackLessonProgress(
    lessonId: widget.lesson.id,
    timeSpent: _elapsedSeconds,
    completionPercentage: _progress * 100,
    currentSectionIndex: _currentSectionIndex,
  );
}
```

### 4.4. Thuật toán Hoàn thành Section

**Vị trí code**: `lesson_detail_screen.dart`

```dart
Future<void> _completeSection(int sectionIndex) async {
  if (sectionIndex >= widget.lesson.sections.length) return;
  
  setState(() {
    _sectionCompletionStatus[sectionIndex] = true;
    
    // Tính lại progress
    final completedSections = _sectionCompletionStatus
      .where((status) => status == true)
      .length;
    _progress = completedSections / widget.lesson.sections.length;
    
    // Chuyển sang section tiếp theo
    if (sectionIndex < widget.lesson.sections.length - 1) {
      _currentSectionIndex = sectionIndex + 1;
    }
  });
  
  // Lưu progress
  await LearningProgressService.trackLessonProgress(
    lessonId: widget.lesson.id,
    timeSpent: _elapsedSeconds,
    completionPercentage: _progress * 100,
    currentSectionIndex: _currentSectionIndex,
  );
  
  // Kiểm tra nếu hoàn thành toàn bộ bài học
  if (_progress >= 1.0) {
    _completeLesson();
  }
}
```

---

## 5. Flow Hoạt động

### 5.1. Flow Xem Danh sách Bài học

```
User mở LessonsScreen
  ↓
initState() → _loadLessons()
  ↓
LessonService.getAllLessons()
  ↓
Firebase Firestore query
  ↓
Filter active lessons
  ↓
setState() → Hiển thị ListView
  ↓
User có thể:
  - Scroll danh sách
  - Filter theo category/difficulty
  - Search qua SearchDelegate
  - Tap vào card → Navigate to LessonDetailScreen
```

### 5.2. Flow Xem Chi tiết Bài học

```
User tap vào LessonCard
  ↓
_openLesson(lesson)
  ↓
Navigate to LessonDetailScreen
  ↓
initState():
  - _loadLessonProgress() → Load tiến độ cũ
  - _checkFavoriteStatus() → Check yêu thích
  ↓
User xem 4 tabs:
  - Overview: Thông tin tổng quan
  - Content: Danh sách sections
  - Vocabulary: Từ vựng trong bài
  - Quiz: Bài kiểm tra
  ↓
User bấm "Start Lesson"
  ↓
Navigate to LessonPlayerScreen
```

### 5.3. Flow Học Bài

```
User vào LessonPlayerScreen
  ↓
_startLearningTimer() → Bắt đầu đếm thời gian
  ↓
User xem section đầu tiên
  ↓
User scroll/xem media
  ↓
User bấm "Mark as Complete"
  ↓
_completeSection(sectionIndex)
  ↓
Update progress:
  - _sectionCompletionStatus[sectionIndex] = true
  - _progress = completedSections / totalSections
  - _currentSectionIndex++
  ↓
Save to Firebase
  ↓
Nếu _progress >= 1.0:
  _completeLesson()
  - Hiển thị completion dialog
  - Update user stats
  - Unlock next lesson (nếu có)
```

### 5.4. Flow Xem Tiến độ

```
User vào tab "Progress"
  ↓
_loadLearningData()
  ↓
Load:
  - LearningProgressService.getLearningStats()
  - LearningProgressService.getRecentHistory(limit: 5)
  ↓
Hiển thị:
  - Overall progress card
  - Study streak card
  - Recent activity list
```

---

## 6. Services và Data Flow

### 6.1. LessonService

**Chức năng chính:**
- `getAllLessons()`: Lấy tất cả bài học
- `getLessonById(lessonId)`: Lấy bài học theo ID
- `getLessonsByCategory(category)`: Lấy theo category
- `getLessonsByDifficulty(difficulty)`: Lấy theo độ khó

**Firebase Query:**
```dart
final querySnapshot = await _firestore
  .collection('lessons')
  .where('isActive', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .get();
```

### 6.2. LearningProgressService

**Chức năng:**
- `trackLessonProgress()`: Lưu tiến độ học bài
- `getLessonProgress(lessonId)`: Lấy tiến độ của một bài
- `getLearningStats()`: Lấy thống kê tổng quát
- `getRecentHistory(limit)`: Lấy lịch sử gần đây

**Data structure:**
```
users/{userId}/lesson_progress/{lessonId}
{
  lessonId: string,
  completionPercentage: number (0-100),
  timeSpent: number (seconds),
  currentSectionIndex: number,
  completedAt: timestamp?,
  lastUpdatedAt: timestamp
}
```

### 6.3. VocabularyService (trong Lesson)

**Chức năng:**
- `getVocabularyByLessonId(lessonId)`: Lấy từ vựng trong bài học

**Firebase Query:**
```dart
final querySnapshot = await _firestore
  .collection('vocabulary')
  .where('lessonIds', arrayContains: lessonId)
  .get();
```

### 6.4. QuizService (trong Lesson)

**Chức năng:**
- `getQuizzesByLessonId(lessonId)`: Lấy quiz liên quan đến bài học

**Firebase Query:**
```dart
final querySnapshot = await _firestore
  .collection('quizzes')
  .where('lessonId', isEqualTo: lessonId)
  .get();
```

---

## 7. Media Handling

### 7.1. Video Player

**Package**: `video_player` hoặc `chewie`

**Implementation:**
```dart
VideoPlayerController _controller;

@override
void initState() {
  super.initState();
  _controller = VideoPlayerController.networkUrl(
    Uri.parse(lesson.videoUrl!)
  );
  _controller.initialize().then((_) {
    setState(() {});
  });
}

@override
Widget build(BuildContext context) {
  if (!_controller.value.isInitialized) {
    return CircularProgressIndicator();
  }
  return AspectRatio(
    aspectRatio: _controller.value.aspectRatio,
    child: VideoPlayer(_controller),
  );
}
```

### 7.2. Audio Player

**Package**: `audioplayers`

**Implementation:**
```dart
AudioPlayer _audioPlayer = AudioPlayer();

Future<void> playAudio() async {
  await _audioPlayer.play(UrlSource(lesson.audioUrl!));
}

Future<void> pauseAudio() async {
  await _audioPlayer.pause();
}
```

### 7.3. Image Display

**Package**: `cached_network_image` (optional, để cache)

**Implementation:**
```dart
Image.network(
  lesson.imageUrl!,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.broken_image);
  },
)
```

---

## 8. Best Practices và Patterns

### 8.1. Progress Tracking
- **Auto-save**: Lưu progress mỗi 30 giây
- **Manual save**: Lưu khi hoàn thành section
- **Resume**: Load progress cũ khi mở lại bài học

### 8.2. State Management
- `setState()` cho local state
- `FutureBuilder` cho async data
- Timer management: Cancel khi dispose

### 8.3. Performance
- **Lazy loading**: Chỉ load sections khi cần
- **Image caching**: Dùng cached_network_image
- **Video buffering**: Pre-buffer video trước khi play

### 8.4. Error Handling
```dart
try {
  final lessons = await LessonService.getAllLessons();
  setState(() {
    _allLessons = lessons;
    _isLoading = false;
  });
} catch (e) {
  setState(() => _isLoading = false);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lỗi khi tải bài học: $e'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
```

---

## 9. Tóm tắt

**Các điểm chính:**
1. **LessonDetailScreen** với 4 tabs: Overview, Content, Vocabulary, Quiz
2. **Progress tracking** với timer và completion percentage
3. **Media support**: Video, Audio, Image
4. **SearchDelegate** cho tìm kiếm nâng cao
5. **Section-based learning**: Học theo từng section, track progress từng section

**Các thuật toán quan trọng:**
- Filtering: O(n) - lọc theo category, difficulty, search
- Progress calculation: O(1) - tính dựa trên completed sections
- Timer tracking: O(1) - update mỗi giây

**UI Components:**
- LessonCard với media preview
- LessonDetailScreen với TabController (4 tabs)
- LessonPlayerScreen với media player
- Progress indicators và completion badges



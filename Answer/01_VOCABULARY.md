# 📚 Chức năng Từ vựng (Vocabulary) - Chi tiết Kỹ thuật

## 1. Tổng quan Nghiệp vụ

Chức năng Vocabulary cho phép người dùng:
- **Xem danh sách từ vựng** với layout dạng Grid (2 cột)
- **Tìm kiếm và lọc** từ vựng theo category (Grammar, Vocabulary, Speaking, Listening, Writing)
- **Xem chi tiết từ vựng** qua ModalBottomSheet khi bấm vào card
- **Luyện tập từ vựng** với nhiều chế độ: Flashcard, Trắc nghiệm, Điền từ, Nghe và chọn
- **Quản lý yêu thích** và bookmark
- **Xem thống kê học tập**: số từ đã học, độ chính xác, streak, thời gian học

---

## 2. Cấu trúc Code và Tổ chức

### 2.1. File Structure

```
lib/features/vocabulary/
├── screens/
│   ├── vocabulary_screen.dart          # Màn hình chính
│   ├── vocabulary_detail_screen.dart   # Màn hình chi tiết (full screen)
│   └── vocabulary_practice_screen.dart # Màn hình luyện tập
├── widgets/
│   └── vocabulary_card_widget.dart     # Widget hiển thị card từ vựng
└── ...

lib/core/services/
├── vocabulary_service.dart             # Service xử lý CRUD từ vựng
├── favorites_service.dart              # Service quản lý yêu thích
├── bookmark_service.dart               # Service quản lý bookmark
└── learning_progress_service.dart      # Service theo dõi tiến độ
```

### 2.2. Class Diagram

```
VocabularyScreen (StatefulWidget)
├── TabController (3 tabs: Tất cả, Yêu thích, Thống kê)
├── List<VocabularyModel> _vocabularies
├── List<VocabularyModel> _filteredVocabularies
└── Methods:
    ├── _loadVocabularies()
    ├── _filterVocabularies()
    ├── _showVocabularyDetail()  # Hiển thị ModalBottomSheet
    └── _startPracticeWith()

VocabularyCardWidget (StatefulWidget)
├── AnimationController (scale & fade animations)
├── AudioPlayer (phát âm thanh)
└── Methods:
    ├── _onCardTap()
    └── _playAudio()
```

---

## 3. UI Components và Popup

### 3.1. ModalBottomSheet - Popup Chi tiết Từ vựng

**Vị trí code**: `vocabulary_screen.dart` dòng 974-1120

**Cách hoạt động:**
```dart
void _showVocabularyDetail(VocabularyModel vocabulary) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,  // Cho phép chiếm toàn bộ màn hình
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,  // Bắt đầu ở 70% màn hình
      maxChildSize: 0.9,       // Kéo tối đa 90%
      minChildSize: 0.5,       // Kéo tối thiểu 50%
      expand: false,
      builder: (context, scrollController) {
        return Container(
          // Nội dung popup
        );
      },
    ),
  );
}
```

**Các thành phần trong ModalBottomSheet:**
1. **Handle bar** (dòng 993-1002): Thanh kéo ở đầu popup
2. **Header** (dòng 1006-1042): 
   - Từ vựng (word) với font size 28
   - Pronunciation (phiên âm)
   - Nút phát âm thanh (nếu có audio)
3. **Content** (dòng 1047-1065): Scrollable content
   - Nghĩa (meaning)
   - Loại từ (partOfSpeech)
   - Ví dụ (examples)
   - Từ đồng nghĩa (synonyms)
   - Từ trái nghĩa (antonyms)
4. **Action buttons** (dòng 1068-1114):
   - Nút "Luyện tập" (navigate to practice screen)
   - Nút "Yêu thích" (toggle favorite)

**Tại sao dùng ModalBottomSheet?**
- UX tốt: không che toàn bộ màn hình, có thể kéo lên/xuống
- Dễ đóng: vuốt xuống hoặc bấm ra ngoài
- Responsive: tự động điều chỉnh theo nội dung

### 3.2. VocabularyCardWidget

**Vị trí code**: `vocabulary_card_widget.dart`

**Các tính năng:**
- **Animation**: Scale và fade khi tap (dòng 44-55)
- **Audio player**: Phát âm thanh từ vựng (dòng 76-102)
- **Visual indicators**:
  - Category color (màu theo category)
  - Difficulty badge (màu theo độ khó)
  - Lesson count icon

**Cấu trúc Card:**
```
Container (card)
├── Row (header)
│   ├── Column (word + pronunciation)
│   └── AudioButton (nếu có audio)
├── Text (meaning)
├── Text (definition) - optional
├── Container (partOfSpeech badge)
├── Text (example) - optional
└── Row (actions)
    ├── PracticeButton
    └── StudyListButton
```

### 3.3. TabBar với 3 Tabs

**Tab 1: Tất cả** (`_buildAllVocabularyTab`)
- Search bar
- Category filter chips
- GridView hiển thị tất cả từ vựng

**Tab 2: Yêu thích** (`_buildFavoritesTab`)
- FutureBuilder load từ FavoritesService
- GridView chỉ hiển thị từ yêu thích
- Có thể xóa khỏi yêu thích

**Tab 3: Thống kê** (`_buildStatisticsTab`)
- Thống kê tổng số từ
- Thống kê học tập (accuracy, streak, study time)
- Hoạt động gần đây

---

## 4. Thuật toán Quan trọng

### 4.1. Thuật toán Lọc Từ vựng

**Vị trí code**: `vocabulary_screen.dart` dòng 70-89

```dart
void _filterVocabularies() {
  List<VocabularyModel> filtered = List.from(_vocabularies);
  
  // 1. Lọc theo category
  if (_selectedCategory != 'Tất cả') {
    filtered = filtered.where((vocab) => 
      vocab.category == _selectedCategory
    ).toList();
  }
  
  // 2. Lọc theo search query
  if (_searchQuery.isNotEmpty) {
    filtered = filtered.where((vocab) =>
      vocab.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      vocab.meaning.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }
  
  setState(() {
    _filteredVocabularies = filtered;
  });
}
```

**Độ phức tạp**: O(n) với n là số từ vựng

### 4.2. Thuật toán Chọn Từ để Luyện tập

**Vị trí code**: `vocabulary_practice_screen.dart` dòng 85-140

**Logic:**
1. Nếu có `initialVocabulary`: Load từ đó + các từ cùng category
2. Nếu có `category`: Load tất cả từ trong category đó
3. Nếu có `difficultyLevel`: Filter theo độ khó
4. Shuffle và lấy 20 từ đầu tiên

```dart
Future<void> _loadVocabularies() async {
  List<VocabularyModel> vocabularies;
  
  if (widget.initialVocabulary != null) {
    // Load từ cụ thể + related
    vocabularies = await VocabularyService.searchVocabulary(
      widget.initialVocabulary!.word
    );
    final relatedVocabs = await VocabularyService.getVocabulariesByCategory(
      widget.initialVocabulary!.category,
      limit: 10,
    );
    vocabularies.addAll(relatedVocabs);
    
    // Remove duplicates
    final seen = <String>{};
    vocabularies = vocabularies.where((vocab) => 
      seen.add(vocab.id)
    ).toList();
  } else if (widget.category != null) {
    vocabularies = await VocabularyService.getVocabulariesByCategory(
      widget.category!
    );
  } else {
    vocabularies = await VocabularyService.getAllVocabulary();
  }
  
  // Filter by difficulty
  if (widget.difficultyLevel != null) {
    vocabularies = vocabularies.where((v) => 
      v.difficultyLevel == widget.difficultyLevel
    ).toList();
  }
  
  // Shuffle và lấy 20 từ
  vocabularies.shuffle();
  _practiceSet = vocabularies.take(20).toList();
}
```

### 4.3. Thuật toán Tạo Câu hỏi Trắc nghiệm

**Vị trí code**: `vocabulary_practice_screen.dart` dòng 159-171

```dart
void _generateMultipleChoice(VocabularyModel correct) {
  final options = <String>[correct.meaning];  // Đáp án đúng
  final otherVocabs = _vocabularies
    .where((v) => v.id != correct.id)
    .toList();
  otherVocabs.shuffle();
  
  // Thêm 3 đáp án sai ngẫu nhiên
  for (int i = 0; i < 3 && i < otherVocabs.length; i++) {
    options.add(otherVocabs[i].meaning);
  }
  
  // Shuffle để đáp án đúng không luôn ở vị trí đầu
  options.shuffle();
  _multipleChoiceOptions = options;
}
```

**Độ phức tạp**: O(n) với n là số từ vựng

### 4.4. Thuật toán Tính Điểm và Thống kê

**Vị trí code**: `vocabulary_practice_screen.dart` dòng 195-199

```dart
void _showResults() {
  final percentage = (_correctAnswers / (_totalQuestions + 1) * 100).round();
  
  // Track progress
  _trackVocabularyProgress();
  
  // Show results dialog
  showDialog(...);
}
```

**Công thức tính điểm:**
- `percentage = (số câu đúng / tổng số câu) * 100`
- Lưu vào `learning_progress` collection với:
  - `accuracy`: percentage
  - `timeSpent`: thời gian luyện tập (giây)
  - `vocabularyIds`: danh sách từ đã luyện

---

## 5. Flow Hoạt động

### 5.1. Flow Xem Danh sách Từ vựng

```
User mở VocabularyScreen
  ↓
initState() → _loadVocabularies()
  ↓
VocabularyService.getAllVocabulary()
  ↓
Firebase Firestore query
  ↓
setState() → Hiển thị GridView
  ↓
User scroll, search, filter
  ↓
_filterVocabularies() → Update UI
```

### 5.2. Flow Xem Chi tiết Từ vựng

```
User tap vào VocabularyCardWidget
  ↓
_onCardTap() → Animation
  ↓
_showVocabularyDetail(vocabulary)
  ↓
showModalBottomSheet()
  ↓
DraggableScrollableSheet hiển thị
  ↓
User có thể:
  - Kéo lên/xuống để resize
  - Scroll nội dung
  - Bấm "Luyện tập" → Navigate to PracticeScreen
  - Bấm "Yêu thích" → Toggle favorite
  - Bấm nút audio → Phát âm thanh
```

### 5.3. Flow Luyện tập Từ vựng

```
User bấm "Luyện tập" (FAB hoặc từ card)
  ↓
_showPracticeOptions() → ModalBottomSheet
  ↓
User chọn chế độ:
  - Luyện tập tất cả
  - Ôn lại Bookmark
  - Theo danh mục
  - Theo độ khó
  ↓
Navigate to VocabularyPracticeScreen
  ↓
_loadVocabularies() → Load 20 từ
  ↓
_generateQuizContent() → Tạo câu hỏi
  ↓
User trả lời → _nextQuestion()
  ↓
Hết câu hỏi → _showResults()
  ↓
Track progress → LearningProgressService
  ↓
Navigate back → Refresh statistics
```

---

## 6. Services và Data Flow

### 6.1. VocabularyService

**Chức năng chính:**
- `getAllVocabulary()`: Lấy tất cả từ vựng
- `getVocabulariesByCategory(category)`: Lấy theo category
- `searchVocabulary(query)`: Tìm kiếm (client-side filtering)
- `checkWordExists(word)`: Kiểm tra từ đã tồn tại chưa

**Firebase Query:**
```dart
final querySnapshot = await _firestore
  .collection('vocabulary')
  .where('isActive', isEqualTo: true)
  .orderBy('word')
  .get();
```

### 6.2. FavoritesService

**Chức năng:**
- `getFavoriteVocabularies()`: Lấy danh sách yêu thích
- `toggleVocabularyFavorite(vocabId)`: Thêm/xóa yêu thích
- `isVocabularyInFavorites(vocabId)`: Kiểm tra trạng thái

**Data structure:**
```
users/{userId}/favorites/vocabulary/{vocabId}
```

### 6.3. LearningProgressService

**Chức năng:**
- `trackVocabularyProgress()`: Lưu tiến độ luyện tập
- `getLearningStats()`: Lấy thống kê tổng quát
- `getRecentHistory(limit)`: Lấy lịch sử gần đây

**Data structure:**
```
users/{userId}/learning_progress/vocabulary/{progressId}
{
  vocabularyId: string,
  accuracy: number,
  timeSpent: number,
  completedAt: timestamp
}
```

---

## 7. Best Practices và Patterns

### 7.1. State Management
- Sử dụng `setState()` cho local state
- `FutureBuilder` cho async data loading
- `StreamBuilder` cho real-time updates (nếu cần)

### 7.2. Performance Optimization
- **Lazy loading**: Chỉ load 20 từ đầu tiên cho practice
- **Caching**: Vocabulary list được cache trong state
- **Debounce search**: Có thể thêm debounce cho search input

### 7.3. Error Handling
```dart
try {
  final vocabularies = await VocabularyService.getAllVocabulary();
  setState(() {
    _vocabularies = vocabularies;
    _isLoading = false;
  });
} catch (e) {
  setState(() => _isLoading = false);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Lỗi tải từ vựng: $e'),
      backgroundColor: AppColors.error,
    ),
  );
}
```

### 7.4. Animation
- **Scale animation**: Khi tap card (0.95 scale)
- **Fade animation**: Khi chuyển câu hỏi
- **Slide animation**: Khi mở practice screen

---

## 8. Tóm tắt

**Các điểm chính:**
1. **ModalBottomSheet** là popup chính để hiển thị chi tiết từ vựng
2. **Grid layout** với 2 cột cho danh sách từ vựng
3. **TabController** quản lý 3 tabs: Tất cả, Yêu thích, Thống kê
4. **Practice screen** với 4 chế độ: Flashcard, Trắc nghiệm, Điền từ, Nghe
5. **Real-time tracking** tiến độ học tập qua LearningProgressService

**Các thuật toán quan trọng:**
- Filtering: O(n) - lọc theo category và search
- Multiple choice generation: O(n) - tạo 4 đáp án
- Progress tracking: O(1) - lưu vào Firebase

**UI Components:**
- ModalBottomSheet (DraggableScrollableSheet)
- VocabularyCardWidget với animations
- TabBar với 3 tabs
- GridView với custom cards



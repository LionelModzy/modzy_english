# 🎮 Chức năng Mini Games - Chi tiết Kỹ thuật

## 1. Tổng quan Nghiệp vụ

Chức năng Mini Games cho phép người dùng:
- **Xem danh sách mini games** với layout dạng List
- **Lọc games** theo loại: Word Match, Word Scramble, Word Search
- **Chơi game** để học từ vựng một cách vui vẻ
- **Tính điểm** dựa trên thời gian và độ chính xác
- **Lưu kết quả** và cập nhật tiến độ học tập

**3 loại game:**
1. **Word Match (Ghép Cặp)**: Ghép từ tiếng Anh với nghĩa tiếng Việt
2. **Word Scramble (Xếp Chữ)**: Sắp xếp các chữ cái để tạo thành từ đúng
3. **Word Search (Tìm Từ)**: Tìm từ vựng trong lưới chữ cái

---

## 2. Cấu trúc Code và Tổ chức

### 2.1. File Structure

```
lib/features/mini_games/
├── screens/
│   ├── mini_games_menu_screen.dart    # Màn hình menu chọn game
│   ├── word_match_game_screen.dart    # Game ghép cặp
│   ├── word_scramble_game_screen.dart # Game xếp chữ
│   └── word_search_game_screen.dart   # Game tìm từ
└── ...

lib/core/services/
├── mini_game_service.dart             # Service quản lý games
└── sample_data_service.dart           # Service tạo dữ liệu mẫu
```

### 2.2. Class Diagram

```
MiniGamesMenuScreen (StatefulWidget)
├── List<MiniGameModel> _games
├── String _selectedFilter
└── Methods:
    ├── _loadGames()
    ├── _playGame() → Navigate to game screen
    └── _buildGameCard()

WordMatchGameScreen (StatefulWidget)
├── List<VocabularyModel> _vocabularies
├── List<Card> _cards (shuffled)
├── Card? _firstSelectedCard
├── Card? _secondSelectedCard
├── int _matchesFound
├── int _moves
├── Timer? _gameTimer
└── Methods:
    ├── _initializeGame()
    ├── _onCardTap()
    ├── _checkMatch()
    └── _checkGameComplete()
```

---

## 3. UI Components

### 3.1. MiniGamesMenuScreen

**Vị trí code**: `mini_games_menu_screen.dart`

**Cấu trúc:**
- **Header**: Gradient với title và description
- **Filter chips**: Lọc theo loại game
- **Game cards**: ListView với các game card

**Game Card:**
```
Container (game card)
├── Row
│   ├── Container (icon với gradient)
│   ├── Column (info)
│   │   ├── Text (title)
│   │   ├── Text (description)
│   │   └── Row (chips)
│   │       ├── Difficulty chip
│   │       └── Play count chip
│   └── Container (play button - circle)
```

### 3.2. WordMatchGameScreen

**Vị trí code**: `word_match_game_screen.dart`

**Game Logic:**
1. Load vocabulary từ MiniGameService
2. Tạo cards: mỗi từ có 2 cards (word và meaning)
3. Shuffle cards
4. User tap 2 cards:
   - Nếu match → Giữ cards mở, tăng matchesFound
   - Nếu không match → Đóng cards sau 1 giây
5. Game complete khi matchesFound == vocabularies.length

**UI:**
- GridView với cards (4-6 cột tùy màn hình)
- Timer hiển thị thời gian chơi
- Moves counter
- Progress indicator

### 3.3. WordScrambleGameScreen

**Vị trí code**: `word_scramble_game_screen.dart`

**Game Logic:**
1. Load vocabulary
2. Shuffle letters của từ
3. User sắp xếp letters để tạo từ đúng
4. Check answer khi user submit
5. Next word khi đúng

**UI:**
- Scrambled letters (có thể drag hoặc tap để sắp xếp)
- Answer input field
- Hint button (hiển thị nghĩa)
- Score và timer

### 3.4. WordSearchGameScreen

**Vị trí code**: `word_search_game_screen.dart`

**Game Logic:**
1. Tạo grid 10x10 hoặc 15x15 với random letters
2. Đặt các từ vựng vào grid (ngang, dọc, chéo)
3. User tìm và highlight từ
4. Check nếu từ đúng
5. Game complete khi tìm hết từ

**UI:**
- Grid với letters
- Word list (các từ cần tìm)
- Found words list
- Timer và score

---

## 4. Thuật toán Quan trọng

### 4.1. Thuật toán Word Match - Tạo Cards

```dart
void _initializeGame() {
  final cards = <Card>[];
  
  // Tạo 2 cards cho mỗi từ: 1 cho word, 1 cho meaning
  for (var vocab in _vocabularies) {
    cards.add(Card(
      id: '${vocab.id}_word',
      content: vocab.word,
      type: CardType.word,
      vocabularyId: vocab.id,
    ));
    cards.add(Card(
      id: '${vocab.id}_meaning',
      content: vocab.meaning,
      type: CardType.meaning,
      vocabularyId: vocab.id,
    ));
  }
  
  // Shuffle để random vị trí
  cards.shuffle();
  _cards = cards;
}
```

**Độ phức tạp**: O(n) với n là số từ vựng

### 4.2. Thuật toán Word Match - Kiểm tra Match

```dart
void _checkMatch() {
  if (_firstSelectedCard == null || _secondSelectedCard == null) return;
  
  // Kiểm tra nếu 2 cards cùng vocabularyId và khác type
  if (_firstSelectedCard!.vocabularyId == _secondSelectedCard!.vocabularyId &&
      _firstSelectedCard!.type != _secondSelectedCard!.type) {
    // Match!
    setState(() {
      _firstSelectedCard!.isMatched = true;
      _secondSelectedCard!.isMatched = true;
      _matchesFound++;
      _firstSelectedCard = null;
      _secondSelectedCard = null;
    });
    
    // Check game complete
    if (_matchesFound == _vocabularies.length) {
      _completeGame();
    }
  } else {
    // Không match - đóng cards sau 1 giây
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _firstSelectedCard!.isFlipped = false;
          _secondSelectedCard!.isFlipped = false;
          _firstSelectedCard = null;
          _secondSelectedCard = null;
        });
      }
    });
  }
  
  _moves++;
}
```

**Độ phức tạp**: O(1)

### 4.3. Thuật toán Word Scramble - Shuffle Letters

```dart
String _scrambleWord(String word) {
  final letters = word.split('');
  letters.shuffle();
  return letters.join('');
}

// Đảm bảo không trùng với từ gốc
String _getScrambledWord(String word) {
  String scrambled;
  do {
    scrambled = _scrambleWord(word);
  } while (scrambled == word && word.length > 1);
  return scrambled;
}
```

**Độ phức tạp**: O(n) với n là độ dài từ

### 4.4. Thuật toán Word Search - Tạo Grid

```dart
List<List<String>> _generateGrid(List<VocabularyModel> vocabularies, int size) {
  // Tạo grid rỗng
  final grid = List.generate(size, (_) => List.generate(size, (_) => ''));
  
  // Đặt các từ vào grid
  for (var vocab in vocabularies) {
    final word = vocab.word.toUpperCase();
    final placed = _placeWordInGrid(grid, word);
    if (!placed) {
      // Nếu không đặt được, bỏ qua từ này
      continue;
    }
  }
  
  // Điền các ô trống với random letters
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      if (grid[i][j].isEmpty) {
        grid[i][j] = _getRandomLetter();
      }
    }
  }
  
  return grid;
}

bool _placeWordInGrid(List<List<String>> grid, String word) {
  final directions = [
    [0, 1],   // Horizontal
    [1, 0],   // Vertical
    [1, 1],   // Diagonal down-right
    [1, -1],  // Diagonal down-left
  ];
  
  final size = grid.length;
  final attempts = 100; // Thử tối đa 100 lần
  
  for (int attempt = 0; attempt < attempts; attempt++) {
    final row = Random().nextInt(size);
    final col = Random().nextInt(size);
    final direction = directions[Random().nextInt(directions.length)];
    
    // Kiểm tra xem có đặt được không
    if (_canPlaceWord(grid, word, row, col, direction)) {
      _placeWord(grid, word, row, col, direction);
      return true;
    }
  }
  
  return false;
}
```

**Độ phức tạp**: O(n * m * k) với n là số từ, m là kích thước grid, k là số lần thử

### 4.5. Thuật toán Tính Điểm

```dart
int _calculateScore() {
  int baseScore = 1000;
  
  // Trừ điểm theo thời gian (mỗi giây trừ 10 điểm)
  final timePenalty = _elapsedSeconds * 10;
  
  // Trừ điểm theo số lần di chuyển (mỗi move trừ 5 điểm)
  final movePenalty = _moves * 5;
  
  final finalScore = baseScore - timePenalty - movePenalty;
  return finalScore > 0 ? finalScore : 0;
}
```

**Công thức:**
- `score = 1000 - (timeSeconds * 10) - (moves * 5)`
- Minimum score = 0

---

## 5. Flow Hoạt động

### 5.1. Flow Chọn Game

```
User mở MiniGamesMenuScreen
  ↓
_loadGames() → MiniGameService.getAllGames()
  ↓
Hiển thị danh sách games
  ↓
User chọn filter (Tất cả, Ghép Cặp, Xếp Chữ, Tìm Từ)
  ↓
Filter games theo type
  ↓
User tap vào game card
  ↓
_playGame(game)
  ↓
Load vocabulary cho game
  ↓
Navigate to game screen tương ứng
```

### 5.2. Flow Chơi Word Match

```
User vào WordMatchGameScreen
  ↓
_initializeGame()
  ↓
Tạo cards và shuffle
  ↓
User tap card đầu tiên
  ↓
_flipCard(card) → _firstSelectedCard = card
  ↓
User tap card thứ hai
  ↓
_flipCard(card) → _secondSelectedCard = card
  ↓
_checkMatch()
  ↓
Nếu match:
  - Đánh dấu cards là matched
  - Tăng matchesFound
  - Check game complete
Nếu không match:
  - Đóng cards sau 1 giây
  ↓
Game complete → _completeGame()
  ↓
Tính điểm và lưu kết quả
```

### 5.3. Flow Chơi Word Scramble

```
User vào WordScrambleGameScreen
  ↓
Load vocabulary
  ↓
Shuffle letters của từ đầu tiên
  ↓
User sắp xếp letters
  ↓
User submit answer
  ↓
Check answer:
  - Nếu đúng → Next word, tăng score
  - Nếu sai → Hiển thị hint, cho phép thử lại
  ↓
Hết từ → Game complete
```

### 5.4. Flow Chơi Word Search

```
User vào WordSearchGameScreen
  ↓
_generateGrid() → Tạo grid với từ vựng
  ↓
User tìm và highlight từ
  ↓
Check nếu từ đúng:
  - Đánh dấu từ đã tìm
  - Tăng score
  - Check game complete
  ↓
Game complete → Hiển thị kết quả
```

---

## 6. Services và Data Flow

### 6.1. MiniGameService

**Chức năng:**
- `getAllGames()`: Lấy tất cả games
- `getGameVocabulary(game)`: Lấy từ vựng cho game
- `saveGameResult()`: Lưu kết quả chơi game

**Firebase Query:**
```dart
final querySnapshot = await _firestore
  .collection('mini_games')
  .where('isActive', isEqualTo: true)
  .get();
```

### 6.2. Data Structure

**MiniGame Model:**
```dart
{
  id: string,
  title: string,
  description: string,
  gameType: string ('word_match', 'word_scramble', 'word_search'),
  difficultyLevel: number (1-5),
  playCount: number,
  isActive: boolean,
  createdAt: timestamp,
}
```

**Game Result:**
```dart
{
  gameId: string,
  userId: string,
  score: number,
  timeSpent: number (seconds),
  moves: number?,
  completedAt: timestamp,
}
```

---

## 7. Best Practices

### 7.1. Game State Management
- **Timer management**: Cancel khi dispose
- **Card state**: Track flipped và matched state
- **Animation**: Smooth flip animation cho cards

### 7.2. Performance
- **Lazy loading**: Chỉ load vocabulary khi cần
- **Grid generation**: Cache grid nếu có thể
- **Memory management**: Dispose controllers khi không dùng

### 7.3. UX
- **Visual feedback**: Highlight khi match/sai
- **Sound effects**: Optional sound khi match
- **Hints**: Cho phép xem hint khi stuck

---

## 8. Tóm tắt

**Các điểm chính:**
1. **3 loại game**: Word Match, Word Scramble, Word Search
2. **Score system**: Dựa trên thời gian và số lần di chuyển
3. **Progress tracking**: Lưu kết quả vào Firebase
4. **Vocabulary integration**: Sử dụng từ vựng từ database

**Các thuật toán quan trọng:**
- Card matching: O(1)
- Word scrambling: O(n)
- Grid generation: O(n * m * k)
- Score calculation: O(1)

**UI Components:**
- Game cards với difficulty và play count
- Game screens với timer và score
- Completion dialog với results



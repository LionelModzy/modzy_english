# 📝 Chức năng Làm bài Kiểm tra (Quiz) - Chi tiết Kỹ thuật

## 1. Tổng quan Nghiệp vụ

Chức năng Quiz cho phép người dùng:
- **Xem danh sách quiz** với layout dạng List
- **Lọc quiz** theo category và difficulty
- **Tìm kiếm quiz** qua SearchDelegate
- **Làm bài quiz** với timer (nếu có time limit)
- **Xem kết quả** sau khi hoàn thành với điểm số và đáp án đúng/sai
- **Xem lịch sử làm bài** trong tab "My Results"
- **Xem quiz theo category** trong tab "Categories"
- **Làm lại quiz** để cải thiện điểm số

---

## 2. Cấu trúc Code và Tổ chức

### 2.1. File Structure

```
lib/features/quiz/
├── screens/
│   ├── quiz_list_screen.dart    # Màn hình danh sách quiz
│   └── quiz_screen.dart         # Màn hình làm bài quiz
└── ...

lib/core/services/
├── quiz_service.dart            # Service xử lý CRUD quiz và results
└── challenge_service.dart       # Service xử lý challenge (nếu quiz là challenge)
```

### 2.2. Class Diagram

```
QuizListScreen (StatefulWidget)
├── TabController (3 tabs: All Quizzes, My Results, Categories)
├── List<QuizModel> _allQuizzes
├── List<QuizModel> _filteredQuizzes
└── Methods:
    ├── _loadQuizzes()
    ├── _filterQuizzes()
    ├── _startQuiz() → Navigate to QuizScreen
    └── _buildQuizCard()

QuizScreen (StatefulWidget)
├── Timer _quizTimer (đếm ngược thời gian)
├── int _currentQuestionIndex
├── List<QuizAnswer> _answers
├── Duration _timeRemaining
├── bool _isQuizCompleted
└── Methods:
    ├── _initializeQuiz()
    ├── _startTimer()
    ├── _submitAnswer()
    ├── _nextQuestion()
    ├── _submitQuiz()
    └── _buildResultsScreen()
```

---

## 3. UI Components và Navigation

### 3.1. QuizScreen - Màn hình Làm bài

**Vị trí code**: `quiz_screen.dart`

**Cấu trúc màn hình:**

**Header (AppBar):**
- Title: Quiz title
- Timer (nếu có time limit): Hiển thị thời gian còn lại
  - Màu đỏ khi < 5 phút
  - Format: "MM:SS"

**Progress Bar:**
- Hiển thị: "Câu hỏi X/Y" và percentage
- LinearProgressIndicator với value = (currentIndex + 1) / totalQuestions

**Question Content:**
- Question text
- Question type:
  - **Multiple Choice**: Radio buttons hoặc checkboxes
  - **True/False**: 2 options
  - **Text Input**: TextField
  - **Matching**: Drag and drop (nếu có)

**Navigation Bar:**
- "Previous" button (disabled ở câu đầu)
- "Next" button hoặc "Submit" button (ở câu cuối)

### 3.2. QuizCard trong QuizListScreen

**Vị trí code**: `quiz_list_screen.dart` dòng 391-522

**Cấu trúc Card:**
```
Container (quiz card)
├── Container (header với gradient)
│   ├── Icon (category icon)
│   └── Column
│       ├── Text (title)
│       └── Text (description)
├── Padding (content)
│   ├── Row (stats)
│   │   ├── Questions count
│   │   ├── Time limit
│   │   └── Difficulty
│   └── Row (best result hoặc start button)
│       ├── Best result badge (nếu đã làm)
│       └── ElevatedButton (Start Quiz / Retake)
```

### 3.3. Results Screen

**Vị trí code**: `quiz_screen.dart` method `_buildResultsScreen()`

**Hiển thị:**
- **Score**: Điểm số và percentage
- **Summary**: Số câu đúng/tổng số câu
- **Time taken**: Thời gian làm bài
- **Pass/Fail status**: Dựa trên passing score
- **Review section**: 
  - Danh sách câu hỏi với đáp án đúng/sai
  - Highlight đáp án đúng (màu xanh)
  - Highlight đáp án sai (màu đỏ)
- **Action buttons**:
  - "Retake Quiz" (làm lại)
  - "View Details" (xem chi tiết)
  - "Back to List" (quay lại danh sách)

### 3.4. SearchDelegate - Tìm kiếm Quiz

**Vị trí code**: `quiz_list_screen.dart` dòng 875-949

**Class**: `QuizSearchDelegate extends SearchDelegate<QuizModel>`

**Chức năng:**
- Tìm kiếm theo: title, description, category
- Navigate to QuizScreen khi chọn

---

## 4. Thuật toán Quan trọng

### 4.1. Thuật toán Lọc Quiz

**Vị trí code**: `quiz_list_screen.dart` dòng 79-95

```dart
void _filterQuizzes() {
  List<QuizModel> filtered = List.from(_allQuizzes);
  
  // 1. Lọc theo category
  if (_selectedCategory != 'All') {
    filtered = filtered.where((quiz) => 
      quiz.category == _selectedCategory
    ).toList();
  }
  
  // 2. Lọc theo difficulty
  if (_selectedDifficulty != 'All') {
    filtered = filtered.where((quiz) => 
      quiz.difficultyLevelName == _selectedDifficulty
    ).toList();
  }
  
  setState(() {
    _filteredQuizzes = filtered;
  });
}
```

**Độ phức tạp**: O(n) với n là số quiz

### 4.2. Thuật toán Timer (Đếm ngược)

**Vị trí code**: `quiz_screen.dart` dòng 72-91

```dart
void _startTimer() {
  _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    setState(() {
      _timeElapsed = _timeElapsed + const Duration(seconds: 1);

      if (widget.quiz.timeLimit > 0) {
        _timeRemaining = Duration(minutes: widget.quiz.timeLimit) - _timeElapsed;

        // Tự động submit khi hết thời gian
        if (_timeRemaining.inSeconds <= 0) {
          _submitQuiz();
        }
      }
    });
  });
}
```

**Logic:**
- Update mỗi giây: `_timeElapsed++`
- Tính thời gian còn lại: `_timeRemaining = timeLimit - timeElapsed`
- Auto-submit khi `_timeRemaining <= 0`

### 4.3. Thuật toán Tính Điểm

**Vị trí code**: `quiz_screen.dart` method `_submitQuiz()`

```dart
void _submitQuiz() {
  int totalPoints = 0;
  int correctAnswers = 0;
  
  for (int i = 0; i < widget.quiz.questions.length; i++) {
    final question = widget.quiz.questions[i];
    final answer = _answers[i];
    
    // Kiểm tra đáp án đúng
    bool isCorrect = _checkAnswer(question, answer);
    
    if (isCorrect) {
      correctAnswers++;
      totalPoints += question.points;
      answer.isCorrect = true;
      answer.pointsEarned = question.points;
    } else {
      answer.isCorrect = false;
      answer.pointsEarned = 0;
    }
  }
  
  // Tính percentage
  final totalPossiblePoints = widget.quiz.questions
    .fold(0, (sum, q) => sum + q.points);
  final percentage = (totalPoints / totalPossiblePoints) * 100;
  
  // Kiểm tra pass/fail
  final passed = percentage >= widget.quiz.passingScore;
  
  // Lưu kết quả
  _saveQuizResult(totalPoints, totalPossiblePoints, percentage, passed);
}
```

**Công thức:**
- `totalPoints = sum(points của câu đúng)`
- `percentage = (totalPoints / totalPossiblePoints) * 100`
- `passed = percentage >= passingScore`

### 4.4. Thuật toán Kiểm tra Đáp án

**Vị trí code**: `quiz_screen.dart` method `_checkAnswer()`

```dart
bool _checkAnswer(QuizQuestion question, QuizAnswer answer) {
  switch (question.type) {
    case 'multiple_choice':
      // So sánh selectedAnswers với correctAnswers
      if (answer.selectedAnswers.length != question.correctAnswers.length) {
        return false;
      }
      return answer.selectedAnswers.every((selected) => 
        question.correctAnswers.contains(selected)
      );
      
    case 'true_false':
      return answer.selectedAnswers.first == question.correctAnswers.first;
      
    case 'text_input':
      // So sánh không phân biệt hoa thường
      final userAnswer = answer.textAnswer.trim().toLowerCase();
      final correctAnswer = question.correctAnswers.first.toLowerCase();
      return userAnswer == correctAnswer;
      
    case 'matching':
      // Kiểm tra tất cả các cặp matching
      return answer.selectedAnswers.length == question.correctAnswers.length &&
             answer.selectedAnswers.every((selected) => 
               question.correctAnswers.contains(selected)
             );
      
    default:
      return false;
  }
}
```

**Độ phức tạp**: O(n) với n là số đáp án

### 4.5. Thuật toán Lưu Kết quả

**Vị trí code**: `quiz_service.dart`

```dart
static Future<void> submitQuizResult({
  required String quizId,
  required String userId,
  required int score,
  required int totalPoints,
  required double percentage,
  required bool passed,
  required Duration timeTaken,
  required List<QuizAnswer> answers,
  String? challengeId,
}) async {
  final result = {
    'quizId': quizId,
    'userId': userId,
    'score': score,
    'totalPoints': totalPoints,
    'percentage': percentage,
    'passed': passed,
    'timeTaken': timeTaken.inSeconds,
    'answers': answers.map((a) => a.toMap()).toList(),
    'completedAt': FieldValue.serverTimestamp(),
    'challengeId': challengeId,
  };
  
  // Lưu vào quiz_results collection
  await _firestore
    .collection('quiz_results')
    .add(result);
  
  // Update best result nếu điểm cao hơn
  await _updateBestResult(userId, quizId, percentage);
  
  // Nếu là challenge, update challenge result
  if (challengeId != null) {
    await ChallengeService.updateChallengeResult(
      challengeId: challengeId,
      userId: userId,
      score: score,
      percentage: percentage,
    );
  }
}
```

---

## 5. Flow Hoạt động

### 5.1. Flow Xem Danh sách Quiz

```
User mở QuizListScreen
  ↓
initState() → _loadQuizzes()
  ↓
QuizService.getAllQuizzes()
  ↓
Filter standalone quizzes (lessonId == null)
  ↓
setState() → Hiển thị ListView
  ↓
User có thể:
  - Filter theo category/difficulty
  - Search qua SearchDelegate
  - Tap vào card → Navigate to QuizScreen
```

### 5.2. Flow Làm bài Quiz

```
User tap vào QuizCard
  ↓
_startQuiz(quiz)
  ↓
Navigate to QuizScreen
  ↓
initState():
  - _initializeQuiz() → Khởi tạo answers list
  - _startTimer() → Bắt đầu đếm ngược (nếu có time limit)
  ↓
User xem câu hỏi đầu tiên
  ↓
User chọn đáp án
  ↓
User bấm "Next"
  ↓
_submitAnswer() → Lưu đáp án vào _answers
  ↓
_nextQuestion() → Chuyển sang câu tiếp theo
  ↓
Lặp lại cho đến câu cuối
  ↓
User bấm "Submit"
  ↓
_submitQuiz()
  ↓
Tính điểm:
  - _checkAnswer() cho từng câu
  - Tính totalPoints và percentage
  - Kiểm tra pass/fail
  ↓
_saveQuizResult() → Lưu vào Firebase
  ↓
_buildResultsScreen() → Hiển thị kết quả
```

### 5.3. Flow Xem Kết quả

```
User hoàn thành quiz
  ↓
_buildResultsScreen()
  ↓
Hiển thị:
  - Score và percentage
  - Summary (correct/total)
  - Time taken
  - Pass/Fail badge
  ↓
User scroll xem review section
  ↓
Mỗi câu hỏi hiển thị:
  - Question text
  - User's answer (màu đỏ nếu sai, xanh nếu đúng)
  - Correct answer (highlight)
  - Explanation (nếu có)
  ↓
User có thể:
  - Bấm "Retake Quiz" → Làm lại
  - Bấm "Back to List" → Quay lại
```

### 5.4. Flow Xem Lịch sử (My Results)

```
User vào tab "My Results"
  ↓
FutureBuilder → QuizService.getUserQuizResults()
  ↓
Firebase query:
  collection('quiz_results')
    .where('userId', isEqualTo: currentUserId)
    .orderBy('completedAt', descending: true)
  ↓
Hiển thị ListView với:
  - Quiz title
  - Score và percentage
  - Date completed
  - Pass/Fail badge
  ↓
User tap vào result card
  ↓
Navigate to QuizScreen với mode = 'review'
  ↓
Hiển thị quiz với đáp án đã chọn và đáp án đúng
```

---

## 6. Services và Data Flow

### 6.1. QuizService

**Chức năng chính:**
- `getAllQuizzes()`: Lấy tất cả quiz
- `getQuizById(quizId)`: Lấy quiz theo ID
- `getQuizzesByCategory(category)`: Lấy theo category
- `getQuizzesByLessonId(lessonId)`: Lấy quiz của một lesson
- `submitQuizResult()`: Lưu kết quả làm bài
- `getUserQuizResults()`: Lấy lịch sử làm bài của user
- `getUserBestResult(quizId)`: Lấy điểm cao nhất của user cho một quiz

**Firebase Query:**
```dart
// Get all quizzes
final querySnapshot = await _firestore
  .collection('quizzes')
  .where('isActive', isEqualTo: true)
  .orderBy('createdAt', descending: true)
  .get();

// Get user results
final resultsSnapshot = await _firestore
  .collection('quiz_results')
  .where('userId', isEqualTo: userId)
  .orderBy('completedAt', descending: true)
  .get();
```

### 6.2. Data Structure

**Quiz Model:**
```dart
{
  id: string,
  title: string,
  description: string,
  category: string,
  difficultyLevel: number (1-5),
  difficultyLevelName: string,
  questions: List<QuizQuestion>,
  timeLimit: number (minutes, 0 = no limit),
  passingScore: number (0-100),
  totalPoints: number,
  lessonId: string? (null nếu là standalone quiz),
  isActive: boolean,
  createdAt: timestamp,
  updatedAt: timestamp,
}
```

**QuizQuestion:**
```dart
{
  id: string,
  type: string ('multiple_choice', 'true_false', 'text_input', 'matching'),
  question: string,
  options: List<string>?,
  correctAnswers: List<string>,
  points: number,
  explanation: string?,
}
```

**QuizResult:**
```dart
{
  id: string,
  quizId: string,
  userId: string,
  score: number,
  totalPoints: number,
  percentage: number (0-100),
  passed: boolean,
  timeTaken: number (seconds),
  answers: List<QuizAnswer>,
  completedAt: timestamp,
  challengeId: string?,
}
```

---

## 7. Question Types và UI

### 7.1. Multiple Choice

**UI:**
- Radio buttons (single choice) hoặc Checkboxes (multiple choice)
- Mỗi option là một Card có thể tap

**Code:**
```dart
Widget _buildMultipleChoice(QuizQuestion question) {
  return Column(
    children: question.options!.map((option) {
      final isSelected = _selectedAnswers.contains(option);
      return Card(
        child: ListTile(
          title: Text(option),
          leading: Radio<String>(
            value: option,
            groupValue: _selectedAnswers.isNotEmpty 
              ? _selectedAnswers.first 
              : null,
            onChanged: (value) {
              setState(() {
                _selectedAnswers = [value!];
              });
            },
          ),
          onTap: () {
            setState(() {
              _selectedAnswers = [option];
            });
          },
        ),
      );
    }).toList(),
  );
}
```

### 7.2. True/False

**UI:**
- 2 buttons lớn: "True" và "False"

**Code:**
```dart
Widget _buildTrueFalse(QuizQuestion question) {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedAnswers = ['true'];
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAnswers.contains('true') 
              ? Colors.green 
              : null,
          ),
          child: Text('True'),
        ),
      ),
      SizedBox(width: 16),
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedAnswers = ['false'];
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAnswers.contains('false') 
              ? Colors.red 
              : null,
          ),
          child: Text('False'),
        ),
      ),
    ],
  );
}
```

### 7.3. Text Input

**UI:**
- TextField để nhập đáp án

**Code:**
```dart
Widget _buildTextInput(QuizQuestion question) {
  return TextField(
    controller: _textController,
    decoration: InputDecoration(
      hintText: 'Nhập đáp án của bạn',
      border: OutlineInputBorder(),
    ),
    onChanged: (value) {
      setState(() {
        _textAnswer = value;
      });
    },
  );
}
```

---

## 8. Best Practices và Patterns

### 8.1. Timer Management
- **Cancel timer** khi dispose để tránh memory leak
- **Update UI** mỗi giây nhưng không cần rebuild toàn bộ
- **Auto-submit** khi hết thời gian

### 8.2. State Management
- `setState()` cho local state
- `FutureBuilder` cho async data (results list)
- Separate state cho current question và answers

### 8.3. Performance
- **Lazy loading**: Chỉ load quiz khi cần
- **Answer caching**: Lưu đáp án trong memory, chỉ submit khi hoàn thành
- **Optimistic UI**: Hiển thị kết quả ngay, sync với Firebase sau

### 8.4. Error Handling
```dart
try {
  await QuizService.submitQuizResult(...);
  _showResults();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Lỗi khi lưu kết quả: $e'),
      backgroundColor: AppColors.error,
    ),
  );
}
```

---

## 9. Tóm tắt

**Các điểm chính:**
1. **QuizScreen** với timer và progress tracking
2. **Multiple question types**: Multiple choice, True/False, Text input, Matching
3. **Auto-submit** khi hết thời gian
4. **Results screen** với review section
5. **History tracking** trong tab "My Results"

**Các thuật toán quan trọng:**
- Timer: O(1) - update mỗi giây
- Score calculation: O(n) - n là số câu hỏi
- Answer checking: O(n) - n là số đáp án

**UI Components:**
- QuizCard với best result badge
- QuizScreen với timer và progress bar
- ResultsScreen với review section
- SearchDelegate cho tìm kiếm



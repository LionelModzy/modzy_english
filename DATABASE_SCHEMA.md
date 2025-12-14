# 📊 Cấu trúc Database - Modzy English

Tài liệu này mô tả chi tiết tất cả các bảng (collections) và trường dữ liệu trong Firestore của hệ thống Modzy English.

---

## 📋 Tổng quan

Hệ thống sử dụng **Firebase Firestore** với các collection chính và subcollections. Tổng cộng có **12 collection chính** và **8 subcollections** dưới collection `users`.

---

## 1. Collection: `users`

**Mô tả**: Lưu trữ thông tin người dùng của hệ thống

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | uid | String | ID duy nhất của người dùng (document ID) | Trùng với Firebase Auth UID |
| 2 | email | String | Email đăng nhập | Bắt buộc, unique |
| 3 | displayName | String | Tên hiển thị | Bắt buộc |
| 4 | profileImageUrl | String? | URL ảnh đại diện | Optional, lưu trên Cloudinary |
| 5 | role | String | Vai trò người dùng | Giá trị: 'user', 'teacher', 'admin' |
| 6 | createdAt | Timestamp | Thời gian tạo tài khoản | Server timestamp |
| 7 | lastLoginAt | Timestamp? | Thời gian đăng nhập cuối | Optional, server timestamp |
| 8 | isActive | Boolean | Trạng thái hoạt động | Mặc định: true |
| 9 | preferences | Map<String, dynamic> | Tùy chọn cá nhân | JSON object |
| 10 | totalLessonsCompleted | Integer | Tổng số bài học đã hoàn thành | Mặc định: 0 |
| 11 | totalVocabularyLearned | Integer | Tổng số từ vựng đã học | Mặc định: 0 |
| 12 | currentLevel | Integer | Level hiện tại | 1-5 (Beginner → Advanced) |
| 13 | progressPercentage | Double | Phần trăm tiến độ học tập | 0.0 - 100.0 |
| 14 | friends | Array<String> | Danh sách ID bạn bè | Mảng các user ID |

### Subcollections của `users`:

#### 1.1. `users/{userId}/favorites`
**Mô tả**: Lưu trữ các mục yêu thích của người dùng

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | type | String | Loại mục yêu thích | 'vocabulary', 'lesson', 'video' |
| 2 | itemId | String | ID của mục yêu thích | Reference đến collection tương ứng |
| 3 | addedAt | Timestamp | Thời gian thêm vào yêu thích | Server timestamp |

#### 1.2. `users/{userId}/bookmarks`
**Mô tả**: Lưu trữ các từ vựng đã đánh dấu để ôn tập

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | type | String | Loại bookmark | 'vocabulary' |
| 2 | itemId | String | ID từ vựng | Reference đến vocabulary collection |
| 3 | practiceType | String | Loại luyện tập | 'flashcard', 'quiz', etc. |
| 4 | notes | String | Ghi chú của người dùng | Optional |
| 5 | bookmarkedAt | Timestamp | Thời gian đánh dấu | Server timestamp |
| 6 | needsReview | Boolean | Cần ôn tập | Mặc định: true |
| 7 | reviewCount | Integer | Số lần đã ôn tập | Mặc định: 0 |
| 8 | lastReviewed | Timestamp? | Lần ôn tập cuối | Optional |

#### 1.3. `users/{userId}/lesson_progress`
**Mô tả**: Tiến độ học tập bài học của người dùng

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | lessonId | String | ID bài học | Reference đến lessons collection |
| 2 | userId | String | ID người dùng | Reference đến users collection |
| 3 | progressPercentage | Double | Phần trăm hoàn thành | 0.0 - 100.0 |
| 4 | isCompleted | Boolean | Đã hoàn thành | Mặc định: false |
| 5 | startedAt | Timestamp | Thời gian bắt đầu | Server timestamp |
| 6 | completedAt | Timestamp? | Thời gian hoàn thành | Optional |
| 7 | lastAccessedAt | Timestamp | Lần truy cập cuối | Server timestamp |
| 8 | timeSpent | Integer | Thời gian học (giây) | Mặc định: 0 |
| 9 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |

#### 1.4. `users/{userId}/vocabulary_progress`
**Mô tả**: Tiến độ học từ vựng của người dùng

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | vocabularyId | String | ID từ vựng | Reference đến vocabulary collection |
| 2 | userId | String | ID người dùng | Reference đến users collection |
| 3 | masteryLevel | Integer | Mức độ thành thạo | 0-5 (0: chưa học, 5: thành thạo) |
| 4 | timesPracticed | Integer | Số lần luyện tập | Mặc định: 0 |
| 5 | timesCorrect | Integer | Số lần trả lời đúng | Mặc định: 0 |
| 6 | timesWrong | Integer | Số lần trả lời sai | Mặc định: 0 |
| 7 | lastPracticedAt | Timestamp? | Lần luyện tập cuối | Optional |
| 8 | completedAt | Timestamp? | Thời gian hoàn thành | Optional |
| 9 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |

#### 1.5. `users/{userId}/general_progress`
**Mô tả**: Tiến độ học tập tổng quát của người dùng

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | userId | String | ID người dùng | Reference đến users collection |
| 2 | totalLessonsCompleted | Integer | Tổng bài học đã hoàn thành | Mặc định: 0 |
| 3 | totalVocabularyLearned | Integer | Tổng từ vựng đã học | Mặc định: 0 |
| 4 | totalQuizzesCompleted | Integer | Tổng quiz đã làm | Mặc định: 0 |
| 5 | totalGamesPlayed | Integer | Tổng game đã chơi | Mặc định: 0 |
| 6 | currentStreak | Integer | Chuỗi ngày học liên tiếp | Mặc định: 0 |
| 7 | longestStreak | Integer | Chuỗi ngày học dài nhất | Mặc định: 0 |
| 8 | lastActivityAt | Timestamp | Hoạt động cuối cùng | Server timestamp |
| 9 | updatedAt | Timestamp | Thời gian cập nhật | Server timestamp |

#### 1.6. `users/{userId}/lesson_media_progress`
**Mô tả**: Tiến độ xem video/nghe audio của bài học

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | lessonId | String | ID bài học | Reference đến lessons collection |
| 2 | userId | String | ID người dùng | Reference đến users collection |
| 3 | mediaType | String | Loại media | 'video', 'audio' |
| 4 | mediaUrl | String | URL media | URL của video/audio |
| 5 | currentPosition | Integer | Vị trí hiện tại (giây) | Mặc định: 0 |
| 6 | duration | Integer | Tổng thời lượng (giây) | Mặc định: 0 |
| 7 | isCompleted | Boolean | Đã xem/nghe hết | Mặc định: false |
| 8 | lastAccessedAt | Timestamp | Lần truy cập cuối | Server timestamp |

#### 1.7. `users/{userId}/vocabulary_mastery`
**Mô tả**: Mức độ thành thạo từ vựng chi tiết

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | vocabularyId | String | ID từ vựng | Reference đến vocabulary collection |
| 2 | userId | String | ID người dùng | Reference đến users collection |
| 3 | masteryScore | Double | Điểm thành thạo | 0.0 - 100.0 |
| 4 | nextReviewAt | Timestamp | Thời gian ôn tập tiếp theo | Server timestamp |
| 5 | reviewHistory | Array<Map> | Lịch sử ôn tập | Mảng các object |
| 6 | updatedAt | Timestamp | Thời gian cập nhật | Server timestamp |

---

## 2. Collection: `challenges`

**Mô tả**: Lưu trữ các thách đấu giữa người dùng

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | challengerId | String | ID người tạo thách đấu | Reference đến users |
| 2 | challengerName | String | Tên người tạo thách đấu | Display name |
| 3 | opponentId | String | ID người được thách đấu | Reference đến users |
| 4 | opponentName | String | Tên người được thách đấu | Display name |
| 5 | challengeType | String | Loại thách đấu | 'quiz_rush', 'vocab_duel', 'lesson_sprint', etc. |
| 6 | status | String | Trạng thái | 'pending', 'accepted', 'declined', 'completed' |
| 7 | createdAt | Timestamp | Thời gian tạo | Server timestamp |
| 8 | updatedAt | Timestamp | Thời gian cập nhật | Server timestamp |
| 9 | expiresAt | Timestamp | Thời gian hết hạn | Mặc định: +3 ngày |
| 10 | metadata | Map<String, dynamic> | Thông tin chi tiết | JSON object (questions, timeLimit, etc.) |
| 11 | participants | Array<String> | Danh sách người tham gia | [challengerId, opponentId] |
| 12 | results | Map<String, dynamic>? | Kết quả thách đấu | Optional, chứa score của từng người |

**Cấu trúc `results`**:
```json
{
  "userId1": {
    "score": 85,
    "totalPoints": 100,
    "percentage": 85.0,
    "timeSpentSeconds": 120,
    "completedAt": Timestamp
  },
  "userId2": { ... }
}
```

---

## 3. Collection: `friend_requests`

**Mô tả**: Lưu trữ các lời mời kết bạn

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | senderId | String | ID người gửi | Reference đến users |
| 2 | senderName | String | Tên người gửi | Display name |
| 3 | senderAvatar | String? | Avatar người gửi | Optional, URL |
| 4 | receiverId | String | ID người nhận | Reference đến users |
| 5 | receiverName | String | Tên người nhận | Display name |
| 6 | receiverAvatar | String? | Avatar người nhận | Optional, URL |
| 7 | status | String | Trạng thái | 'pending', 'accepted', 'declined', 'cancelled' |
| 8 | createdAt | Timestamp | Thời gian tạo | Server timestamp |
| 9 | updatedAt | Timestamp? | Thời gian cập nhật | Optional, server timestamp |
| 10 | participants | Array<String> | Danh sách người tham gia | [senderId, receiverId] |

---

## 4. Collection: `lessons`

**Mô tả**: Lưu trữ các bài học

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | title | String | Tiêu đề bài học | Bắt buộc |
| 2 | description | String | Mô tả bài học | Bắt buộc |
| 3 | content | String | Nội dung bài học | HTML/Markdown |
| 4 | category | String | Danh mục | 'Grammar', 'Vocabulary', 'Speaking', etc. |
| 5 | difficultyLevel | Integer | Mức độ khó | 1-5 (Beginner → Advanced) |
| 6 | estimatedDuration | Integer | Thời lượng ước tính (phút) | Mặc định: 0 |
| 7 | tags | Array<String> | Thẻ phân loại | Mảng các tag |
| 8 | objectives | Array<String> | Mục tiêu học tập | Mảng các mục tiêu |
| 9 | audioUrl | String? | URL audio chính | Optional, Cloudinary URL |
| 10 | imageUrl | String? | URL ảnh thumbnail | Optional, Cloudinary URL |
| 11 | videoUrl | String? | URL video chính | Optional, Cloudinary URL |
| 12 | sections | Array<Map> | Các phần của bài học | Mảng các LessonSection |
| 13 | vocabulary | Array<String> | Danh sách từ vựng | Mảng các vocabulary ID |
| 14 | createdAt | Timestamp | Thời gian tạo | Server timestamp |
| 15 | updatedAt | Timestamp? | Thời gian cập nhật | Optional, server timestamp |
| 16 | isActive | Boolean | Trạng thái hoạt động | Mặc định: true |
| 17 | isPremium | Boolean | Bài học premium | Mặc định: false |
| 18 | order | Integer | Thứ tự hiển thị | Mặc định: 0 |
| 19 | createdBy | String | ID người tạo | Reference đến users (teacher/admin) |
| 20 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |

**Cấu trúc `sections`** (LessonSection):
```json
{
  "title": "String",
  "content": "String",
  "type": "text|audio|video|exercise",
  "mediaUrl": "String?",
  "metadata": {}
}
```

---

## 5. Collection: `vocabulary`

**Mô tả**: Lưu trữ từ vựng

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | word | String | Từ vựng | Bắt buộc |
| 2 | pronunciation | String | Cách phát âm | Bắt buộc |
| 3 | meaning | String | Nghĩa tiếng Việt | Bắt buộc |
| 4 | definition | String? | Định nghĩa chi tiết | Optional, tiếng Anh |
| 5 | examples | Array<String> | Ví dụ sử dụng | Mảng các câu ví dụ |
| 6 | imageUrl | String? | URL ảnh minh họa | Optional, Cloudinary URL |
| 7 | audioUrl | String? | URL audio phát âm | Optional, Cloudinary URL |
| 8 | category | String | Danh mục | 'Daily', 'Business', 'Academic', etc. |
| 9 | difficultyLevel | Integer | Mức độ khó | 1-5 (Beginner → Advanced) |
| 10 | synonyms | Array<String> | Từ đồng nghĩa | Mảng các từ |
| 11 | antonyms | Array<String> | Từ trái nghĩa | Mảng các từ |
| 12 | partOfSpeech | String | Loại từ | 'noun', 'verb', 'adjective', etc. |
| 13 | lessonIds | Array<String> | Bài học chứa từ này | Mảng các lesson ID |
| 14 | createdAt | Timestamp | Thời gian tạo | Server timestamp |
| 15 | updatedAt | Timestamp? | Thời gian cập nhật | Optional, server timestamp |
| 16 | isActive | Boolean | Trạng thái hoạt động | Mặc định: true |
| 17 | usageCount | Integer | Số lần sử dụng | Mặc định: 0 |
| 18 | createdBy | String | ID người tạo | Reference đến users (teacher/admin) |
| 19 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |

---

## 6. Collection: `quizzes`

**Mô tả**: Lưu trữ các bài quiz

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | title | String | Tiêu đề quiz | Bắt buộc |
| 2 | description | String | Mô tả quiz | Bắt buộc |
| 3 | lessonId | String? | ID bài học liên quan | Optional, reference đến lessons |
| 4 | questions | Array<Map> | Danh sách câu hỏi | Mảng các QuizQuestion |
| 5 | timeLimit | Integer | Thời gian giới hạn (phút) | 0 = không giới hạn |
| 6 | passingScore | Integer | Điểm đạt (phần trăm) | Mặc định: 70 |
| 7 | isActive | Boolean | Trạng thái hoạt động | Mặc định: true |
| 8 | category | String | Danh mục | 'Grammar', 'Vocabulary', etc. |
| 9 | difficultyLevel | Integer | Mức độ khó | 1-5 (Beginner → Advanced) |
| 10 | createdAt | Timestamp | Thời gian tạo | Server timestamp |
| 11 | updatedAt | Timestamp? | Thời gian cập nhật | Optional, server timestamp |
| 12 | createdBy | String | ID người tạo | Reference đến users (teacher/admin) |
| 13 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |

**Cấu trúc `questions`** (QuizQuestion):
```json
{
  "id": "String",
  "question": "String",
  "type": "multipleChoice|multipleSelect|trueFalse|fillInBlank|shortAnswer|matching|ordering",
  "options": ["String"],
  "correctAnswer": "String",
  "correctAnswers": ["String"],
  "explanation": "String?",
  "imageUrl": "String?",
  "audioUrl": "String?",
  "points": Integer,
  "metadata": {}
}
```

---

## 7. Collection: `quiz_results`

**Mô tả**: Lưu trữ kết quả làm quiz của người dùng

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | quizId | String | ID quiz | Reference đến quizzes |
| 2 | userId | String | ID người dùng | Reference đến users |
| 3 | answers | Array<Map> | Danh sách câu trả lời | Mảng các QuizAnswer |
| 4 | score | Integer | Điểm số đạt được | Mặc định: 0 |
| 5 | totalPoints | Integer | Tổng điểm có thể đạt | Mặc định: 0 |
| 6 | percentage | Double | Phần trăm đúng | 0.0 - 100.0 |
| 7 | passed | Boolean | Đã đạt yêu cầu | Dựa trên passingScore |
| 8 | timeSpentSeconds | Integer | Thời gian làm bài (giây) | Mặc định: 0 |
| 9 | completedAt | Timestamp | Thời gian hoàn thành | Server timestamp |
| 10 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |

**Cấu trúc `answers`** (QuizAnswer):
```json
{
  "questionId": "String",
  "selectedAnswers": ["String"],
  "textAnswer": "String?",
  "isCorrect": Boolean,
  "pointsEarned": Integer
}
```

---

## 8. Collection: `challenge_exercises`

**Mô tả**: Lưu trữ các bài tập dùng cho thách đấu

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | title | String | Tiêu đề bài tập | Bắt buộc |
| 2 | description | String | Mô tả bài tập | Bắt buộc |
| 3 | challengeType | String | Loại thách đấu | 'quiz_rush', 'vocab_duel', 'lesson_sprint' |
| 4 | questions | Array<Map> | Danh sách câu hỏi | Mảng các QuizQuestion (giống quizzes) |
| 5 | timeLimit | Integer | Thời gian giới hạn (giây) | Mặc định: 60 |
| 6 | isActive | Boolean | Trạng thái hoạt động | Mặc định: true |
| 7 | category | String | Danh mục | 'Grammar', 'Vocabulary', etc. |
| 8 | difficultyLevel | Integer | Mức độ khó | 1-5 (Beginner → Advanced) |
| 9 | createdAt | Timestamp | Thời gian tạo | Server timestamp |
| 10 | updatedAt | Timestamp? | Thời gian cập nhật | Optional, server timestamp |
| 11 | createdBy | String | ID người tạo | Reference đến users (teacher/admin) |
| 12 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |

---

## 9. Collection: `videos`

**Mô tả**: Lưu trữ video học tập

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | title | String | Tiêu đề video | Bắt buộc |
| 2 | description | String | Mô tả video | Bắt buộc |
| 3 | videoUrl | String | URL video | Bắt buộc, Cloudinary URL |
| 4 | thumbnailUrl | String? | URL thumbnail | Optional, Cloudinary URL |
| 5 | category | String | Danh mục | 'Grammar', 'Vocabulary', etc. |
| 6 | difficultyLevel | Integer | Mức độ khó | 1-5 (Beginner → Advanced) |
| 7 | duration | Integer | Thời lượng (giây) | Mặc định: 0 |
| 8 | tags | Array<String> | Thẻ phân loại | Mảng các tag |
| 9 | subtitles | Array<String> | Danh sách phụ đề | Mảng các URL subtitle |
| 10 | transcript | String? | Bản ghi chữ | Optional |
| 11 | createdAt | Timestamp | Thời gian tạo | Server timestamp |
| 12 | updatedAt | Timestamp? | Thời gian cập nhật | Optional, server timestamp |
| 13 | isActive | Boolean | Trạng thái hoạt động | Mặc định: true |
| 14 | isPremium | Boolean | Video premium | Mặc định: false |
| 15 | viewCount | Integer | Số lượt xem | Mặc định: 0 |
| 16 | rating | Double | Tổng điểm đánh giá | Mặc định: 0.0 |
| 17 | ratingCount | Integer | Số lượt đánh giá | Mặc định: 0 |
| 18 | createdBy | String | ID người tạo | Reference đến users (teacher/admin) |
| 19 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |
| 20 | chapters | Array<Map> | Danh sách chương | Mảng các VideoChapter |

**Cấu trúc `chapters`** (VideoChapter):
```json
{
  "title": "String",
  "startTime": Integer,
  "endTime": Integer,
  "description": "String?"
}
```

---

## 10. Collection: `mini_games`

**Mô tả**: Lưu trữ các mini game học tập

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | gameType | String | Loại game | 'word_match', 'word_scramble', 'word_search' |
| 2 | title | String | Tiêu đề game | Bắt buộc |
| 3 | description | String | Mô tả game | Bắt buộc |
| 4 | difficultyLevel | Integer | Mức độ khó | 1-5 (Beginner → Advanced) |
| 5 | category | String | Danh mục | 'Vocabulary', 'Grammar', etc. |
| 6 | vocabularyIds | Array<String> | Danh sách từ vựng | Mảng các vocabulary ID |
| 7 | gameData | Map<String, dynamic> | Dữ liệu game | JSON object (game-specific) |
| 8 | createdAt | Timestamp | Thời gian tạo | Server timestamp |
| 9 | updatedAt | Timestamp? | Thời gian cập nhật | Optional, server timestamp |
| 10 | isActive | Boolean | Trạng thái hoạt động | Mặc định: true |
| 11 | createdBy | String | ID người tạo | Reference đến users (teacher/admin) |
| 12 | playCount | Integer | Số lượt chơi | Mặc định: 0 |
| 13 | averageScore | Double | Điểm trung bình | Mặc định: 0.0 |
| 14 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |

---

## 11. Collection: `game_scores`

**Mô tả**: Lưu trữ điểm số khi chơi mini game

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | userId | String | ID người dùng | Reference đến users |
| 2 | gameId | String | ID game | Reference đến mini_games |
| 3 | gameType | String | Loại game | 'word_match', 'word_scramble', etc. |
| 4 | score | Integer | Điểm số đạt được | Mặc định: 0 |
| 5 | maxScore | Integer | Điểm tối đa | Mặc định: 0 |
| 6 | timeSeconds | Integer | Thời gian chơi (giây) | Mặc định: 0 |
| 7 | correctAnswers | Integer | Số câu trả lời đúng | Mặc định: 0 |
| 8 | wrongAnswers | Integer | Số câu trả lời sai | Mặc định: 0 |
| 9 | accuracy | Double | Độ chính xác (%) | 0.0 - 100.0 |
| 10 | playedAt | Timestamp | Thời gian chơi | Server timestamp |
| 11 | gameDetails | Map<String, dynamic> | Chi tiết game | JSON object |

---

## 12. Collection: `lesson_notes`

**Mô tả**: Lưu trữ ghi chú của người dùng về bài học

| STT | Tên trường | Kiểu dữ liệu | Mô tả | Ghi chú |
|-----|-----------|--------------|-------|---------|
| 1 | lessonId | String | ID bài học | Reference đến lessons |
| 2 | userId | String | ID người dùng | Reference đến users |
| 3 | title | String | Tiêu đề ghi chú | Bắt buộc |
| 4 | content | String | Nội dung ghi chú | Bắt buộc |
| 5 | createdAt | Timestamp | Thời gian tạo | Server timestamp |
| 6 | updatedAt | Timestamp? | Thời gian cập nhật | Optional, server timestamp |
| 7 | metadata | Map<String, dynamic> | Dữ liệu bổ sung | JSON object |

---

## 📊 Tổng kết

### Collections chính: 12
1. `users` (với 8 subcollections)
2. `challenges`
3. `friend_requests`
4. `lessons`
5. `vocabulary`
6. `quizzes`
7. `quiz_results`
8. `challenge_exercises`
9. `videos`
10. `mini_games`
11. `game_scores`
12. `lesson_notes`

### Subcollections của `users`: 8
1. `favorites`
2. `bookmarks`
3. `lesson_progress`
4. `vocabulary_progress`
5. `general_progress`
6. `lesson_media_progress`
7. `vocabulary_mastery`
8. `quiz_results` (có thể là subcollection hoặc top-level)

### Tổng số bảng: 20 (12 collections + 8 subcollections)

---

**Ghi chú**: 
- Tất cả các trường `Timestamp` sử dụng `FieldValue.serverTimestamp()` khi tạo/cập nhật
- Các trường `Map<String, dynamic>` có thể chứa dữ liệu JSON tùy chỉnh
- Các URL media (imageUrl, videoUrl, audioUrl) được lưu trữ trên Cloudinary
- Tất cả các collection đều có security rules trong `firestore.rules`


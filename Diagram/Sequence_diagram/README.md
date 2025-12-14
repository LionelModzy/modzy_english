# 📊 Sequence Diagrams - Modzy English

Thư mục này chứa các sơ đồ trình tự (Sequence Diagrams) mô tả chi tiết luồng hoạt động của từng chức năng chính trong ứng dụng Modzy English.

## 📋 Danh sách Sequence Diagrams

### 1. **SD_01_Register.puml** - Đăng ký tài khoản
- **Mô tả**: Luồng đăng ký tài khoản mới với email và mật khẩu
- **Các thành phần tham gia**:
  - Register Screen
  - Auth Repository
  - Firebase Service
  - Firebase Auth
  - Firestore
- **Các luồng chính**:
  - Main Flow: Đăng ký thành công
  - Alternative Flows: Hủy đăng ký, lỗi mạng, lỗi Firestore

### 2. **SD_02_Login.puml** - Đăng nhập
- **Mô tả**: Luồng đăng nhập vào hệ thống với email và mật khẩu
- **Các thành phần tham gia**:
  - Login Screen
  - Preferences Service (Remember Me)
  - Auth Repository
  - Firebase Service
  - Firebase Auth
  - Firestore
  - Home Screen
- **Các luồng chính**:
  - Main Flow: Đăng nhập thành công
  - Alternative Flows: Quên mật khẩu, chưa có tài khoản, lỗi mạng

### 3. **SD_03_CompleteLesson.puml** - Hoàn thành bài học
- **Mô tả**: Luồng hoàn thành một bài học và cập nhật tiến độ
- **Các thành phần tham gia**:
  - Lesson Detail Screen
  - Lesson Player Screen
  - Learning Progress Service
  - User Progress Utils
  - Firestore
  - Home Screen
- **Các luồng chính**:
  - Main Flow: Hoàn thành bài học
  - Alternative Flows: Bài học đã hoàn thành, chưa xem đủ nội dung, lên level

### 4. **SD_04_TakeQuiz.puml** - Làm bài kiểm tra
- **Mô tả**: Luồng làm bài quiz từ đầu đến khi nộp bài và xem kết quả
- **Các thành phần tham gia**:
  - Quiz List Screen
  - Quiz Screen
  - Quiz Service
  - Challenge Service (nếu là challenge)
  - Firestore
- **Các luồng chính**:
  - Main Flow: Làm quiz và nộp bài
  - Alternative Flows: Hết thời gian, quiz không có timer

### 5. **SD_05_PracticeVocabulary.puml** - Luyện tập từ vựng
- **Mô tả**: Luồng luyện tập từ vựng với nhiều chế độ khác nhau
- **Các thành phần tham gia**:
  - Vocabulary Screen
  - Vocabulary Practice Screen
  - Vocabulary Practice Session
  - Vocabulary Service
  - Learning Progress Service
  - Bookmark Service
  - Firestore
  - AudioPlayer
- **Các chế độ luyện tập**:
  - Flashcard
  - Multiple Choice
  - Typing
  - Listening
- **Các luồng chính**:
  - Main Flow: Luyện tập và lưu kết quả
  - Alternative Flows: Bookmark từ vựng, nghe phát âm

### 6. **SD_06_PlayMiniGame.puml** - Chơi mini game
- **Mô tả**: Luồng chơi các mini game (Word Match, Word Scramble, Word Search)
- **Các thành phần tham gia**:
  - Mini Games Menu Screen
  - Game Screen (Word Match/Scramble/Search)
  - Mini Game Service
  - Vocabulary Service
  - Firestore
- **Các loại game**:
  - Word Match Game: Ghép từ với nghĩa
  - Word Scramble Game: Sắp xếp chữ cái
  - Word Search Game: Tìm từ trong lưới
- **Các luồng chính**:
  - Main Flow: Chơi game và lưu điểm
  - Alternative Flows: Hết thời gian, xem leaderboard, xem lịch sử

### 7. **SD_07_SendFriendRequest.puml** - Gửi lời mời kết bạn
- **Mô tả**: Luồng tìm kiếm và gửi lời mời kết bạn cho người dùng khác
- **Các thành phần tham gia**:
  - Friend Challenge Screen
  - Friend Service
  - Friend Request Service
  - Firestore
- **Các luồng chính**:
  - Main Flow: Tìm kiếm và gửi lời mời
  - Alternative Flows: Tìm theo Friend Code, xem lời mời đã gửi/nhận

### 8. **SD_08_CreateChallenge.puml** - Tạo thách đấu
- **Mô tả**: Luồng tạo thách đấu với bạn bè (Quiz, Mini Game, Challenge Exercise)
- **Các thành phần tham gia**:
  - Friend Challenge Screen
  - Challenge Template Sheet
  - Friend Service
  - Challenge Service
  - Quiz Service
  - Mini Game Service
  - Challenge Exercise Service
  - Firestore
- **Các loại challenge**:
  - Quiz Challenge
  - Mini Game Challenge
  - Challenge Exercise
- **Các luồng chính**:
  - Main Flow: Tạo và gửi challenge
  - Alternative Flows: Friend chấp nhận/từ chối, challenge hết hạn

### 9. **SD_09_TeacherCreateLesson.puml** - Giáo viên tạo bài học
- **Mô tả**: Luồng giáo viên tạo bài học mới với upload media (video, audio, hình ảnh)
- **Các thành phần tham gia**:
  - Teacher Dashboard
  - Create Lesson Screen
  - Media Upload Widget
  - Cloudinary Service
  - Lesson Service
  - Vocabulary Service
  - Firestore
- **Các luồng chính**:
  - Main Flow: Tạo bài học với sections và media
  - Alternative Flows: Xóa section, sắp xếp sections, upload thất bại, edit bài học

### 10. **SD_10_AdminManageUsers.puml** - Quản trị viên quản lý người dùng
- **Mô tả**: Luồng quản trị viên quản lý người dùng (xem, tìm kiếm, chỉnh sửa, vô hiệu hóa, thay đổi vai trò)
- **Các thành phần tham gia**:
  - Admin Dashboard
  - User Management Screen
  - User Management Service
  - Firebase Service
  - Firestore
  - Firebase Auth
- **Các chức năng**:
  - Xem danh sách người dùng
  - Tìm kiếm người dùng
  - Xem chi tiết người dùng
  - Chỉnh sửa thông tin người dùng
  - Vô hiệu hóa/Kích hoạt người dùng
  - Thay đổi vai trò người dùng
- **Các luồng chính**:
  - Main Flow: Các thao tác quản lý người dùng
  - Alternative Flows: Filter users, xem thống kê, hành động hàng loạt

---

## 🛠️ Công nghệ sử dụng

Các sequence diagrams được tạo bằng **PlantUML** và mô tả luồng hoạt động với các công nghệ:

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Media Storage**: Cloudinary
- **State Management**: Riverpod
- **Services**: Các service layer trong ứng dụng

---

## 📖 Cách sử dụng

### Xem Sequence Diagrams

1. **Cài đặt PlantUML**:
   - Cài đặt Java: https://www.java.com/
   - Tải PlantUML: http://plantuml.com/download
   - Hoặc sử dụng extension PlantUML trong VS Code

2. **Xem trong VS Code**:
   - Cài đặt extension "PlantUML"
   - Mở file `.puml`
   - Nhấn `Alt+D` để xem preview

3. **Tạo hình ảnh**:
   ```bash
   java -jar plantuml.jar SD_01_Register.puml
   ```

### Cấu trúc file

Mỗi file sequence diagram có cấu trúc:
- **Header**: Tiêu đề và mô tả
- **Actors/Participants**: Các đối tượng tham gia
- **Main Flow**: Luồng chính của chức năng
- **Alternative Flows**: Các luồng phụ, xử lý lỗi, các trường hợp đặc biệt

---

## 🔗 Liên kết với các diagram khác

Các sequence diagrams này bổ sung cho:
- **Use Case Diagrams**: `Use_Case/` - Mô tả các use cases
- **Activity Diagrams**: `Diagram/Activity_diagram/` - Mô tả luồng hoạt động chi tiết

---

## 📝 Ghi chú

- Tất cả các sequence diagrams được tạo dựa trên phân tích codebase thực tế
- Các thành phần (participants) được đặt tên theo các class/service trong code
- Các luồng xử lý lỗi và alternative flows được mô tả chi tiết
- Các ghi chú (notes) giải thích các thông tin quan trọng trong từng bước

---

## ✅ Checklist

- [x] SD_01_Register - Đăng ký tài khoản
- [x] SD_02_Login - Đăng nhập
- [x] SD_03_CompleteLesson - Hoàn thành bài học
- [x] SD_04_TakeQuiz - Làm bài kiểm tra
- [x] SD_05_PracticeVocabulary - Luyện tập từ vựng
- [x] SD_06_PlayMiniGame - Chơi mini game
- [x] SD_07_SendFriendRequest - Gửi lời mời kết bạn
- [x] SD_08_CreateChallenge - Tạo thách đấu
- [x] SD_09_TeacherCreateLesson - Giáo viên tạo bài học
- [x] SD_10_AdminManageUsers - Quản trị viên quản lý người dùng

---

*Tài liệu được tạo tự động từ phân tích codebase - Modzy English Project*

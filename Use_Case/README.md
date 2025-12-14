# 📚 Use Cases - Modzy English

Thư mục này chứa các use case diagram chi tiết (phân rã) của dự án Modzy English.

## 📋 Danh sách Use Cases

### 🔐 Authentication & User Management

1. **[UC_01_Register.puml](UC_01_Register.puml)** - Đăng ký tài khoản
   - Mô tả: Người dùng tạo tài khoản mới với email và mật khẩu
   - Actors: User
   - Flow: Validate → Firebase Auth → Firestore → Khởi tạo stats

2. **[UC_02_Login.puml](UC_02_Login.puml)** - Đăng nhập
   - Mô tả: Người dùng đăng nhập vào hệ thống
   - Actors: User, Teacher, Admin
   - Flow: Validate → Firebase Auth → Load user data → HomeScreen

### 📚 Learning Content

3. **[UC_03_CompleteLesson.puml](UC_03_CompleteLesson.puml)** - Hoàn thành bài học
   - Mô tả: Người dùng xem và hoàn thành bài học
   - Actors: User
   - Flow: Xem bài học → Phát video/audio → Hoàn thành → Cập nhật progress

4. **[UC_04_TakeQuiz.puml](UC_04_TakeQuiz.puml)** - Làm bài quiz
   - Mô tả: Người dùng làm bài kiểm tra và xem kết quả
   - Actors: User
   - Flow: Chọn quiz → Làm bài → Nộp bài → Tính điểm → Lưu kết quả

5. **[UC_05_PracticeVocabulary.puml](UC_05_PracticeVocabulary.puml)** - Luyện tập từ vựng
   - Mô tả: Người dùng luyện tập từ vựng với các bài tập
   - Actors: User
   - Flow: Chọn từ vựng → Nghe phát âm → Làm bài tập → Đánh dấu đã học

### 🎮 Interactive Learning

6. **[UC_06_PlayMiniGame.puml](UC_06_PlayMiniGame.puml)** - Chơi mini game
   - Mô tả: Người dùng chơi các game học từ vựng
   - Actors: User
   - Flow: Chọn game → Chơi → Tính điểm → Lưu score → Leaderboard
   - Game types: Word Match, Word Scramble, Word Search

### 👥 Social Features

7. **[UC_07_CreateChallenge.puml](UC_07_CreateChallenge.puml)** - Tạo thách đấu
   - Mô tả: Người dùng tạo challenge với bạn bè
   - Actors: User
   - Flow: Chọn bạn bè → Chọn loại challenge → Gửi challenge → Notification

8. **[UC_10_SendFriendRequest.puml](UC_10_SendFriendRequest.puml)** - Gửi lời mời kết bạn
   - Mô tả: Người dùng gửi lời mời kết bạn cho người khác
   - Actors: User
   - Flow: Tìm kiếm user → Gửi request → Notification → Chấp nhận/Từ chối

### 👨‍💼 Admin Features

9. **[UC_08_AdminManageUsers.puml](UC_08_AdminManageUsers.puml)** - Quản lý người dùng (Admin)
   - Mô tả: Admin quản lý tất cả người dùng trong hệ thống
   - Actors: Admin
   - Flow: Xem danh sách → Tìm kiếm → Chỉnh sửa → Vô hiệu hóa/Kích hoạt → Đổi role

### 👨‍🏫 Teacher Features

10. **[UC_09_TeacherCreateLesson.puml](UC_09_TeacherCreateLesson.puml)** - Giáo viên tạo bài học
    - Mô tả: Giáo viên tạo bài học mới với nội dung đầy đủ
    - Actors: Teacher
    - Flow: Nhập thông tin → Thêm sections → Upload media → Lưu bài học

---

## 📊 Use Case Diagram Tổng quan

Xem file **[USE_CASE_DIAGRAM.puml](USE_CASE_DIAGRAM.puml)** để xem toàn bộ use cases và mối quan hệ giữa chúng.

## 📖 Tóm tắt Use Cases

Xem file **[USE_CASES_SUMMARY.md](USE_CASES_SUMMARY.md)** để xem mô tả chi tiết tất cả use cases.

---

## 🛠️ Cách sử dụng

### Xem Use Case Diagram

1. **Sử dụng VS Code Extension:**
   - Cài đặt extension "PlantUML"
   - Mở file `.puml`
   - Nhấn `Alt + D` để preview

2. **Sử dụng Online:**
   - Truy cập http://www.plantuml.com/plantuml
   - Copy nội dung file `.puml`
   - Paste vào editor và xem kết quả

3. **Sử dụng Command Line:**
   ```bash
   # Cài đặt PlantUML
   npm install -g node-plantuml
   
   # Generate PNG
   puml generate UC_01_Register.puml
   ```

### Cấu trúc Use Case Diagram

Mỗi use case diagram bao gồm:
- **Title**: Tên use case
- **Actors**: Các actor tham gia
- **Participants**: Các component/service tham gia
- **Main Flow**: Luồng chính của use case
- **Alternative Flows**: Các luồng thay thế
- **Exception Flows**: Xử lý lỗi

---

## 📝 Ghi chú

- Tất cả các use case đều được mô tả chi tiết với sequence diagram
- Mỗi use case có các alternative flows và exception handling
- Các use case được đánh số theo thứ tự ưu tiên
- File naming convention: `UC_XX_UseCaseName.puml`

---

*Tài liệu được tạo tự động - Modzy English Project*


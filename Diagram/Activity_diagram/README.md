# 📊 Activity Diagrams - Modzy English

Thư mục này chứa các sơ đồ activity (Activity Diagrams) cho các chức năng chính của ứng dụng Modzy English, được vẽ bằng PlantUML.

## 📋 Danh sách Activity Diagrams

### 🔐 Xác thực & Quản lý Tài khoản

1. **AD_01_Register.puml** - Đăng ký tài khoản
   - Mô tả luồng đăng ký tài khoản mới
   - Bao gồm validation, tạo tài khoản Firebase, tạo document Firestore, khởi tạo thống kê

2. **AD_02_Login.puml** - Đăng nhập
   - Mô tả luồng đăng nhập vào hệ thống
   - Bao gồm Remember Me, xác thực Firebase, kiểm tra trạng thái tài khoản

### 📚 Học tập

3. **AD_03_CompleteLesson.puml** - Hoàn thành bài học
   - Mô tả luồng hoàn thành một bài học
   - Bao gồm xem nội dung, đánh dấu hoàn thành, cập nhật tiến độ, kiểm tra lên level

4. **AD_04_TakeQuiz.puml** - Làm bài quiz
   - Mô tả luồng làm bài kiểm tra
   - Bao gồm hiển thị câu hỏi, chọn đáp án, tính điểm, lưu kết quả, cập nhật thống kê

5. **AD_05_PracticeVocabulary.puml** - Luyện tập từ vựng
   - Mô tả luồng luyện tập từ vựng
   - Bao gồm xem từ vựng, nghe phát âm, làm bài tập, đánh dấu đã học

6. **AD_06_PlayMiniGame.puml** - Chơi mini game
   - Mô tả luồng chơi các mini game
   - Bao gồm 3 loại game: Word Match, Word Scramble, Word Search
   - Tính điểm, lưu kết quả, cập nhật leaderboard

### 👥 Tính năng Xã hội

7. **AD_07_SendFriendRequest.puml** - Gửi lời mời kết bạn
   - Mô tả luồng gửi lời mời kết bạn
   - Bao gồm tìm kiếm người dùng, kiểm tra trạng thái, tạo request, gửi notification

8. **AD_08_CreateChallenge.puml** - Tạo thách đấu
   - Mô tả luồng tạo thách đấu với bạn bè
   - Bao gồm chọn bạn bè, chọn loại challenge (Quiz/Game/Exercise), thiết lập deadline

### 👨‍💼 Quản trị

9. **AD_09_AdminManageUsers.puml** - Quản lý người dùng (Admin)
   - Mô tả luồng quản lý người dùng của Admin
   - Bao gồm xem danh sách, tìm kiếm, chỉnh sửa, vô hiệu hóa/kích hoạt, thay đổi vai trò

### 👨‍🏫 Giáo viên

10. **AD_10_TeacherCreateLesson.puml** - Giáo viên tạo bài học
    - Mô tả luồng giáo viên tạo bài học mới
    - Bao gồm nhập thông tin, thêm sections (video/audio/text), upload media, liên kết từ vựng

## 🛠️ Cách sử dụng

### Xem Activity Diagrams

1. **Sử dụng PlantUML Online Editor:**
   - Truy cập: https://plantuml.com/plantuml/uml/
   - Copy nội dung file `.puml` và paste vào editor
   - Diagram sẽ được render tự động

2. **Sử dụng VS Code Extension:**
   - Cài đặt extension "PlantUML" trong VS Code
   - Mở file `.puml` và nhấn `Alt + D` để preview

3. **Sử dụng IntelliJ IDEA:**
   - Cài đặt plugin "PlantUML integration"
   - Mở file `.puml` và xem preview

### Export sang hình ảnh

```bash
# Sử dụng PlantUML jar file
java -jar plantuml.jar AD_01_Register.puml

# Hoặc sử dụng PlantUML server
# Truy cập: http://www.plantuml.com/plantuml/uml/[encoded_url]
```

## 📝 Cấu trúc Activity Diagram

Mỗi activity diagram bao gồm:

- **Start node**: Điểm bắt đầu của luồng
- **Activities**: Các hoạt động được thực hiện
- **Decisions**: Các điểm quyết định (if/else)
- **Loops**: Các vòng lặp (repeat/while)
- **Notes**: Ghi chú giải thích
- **Stop node**: Điểm kết thúc của luồng

## 🔗 Liên quan

- **Use Case Diagrams**: Xem trong thư mục `Use_Case/`
- **Sequence Diagrams**: Xem trong thư mục `Diagram/Sequence_diagram/`

## 📌 Lưu ý

- Tất cả các activity diagrams được tạo dựa trên phân tích codebase thực tế
- Các luồng được mô tả theo logic nghiệp vụ của ứng dụng
- Có thể cần cập nhật khi codebase thay đổi

---

*Tài liệu được tạo tự động từ phân tích codebase - Modzy English Project*


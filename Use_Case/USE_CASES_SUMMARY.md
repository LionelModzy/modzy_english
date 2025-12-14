# 📋 Tổng hợp Use Cases - Modzy English

## 🎯 Tổng quan

Dự án **Modzy English** là một ứng dụng học tiếng Anh với đầy đủ tính năng, hỗ trợ 3 loại người dùng:
- **Người dùng thường (User)**: Học tập và tương tác
- **Giáo viên (Teacher)**: Tạo và quản lý nội dung học tập
- **Quản trị viên (Admin)**: Quản lý toàn bộ hệ thống

---

## 👤 USE CASES CHO NGƯỜI DÙNG THƯỜNG (USER)

### 🔐 1. Xác thực & Quản lý Tài khoản
- **Đăng ký tài khoản**: Tạo tài khoản mới với email và mật khẩu
- **Đăng nhập**: Xác thực và truy cập vào hệ thống
- **Đăng xuất**: Thoát khỏi tài khoản
- **Quên mật khẩu**: Yêu cầu reset mật khẩu qua email
- **Đặt lại mật khẩu**: Tạo mật khẩu mới sau khi nhận link reset
- **Ghi nhớ đăng nhập**: Lưu thông tin đăng nhập để tự động đăng nhập lần sau

### 👤 2. Hồ sơ & Cài đặt
- **Xem hồ sơ cá nhân**: Xem thông tin tài khoản, tiến độ học tập
- **Chỉnh sửa hồ sơ**: Cập nhật tên, email, thông tin cá nhân
- **Tải ảnh đại diện**: Upload và thay đổi ảnh profile (hỗ trợ Cloudinary)
- **Xem lịch sử học tập**: Xem các bài học, quiz đã hoàn thành
- **Xem yêu thích**: Xem danh sách bài học, từ vựng, video đã yêu thích
- **Quản lý cài đặt**: Cấu hình theme, ngôn ngữ, thông báo
- **Xem trợ giúp**: Xem hướng dẫn sử dụng và hỗ trợ

### 📚 3. Bài học (Lessons)
- **Duyệt danh sách bài học**: Xem tất cả bài học có sẵn
- **Tìm kiếm bài học**: Tìm bài học theo từ khóa
- **Lọc bài học**: Lọc theo danh mục (Grammar, Vocabulary, Speaking, Listening, Writing) và độ khó
- **Xem chi tiết bài học**: Xem thông tin chi tiết, mục tiêu, từ vựng liên quan
- **Phát video bài học**: Xem video học tập với player đầy đủ tính năng
- **Phát audio bài học**: Nghe audio bài học với controls
- **Hoàn thành bài học**: Đánh dấu bài học đã hoàn thành
- **Thêm vào yêu thích**: Lưu bài học vào danh sách yêu thích
- **Xem tiến độ bài học**: Xem phần trăm hoàn thành và các section đã học

### 📖 4. Từ vựng (Vocabulary)
- **Duyệt danh sách từ vựng**: Xem tất cả từ vựng có sẵn
- **Tìm kiếm từ vựng**: Tìm theo từ hoặc nghĩa
- **Lọc từ vựng**: Lọc theo danh mục
- **Xem chi tiết từ vựng**: Xem nghĩa, ví dụ, phát âm, hình ảnh
- **Luyện tập từ vựng**: Thực hành từ vựng với các bài tập
- **Nghe phát âm**: Phát âm từ vựng (text-to-speech)
- **Đánh dấu từ vựng**: Bookmark từ vựng để học sau
- **Xóa đánh dấu**: Bỏ bookmark
- **Thêm vào yêu thích**: Lưu từ vựng vào yêu thích

### 📝 5. Bài kiểm tra (Quiz)
- **Duyệt danh sách quiz**: Xem tất cả quiz có sẵn
- **Tìm kiếm quiz**: Tìm quiz theo từ khóa
- **Lọc quiz**: Lọc theo danh mục và độ khó
- **Làm bài quiz**: Trả lời câu hỏi và nộp bài
- **Xem kết quả quiz**: Xem điểm số, câu đúng/sai
- **Xem thống kê quiz**: Xem lịch sử làm quiz, tỉ lệ đúng

### 🎥 6. Video học tập
- **Xem danh sách video**: Duyệt các video học tiếng Anh
- **Phát video**: Xem video với player
- **Thêm video yêu thích**: Lưu video vào danh sách yêu thích

### 🎮 7. Trò chơi Mini (Mini Games)
- **Xem danh sách mini games**: Duyệt các game có sẵn
- **Chơi Word Match Game**: Ghép từ tiếng Anh với nghĩa tiếng Việt
- **Chơi Word Scramble Game**: Sắp xếp lại các chữ cái để tạo từ
- **Chơi Word Search Game**: Tìm từ trong lưới chữ cái
- **Xem điểm số game**: Xem điểm sau khi chơi
- **Xem lịch sử chơi game**: Xem các game đã chơi và điểm số

### 👥 8. Tính năng Xã hội
- **Gửi lời mời kết bạn**: Gửi request kết bạn cho người dùng khác
- **Chấp nhận lời mời**: Đồng ý kết bạn
- **Từ chối lời mời**: Từ chối lời mời kết bạn
- **Xem danh sách bạn bè**: Xem tất cả bạn bè
- **Xóa bạn bè**: Hủy kết bạn
- **Tạo thách đấu**: Tạo challenge với bạn bè (quiz hoặc game)
- **Chấp nhận thách đấu**: Đồng ý tham gia challenge
- **Từ chối thách đấu**: Từ chối challenge
- **Hoàn thành thách đấu**: Hoàn thành challenge đã nhận
- **Xem kết quả thách đấu**: Xem ai thắng, điểm số

### 🏆 9. Bảng xếp hạng (Leaderboard)
- **Xem bảng xếp hạng**: Xem top người dùng
- **Xem xếp hạng theo điểm**: Sắp xếp theo điểm số
- **Xem xếp hạng theo level**: Sắp xếp theo level (Beginner → Advanced)

---

## 👨‍🏫 USE CASES CHO GIÁO VIÊN (TEACHER)

### 📊 1. Bảng điều khiển Giáo viên
- **Xem bảng điều khiển Giáo viên**: Dashboard với thống kê nội dung của mình
- **Xem thống kê nội dung của mình**: Xem số lượng bài học, quiz, từ vựng đã tạo

### 📚 2. Quản lý Bài học
- **Tạo bài học**: Tạo bài học mới với video, audio, nội dung
- **Chỉnh sửa bài học**: Cập nhật thông tin bài học đã tạo

### 📖 3. Quản lý Từ vựng
- **Tạo từ vựng**: Thêm từ vựng mới với nghĩa, ví dụ, phát âm
- **Chỉnh sửa từ vựng**: Cập nhật thông tin từ vựng

### 📝 4. Quản lý Quiz
- **Tạo quiz**: Tạo bài kiểm tra với các câu hỏi
- **Chỉnh sửa quiz**: Cập nhật quiz đã tạo

### 🎮 5. Quản lý Mini Games
- **Tạo mini game**: Tạo game học từ vựng (Word Match, Word Scramble, Word Search)
- **Chỉnh sửa mini game**: Cập nhật game đã tạo

### 🎯 6. Quản lý Challenge Exercises
- **Tạo bài tập challenge**: Tạo bài tập thách đấu
- **Chỉnh sửa bài tập challenge**: Cập nhật bài tập challenge

**Lưu ý**: Giáo viên cũng có thể sử dụng tất cả tính năng của người dùng thường (xem bài học, làm quiz, chơi game, v.v.)

---

## 👨‍💼 USE CASES CHO QUẢN TRỊ VIÊN (ADMIN)

### 📊 1. Bảng điều khiển Admin
- **Xem bảng điều khiển Admin**: Dashboard với thống kê toàn bộ nền tảng
- **Xem thống kê nền tảng**: Xem tổng số người dùng, bài học, quiz, từ vựng, v.v.

### 👥 2. Quản lý Người dùng
- **Xem danh sách người dùng**: Xem tất cả người dùng trong hệ thống
- **Tìm kiếm người dùng**: Tìm người dùng theo tên, email
- **Chỉnh sửa thông tin người dùng**: Cập nhật thông tin người dùng
- **Vô hiệu hóa người dùng**: Khóa tài khoản người dùng
- **Kích hoạt người dùng**: Mở khóa tài khoản
- **Thay đổi vai trò người dùng**: Chuyển đổi giữa User, Teacher, Admin

### 📚 3. Quản lý Bài học
- **Tạo bài học**: Tạo bài học mới
- **Chỉnh sửa bài học**: Cập nhật bài học
- **Xóa bài học**: Xóa bài học khỏi hệ thống
- **Tải lên media bài học**: Upload video, audio cho bài học
- **Kích hoạt/Vô hiệu hóa bài học**: Bật/tắt hiển thị bài học

### 📖 4. Quản lý Từ vựng
- **Tạo từ vựng**: Thêm từ vựng mới
- **Chỉnh sửa từ vựng**: Cập nhật từ vựng
- **Xóa từ vựng**: Xóa từ vựng
- **Tải lên phát âm**: Upload file audio phát âm

### 📝 5. Quản lý Quiz
- **Tạo quiz**: Tạo bài kiểm tra mới
- **Chỉnh sửa quiz**: Cập nhật quiz
- **Xóa quiz**: Xóa quiz
- **Xem thống kê quiz**: Xem số lượt làm, tỉ lệ đạt, v.v.

### 🎮 6. Quản lý Mini Games
- **Tạo mini game**: Tạo game mới
- **Chỉnh sửa mini game**: Cập nhật game
- **Xóa mini game**: Xóa game
- **Xem thống kê game**: Xem số lượt chơi, điểm trung bình

### 🎯 7. Quản lý Challenge Exercises
- **Tạo bài tập challenge**: Tạo bài tập thách đấu
- **Chỉnh sửa bài tập challenge**: Cập nhật bài tập
- **Xóa bài tập challenge**: Xóa bài tập

### 📈 8. Phân tích & Thống kê
- **Xem phân tích người dùng**: Thống kê hành vi, tiến độ người dùng
- **Xem phân tích nội dung**: Thống kê bài học, quiz được sử dụng nhiều nhất
- **Xem báo cáo tiến độ**: Báo cáo tổng hợp tiến độ học tập

### 🗂️ 9. Quản lý Media
- **Tải lên media**: Upload file video, audio, hình ảnh (Firebase Storage + Cloudinary)
- **Quản lý thư viện media**: Xem, xóa, quản lý các file media

**Lưu ý**: Admin có toàn quyền truy cập tất cả tính năng, bao gồm cả tính năng của User và Teacher

---

## 🔗 Mối quan hệ Use Cases

### Extend Relationships (Mở rộng)
- `Hoàn thành bài học` → `Xem tiến độ bài học`
- `Làm bài quiz` → `Xem kết quả quiz`
- `Hoàn thành thách đấu` → `Xem kết quả thách đấu`
- `Chơi game` → `Xem điểm số game`

### Include Relationships (Bao gồm)
- `Xem chi tiết bài học` → `Phát video bài học` + `Phát audio bài học`
- `Luyện tập từ vựng` → `Nghe phát âm`
- `Tạo thách đấu` → `Xem danh sách bạn bè`
- `Chấp nhận thách đấu` → `Làm bài quiz`

---

## 📊 Thống kê Use Cases

- **Tổng số Use Cases**: ~100+
- **Use Cases cho User**: ~50
- **Use Cases cho Teacher**: ~15
- **Use Cases cho Admin**: ~35

---

## 🛠️ Công nghệ sử dụng

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Media Storage**: Cloudinary
- **State Management**: Riverpod
- **Routing**: GoRouter

---

*Tài liệu được tạo tự động từ phân tích codebase - Modzy English Project*


# BÁO CÁO TIẾN ĐỘ DỰ ÁN ỨNG DỤNG HỌC TIẾNG ANH

## Bảng Tiến Độ Thực Hiện

| Tuần thứ | Ngày | Kế hoạch thực hiện |
|----------|------|-------------------|
| 1 | 04/08/2025 | Trao đổi với giảng viên hướng dẫn, xác định đề tài, viết đề cương và đăng ký đề tài |
| 2 | 08/09/2025 | Phân tích yêu cầu hệ thống, xác định các chức năng chính của ứng dụng. Nghiên cứu công nghệ: Flutter, Firebase (Authentication, Firestore, Storage). Thu thập và phân tích các ứng dụng học tiếng Anh tương tự trên thị trường |
| 3 | 15/9 | Thiết kế use case diagram, xác định các actor (User, Admin, Teacher) và các use case chính. Thiết kế sơ đồ hệ thống (System Architecture Diagram), mô hình dữ liệu. Thiết kế cơ sở dữ liệu Firestore: collections (users, lessons, vocabulary, quizzes, mini_games, challenges, friend_requests), xác định các trường dữ liệu và mối quan hệ |
| 4 | 22/9 | Thiết lập môi trường phát triển: cài đặt Flutter SDK, Android Studio, Firebase CLI. Khởi tạo dự án Flutter, cấu hình Firebase (Authentication, Firestore, Storage). Thiết kế UI/UX cơ bản: color scheme, typography, component library. Xây dựng cấu trúc thư mục dự án theo clean architecture |
| 5 | 29/9 | Phát triển màn hình xác thực người dùng (Authentication): Login, Register, Password Reset với Firebase Authentication. Xây dựng các custom widgets cơ bản: CustomTextField, CustomButton, CustomCard. Triển khai routing system và navigation. Xây dựng User Model và User Service để quản lý thông tin người dùng |
| 6 | 6/10 | Phát triển màn hình Home/Dashboard với thống kê tiến độ học tập. Xây dựng Profile Screen: hiển thị thông tin cá nhân, upload ảnh đại diện, cập nhật thông tin. Triển khai Progress Tracking System: theo dõi bài học đã hoàn thành, từ vựng đã học, điểm số. Xây dựng Settings Screen với các tùy chọn cài đặt |
| 7 | 13/10 | Phát triển hệ thống quản lý bài học (Lessons): LessonsScreen với các tab Khám Phá, Tiến Độ, Yêu Thích. Xây dựng LessonDetailScreen hiển thị chi tiết bài học với video, audio, nội dung. Triển khai LessonPlayerScreen với video player và audio player. Xây dựng Lesson Model và Lesson Service, tích hợp với Firestore |
| 8 | 20/10 | Phát triển hệ thống từ vựng (Vocabulary): VocabularyScreen với danh sách từ vựng, tìm kiếm và lọc. Xây dựng VocabularyDetailScreen hiển thị chi tiết từ vựng (nghĩa, ví dụ, phát âm). Triển khai Vocabulary Progress Tracking. Xây dựng Quiz System: tạo quiz, làm bài quiz, xem kết quả và thống kê |
| 9 | 27/10 | Phát triển Mini Games System: Word Match Game, Word Scramble Game, Word Search Game. Xây dựng Game Service để quản lý điểm số và leaderboard. Triển khai Video Learning System: VideoScreen để xem các video học tiếng Anh. Xây dựng Learning History: lịch sử học tập, bài học đã hoàn thành, quiz đã làm |
| 10 | 10/11 | Phát triển Social Features: Friend System (gửi/nhận lời mời kết bạn, danh sách bạn bè), Challenge System (thách đấu bạn bè trong quiz và games). Xây dựng Leaderboard Screen hiển thị bảng xếp hạng người dùng. Triển khai Favorites System: lưu bài học, từ vựng, video yêu thích |
| 11 | 17/11 | Phát triển Admin Panel: Admin Dashboard với thống kê tổng quan, User Management (quản lý người dùng), Content Management (quản lý bài học, từ vựng, quiz, games). Xây dựng Teacher Role: giao diện cho giáo viên tạo và quản lý nội dung học tập. Triển khai Firestore Security Rules để bảo mật dữ liệu. Xây dựng Analytics và Reporting System |
| 12 | 25/11 | Testing toàn diện: Unit testing, Integration testing, UI testing. Sửa lỗi (bug fixing) và tối ưu hóa hiệu năng ứng dụng. Tối ưu hóa UI/UX, cải thiện trải nghiệm người dùng. Hoàn thiện tài liệu: README, API documentation, User Guide. Chuẩn bị báo cáo cuối kỳ và demo sản phẩm |

---

## Chi Tiết Các Giai Đoạn

### Giai Đoạn 1: Phân Tích và Thiết Kế (Tuần 2-3)
- **Phân tích yêu cầu**: Xác định các chức năng chính, nghiên cứu công nghệ
- **Thiết kế Use Case**: Vẽ use case diagram, xác định các actor và use case
- **Thiết kế hệ thống**: System architecture, data flow, component diagram
- **Thiết kế cơ sở dữ liệu**: Firestore collections, data models, relationships

### Giai Đoạn 2: Thiết Lập Môi Trường và UI Cơ Bản (Tuần 4-5)
- **Setup môi trường**: Flutter, Firebase, cấu trúc dự án
- **Authentication System**: Login, Register, Password Reset
- **UI Components**: Custom widgets, theme, color scheme

### Giai Đoạn 3: Phát Triển Tính Năng Cốt Lõi (Tuần 6-7)
- **User Management**: Profile, Settings, Progress Tracking
- **Lessons System**: Hiển thị, chi tiết, player (video/audio)

### Giai Đoạn 4: Phát Triển Tính Năng Học Tập (Tuần 8-9)
- **Vocabulary System**: Quản lý từ vựng, theo dõi tiến độ
- **Quiz System**: Tạo và làm quiz, xem kết quả
- **Mini Games**: 3 trò chơi học từ vựng
- **Video Learning**: Xem video học tiếng Anh

### Giai Đoạn 5: Tính Năng Xã Hội và Quản Trị (Tuần 10-11)
- **Social Features**: Friends, Challenges, Leaderboard
- **Admin Panel**: Quản lý người dùng, nội dung, thống kê
- **Teacher Role**: Tạo và quản lý nội dung học tập

### Giai Đoạn 6: Hoàn Thiện (Tuần 12)
- **Testing**: Unit test, Integration test, UI test
- **Bug Fixing**: Sửa lỗi và tối ưu hóa
- **Documentation**: Tài liệu hướng dẫn, báo cáo

---

## Các Tính Năng Chính Đã Xác Định

1. **Authentication & User Management**
   - Đăng nhập, đăng ký, đặt lại mật khẩu
   - Quản lý hồ sơ người dùng
   - Theo dõi tiến độ học tập

2. **Learning Content**
   - Bài học (Lessons) với video, audio, nội dung
   - Từ vựng (Vocabulary) với nghĩa, ví dụ, phát âm
   - Quiz kiểm tra kiến thức
   - Video học tiếng Anh

3. **Interactive Learning**
   - Mini Games (Word Match, Word Scramble, Word Search)
   - Challenge System (thách đấu bạn bè)
   - Leaderboard (bảng xếp hạng)

4. **Social Features**
   - Friend System (kết bạn)
   - Challenge System (thách đấu)
   - Favorites (yêu thích)

5. **Admin & Teacher**
   - Admin Panel (quản lý toàn bộ hệ thống)
   - Teacher Role (tạo và quản lý nội dung)

---

*Báo cáo được tạo ngày: 2025*


# 🗺️ Mind Map - Modzy English

Thư mục này chứa các sơ đồ mind map (bản đồ tư duy) các chức năng của ứng dụng Modzy English, được vẽ bằng PlantUML.

## 📋 Danh sách Mind Maps

### 1. **MIND_MAP_SIMPLE.puml** - Mind Map Đơn giản
- **Mô tả**: Mind map đơn giản theo yêu cầu ban đầu, chỉ bao gồm User và Admin
- **Cấu trúc**:
  - **User**: Authentication & Account, Learning & Practice, Progress Tracking, Videos
  - **Admin**: Content Management, User Management, Analytics
- **Sử dụng**: Phù hợp cho tài liệu tổng quan, giới thiệu nhanh

### 2. **MIND_MAP_COMPLETE.puml** - Mind Map Đầy đủ
- **Mô tả**: Mind map đầy đủ tất cả tính năng dựa trên codebase thực tế
- **Cấu trúc**:
  - **User**: 9 nhóm chức năng chính với ~50 tính năng chi tiết
  - **Teacher**: Dashboard, Content Management, Media Management
  - **Admin**: Dashboard, User Management, Content Management, Analytics, Media Management
- **Sử dụng**: Tài liệu kỹ thuật, phân tích hệ thống, documentation đầy đủ

## 🎨 Màu sắc và Phân loại

### User (Màu xanh dương - #E3F2FD)
- **Authentication & Account** (Vàng nhạt): Đăng ký, Đăng nhập, Quên mật khẩu
- **Profile & Settings** (Xanh nhạt): Hồ sơ, Cài đặt, Lịch sử, Yêu thích
- **Lessons** (Xanh lá): Bài học, Video, Audio
- **Vocabulary** (Xanh lá nhạt): Từ vựng, Flashcard, Luyện tập
- **Quiz** (Xanh lá rất nhạt): Bài kiểm tra, Kết quả, Thống kê
- **Videos** (Cam nhạt): Video học tập
- **Mini Games** (Hồng): Word Match, Word Scramble, Word Search
- **Social Features** (Tím nhạt): Kết bạn, Thách đấu
- **Leaderboard** (Tím): Bảng xếp hạng

### Teacher (Màu cam - #FFF3E0)
- **Dashboard**: Thống kê nội dung
- **Content Management**: Quản lý Bài học, Từ vựng, Quiz, Games, Challenge
- **Media Management**: Upload media

### Admin (Màu đỏ nhạt - #FFEBEE)
- **Dashboard**: Thống kê nền tảng
- **User Management**: Quản lý người dùng, Phân quyền
- **Content Management**: CRUD đầy đủ cho tất cả nội dung
- **Analytics & Reports**: Phân tích và báo cáo
- **Media Management**: Quản lý thư viện media

## 📊 Thống kê

### Mind Map Đơn giản:
- **Tổng số nhánh**: 2 (User, Admin)
- **Tổng số tính năng**: ~20

### Mind Map Đầy đủ:
- **Tổng số nhánh**: 3 (User, Teacher, Admin)
- **Tổng số tính năng**: ~100+
- **User**: ~50 tính năng
- **Teacher**: ~15 tính năng
- **Admin**: ~35 tính năng

## 🚀 Cách sử dụng

### Xem Mind Map trong PlantUML:

1. **Online**: 
   - Truy cập http://www.plantuml.com/plantuml/uml/
   - Copy nội dung file `.puml`
   - Paste vào editor và xem kết quả

2. **VS Code Extension**:
   - Cài đặt extension "PlantUML"
   - Mở file `.puml`
   - Nhấn `Alt+D` để preview

3. **Export sang hình ảnh**:
   - Sử dụng PlantUML jar file
   - Hoặc sử dụng online tool để export PNG/SVG

### Ví dụ lệnh export:
```bash
java -jar plantuml.jar MIND_MAP_COMPLETE.puml -tpng
java -jar plantuml.jar MIND_MAP_COMPLETE.puml -tsvg
```

## 📝 Ghi chú

- Mind Map đơn giản phù hợp cho **presentation** và **giới thiệu nhanh**
- Mind Map đầy đủ phù hợp cho **tài liệu kỹ thuật** và **phân tích hệ thống**
- Tất cả tính năng trong mind map đều dựa trên codebase thực tế trong `lib/features/`
- Màu sắc được thiết kế để dễ phân biệt các nhóm chức năng

---

*Tài liệu được tạo tự động từ phân tích codebase - Modzy English Project*


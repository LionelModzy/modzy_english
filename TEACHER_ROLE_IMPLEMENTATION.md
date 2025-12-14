# Teacher Role Implementation - Hướng dẫn Triển khai Vai trò Giáo viên

## 📋 Tổng quan

Đã thêm vai trò **Teacher** vào hệ thống với các quyền hạn chế so với Admin. Giáo viên có thể tạo và quản lý nội dung học tập nhưng không có quyền quản lý người dùng hoặc cài đặt hệ thống.

## 🎯 Quyền hạn của Giáo viên

### ✅ Giáo viên CÓ THỂ:

1. **Quản lý Bài học (Lessons)**
   - Tạo bài học mới
   - Chỉnh sửa bài học do mình tạo
   - Xóa bài học do mình tạo

2. **Quản lý Từ vựng (Vocabulary)**
   - Thêm từ vựng mới
   - Chỉnh sửa từ vựng do mình tạo
   - Xóa từ vựng do mình tạo

3. **Quản lý Quiz**
   - Tạo quiz mới
   - Chỉnh sửa quiz do mình tạo
   - Xóa quiz do mình tạo

4. **Quản lý Mini Games**
   - Tạo mini game mới
   - Chỉnh sửa mini game do mình tạo
   - Xóa mini game do mình tạo

5. **Quản lý Challenge Exercises**
   - Tạo bài tập challenge mới
   - Chỉnh sửa bài tập challenge do mình tạo
   - Xóa bài tập challenge do mình tạo

6. **Xem thống kê nội dung của mình**
   - Xem số lượng bài học/quiz/vocabulary/games đã tạo

### ❌ Giáo viên KHÔNG THỂ:

1. **Quản lý Người dùng**
   - Xem danh sách người dùng
   - Kích hoạt/vô hiệu hóa tài khoản
   - Thay đổi role của người dùng

2. **Quản lý nội dung của giáo viên khác**
   - Chỉnh sửa bài học/quiz/vocabulary do giáo viên khác tạo
   - Xóa nội dung do giáo viên khác tạo

3. **Truy cập Analytics toàn hệ thống**
   - Chỉ có thể xem thống kê nội dung của mình

4. **Cài đặt Hệ thống**
   - Không có quyền truy cập cài đặt hệ thống

5. **Quản lý User Management**
   - Không thể quản lý tài khoản người dùng

## 🏗️ Kiến trúc Triển khai

### 1. UserModel Updates

**File:** `lib/models/user_model.dart`

- Thêm hỗ trợ role `'teacher'`
- Thêm getter `isTeacher`
- Thêm getter `canManageContent` (true cho cả admin và teacher)

```dart
bool get isTeacher => role == 'teacher';
bool get canManageContent => isAdmin || isTeacher;
```

### 2. Vocabulary Model Updates

**File:** `lib/models/vocab_model.dart`

- Thêm trường `createdBy` để track người tạo từ vựng
- Cập nhật tất cả constructors và methods

### 3. Teacher Dashboard

**File:** `lib/features/teacher/screens/teacher_dashboard_screen.dart`

- Dashboard riêng cho giáo viên với màu sắc khác admin
- Hiển thị thống kê nội dung của giáo viên
- Quick access đến các tính năng quản lý nội dung

### 4. Firestore Security Rules

**File:** `firestore.rules`

Đã thêm các helper functions:
- `isTeacher()` - Kiểm tra user là giáo viên
- `canManageContent()` - Kiểm tra user có thể quản lý nội dung (admin hoặc teacher)
- `isContentOwner(createdBy)` - Kiểm tra user là chủ sở hữu nội dung

Các collection rules đã được cập nhật:
- `lessons`: Teacher có thể tạo/sửa/xóa bài học của mình
- `vocabulary`: Teacher có thể tạo/sửa/xóa từ vựng của mình
- `quizzes`: Teacher có thể tạo/sửa/xóa quiz của mình
- `mini_games`: Teacher có thể tạo/sửa/xóa mini games của mình
- `challenge_exercises`: Teacher có thể tạo/sửa/xóa challenge exercises của mình

### 5. Home Screen Updates

**File:** `lib/features/home/screens/home_screen.dart`

- Thêm `_TeacherCard` widget
- Hiển thị Teacher Panel cho giáo viên (không phải admin)
- Admin vẫn thấy Admin Panel, Teacher thấy Teacher Panel

## 📝 Cách Sử dụng

### Tạo tài khoản Giáo viên

1. Tạo tài khoản người dùng bình thường qua app
2. Vào Firebase Console → Firestore → Collection `users`
3. Tìm document của người dùng
4. Cập nhật field `role` từ `'user'` thành `'teacher'`
5. Lưu thay đổi

### Quy trình làm việc của Giáo viên

1. **Đăng nhập** với tài khoản giáo viên
2. **Truy cập Teacher Panel** từ Home Screen
3. **Tạo nội dung**:
   - Chọn loại nội dung cần tạo (Lesson, Quiz, Vocabulary, etc.)
   - Điền thông tin và lưu
   - Hệ thống tự động gán `createdBy` với UID của giáo viên
4. **Quản lý nội dung**:
   - Xem danh sách nội dung đã tạo
   - Chỉnh sửa/xóa nội dung của mình
   - Không thể sửa/xóa nội dung của giáo viên khác

## 🔐 Bảo mật

### Firestore Rules

Tất cả các rules đảm bảo:
- Giáo viên chỉ có thể tạo nội dung với `createdBy` = UID của mình
- Giáo viên chỉ có thể sửa/xóa nội dung mà mình đã tạo
- Admin có thể quản lý tất cả nội dung
- Người dùng thường chỉ có thể đọc nội dung

### Validation

- Khi tạo nội dung mới, `createdBy` tự động được gán từ `AuthRepository.getCurrentUserData()`
- Firestore rules kiểm tra `createdBy` khi update/delete

## 🎨 UI/UX

### Teacher Dashboard

- **Màu sắc**: Cyan/Secondary blue (khác với Admin purple)
- **Layout**: Tương tự Admin Dashboard nhưng chỉ hiển thị các tính năng quản lý nội dung
- **Statistics**: Chỉ hiển thị thống kê nội dung của giáo viên

### Teacher Panel Card (Home Screen)

- Gradient màu cyan/secondary
- Icon: `Icons.school_rounded`
- Text: "Teacher Panel"

## 🔄 Workflow Hoàn chỉnh

### Scenario 1: Giáo viên tạo bài học mới

1. Giáo viên đăng nhập → Thấy Teacher Panel trên Home
2. Click "Open Teacher Dashboard"
3. Click "Quản lý Bài học"
4. Click "Tạo bài học mới"
5. Điền thông tin bài học
6. Hệ thống tự động:
   - Gán `createdBy` = UID của giáo viên
   - Lưu vào Firestore với permission kiểm tra
7. Bài học được lưu thành công

### Scenario 2: Giáo viên chỉnh sửa bài học của mình

1. Giáo viên vào Teacher Dashboard → Quản lý Bài học
2. Tìm bài học do mình tạo
3. Click "Chỉnh sửa"
4. Sửa thông tin
5. Firestore rules kiểm tra `createdBy` == UID của giáo viên
6. Cho phép cập nhật

### Scenario 3: Giáo viên cố gắng sửa bài học của giáo viên khác

1. Giáo viên vào Teacher Dashboard → Quản lý Bài học
2. Tìm bài học do giáo viên khác tạo
3. Click "Chỉnh sửa" (nếu UI cho phép)
4. Cập nhật thất bại
5. Firestore rules từ chối vì `createdBy` != UID của giáo viên

## 📊 So sánh Roles

| Tính năng | User | Teacher | Admin |
|-----------|------|---------|-------|
| Học bài học | ✅ | ✅ | ✅ |
| Làm quiz | ✅ | ✅ | ✅ |
| Học từ vựng | ✅ | ✅ | ✅ |
| Tạo bài học | ❌ | ✅ | ✅ |
| Tạo quiz | ❌ | ✅ | ✅ |
| Tạo từ vựng | ❌ | ✅ | ✅ |
| Sửa bài học của người khác | ❌ | ❌ | ✅ |
| Xóa bài học của người khác | ❌ | ❌ | ✅ |
| Quản lý người dùng | ❌ | ❌ | ✅ |
| Xem analytics toàn hệ thống | ❌ | ❌ | ✅ |
| Cài đặt hệ thống | ❌ | ❌ | ✅ |

## 🚀 Tính năng Tương lai (Có thể mở rộng)

1. **Student Management cho Teacher**
   - Giáo viên có thể xem danh sách học sinh
   - Theo dõi tiến độ học tập của học sinh
   - Giao bài tập cho học sinh cụ thể

2. **Assignment System**
   - Giáo viên tạo assignment
   - Giao cho học sinh
   - Chấm điểm và feedback

3. **Teacher Analytics**
   - Thống kê chi tiết về nội dung đã tạo
   - Xem ai đã học bài học của mình
   - Tỷ lệ hoàn thành quiz

4. **Content Approval System**
   - Giáo viên tạo nội dung → Chờ admin duyệt
   - Admin duyệt/từ chối nội dung
   - Nội dung chỉ hiển thị sau khi được duyệt

5. **Teacher Collaboration**
   - Giáo viên có thể chia sẻ nội dung với nhau
   - Tạo nội dung chung
   - Đánh giá nội dung của đồng nghiệp

## ✅ Checklist Triển khai

- [x] Cập nhật UserModel để hỗ trợ role 'teacher'
- [x] Thêm getter isTeacher và canManageContent
- [x] Thêm trường createdBy vào VocabularyModel
- [x] Tạo Teacher Dashboard Screen
- [x] Cập nhật Firestore rules với helper functions mới
- [x] Cập nhật rules cho lessons collection
- [x] Cập nhật rules cho vocabulary collection
- [x] Cập nhật rules cho quizzes collection
- [x] Cập nhật rules cho mini_games collection
- [x] Cập nhật rules cho challenge_exercises collection
- [x] Thêm Teacher Panel Card vào Home Screen
- [x] Cập nhật vocabulary form để gán createdBy
- [x] Lesson form đã có createdBy (không cần sửa)

## 🔧 Troubleshooting

### Giáo viên không thấy Teacher Panel?

- Kiểm tra field `role` trong Firestore = `'teacher'`
- Đăng xuất và đăng nhập lại
- Clear cache ứng dụng

### Giáo viên không thể tạo nội dung?

- Kiểm tra Firestore rules đã được deploy
- Kiểm tra `createdBy` field được gán đúng
- Xem console logs để biết lỗi cụ thể

### Giáo viên có thể sửa nội dung của người khác?

- Kiểm tra Firestore rules có đúng không
- Đảm bảo rules kiểm tra `resource.data.createdBy == request.auth.uid`

## 📚 Files Changed

1. `lib/models/user_model.dart` - Thêm teacher role support
2. `lib/models/vocab_model.dart` - Thêm createdBy field
3. `lib/features/teacher/screens/teacher_dashboard_screen.dart` - NEW FILE
4. `lib/features/home/screens/home_screen.dart` - Thêm Teacher Panel
5. `firestore.rules` - Cập nhật rules cho teacher
6. `lib/features/admin/screens/vocabulary_management_screen.dart` - Gán createdBy

## 🎓 Kết luận

Vai trò Teacher đã được triển khai đầy đủ với:
- Phân quyền rõ ràng (có thể/cannot)
- Security rules chặt chẽ
- UI/UX phù hợp
- Workflow hoàn chỉnh

Giáo viên giờ có thể tạo và quản lý nội dung học tập một cách độc lập mà không cần quyền admin!


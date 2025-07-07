# Hướng dẫn tạo tài khoản Admin - Modzy English

## 📋 Bước 1: Đăng ký tài khoản thường

1. Mở ứng dụng Modzy English
2. Nhấn vào tab **"Đăng ký"**
3. Điền thông tin:
   - **Họ và tên**: Tên quản trị viên
   - **Email**: admin@modzyenglish.com (hoặc email bạn muốn)
   - **Mật khẩu**: Mật khẩu mạnh
   - **Xác nhận mật khẩu**: Nhập lại mật khẩu
4. Nhấn **"Tạo tài khoản"**

## 🔥 Bước 2: Truy cập Firebase Console

1. Đi tới [Firebase Console](https://console.firebase.google.com/)
2. Chọn project **"english-modzy"**
3. Vào **"Firestore Database"**
4. Tìm collection **"users"**

## ⚙️ Bước 3: Chỉnh sửa quyền Admin

1. Trong collection **"users"**, tìm document có email vừa đăng ký
2. Nhấn vào document đó để chỉnh sửa
3. Tìm field **"role"** 
4. Thay đổi giá trị từ `"user"` thành `"admin"`
5. Thêm field **"isAdmin"** với giá trị `true` (boolean)
6. Nhấn **"Save"** để lưu thay đổi

## 🎯 Bước 4: Kiểm tra quyền Admin

1. Đóng và mở lại ứng dụng
2. Đăng nhập với tài khoản vừa tạo
3. Bạn sẽ thấy:
   - Badge **"Administrator"** trên profile
   - Nút **"Admin Panel"** trên màn hình chính
   - Giao diện màu tím khi vào Admin Panel

## 📊 Cấu trúc dữ liệu Admin

```json
{
  "uid": "xM2lNhpTM4XAqIOoVhvjibw9oto2",
  "email": "admin@modzyenglish.com",
  "displayName": "Admin User",
  "role": "admin",
  "isAdmin": true,
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00Z",
  "lastLoginAt": "2024-01-01T00:00:00Z",
  "currentLevel": 1,
  "totalLessonsCompleted": 0,
  "totalVocabularyLearned": 0,
  "progressPercentage": 0.0
}
```

## 🛡️ Firestore Security Rules

Đảm bảo bạn có rules sau trong Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users có thể đọc/ghi dữ liệu của chính họ
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chỉ admin mới được truy cập collections quản trị
    match /admin/{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Dữ liệu học tập - đọc public, ghi chỉ admin
    match /lessons/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /vocabulary/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## ✅ Tính năng Admin có sẵn

- ✅ **Admin Dashboard**: Thống kê tổng quan hệ thống
- ✅ **User Management**: Quản lý người dùng
- ✅ **Role-based Access**: Phân quyền dựa trên vai trò
- ✅ **Purple Theme**: Giao diện riêng cho admin
- 🔄 **Content Management**: Đang phát triển
- 🔄 **Analytics**: Đang phát triển

## 🚨 Lưu ý bảo mật

1. **Không chia sẻ** thông tin đăng nhập admin
2. **Sử dụng mật khẩu mạnh** cho tài khoản admin
3. **Kiểm tra logs** thường xuyên để phát hiện truy cập bất thường
4. **Backup dữ liệu** định kỳ
5. **Chỉ cấp quyền admin** cho người đáng tin cậy

## 🔧 Troubleshooting

### Không thấy nút Admin Panel?
- Kiểm tra lại field `role` và `isAdmin` trong Firestore
- Đăng xuất và đăng nhập lại
- Clear cache ứng dụng

### Không truy cập được Admin Dashboard?
- Kiểm tra Firestore Security Rules
- Đảm bảo field `role` = `"admin"`
- Kiểm tra connection Firebase

### Giao diện không chuyển sang màu tím?
- Force refresh ứng dụng
- Kiểm tra field `isAdmin` = `true`

## 📞 Hỗ trợ

Nếu gặp vấn đề, hãy liên hệ:
- **Email**: tct222072003@gmail.com
- **GitHub Issues**: [Báo lỗi tại đây](https://github.com/your-repo/issues)

---

**Lưu ý**: Hướng dẫn này áp dụng cho phiên bản hiện tại của Modzy English. Các tính năng có thể thay đổi trong các bản cập nhật sau. 
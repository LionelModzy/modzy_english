# Cải thiện tính năng ảnh đại diện

## Các thay đổi đã thực hiện

### 1. Cải thiện đặt tên ảnh
- **Trước**: Sử dụng timestamp đơn giản `profile_1234567890.jpg`
- **Sau**: Format `user_ngaythangnam_giohophut` 
  - Ví dụ: `Nguyen_Van_A_25122024_1430.jpg`
  - Tên người dùng được làm sạch (loại bỏ ký tự đặc biệt)
  - Ngày tháng năm: `ddmmyyyy`
  - Giờ phút: `hhmm`

### 2. Xóa ảnh cũ trên Cloudinary
- **Thêm logic xóa ảnh cũ** trước khi upload ảnh mới
- **Cải thiện hàm `_extractPublicIdFromUrl`** để xử lý đúng public ID từ Cloudinary URL
- **Thêm logging chi tiết** để debug việc xóa ảnh
- **Xử lý lỗi gracefully** - tiếp tục upload ngay cả khi xóa ảnh cũ thất bại

### 3. Cải thiện ProfileImageViewer Widget
- **Thêm parameter `userName`** để tạo tên file hợp lý
- **Thêm parameter `currentImagePublicId`** để xóa ảnh cũ
- **Cải thiện logic upload** với tên file mới
- **Thêm logging** để theo dõi quá trình xóa và upload

### 4. Cập nhật các màn hình
- **ProfileScreen**: Truyền `userName` và `currentImagePublicId`
- **EditProfileScreen**: Truyền `userName` (sử dụng tên hiện tại hoặc tên mới) và `currentImagePublicId`

### 5. Cải thiện CloudinaryService
- **Thêm logging chi tiết** trong hàm `deleteFile`
- **Cải thiện xử lý lỗi** và response
- **Thêm debug information** để theo dõi quá trình xóa

## Cách hoạt động

### 1. Khi người dùng chọn ảnh mới:
1. Hiển thị preview ảnh
2. Người dùng xác nhận sử dụng ảnh
3. **Xóa ảnh cũ** trên Cloudinary (nếu có)
4. **Tạo tên file mới** theo format: `user_ngaythangnam_giohophut`
5. Upload ảnh mới với tên file mới
6. Cập nhật URL trong database

### 2. Format tên file:
```
{userName}_{ddmmyyyy}_{hhmm}
```
- `userName`: Tên người dùng (đã làm sạch ký tự đặc biệt)
- `ddmmyyyy`: Ngày tháng năm (ví dụ: 25122024)
- `hhmm`: Giờ phút (ví dụ: 1430)

### 3. Ví dụ tên file:
- `Nguyen_Van_A_25122024_1430.jpg`
- `Tran_Thi_B_25122024_0915.jpg`
- `user_25122024_1600.jpg` (nếu không có tên người dùng)

## Lợi ích

1. **Tiết kiệm không gian**: Xóa ảnh cũ tự động
2. **Tên file có ý nghĩa**: Dễ quản lý và tìm kiếm
3. **Tránh trùng lặp**: Mỗi ảnh có tên duy nhất
4. **Debug dễ dàng**: Logging chi tiết giúp theo dõi quá trình
5. **Xử lý lỗi tốt**: Không bị crash khi xóa ảnh thất bại

## Files đã thay đổi

1. `lib/core/widgets/profile_image_viewer.dart`
2. `lib/features/profile/screens/profile_screen.dart`
3. `lib/features/profile/screens/edit_profile_screen.dart`
4. `lib/core/services/cloudinary_service.dart`

## Testing

Để test tính năng:
1. Thay đổi ảnh đại diện từ profile screen
2. Kiểm tra console logs để xem quá trình xóa và upload
3. Kiểm tra Cloudinary dashboard để xác nhận ảnh cũ đã bị xóa
4. Kiểm tra tên file mới có đúng format không 
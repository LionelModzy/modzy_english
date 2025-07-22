# Sửa lỗi ảnh đại diện - Tóm tắt

## Vấn đề đã phát hiện

### 1. Không xóa được ảnh cũ
- **Nguyên nhân**: Public ID được trích xuất không đúng từ Cloudinary URL
- **Log lỗi**: `"result":"not found"` khi xóa ảnh

### 2. Tên file bị duplicate
- **Nguyên nhân**: CloudinaryService sử dụng cả `folder` và `public_id` riêng biệt
- **Kết quả**: Tên file thành `profile_images/profile_images/Thanh_Modzy_18072025_0938` thay vì `profile_images/Thanh_Modzy_18072025_0938`

## Các sửa đổi đã thực hiện

### 1. Sửa CloudinaryService
**File**: `lib/core/services/cloudinary_service.dart`

**Thay đổi**:
```dart
// Trước
final publicId = customPublicId ?? '${folder.folderName}_${DateTime.now().millisecondsSinceEpoch}';
request.fields.addAll({
  'upload_preset': _uploadPreset,
  'folder': folder.folderName,  // ❌ Gây duplicate
  'public_id': publicId,
  'resource_type': 'image',
});

// Sau
final publicId = customPublicId != null 
    ? '${folder.folderName}/$customPublicId'  // ✅ Include folder trong public_id
    : '${folder.folderName}_${DateTime.now().millisecondsSinceEpoch}';
request.fields.addAll({
  'upload_preset': _uploadPreset,
  'public_id': publicId,  // ✅ Chỉ dùng public_id
  'resource_type': 'image',
});
```

### 2. Cải thiện hàm trích xuất Public ID
**Files**: `profile_screen.dart`, `edit_profile_screen.dart`

**Thay đổi**:
```dart
// Thêm logging chi tiết để debug
print('Extracting public ID from URL: $url');
print('Path segments: $pathSegments');
print('Path after upload: $pathAfterUpload');

// Logic mới: Tìm folder 'profile_images' và lấy phần sau nó
for (int i = 0; i < parts.length; i++) {
  if (parts[i] == 'profile_images' && i + 1 < parts.length) {
    final publicId = parts.sublist(i + 1).join('/');
    print('Extracted public ID: $publicId');
    return publicId;
  }
}
```

### 3. Cập nhật ProfileImageViewer
**File**: `lib/core/widgets/profile_image_viewer.dart`

**Thay đổi**:
```dart
// Không thêm folder prefix nữa vì CloudinaryService đã xử lý
customPublicId: fileName,  // ✅ Chỉ truyền tên file
```

## Kết quả mong đợi

### 1. Tên file đúng format
- **Trước**: `profile_images/profile_images/Thanh_Modzy_18072025_0938`
- **Sau**: `profile_images/Thanh_Modzy_18072025_0938`

### 2. Xóa ảnh cũ thành công
- Public ID được trích xuất chính xác
- Log sẽ hiển thị: `"result":"ok"` thay vì `"result":"not found"`

### 3. Logging chi tiết
- Có thể theo dõi quá trình trích xuất public ID
- Debug dễ dàng khi có lỗi

## Testing

### 1. Test trên Web
- Upload ảnh mới → Kiểm tra tên file trong Cloudinary
- Thay đổi ảnh → Kiểm tra ảnh cũ có bị xóa không

### 2. Test trên Mobile
- Upload ảnh mới → Kiểm tra tên file
- Thay đổi ảnh → Kiểm tra xóa ảnh cũ

### 3. Kiểm tra Logs
- Xem log `Extracting public ID from URL`
- Xem log `Attempting to delete Cloudinary file`
- Xem log `Delete result`

## Files đã thay đổi

1. `lib/core/services/cloudinary_service.dart` - Sửa logic upload
2. `lib/features/profile/screens/profile_screen.dart` - Cải thiện trích xuất public ID
3. `lib/features/profile/screens/edit_profile_screen.dart` - Cải thiện trích xuất public ID
4. `lib/core/widgets/profile_image_viewer.dart` - Cập nhật upload logic 
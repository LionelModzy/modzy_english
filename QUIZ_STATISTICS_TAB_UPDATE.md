# Cập nhật Quiz Management Screen - Thêm Tab Thống kê

## Tổng quan thay đổi

Đã cập nhật `QuizManagementScreen` để tách riêng phần thống kê thành một tab riêng biệt, giúp tối ưu không gian hiển thị và cải thiện trải nghiệm người dùng.

## Các thay đổi chính

### 1. Cấu trúc Tab mới
- **Trước**: 2 tab (Quiz Hoạt động, Quiz Tạm dừng)
- **Sau**: 3 tab (Quiz Hoạt động, Quiz Tạm dừng, Thống kê)

### 2. Tab Thống kê mới
- **Bộ lọc thông minh**:
  - Lọc theo danh mục (Category)
  - Lọc theo độ khó (Difficulty Level)
  - Lọc theo khoảng thời gian tạo (Date Range)
  - Nút "Đặt lại" để xóa tất cả filter

### 3. Thống kê chi tiết
- **6 thẻ thống kê chính**:
  - Tổng số Quiz
  - Quiz Hoạt động
  - Số danh mục
  - Tổng câu hỏi
  - Tổng điểm
  - Tỷ lệ hoạt động

- **Thống kê theo danh mục**:
  - Hiển thị số lượng quiz theo từng danh mục
  - Phần trăm phân bố
  - Sắp xếp theo số lượng giảm dần

- **Thống kê theo độ khó**:
  - Hiển thị số lượng quiz theo từng cấp độ (1-5)
  - Phần trăm phân bố
  - Màu sắc phân biệt cho từng cấp độ

### 4. Cải thiện UI/UX
- **Responsive Design**: Tối ưu cho các kích thước màn hình khác nhau
- **Tối ưu không gian**: Phần search và tạo quiz chỉ hiển thị ở 2 tab đầu
- **Filter trực quan**: Date picker với giao diện thân thiện
- **Màu sắc phân biệt**: Mỗi loại thống kê có màu riêng

### 5. Logic Filter
```dart
// Filter theo danh mục
if (_selectedCategory != 'Tất cả') {
  filtered = filtered.where((quiz) => quiz.category == _selectedCategory).toList();
}

// Filter theo độ khó
if (_selectedDifficulty != 'Tất cả') {
  final difficultyLevel = int.tryParse(_selectedDifficulty) ?? 1;
  filtered = filtered.where((quiz) => quiz.difficultyLevel == difficultyLevel).toList();
}

// Filter theo khoảng thời gian
if (_startDate != null) {
  filtered = filtered.where((quiz) => quiz.createdAt.isAfter(_startDate!)).toList();
}
if (_endDate != null) {
  filtered = filtered.where((quiz) => quiz.createdAt.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
}
```

## Lợi ích

1. **Không gian hiển thị tốt hơn**: Danh sách quiz có nhiều không gian hơn
2. **Thống kê chi tiết**: Thông tin thống kê được tổ chức rõ ràng
3. **Filter linh hoạt**: Người dùng có thể lọc theo nhiều tiêu chí
4. **UI thân thiện**: Giao diện trực quan, dễ sử dụng
5. **Performance**: Tối ưu hiệu suất với lazy loading

## Cách sử dụng

1. **Xem thống kê tổng quan**: Chuyển sang tab "Thống kê"
2. **Lọc dữ liệu**: Sử dụng các filter để xem thống kê theo tiêu chí cụ thể
3. **Đặt lại filter**: Nhấn nút "Đặt lại" để xóa tất cả filter
4. **Xem chi tiết**: Cuộn xuống để xem thống kê theo danh mục và độ khó

## Tương thích

- ✅ Web
- ✅ Android
- ✅ iOS
- ✅ Responsive design
- ✅ Không có overflow pixel 
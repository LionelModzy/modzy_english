# Thêm Bộ Lọc Cho Quiz Tabs - Quiz Management Screen

## Tổng quan thay đổi

Đã thêm bộ lọc nâng cao cho 2 tab quiz đầu tiên (Quiz Hoạt động và Quiz Tạm dừng) để giúp quản lý quiz dễ dàng hơn với khả năng lọc theo danh mục, cấp độ và ngày tạo.

## Các tính năng mới

### 1. Bộ lọc nâng cao
- **Lọc theo danh mục**: Dropdown với tất cả categories có sẵn
- **Lọc theo độ khó**: Dropdown từ cấp 1-5
- **Lọc theo ngày tạo**: Date picker cho khoảng thời gian
- **Kết hợp với tìm kiếm**: Có thể kết hợp filter với search text

### 2. Giao diện người dùng
- **Nút toggle filter**: Icon filter có thể bật/tắt bộ lọc
- **Filter section**: Hiển thị/ẩn bộ lọc khi cần
- **Nút "Đặt lại"**: Xóa tất cả filter nhanh chóng
- **Responsive design**: Tối ưu cho mọi kích thước màn hình

### 3. Logic lọc thông minh
- **Filter riêng biệt**: Mỗi tab có bộ lọc độc lập
- **Kết hợp nhiều điều kiện**: Có thể lọc theo nhiều tiêu chí cùng lúc
- **Real-time update**: Kết quả cập nhật ngay lập tức

## Cấu trúc code

### 1. Biến filter mới
```dart
// Filter variables for quiz tabs
String _quizSelectedCategory = 'Tất cả';
String _quizSelectedDifficulty = 'Tất cả';
DateTime? _quizStartDate;
DateTime? _quizEndDate;
bool _showQuizFilters = false;
```

### 2. Logic lọc cập nhật
```dart
List<QuizModel> get _activeQuizzes {
  List<QuizModel> activeQuizzes = _quizzes.where((quiz) => quiz.isActive).toList();
  
  // Apply filters
  activeQuizzes = _applyQuizFilters(activeQuizzes);
  
  // Apply search
  if (_searchQuery.isNotEmpty) {
    activeQuizzes = activeQuizzes.where((quiz) {
      return quiz.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             quiz.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             quiz.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  return activeQuizzes;
}
```

### 3. Method lọc chung
```dart
List<QuizModel> _applyQuizFilters(List<QuizModel> quizzes) {
  List<QuizModel> filtered = quizzes;
  
  // Filter by category
  if (_quizSelectedCategory != 'Tất cả') {
    filtered = filtered.where((quiz) => quiz.category == _quizSelectedCategory).toList();
  }
  
  // Filter by difficulty
  if (_quizSelectedDifficulty != 'Tất cả') {
    final difficultyLevel = int.tryParse(_quizSelectedDifficulty) ?? 1;
    filtered = filtered.where((quiz) => quiz.difficultyLevel == difficultyLevel).toList();
  }
  
  // Filter by date range
  if (_quizStartDate != null) {
    filtered = filtered.where((quiz) => quiz.createdAt.isAfter(_quizStartDate!)).toList();
  }
  if (_quizEndDate != null) {
    filtered = filtered.where((quiz) => quiz.createdAt.isBefore(_quizEndDate!.add(const Duration(days: 1)))).toList();
  }
  
  return filtered;
}
```

## Giao diện người dùng

### 1. Search và Filter Row
- **Search bar**: Tìm kiếm theo text (tiêu đề, danh mục, mô tả)
- **Filter toggle**: Nút bật/tắt bộ lọc với icon thay đổi
- **Visual feedback**: Icon filter có màu khi đang bật

### 2. Filter Section
- **Collapsible**: Có thể ẩn/hiện để tiết kiệm không gian
- **Clean design**: Giao diện sạch sẽ với border và shadow
- **Easy reset**: Nút "Đặt lại" để xóa tất cả filter

### 3. Empty State cải thiện
- **Smart detection**: Phát hiện khi không có kết quả do filter
- **Helpful message**: Hướng dẫn người dùng thay đổi filter
- **Quick reset**: Nút "Đặt lại bộ lọc" nhanh chóng

## Cách sử dụng

### 1. Bật bộ lọc
- Nhấn icon filter bên cạnh ô tìm kiếm
- Filter section sẽ hiển thị bên dưới

### 2. Sử dụng các filter
- **Danh mục**: Chọn category cụ thể hoặc "Tất cả"
- **Độ khó**: Chọn cấp độ từ 1-5 hoặc "Tất cả"
- **Ngày tạo**: Chọn khoảng thời gian tạo quiz

### 3. Kết hợp với tìm kiếm
- Nhập từ khóa vào ô tìm kiếm
- Kết quả sẽ được lọc theo cả filter và search

### 4. Đặt lại filter
- Nhấn nút "Đặt lại" trong filter section
- Hoặc nhấn nút "Đặt lại bộ lọc" trong empty state

## Lợi ích

1. **Quản lý hiệu quả**: Dễ dàng tìm quiz theo tiêu chí cụ thể
2. **Tiết kiệm thời gian**: Không cần cuộn qua tất cả quiz
3. **Trải nghiệm tốt**: Giao diện trực quan, dễ sử dụng
4. **Linh hoạt**: Có thể kết hợp nhiều điều kiện lọc
5. **Responsive**: Hoạt động tốt trên mọi thiết bị

## Tương thích

- ✅ Web
- ✅ Android
- ✅ iOS
- ✅ Responsive design
- ✅ Không có overflow pixel
- ✅ Performance tốt

## Lưu ý

- Filter chỉ áp dụng cho 2 tab quiz đầu tiên
- Tab thống kê có bộ lọc riêng biệt
- Filter state được giữ nguyên khi chuyển tab
- Có thể reset filter nhanh chóng khi cần 
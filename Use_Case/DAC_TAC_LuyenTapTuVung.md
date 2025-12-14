# Đặc tả Use Case: Luyện tập từ vựng

## Bảng đặc tả Use Case

| Thuộc tính | Mô tả |
|------------|-------|
| **Tên Use Case** | Luyện tập từ vựng |
| **Mô tả** | Học viên chọn từ vựng để luyện tập, chọn một trong các chế độ luyện tập (Flashcard, Trắc nghiệm, Điền từ, Nghe và chọn), làm bài tập với từ vựng, nghe phát âm, kiểm tra đáp án, và hệ thống tự động cập nhật tiến độ học tập của học viên. |
| **Tác nhân** | Học viên |
| **Use-Case liên quan** | - **Bao gồm**: Nghe phát âm từ vựng, Đánh dấu từ vựng (Bookmark)<br>- **Mở rộng**: Hoàn thành luyện tập → Cập nhật tiến độ học tập |
| **Sự kiện kích hoạt** | 1. Học viên chọn "Luyện tập từ vựng" từ danh sách từ vựng hoặc từ danh sách đã đánh dấu<br>2. Học viên chọn chế độ luyện tập (Flashcard, Trắc nghiệm, Điền từ, Nghe và chọn)<br>3. Học viên làm bài tập và hoàn thành phiên luyện tập<br>4. Hệ thống tự động cập nhật tiến độ học tập |
| **Tiền điều kiện** | Học viên đã đăng nhập vào hệ thống |
| **Hậu điều kiện** | - Tiến độ luyện tập từ vựng được lưu vào cơ sở dữ liệu<br>- Thống kê học tập của học viên được cập nhật (số từ đã luyện tập, độ chính xác, thời gian)<br>- Từ vựng đã luyện tập được đánh dấu trong lịch sử học tập |
| **Biến thể** | - **Luyện tập theo danh mục**: Học viên có thể chọn luyện tập từ vựng theo danh mục cụ thể (ví dụ: Động từ, Danh từ, Tính từ)<br>- **Luyện tập từ danh sách đã đánh dấu**: Học viên có thể luyện tập các từ vựng đã được đánh dấu (bookmark) trước đó<br>- **Luyện tập lại**: Học viên có thể luyện tập lại với cùng bộ từ vựng để cải thiện kết quả<br>- **Chọn chế độ luyện tập**: Học viên có thể chọn một trong 4 chế độ: Flashcard, Trắc nghiệm, Điền từ, Nghe và chọn |
| **Ngoại lệ** | - **Lỗi tải danh sách từ vựng**: Nếu không thể tải danh sách từ vựng từ cơ sở dữ liệu, hệ thống hiển thị thông báo lỗi và yêu cầu học viên thử lại<br>- **Lỗi phát âm**: Nếu không thể phát âm từ vựng (text-to-speech API lỗi), hệ thống hiển thị thông báo và cho phép học viên bỏ qua hoặc thử lại<br>- **Mất kết nối khi lưu tiến độ**: Nếu mất kết nối khi đang lưu tiến độ, hệ thống lưu tạm vào bộ nhớ cục bộ và đồng bộ lại khi có kết nối<br>- **Không có từ vựng để luyện tập**: Nếu danh sách từ vựng trống, hệ thống hiển thị thông báo và đề xuất học viên chọn danh mục khác |

## Luồng chính (Main Flow)

1. Học viên mở danh sách từ vựng
2. Học viên chọn "Luyện tập từ vựng"
3. Hệ thống hiển thị danh sách từ vựng có sẵn (hoặc từ vựng theo danh mục đã chọn)
4. Hệ thống tạo bộ luyện tập gồm 20 từ vựng ngẫu nhiên
5. Học viên chọn chế độ luyện tập (Flashcard, Trắc nghiệm, Điền từ, Nghe và chọn)
6. Hệ thống khởi tạo phiên luyện tập với từ vựng đầu tiên
7. Với mỗi từ vựng:
   - Học viên xem từ vựng và làm bài tập theo chế độ đã chọn
   - Học viên có thể nghe phát âm (nếu cần)
   - Học viên trả lời câu hỏi/điền từ/chọn đáp án
   - Hệ thống kiểm tra đáp án và hiển thị kết quả (Đúng/Sai)
   - Học viên chuyển đến từ vựng tiếp theo
8. Sau khi hoàn thành tất cả từ vựng:
   - Hệ thống tính toán kết quả (tổng điểm, độ chính xác, thời gian)
   - Hệ thống hiển thị kết quả luyện tập
   - Hệ thống lưu tiến độ vào cơ sở dữ liệu
   - Hệ thống cập nhật thống kê học tập của học viên
9. Học viên có thể đánh dấu từ vựng hoặc luyện tập lại
10. Học viên hoàn thành và quay về danh sách từ vựng

## Luồng phụ (Alternative Flows)

### A1: Luyện tập theo danh mục
- Học viên chọn danh mục từ vựng cụ thể trước khi luyện tập
- Hệ thống chỉ hiển thị và luyện tập các từ vựng thuộc danh mục đó

### A2: Luyện tập từ danh sách đã đánh dấu
- Học viên mở tab "Đã đánh dấu"
- Học viên chọn các từ vựng đã bookmark để luyện tập
- Hệ thống tạo bộ luyện tập từ các từ vựng đã đánh dấu

### A3: Đánh dấu từ vựng trong khi luyện tập
- Học viên nhấn nút "Đánh dấu" trên từ vựng đang luyện tập
- Hệ thống thêm từ vựng vào danh sách bookmark
- Hệ thống cập nhật icon bookmark

### A4: Luyện tập lại
- Sau khi xem kết quả, học viên chọn "Luyện tập lại"
- Hệ thống reset phiên luyện tập và bắt đầu lại từ đầu với cùng bộ từ vựng

## Các chế độ luyện tập

### 1. Flashcard (Thẻ từ)
- Hệ thống hiển thị từ tiếng Anh
- Học viên nhấn để xem nghĩa tiếng Việt
- Học viên đánh dấu đúng/sai dựa trên khả năng nhớ của mình

### 2. Trắc nghiệm (Multiple Choice)
- Hệ thống hiển thị từ tiếng Anh và tạo 4 lựa chọn nghĩa (1 đúng + 3 sai)
- Học viên chọn đáp án đúng
- Hệ thống kiểm tra và hiển thị kết quả

### 3. Điền từ (Typing)
- Hệ thống hiển thị nghĩa tiếng Việt và ô nhập
- Học viên nhập từ tiếng Anh tương ứng
- Hệ thống so sánh (không phân biệt hoa thường) và hiển thị kết quả

### 4. Nghe và chọn (Listening)
- Hệ thống phát âm từ vựng (text-to-speech)
- Hệ thống hiển thị 4 lựa chọn nghĩa tiếng Việt
- Học viên chọn nghĩa phù hợp với phát âm đã nghe
- Hệ thống kiểm tra và hiển thị kết quả


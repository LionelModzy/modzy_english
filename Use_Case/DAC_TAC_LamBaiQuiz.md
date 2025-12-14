# Đặc tả Use Case: Làm bài Quiz & xem kết quả

## Bảng đặc tả Use Case

| Thuộc tính | Mô tả |
|------------|-------|
| **Tên Use Case** | Làm bài Quiz & xem kết quả |
| **Mô tả** | Học viên duyệt danh sách Quiz, chọn Quiz muốn làm, trả lời các câu hỏi trong Quiz, nộp bài, và xem kết quả với điểm số, số câu đúng/sai, tỉ lệ đúng, cùng với chi tiết đáp án từng câu. Hệ thống tự động tính điểm, lưu kết quả, và cập nhật thống kê học tập. |
| **Tác nhân** | Học viên |
| **Use-Case liên quan** | - **Bao gồm**: Xem chi tiết Quiz, Trả lời câu hỏi, Tính điểm số, Lưu kết quả Quiz<br>- **Mở rộng**: Hoàn thành Quiz → Cập nhật thống kê học tập<br>- **Mở rộng**: Xem kết quả → Xem chi tiết đáp án |
| **Sự kiện kích hoạt** | 1. Học viên chọn Quiz muốn làm từ danh sách<br>2. Học viên nhấn "Bắt đầu làm bài"<br>3. Học viên trả lời tất cả câu hỏi và nhấn "Nộp bài"<br>4. Hệ thống tự động tính điểm và hiển thị kết quả |
| **Tiền điều kiện** | Học viên đã đăng nhập vào hệ thống |
| **Hậu điều kiện** | - Kết quả Quiz được lưu vào cơ sở dữ liệu<br>- Thống kê Quiz được cập nhật (số lượt làm, tỉ lệ đạt, điểm trung bình)<br>- Thống kê học tập của học viên được cập nhật (nếu Quiz đạt)<br>- Lịch sử làm Quiz được lưu |
| **Biến thể** | - **Quiz có giới hạn thời gian**: Hệ thống đếm ngược thời gian, tự động nộp bài khi hết thời gian<br>- **Quiz không có giới hạn thời gian**: Học viên có thể làm bài không giới hạn thời gian<br>- **Các loại câu hỏi**: Trắc nghiệm (1 đáp án), Nhiều đáp án, Điền từ, Câu trả lời ngắn<br>- **Làm lại Quiz**: Học viên có thể làm lại Quiz để cải thiện điểm số<br>- **Quiz trong thách đấu**: Nếu Quiz là một phần của thách đấu, kết quả sẽ được gửi đến hệ thống thách đấu |
| **Ngoại lệ** | - **Hết thời gian làm bài**: Nếu Quiz có timer và hết thời gian, hệ thống tự động nộp bài<br>- **Lỗi tải Quiz**: Nếu không thể tải thông tin Quiz từ cơ sở dữ liệu, hệ thống hiển thị thông báo lỗi và yêu cầu học viên thử lại<br>- **Lỗi lưu kết quả**: Nếu không thể lưu kết quả vào cơ sở dữ liệu, hệ thống hiển thị thông báo lỗi và cho phép học viên thử lại<br>- **Mất kết nối**: Nếu mất kết nối khi đang làm bài, hệ thống lưu tạm tiến độ vào bộ nhớ cục bộ và đồng bộ lại khi có kết nối |

## Luồng chính (Main Flow)

1. Học viên mở danh sách Quiz
2. Học viên có thể tìm kiếm hoặc lọc Quiz theo danh mục, độ khó
3. Học viên chọn Quiz muốn làm
4. Học viên xem chi tiết Quiz (tiêu đề, mô tả, số câu hỏi, thời gian, điểm đạt)
5. Học viên nhấn "Bắt đầu làm bài"
6. Hệ thống tải thông tin Quiz từ cơ sở dữ liệu
7. Hệ thống khởi tạo phiên làm bài:
   - Khởi tạo danh sách đáp án
   - Set currentQuestionIndex = 0
   - Bắt đầu timer (nếu Quiz có giới hạn thời gian)
8. Hệ thống hiển thị câu hỏi đầu tiên với:
   - Câu hỏi
   - Các lựa chọn (nếu có)
   - Timer (nếu có)
   - Progress bar
   - Số câu đã làm / Tổng số câu
9. Với mỗi câu hỏi:
   - Học viên đọc câu hỏi
   - Học viên trả lời câu hỏi (tùy loại: chọn đáp án, nhập text, chọn nhiều đáp án)
   - Hệ thống lưu đáp án đã chọn
   - Học viên chuyển đến câu hỏi tiếp theo hoặc nộp bài (nếu là câu cuối)
10. Học viên nhấn "Nộp bài"
11. Hệ thống hiển thị xác nhận nộp bài
12. Nếu học viên xác nhận:
    - Hệ thống dừng timer (nếu có)
    - Hệ thống tính điểm số:
      * So sánh đáp án với đáp án đúng
      * Tính số câu đúng
      * Tính điểm (điểm/câu * số câu đúng)
      * Tính tỉ lệ đúng (%)
      * Xác định đạt/không đạt (score >= passingScore)
    - Hệ thống lưu kết quả vào cơ sở dữ liệu
    - Hệ thống cập nhật thống kê Quiz (totalAttempts, totalPassed, averageScore, passRate)
    - Nếu Quiz đạt, hệ thống cập nhật thống kê học viên
    - Nếu Quiz là thách đấu, hệ thống gửi kết quả đến hệ thống thách đấu
13. Hệ thống hiển thị kết quả Quiz:
    - Tổng điểm
    - Số câu đúng / Tổng số câu
    - Tỉ lệ đúng (%)
    - Đạt / Không đạt
    - Thời gian làm bài
    - Animation kết quả
14. Học viên có thể xem chi tiết từng câu:
    - Câu hỏi
    - Đáp án đã chọn
    - Đáp án đúng
    - Giải thích (nếu có)
    - Đúng / Sai
15. Học viên có thể làm lại Quiz hoặc hoàn thành và quay về danh sách Quiz

## Luồng phụ (Alternative Flows)

### A1: Hết thời gian làm bài
- Nếu Quiz có timer và thời gian đếm ngược về 0
- Hệ thống tự động nộp bài
- Hệ thống hiển thị cảnh báo "Hết thời gian!"
- Chuyển đến luồng tính điểm và hiển thị kết quả

### A2: Quiz không có giới hạn thời gian
- Hệ thống bỏ qua logic timer
- Học viên có thể làm bài không giới hạn thời gian

### A3: Tạm dừng làm bài
- Học viên nhấn "Tạm dừng"
- Hệ thống lưu tiến độ hiện tại
- Hệ thống hiển thị dialog xác nhận
- Nếu xác nhận thoát, hệ thống quay về danh sách Quiz (lưu tiến độ)
- Nếu hủy, hệ thống tiếp tục làm bài

### A4: Quiz đã làm trước đó
- Hệ thống kiểm tra Quiz đã làm chưa
- Nếu đã có kết quả, hệ thống hiển thị kết quả trước đó
- Học viên có thể chọn "Làm lại" hoặc "Xem kết quả"

### A5: Quiz liên kết với Lesson
- Nếu Quiz có lessonId
- Sau khi hoàn thành Quiz, hệ thống đánh dấu Lesson đã hoàn thành Quiz
- Hệ thống cập nhật tiến độ Lesson

### A6: Lỗi lưu kết quả
- Nếu không thể lưu kết quả vào cơ sở dữ liệu
- Hệ thống hiển thị thông báo lỗi "Đã xảy ra lỗi, vui lòng thử lại"
- Hệ thống cho phép học viên thử lại lưu kết quả

## Các loại câu hỏi Quiz

### 1. Trắc nghiệm (Multiple Choice)
- Học viên chọn một đáp án từ các lựa chọn
- Hệ thống so sánh đáp án đã chọn với đáp án đúng

### 2. Nhiều đáp án (Multiple Select)
- Học viên chọn nhiều đáp án từ các lựa chọn
- Hệ thống so sánh tập hợp đáp án đã chọn với tập hợp đáp án đúng

### 3. Điền từ (Fill in Blank)
- Học viên nhập đáp án text vào ô trống
- Hệ thống so sánh text đã nhập với đáp án đúng (có thể không phân biệt hoa thường)

### 4. Câu trả lời ngắn (Short Answer)
- Học viên nhập câu trả lời ngắn
- Hệ thống so sánh câu trả lời với đáp án đúng (có thể chấp nhận nhiều đáp án đúng)

## Tính điểm Quiz

- **Điểm mỗi câu**: Mỗi câu hỏi có điểm số riêng (points)
- **Tổng điểm**: Tổng điểm = Tổng điểm của tất cả câu đúng
- **Tỉ lệ đúng**: Tỉ lệ đúng (%) = (Số câu đúng / Tổng số câu) * 100
- **Đạt/Không đạt**: Quiz đạt nếu tổng điểm >= passingScore


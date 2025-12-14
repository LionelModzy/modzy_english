# Hướng dẫn nhập dữ liệu Quiz từ file JSON

## Tổng quan

File `sample_quiz_data.json` chứa 5 bài quiz mẫu với đầy đủ câu hỏi. Bạn có thể sử dụng file này để nhập dữ liệu vào hệ thống thông qua giao diện admin.

## Các quiz có trong file

1. **Kiểm tra Ngữ pháp cơ bản - Present Simple** (Grammar, Beginner)
   - 5 câu hỏi trắc nghiệm về thì hiện tại đơn
   - Thời gian: 15 phút
   - Điểm đạt: 70%

2. **Từ vựng về Gia đình** (Vocabulary, Beginner)
   - 5 câu hỏi (trắc nghiệm, điền từ, nhiều lựa chọn)
   - Thời gian: 10 phút
   - Điểm đạt: 60%

3. **Kiểm tra Từ vựng cơ bản** (Vocabulary, Beginner)
   - 5 câu hỏi trắc nghiệm về từ vựng cơ bản
   - Thời gian: 12 phút
   - Điểm đạt: 65%

4. **Kiểm tra Đúng/Sai - Ngữ pháp cơ bản** (Grammar, Beginner)
   - 6 câu hỏi True/False
   - Thời gian: 10 phút
   - Điểm đạt: 60%

5. **Kiểm tra từ vựng về Màu sắc và Số đếm** (Vocabulary, Beginner)
   - 5 câu hỏi về màu sắc và số đếm
   - Thời gian: 10 phút
   - Điểm đạt: 70%

6. **Kiểm tra từ vựng về Hành động** (Vocabulary, Beginner)
   - 5 câu hỏi về động từ hành động
   - Thời gian: 12 phút
   - Điểm đạt: 65%

## Các loại câu hỏi được sử dụng

1. **multipleChoice** - Trắc nghiệm một lựa chọn
2. **multipleSelect** - Trắc nghiệm nhiều lựa chọn
3. **trueFalse** - Đúng/Sai
4. **fillInBlank** - Điền từ vào chỗ trống
5. **shortAnswer** - Câu trả lời ngắn
6. **matching** - Nối cặp
7. **ordering** - Sắp xếp thứ tự

## Cách nhập dữ liệu

### Bước 1: Mở giao diện Admin
1. Đăng nhập với tài khoản admin
2. Vào mục "Quản lý Quiz" (Quiz Management)
3. Nhấn nút "Tạo Quiz mới" (Create New Quiz)

### Bước 2: Nhập thông tin Quiz cơ bản

Từ file JSON, copy các trường sau vào form:

#### Thông tin cơ bản (Bắt buộc):
- **Title (Tiêu đề)**: `title` - Tiêu đề quiz
- **Description (Mô tả)**: `description` - Mô tả ngắn về quiz
- **Category (Danh mục)**: Chọn từ dropdown
  - Grammar, Vocabulary, Listening, Speaking, Writing, Reading
  
- **Difficulty Level (Mức độ khó)**: Chọn từ 1-5
  - 1 = Cơ bản (Beginner)
  - 2 = Sơ cấp (Elementary)
  - 3 = Trung cấp (Intermediate)
  - 4 = Trung cấp cao (Upper Intermediate)
  - 5 = Nâng cao (Advanced)

- **Time Limit (Thời gian)**: `timeLimit` - Thời gian làm bài (phút)
- **Passing Score (Điểm đạt)**: `passingScore` - Phần trăm điểm cần đạt để vượt qua

### Bước 3: Thêm câu hỏi

Với mỗi câu hỏi trong quiz, nhấn "Thêm câu hỏi" và điền thông tin:

#### Thông tin câu hỏi:
- **Question (Câu hỏi)**: `question` - Nội dung câu hỏi
- **Type (Loại câu hỏi)**: Chọn từ dropdown
  - multipleChoice - Trắc nghiệm một lựa chọn
  - multipleSelect - Trắc nghiệm nhiều lựa chọn
  - trueFalse - Đúng/Sai
  - fillInBlank - Điền từ
  - shortAnswer - Trả lời ngắn
  - matching - Nối cặp
  - ordering - Sắp xếp

#### Tùy theo loại câu hỏi:

**1. Multiple Choice (Trắc nghiệm một lựa chọn):**
- **Options (Lựa chọn)**: Nhập các phương án, mỗi phương án một dòng
- **Correct Answer (Đáp án đúng)**: Chọn một đáp án đúng
- **Explanation (Giải thích)**: Giải thích tại sao đáp án đó đúng

**2. Multiple Select (Trắc nghiệm nhiều lựa chọn):**
- **Options**: Nhập các phương án
- **Correct Answers**: Chọn nhiều đáp án đúng
- **Explanation**: Giải thích

**3. True/False (Đúng/Sai):**
- **Options**: Thường là ["True", "False"]
- **Correct Answer**: Chọn "True" hoặc "False"
- **Explanation**: Giải thích

**4. Fill in Blank (Điền từ):**
- **Correct Answer**: Đáp án đúng (có thể có nhiều đáp án chấp nhận được)
- **Explanation**: Giải thích

**5. Short Answer (Trả lời ngắn):**
- **Correct Answer**: Đáp án mẫu
- **Explanation**: Giải thích

#### Thông tin bổ sung:
- **Points (Điểm số)**: `points` - Số điểm của câu hỏi (thường là 10-15 điểm)
- **Explanation (Giải thích)**: `explanation` - Giải thích đáp án (tùy chọn)
- **Image URL**: Để trống (có thể thêm ảnh minh họa sau)
- **Audio URL**: Để trống (có thể thêm audio sau)

### Bước 4: Liên kết với bài học (tùy chọn)
- **Lesson ID**: ID của bài học liên quan (nếu có)
- Trong file JSON, `lessonId` để `null`
- Bạn có thể thêm sau khi đã tạo bài học

### Bước 5: Lưu Quiz
Nhấn nút "Lưu" để hoàn tất.

## Ví dụ nhập dữ liệu

Giả sử bạn muốn nhập quiz "Kiểm tra Ngữ pháp cơ bản - Present Simple":

### Thông tin Quiz:
1. **Title**: Kiểm tra Ngữ pháp cơ bản - Present Simple
2. **Description**: Bài kiểm tra về thì hiện tại đơn (Present Simple Tense), bao gồm cách chia động từ, cấu trúc câu khẳng định, phủ định và câu hỏi.
3. **Category**: Chọn "Grammar"
4. **Difficulty Level**: Chọn "1" (Cơ bản)
5. **Time Limit**: 15
6. **Passing Score**: 70

### Câu hỏi 1:
1. **Question**: Chọn dạng đúng: I ___ to school every day.
2. **Type**: Chọn "multipleChoice"
3. **Options** (mỗi dòng một phương án):
   ```
   go
   goes
   going
   went
   ```
4. **Correct Answer**: go
5. **Explanation**: Với chủ ngữ 'I', động từ giữ nguyên dạng gốc (go).
6. **Points**: 10

### Câu hỏi 2:
1. **Question**: Chọn dạng đúng: She ___ coffee every morning.
2. **Type**: multipleChoice
3. **Options**:
   ```
   drink
   drinks
   drinking
   drank
   ```
4. **Correct Answer**: drinks
5. **Explanation**: Với chủ ngữ ngôi thứ ba số ít (she), động từ phải thêm -s hoặc -es. 'drink' → 'drinks'
6. **Points**: 10

Và tiếp tục với các câu hỏi còn lại...

## Lưu ý quan trọng

1. **Câu hỏi Multiple Choice**:
   - Phải có ít nhất 2 lựa chọn
   - Chỉ có một đáp án đúng
   - Nên có 3-4 phương án để tăng độ khó

2. **Câu hỏi Multiple Select**:
   - Có thể có nhiều đáp án đúng
   - Phải chọn tất cả các đáp án đúng
   - Nên ghi rõ trong câu hỏi là "nhiều lựa chọn"

3. **Câu hỏi True/False**:
   - Chỉ có 2 phương án: True và False
   - Câu hỏi phải rõ ràng, không mơ hồ

4. **Câu hỏi Fill in Blank**:
   - Có thể có nhiều đáp án chấp nhận được
   - Nên cung cấp gợi ý trong câu hỏi nếu cần

5. **Explanation (Giải thích)**:
   - Nên có giải thích cho mỗi câu hỏi
   - Giúp người học hiểu rõ tại sao đáp án đó đúng
   - Có thể giải thích cả các đáp án sai (nếu cần)

6. **Points (Điểm số)**:
   - Thường là 10 điểm cho câu hỏi đơn giản
   - 15 điểm cho câu hỏi khó hơn
   - Tổng điểm nên chia hết cho 100 để dễ tính phần trăm

7. **Time Limit (Thời gian)**:
   - Tính bằng phút
   - Nên ước lượng thời gian trung bình để trả lời mỗi câu
   - Quiz ngắn (5-10 câu): 10-15 phút
   - Quiz dài (20+ câu): 30-60 phút

8. **Passing Score (Điểm đạt)**:
   - Tính bằng phần trăm
   - Thường là 60-70% cho quiz cơ bản
   - 80-90% cho quiz nâng cao

## Gợi ý tạo câu hỏi hiệu quả

1. **Câu hỏi rõ ràng, dễ hiểu**:
   - Tránh câu hỏi mơ hồ, khó hiểu
   - Sử dụng ngôn ngữ phù hợp với trình độ người học

2. **Đáp án hợp lý**:
   - Các phương án sai nên có vẻ hợp lý (plausible distractors)
   - Tránh đáp án quá dễ đoán

3. **Câu hỏi đa dạng**:
   - Kết hợp nhiều loại câu hỏi khác nhau
   - Kiểm tra nhiều khía cạnh của kiến thức

4. **Độ khó tăng dần**:
   - Bắt đầu với câu hỏi dễ
   - Kết thúc với câu hỏi khó hơn

5. **Phản hồi hữu ích**:
   - Giải thích rõ ràng cho mỗi đáp án
   - Giúp người học học từ lỗi sai

## Mẹo nhập nhanh

1. **Copy/Paste**: Copy câu hỏi từ JSON và paste vào form
2. **Xử lý hàng loạt**: Tạo quiz trước, sau đó thêm câu hỏi từng câu một
3. **Lưu nháp**: Lưu quiz ngay cả khi chưa hoàn thành để không bị mất dữ liệu
4. **Kiểm tra kỹ**: Đảm bảo đáp án đúng được đánh dấu chính xác
5. **Test quiz**: Sau khi tạo xong, hãy test quiz để đảm bảo hoạt động đúng

## Cần hỗ trợ?

Nếu bạn gặp vấn đề khi nhập dữ liệu:
1. Kiểm tra lại định dạng JSON
2. Đảm bảo các trường bắt buộc đã được điền
3. Kiểm tra quyền admin của tài khoản
4. Đảm bảo mỗi câu hỏi có ít nhất một đáp án đúng
5. Xem lại hướng dẫn trên giao diện admin

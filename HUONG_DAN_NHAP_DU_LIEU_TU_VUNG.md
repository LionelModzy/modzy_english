# Hướng dẫn nhập dữ liệu từ vựng từ file JSON

## Tổng quan

File `sample_vocabulary_data.json` chứa 35 từ vựng mẫu với đầy đủ thông tin. Bạn có thể sử dụng file này để nhập dữ liệu vào hệ thống thông qua giao diện admin.

## Phân loại từ vựng trong file

File chứa các từ vựng được phân loại theo các chủ đề:

1. **Greetings (Chào hỏi)** - 5 từ
   - Hello, Goodbye, Thank you, Please, Sorry

2. **Family (Gia đình)** - 5 từ
   - Family, Father, Mother, Brother, Sister

3. **Objects (Đồ vật)** - 4 từ
   - Book, Pen, Table, Chair

4. **Places (Địa điểm)** - 2 từ
   - House, School

5. **Actions (Hành động)** - 5 từ
   - Eat, Drink, Sleep, Go, Come

6. **Adjectives (Tính từ)** - 4 từ
   - Good, Bad, Big, Small

7. **Emotions (Cảm xúc)** - 2 từ
   - Happy, Sad

8. **Food & Drink (Đồ ăn thức uống)** - 3 từ
   - Water, Bread, Apple

9. **Colors (Màu sắc)** - 3 từ
   - Red, Blue, Green

10. **Numbers (Số đếm)** - 3 từ
    - One, Two, Three

11. **Grammar (Ngữ pháp)** - 3 từ
    - Present, Past, Future

## Cách nhập dữ liệu

### Bước 1: Mở giao diện Admin
1. Đăng nhập với tài khoản admin
2. Vào mục "Quản lý từ vựng" (Vocabulary Management)
3. Nhấn nút "Thêm từ vựng mới" (Add New Vocabulary)

### Bước 2: Nhập thông tin từ vựng

Từ file JSON, copy các trường sau vào form:

#### Thông tin cơ bản (Bắt buộc):
- **Word (Từ vựng)**: `word` - Từ tiếng Anh
- **Pronunciation (Phát âm)**: `pronunciation` - Phiên âm theo IPA (ví dụ: /həˈloʊ/)
- **Meaning (Nghĩa tiếng Việt)**: `meaning` - Nghĩa tiếng Việt

#### Thông tin bổ sung:
- **Definition (Định nghĩa)**: `definition` - Định nghĩa bằng tiếng Anh (tùy chọn)
- **Examples (Ví dụ)**: `examples` - Danh sách các câu ví dụ (mỗi câu trên một dòng)
- **Synonyms (Từ đồng nghĩa)**: `synonyms` - Các từ đồng nghĩa, cách nhau bởi dấu phẩy
- **Antonyms (Từ trái nghĩa)**: `antonyms` - Các từ trái nghĩa, cách nhau bởi dấu phẩy

#### Phân loại:
- **Category (Danh mục)**: Chọn từ dropdown
  - Greetings, Family, Objects, Places, Actions, Adjectives, Emotions, Food & Drink, Colors, Numbers, Grammar
  
- **Part of Speech (Từ loại)**: Chọn từ dropdown
  - noun (Danh từ)
  - verb (Động từ)
  - adjective (Tính từ)
  - adverb (Trạng từ)
  - preposition (Giới từ)
  - conjunction (Liên từ)
  - interjection (Thán từ)
  - pronoun (Đại từ)
  - number (Số từ)

- **Difficulty Level (Mức độ khó)**: Chọn từ 1-5
  - 1 = Cơ bản (Beginner)
  - 2 = Sơ cấp (Elementary)
  - 3 = Trung cấp (Intermediate)
  - 4 = Trung cấp cao (Upper Intermediate)
  - 5 = Nâng cao (Advanced)

### Bước 3: Thêm ảnh và âm thanh (tùy chọn)
Sau khi lưu từ vựng, bạn có thể quay lại chỉnh sửa và thêm:
- **Image URL**: Link ảnh minh họa cho từ vựng
- **Audio URL**: Link file âm thanh phát âm từ vựng

**Lưu ý:** Trong file JSON, tất cả `imageUrl` và `audioUrl` đều để `null`. Bạn cần tự tìm và thêm sau.

### Bước 4: Liên kết với bài học (tùy chọn)
- **Lesson IDs**: Danh sách ID các bài học có sử dụng từ vựng này
- Trong file JSON, `lessonIds` là mảng rỗng `[]`
- Bạn có thể thêm sau khi đã tạo bài học

### Bước 5: Lưu từ vựng
Nhấn nút "Lưu" để hoàn tất.

## Ví dụ nhập dữ liệu

Giả sử bạn muốn nhập từ "Hello" từ file JSON:

```json
{
  "word": "Hello",
  "pronunciation": "/həˈloʊ/",
  "meaning": "Xin chào",
  "definition": "A greeting used when meeting someone or answering the telephone",
  "examples": ["Hello, how are you?", "Hello, nice to meet you!", "Say hello to your teacher"],
  "synonyms": ["Hi", "Hey", "Greetings"],
  "antonyms": ["Goodbye", "Farewell"],
  "category": "Greetings",
  "partOfSpeech": "interjection",
  "difficultyLevel": 1
}
```

**Cách nhập vào form:**
1. **Word**: Hello
2. **Pronunciation**: /həˈloʊ/
3. **Meaning**: Xin chào
4. **Definition**: A greeting used when meeting someone or answering the telephone
5. **Examples** (mỗi câu một dòng):
   ```
   Hello, how are you?
   Hello, nice to meet you!
   Say hello to your teacher
   ```
6. **Synonyms**: Hi, Hey, Greetings
7. **Antonyms**: Goodbye, Farewell
8. **Category**: Chọn "Greetings"
9. **Part of Speech**: Chọn "interjection"
10. **Difficulty Level**: Chọn "1" (Cơ bản)
11. **Image URL**: Để trống (thêm sau)
12. **Audio URL**: Để trống (thêm sau)

## Lưu ý quan trọng

1. **Pronunciation (Phát âm)**:
   - Sử dụng ký hiệu IPA (International Phonetic Alphabet)
   - Ví dụ: /həˈloʊ/, /ɡʊdˈbaɪ/, /ˈfæməli/
   - Bạn có thể tra cứu trên từ điển online như Cambridge Dictionary

2. **Examples (Ví dụ)**:
   - Mỗi câu ví dụ viết trên một dòng riêng
   - Nên có ít nhất 2-3 ví dụ
   - Ví dụ nên đơn giản, dễ hiểu cho người học

3. **Synonyms & Antonyms**:
   - Các từ cách nhau bởi dấu phẩy và khoảng trắng
   - Ví dụ: "Hi, Hey, Greetings"
   - Không bắt buộc phải có

4. **Image & Audio**:
   - Có thể upload lên Cloudinary hoặc hosting khác
   - Hoặc sử dụng URL từ nguồn khác
   - Để trống nếu chưa có

5. **Category**:
   - Chọn category phù hợp từ dropdown
   - Nếu không có category phù hợp, có thể chọn category gần nhất

## Gợi ý tìm ảnh và âm thanh

1. **Ảnh minh họa**:
   - Tìm trên Google Images, Unsplash, Pexels
   - Nên chọn ảnh rõ ràng, liên quan đến từ vựng
   - Kích thước đề xuất: 400x400px trở lên

2. **File âm thanh**:
   - Có thể ghi âm bằng các công cụ online
   - Hoặc sử dụng text-to-speech
   - Định dạng: MP3, WAV
   - Nên có chất lượng tốt, phát âm chuẩn

3. **Nguồn phát âm**:
   - Cambridge Dictionary: https://dictionary.cambridge.org/
   - Oxford Dictionary: https://www.oxfordlearnersdictionaries.com/
   - Forvo: https://forvo.com/ (phát âm từ người bản ngữ)

## Mẹo nhập nhanh

1. **Sử dụng Copy/Paste**: Copy toàn bộ từ JSON và paste vào form
2. **Xử lý hàng loạt**: Nhập từng từ một, lưu lại, rồi tiếp tục từ tiếp theo
3. **Kiểm tra chính tả**: Đảm bảo từ vựng và nghĩa chính xác
4. **Kiểm tra pronunciation**: Đảm bảo phát âm đúng định dạng IPA

## Cần hỗ trợ?

Nếu bạn gặp vấn đề khi nhập dữ liệu:
1. Kiểm tra lại định dạng JSON
2. Đảm bảo các trường bắt buộc đã được điền
3. Kiểm tra quyền admin của tài khoản
4. Xem lại hướng dẫn trên giao diện admin

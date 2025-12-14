# Hướng dẫn nhập dữ liệu bài học từ file JSON

## Tổng quan

File `sample_lessons_data.json` chứa 5 bài học mẫu với đầy đủ thông tin. Bạn có thể sử dụng file này để nhập dữ liệu vào hệ thống thông qua giao diện admin.

## Các bài học có trong file

1. **Giới thiệu bản thân - Self Introduction** (Speaking, Beginner)
2. **Present Simple - Thì hiện tại đơn** (Grammar, Beginner)
3. **Từ vựng về Gia đình - Family Vocabulary** (Vocabulary, Beginner)
4. **Luyện nghe - Chủ đề Shopping** (Listening, Intermediate)
5. **Viết email cơ bản - Basic Email Writing** (Writing, Intermediate)

## Cách nhập dữ liệu

### Bước 1: Mở giao diện Admin
1. Đăng nhập với tài khoản admin
2. Vào mục "Quản lý bài học" (Lesson Management)
3. Nhấn nút "Tạo bài học mới" (Create New Lesson)

### Bước 2: Nhập thông tin cơ bản
Từ file JSON, copy các trường sau vào form:

- **Title**: `title`
- **Description**: `description`
- **Content**: `content`
- **Category**: Chọn từ dropdown (Grammar, Vocabulary, Speaking, Listening, Writing)
- **Difficulty Level**: Chọn từ 1-5 (1 = Beginner, 5 = Advanced)
- **Estimated Duration**: Số phút
- **Tags**: Nhập các tag, cách nhau bởi dấu phẩy
- **Objectives**: Nhập các mục tiêu, cách nhau bởi dấu phẩy

### Bước 3: Nhập các Section
Trong phần "Sections", nhấn "Thêm phần" và nhập từng section:

- **Title**: `sections[].title`
- **Content**: `sections[].content`
- **Type**: Chọn từ dropdown (text, audio, video, exercise)
- **Media URL**: Để trống (bạn sẽ thêm video/ảnh/âm thanh sau)

### Bước 4: Thêm video, ảnh, âm thanh (tùy chọn)
Sau khi lưu bài học, bạn có thể quay lại chỉnh sửa và thêm:
- **Video URL**: Link video bài học
- **Image URL**: Link ảnh thumbnail
- **Audio URL**: Link file audio

### Bước 5: Lưu bài học
Nhấn nút "Lưu" để hoàn tất.

## Lưu ý quan trọng

1. **Video/Ảnh/Âm thanh**: 
   - Tất cả các trường `audioUrl`, `imageUrl`, `videoUrl` đều để `null` trong file JSON
   - Bạn cần tự tìm và thêm các file này sau
   - Có thể upload lên Cloudinary hoặc lưu trữ khác

2. **Vocabulary**: 
   - Trường `vocabulary` trong JSON là mảng rỗng `[]`
   - Bạn có thể thêm vocabulary ID sau khi đã có từ vựng trong hệ thống

3. **Order**: 
   - Trường `order` đã được thiết lập sẵn (1, 2, 3, 4, 5)
   - Bạn có thể điều chỉnh sau nếu cần

4. **Sections**: 
   - Mỗi bài học có 4-5 sections
   - Mỗi section đã có title, content, type và metadata
   - Media URL để trống, bạn có thể thêm sau

## Cấu trúc dữ liệu

Mỗi bài học có các trường sau:

```json
{
  "title": "Tiêu đề bài học",
  "description": "Mô tả ngắn",
  "content": "Nội dung chính (HTML/Markdown)",
  "category": "Grammar | Vocabulary | Speaking | Listening | Writing",
  "difficultyLevel": 1-5,
  "estimatedDuration": 20-30,
  "tags": ["tag1", "tag2"],
  "objectives": ["objective1", "objective2"],
  "audioUrl": null,
  "imageUrl": null,
  "videoUrl": null,
  "sections": [
    {
      "title": "Tiêu đề section",
      "content": "Nội dung section",
      "type": "text | audio | video | exercise",
      "mediaUrl": null,
      "metadata": {}
    }
  ],
  "vocabulary": [],
  "isActive": true,
  "isPremium": false,
  "order": 1
}
```

## Gợi ý thêm video/ảnh/âm thanh

Sau khi nhập xong dữ liệu văn bản, bạn có thể:

1. **Video**: 
   - Tìm video trên YouTube, Vimeo, hoặc tự quay
   - Upload lên Cloudinary hoặc hosting khác
   - Copy URL và paste vào trường "Video URL"

2. **Ảnh thumbnail**: 
   - Tạo ảnh minh họa cho bài học
   - Kích thước đề xuất: 1280x720px
   - Upload và copy URL vào trường "Image URL"

3. **Audio**: 
   - Ghi âm phần đọc nội dung hoặc hội thoại
   - Upload file MP3/WAV
   - Copy URL vào trường "Audio URL"

## Cần hỗ trợ?

Nếu bạn gặp vấn đề khi nhập dữ liệu, hãy:
1. Kiểm tra lại định dạng JSON
2. Đảm bảo các trường bắt buộc đã được điền
3. Kiểm tra quyền admin của tài khoản

# Nghiệp vụ: Tài liệu theo tuần (IELTS Hub)

> File dùng chung cho BE và FE. Khi giao việc cho AI:
> - BE: dán file này + `2_prompt_BE.md` + `weekly_doc.schema.json`
> - FE: dán file này + `3_prompt_FE.md` + `5_ai_rules_FE_flutter.md` + `6_ui_ux_layout_tai_lieu_theo_tuan.md` + `weekly_doc.schema.json`

## 1. Mục tiêu

Admin soạn tài liệu học theo từng tuần (ví dụ Tuần 12 có Tài liệu 1, Tài liệu 2). Mỗi tài liệu là **một file JSON nội dung** dựng từ các khối (block). Người dùng mở cùng một tài liệu theo 2 kiểu:

- **Slide:** mỗi section là một slide, trình chiếu được.
- **Doc:** các section nối liền thành một trang cuộn dọc.

Học xong tài liệu thì cộng chặng "Vũ Môn" của tuần, tính streak ("Ao của bạn") và có thể lưu từ vựng vào Sổ từ.

## 2. Vai trò

| Vai trò | Quyền |
|---|---|
| `admin` | Quản lý tuần; tạo, sửa, xem trước, xuất bản, gỡ, xoá tài liệu; import/export JSON; upload ảnh |
| `user` | Xem tuần đã mở và tài liệu đã xuất bản; đọc; làm trắc nghiệm; đánh dấu hoàn thành; lưu từ vựng |

## 3. Khái niệm và dữ liệu

### 3.1 Tuần (`Week`)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `id` | string/uuid | |
| `number` | int | Duy nhất. Ví dụ 12 |
| `startDate`, `endDate` | date | Ví dụ 30/09 – 06/10 |
| `title` | string? | Tuỳ chọn |
| `stageGoal` | int | Số chặng mục tiêu của tuần cho thác Vũ Môn, mặc định 5 |

- **Trạng thái tính theo ngày** (múi giờ `Asia/Ho_Chi_Minh`): `locked` khi chưa tới `startDate` (user thấy tuần nhưng không mở được, hiện "Mở thứ Hai"); `open` từ `startDate` trở đi.

### 3.2 Tài liệu (`WeeklyDocument`)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `id` | string | Dạng `w{week}-doc{order}`, ví dụ `w12-doc1` |
| `weekId` | ref | |
| `order` | int | Duy nhất trong tuần, bắt đầu từ 1 |
| `title` | string | |
| `skill` | enum | `reading` · `listening` · `writing` · `speaking` · `vocabulary` |
| `template` | string | `reading-lesson` · `writing-task2` · `vocab-set` · `speaking-part2` · `blank` · `custom` |
| `defaultView` | enum | `slide` · `doc` |
| `allowedViews` | enum[] | `["slide","doc"]`, hoặc chỉ một kiểu |
| `content` | JSON | Theo `weekly_doc.schema.json` (các section và block) |
| `schemaVersion` | int | Hiện tại là 1 |
| `status` | enum | `draft` · `scheduled` · `published` · `archived` |
| `publishAt` | datetime? | Lịch xuất bản |
| `version` | int | Tăng mỗi lần lưu, dùng để chống ghi đè (optimistic lock) |
| `sectionCount` | int | Tính từ `content` |
| `estimatedMinutes` | int | Tính tự động: số từ ÷ 180 + 1 phút cho mỗi khối quiz, làm tròn lên, tối thiểu 1 |
| `createdBy`, `createdAt`, `updatedAt`, `publishedAt` | | |

### 3.3 Nội dung JSON (`content`)

```json
{
  "schemaVersion": 1,
  "id": "w12-doc1",
  "week": 12,
  "order": 1,
  "title": "Reading: Matching Headings",
  "template": "reading-lesson",
  "meta": { "skill": "reading", "defaultView": "slide", "allowedViews": ["slide", "doc"] },
  "sections": [
    { "title": "DẠNG BÀI", "blocks": [
      { "type": "heading", "text": "Matching Headings là gì?" },
      { "type": "paragraph", "text": "Chọn tiêu đề cho **từng đoạn văn**." },
      { "type": "callout", "tone": "tip", "text": "Làm dạng này trước." }
    ]}
  ]
}
```

**Các loại khối** (schemaVersion 1):

| `type` | Trường bắt buộc | Trường tuỳ chọn | Ghi chú |
|---|---|---|---|
| `heading` | `text` | | |
| `paragraph` | `text` | | Markdown rút gọn: `**đậm**`, `*nghiêng*`, `[link](https://…)` |
| `callout` | `text` | `tone`: `tip` · `warning` · `note` (mặc định `tip`) | |
| `steps` | `items`: string[] (≥ 1) | | |
| `passage` | `text` | `label` (ví dụ "PARAGRAPH A") | Đoạn văn đề thi |
| `quiz` | `question`, `options`: string[] (2–6), `answer`: int | `explain` | `answer` là chỉ số trong `options`, bắt đầu từ 0 |
| `vocab` | `items`: [{`word`, `meaning`}] (≥ 1) | mỗi item: `pos`, `ipa`, `example` | Nguồn để "Lưu vào Sổ từ" |
| `pattern` | `structure` | `example` | |
| `image` | `url` (https) | `caption`, `alt` | Ảnh upload qua API, JSON chỉ lưu URL |
| `slideBreak` | | | Chỉ có tác dụng ở kiểu Slide: tách section thành nhiều slide |

- **Khoá của mỗi khối** (`blockKey`) = `"{sectionIndex}-{blockIndex}"`. Dùng để lưu đáp án quiz và lưu từ vựng. Nếu cần ổn định qua các lần sửa, cho phép thêm trường tuỳ chọn `id` vào mỗi block; khi có `id` thì dùng `id` làm khoá.
- **Chỗ trống của template** có dạng `[ … ]`, ví dụ `[Tên dạng bài]`.

### 3.4 Kiểm tra hợp lệ (dùng chung FE và BE)

- **Lỗi (error), chặn xuất bản:**
  - JSON sai cú pháp
  - thiếu `title`
  - `sections` rỗng
  - section thiếu `title` hoặc `blocks` rỗng
  - `type` không hỗ trợ
  - thiếu trường bắt buộc của khối
  - `answer` ngoài phạm vi
  - item từ vựng thiếu `word` hoặc `meaning`
  - `url` ảnh không phải https hoặc không thuộc host được phép
  - `schemaVersion` khác 1
- **Lưu ý (warning), vẫn cho xuất bản nhưng hiện cảnh báo:** còn chỗ trống `[ … ]`; section có quá nhiều khối cho một slide (> 6 khối, hoặc > 900 ký tự) thì gợi ý chèn `slideBreak`.
- **Thông báo lỗi kèm đường dẫn**, ví dụ `sections[2].blocks[1].answer: phải nằm trong 0…2`.

### 3.5 Template

Template là JSON khung có sẵn section, block và chỗ trống `[ … ]`:

| Template | Các section |
|---|---|
| `reading-lesson` | DẠNG BÀI → CHIẾN THUẬT → VÍ DỤ (passage + quiz) → TỪ VỰNG (vocab + pattern) |
| `writing-task2` | ĐỀ BÀI → DÀN Ý (steps) → BÀI MẪU → TỪ VỰNG & MẪU CÂU |
| `vocab-set` | CHỦ ĐỀ → TỪ VỰNG → LUYỆN TẬP (quiz) |
| `speaking-part2` | CUE CARD → Ý TƯỞNG → BÀI MẪU → TỪ VỰNG |
| `blank` | 1 section, 1 heading |

## 4. Luồng admin (tạo tài liệu)

1. **Chọn template.**
   - Nhập tên, tuần, số thứ tự (gợi ý = số lớn nhất trong tuần + 1), kỹ năng.
   - Chọn template, hoặc chọn "Nhập từ file JSON".
2. **Soạn nội dung**, có 2 chế độ thao tác trên cùng một dữ liệu:
   - **Form:** cây section và khối; sửa nội dung theo loại khối; thêm, xoá, đổi thứ tự khối; thêm section.
   - **JSON:** dán hoặc tải file `.json` → "Kiểm tra & áp dụng" → hiện lỗi kèm đường dẫn, hoặc dựng lại tài liệu nếu hợp lệ.
   - Xem trước Slide/Doc cập nhật ngay; khối đang sửa được tô viền.
   - Tự lưu nháp (`draft`) mỗi khi ngừng gõ khoảng 1,5 giây.
3. **Xuất bản.**
   - Chọn `defaultView`, có cho người dùng đổi kiểu không (`allowedViews`), và thời điểm xuất bản (ngay hoặc hẹn giờ → `scheduled`).
   - Bảng kiểm tra: đỏ (lỗi) thì chặn; vàng (lưu ý) thì cho xuất bản kèm cảnh báo; xanh thì sẵn sàng.
   - Xuất bản xong: có thể tải file JSON (export) hoặc "Tạo tài liệu tiếp theo".

**Quy tắc sửa và xoá:**
- Sửa tài liệu đã xuất bản thì tăng `version`; người dùng thấy bản mới ở lần mở sau.
- Tiến độ người dùng giữ theo chỉ số section; nếu số section giảm thì kẹp về section cuối. Trạng thái "đã hoàn thành" không bị mất.
- Chỉ xoá được `draft`. Tài liệu đã xuất bản thì chỉ gỡ (`archived`); tài liệu gỡ ẩn với người dùng nhưng vẫn giữ lịch sử tiến độ.
- Hai admin cùng sửa một tài liệu: lưu với `version` cũ thì trả lỗi xung đột (409). FE báo "Tài liệu vừa được người khác sửa" và tải lại bản mới.

## 5. Luồng người dùng

1. **Danh sách theo tuần.**
   - Hàng chọn tuần (đã xong ✓ · tuần hiện tại · khoá).
   - Thẻ tuần có tiến độ "x/y tài liệu đã học".
   - Danh sách tài liệu `published` của tuần, xếp theo `order`. Mỗi thẻ có: kiểu mặc định, số phần, số phút ước tính, trạng thái (Chưa học · Đang học n/N · Đã học).
2. **Đọc tài liệu.**
   - Mở đúng section đang dở (`lastSection`).
   - Chuyển Slide/Doc chỉ khi `allowedViews` có cả hai kiểu.
   - Slide: trước/sau, chấm trang, vuốt ngang; xoay ngang thì trình chiếu toàn màn 16:9.
   - Doc: cuộn dọc, cuối trang có "Đánh dấu đã học xong".
   - Mỗi lần sang section mới thì ghi tiến độ (`seenSections`, `lastSection`).
   - Trắc nghiệm: chọn là hiện đúng/sai + giải thích; lưu lựa chọn; được chọn lại (lưu lần cuối, ghi nhận lần đầu đúng hay sai để thống kê).
3. **Hoàn thành.**
   - Kiểu Slide: bấm "Hoàn thành" ở slide cuối. Kiểu Doc: bấm "Đánh dấu đã học xong".
   - Ghi `completedAt` (chỉ lần đầu), trả về số chặng tuần mới và streak.
   - Màn chúc mừng có: chặng Vũ Môn, "Lưu N từ vựng vào Sổ từ", "Học tài liệu tiếp theo", "Về danh sách".

## 6. Quy tắc tính

- **Chặng Vũ Môn của tuần (lịch):** `done` = số tài liệu hoàn thành lần đầu trong khoảng thứ Hai 00:00 → Chủ nhật 23:59 của tuần hiện tại (giờ Việt Nam), không phân biệt tài liệu thuộc tuần nào. `goal` = `stageGoal` của tuần hiện tại (mặc định 5). `passedGate` = `done ≥ goal`; lần đầu đạt thì trả cờ `justPassedGate = true` để FE phát hiệu ứng.
  > [CẦN CHỐT] Có tính thêm hoạt động khác vào chặng không (ví dụ ôn 20 từ = 1 chặng)?
- **Streak (số cá trong ao):** số ngày liên tiếp (giờ Việt Nam) có ít nhất 1 hoạt động học: xem section mới, trả lời quiz, hoàn thành tài liệu, ôn từ. Bỏ một ngày thì streak về 0 (hôm nay chưa học thì vẫn giữ streak tới hết ngày).
- **Từ đã lưu:** tổng số từ trong Sổ từ của người dùng.
- **Lưu từ vựng từ tài liệu:** lấy các item của khối `vocab`; bỏ trùng theo `word` (viết thường, bỏ khoảng trắng thừa); ghi nguồn (`documentId`, `blockKey`); trả số từ thêm mới và số từ đã có.

## 7. Ngoài phạm vi (giai đoạn này)

- Trình soạn thảo kéo-thả, nhiều người cùng sửa thời gian thực, bình luận trên tài liệu.
- Chấm điểm bài viết, ghi âm Speaking.
- Phân quyền theo lớp hoặc nhóm (mọi user thấy mọi tài liệu đã xuất bản).

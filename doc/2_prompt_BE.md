# Prompt BE: Tài liệu theo tuần

Bạn là backend engineer senior. Hãy xây dựng backend cho chức năng **Tài liệu theo tuần** của app IELTS Hub theo đúng file nghiệp vụ `1_nghiep_vu_tai_lieu_theo_tuan.md` và JSON Schema `weekly_doc.schema.json` (đính kèm). Nếu nghiệp vụ và prompt này mâu thuẫn, **file nghiệp vụ được ưu tiên**; nếu còn mục `[CẦN CHỐT]`, hỏi lại trước khi làm phần đó.

## Bối cảnh kỹ thuật

- Stack: [ĐIỀN: ví dụ NestJS + PostgreSQL + Prisma / Spring Boot + PostgreSQL / Firebase…]
- Auth đã có: [ĐIỀN: JWT / Firebase Auth…], role `admin` | `user` lấy từ [ĐIỀN].
- Lưu file ảnh: [ĐIỀN: S3 / Firebase Storage / Cloudinary…], host ảnh được phép: [ĐIỀN].
- Múi giờ nghiệp vụ: `Asia/Ho_Chi_Minh`. Lưu thời gian dạng UTC, quy đổi khi tính ngày, tuần, streak.
- Đọc cấu trúc project hiện có trước khi tạo file mới; theo đúng convention đặt tên, layer, cách xử lý lỗi đang dùng.

## 1. Mô hình dữ liệu

Tạo migration cho các bảng/collection sau. Có thể đổi tên cho hợp convention, nhưng phải giữ đủ nghĩa.

- `weeks`: `id`, `number` (unique), `start_date`, `end_date`, `title?`, `stage_goal` (mặc định 5), timestamps.
- `weekly_documents`:
  - định danh và phân loại: `id` (string `w{week}-doc{order}`, PK hoặc unique), `week_id` (FK), `order`, `title`, `skill`, `template`
  - hiển thị: `default_view`, `allowed_views` (mảng)
  - nội dung: `content` (JSONB), `schema_version`
  - xuất bản: `status` (`draft|scheduled|published|archived`), `publish_at?`, `published_at?`
  - phiên bản và trường tính sẵn: `version` (int), `section_count`, `estimated_minutes`
  - người tạo và thời gian: `created_by`, timestamps
  - ràng buộc: unique (`week_id`, `order`).
- `weekly_document_revisions` (lịch sử, khuyến nghị): `document_id`, `version`, `content`, `edited_by`, `created_at`.
- `user_document_progress`:
  - khoá: `user_id`, `document_id` (PK kép)
  - tiến độ đọc: `last_section`, `seen_sections` (int[]), `view_mode`
  - trắc nghiệm: `quiz_answers` (JSONB: `{ blockKey: { option, firstCorrect, answeredAt } }`)
  - thời gian: `completed_at?`, `updated_at`
- `learning_activities` (phục vụ streak): `id`, `user_id`, `type` (`section_view|quiz_answer|doc_complete|vocab_review`), `ref_id`, `occurred_at`. Có index (`user_id`, `occurred_at`).
- Sổ từ: dùng bảng hiện có [ĐIỀN tên]; nếu chưa có thì tạo `vocab_entries`: `id`, `user_id`, `word`, `word_norm` (viết thường, đã trim), `pos?`, `ipa?`, `meaning`, `example?`, `source_document_id?`, `source_block_key?`, `created_at`, unique (`user_id`, `word_norm`).

## 2. Kiểm tra nội dung (validator dùng chung)

- Validate `content` bằng JSON Schema 2020-12 (`weekly_doc.schema.json`), dùng thư viện chuẩn của stack (ajv, networknt, jsonschema…).
- Thêm các kiểm tra mà schema không diễn tả được:
  - `quiz.answer < options.length`
  - `image.url` thuộc host được phép
  - `meta.defaultView` phải nằm trong `allowedViews`
  - `id`, `week`, `order` trong `content` khớp với bản ghi (nếu có trong JSON thì ghi đè theo bản ghi khi lưu)
- Trả về `{ valid, errors: [{ path, message }], warnings: [{ path, message }] }`. `path` có dạng `sections[2].blocks[1].answer`. Message bằng tiếng Việt, ngắn gọn.
- Warnings: chỗ trống `[ … ]` còn sót; section > 6 khối hoặc > 900 ký tự (gợi ý `slideBreak`).
- Khi lưu, tính lại `section_count` và `estimated_minutes` (số từ ÷ 180 + 1 phút/quiz, làm tròn lên, tối thiểu 1).

## 3. API

REST, JSON, prefix [ĐIỀN: `/api/v1`]. Định dạng lỗi theo convention hiện có. Có phân trang ở các API danh sách nếu cần.

### Admin (yêu cầu role `admin`)

| Method | Path | Mô tả |
|---|---|---|
| GET | `/admin/templates` | Danh sách template (id, name, skill, desc, outline) |
| GET | `/admin/templates/{id}` | JSON khung của template |
| GET/POST/PATCH | `/admin/weeks`, `/admin/weeks/{id}` | Quản lý tuần |
| GET | `/admin/documents?weekId=&status=` | Danh sách tài liệu |
| POST | `/admin/documents` | Tạo nháp. Body: `{ weekId, order?, title, skill, template }` hoặc `{ weekId, content }`. Thiếu `order` thì lấy max+1 |
| GET | `/admin/documents/{id}` | Chi tiết, kèm `version` |
| PUT | `/admin/documents/{id}` | Lưu nháp hoặc sửa. Body: `{ content, title?, skill?, defaultView?, allowedViews?, version }`. Sai `version` thì trả **409** kèm bản hiện tại. Cho lưu nháp dù còn lỗi (lưu kèm kết quả validate) |
| POST | `/admin/documents/validate` | Chạy thử validate một `content` bất kỳ, không lưu |
| POST | `/admin/documents/import` | `multipart/form-data` file `.json` (≤ 1 MB) + `weekId`: parse, validate, tạo nháp, trả kết quả validate |
| GET | `/admin/documents/{id}/export` | Trả file `{id}.json` (Content-Disposition attachment) |
| POST | `/admin/documents/{id}/publish` | Body: `{ publishAt? }`. Còn **error** thì trả 422 kèm danh sách. Có `publishAt` ở tương lai thì `scheduled`, không thì `published` ngay |
| POST | `/admin/documents/{id}/unpublish` | Chuyển sang `archived` |
| DELETE | `/admin/documents/{id}` | Chỉ cho `draft` |
| POST | `/admin/uploads/images` | Upload ảnh (png/jpg/webp, ≤ 5 MB), trả `{ url }` |

### Người dùng (đăng nhập)

| Method | Path | Mô tả |
|---|---|---|
| GET | `/weeks` | Các tuần kèm `state` (`locked`/`open`), `docTotal`, `docDone` của tôi |
| GET | `/weeks/{id}/documents` | Tài liệu `published` của tuần (không kèm `content`): `id, order, title, skill, defaultView, allowedViews, sectionCount, estimatedMinutes, progress { lastSection, seenCount, completed }`. Tuần `locked` thì 403 |
| GET | `/documents/{id}` | `content` + `progress` của tôi. Hỗ trợ `ETag`/`If-None-Match` để FE cache offline |
| PUT | `/documents/{id}/progress` | Body: `{ sectionIndex, viewMode }`. Thêm vào `seen_sections`, cập nhật `last_section`, ghi `learning_activities` (`section_view`) nếu là section mới. Idempotent |
| POST | `/documents/{id}/quiz-answers` | Body: `{ blockKey, option }`. Lưu lựa chọn, giữ `firstCorrect` của lần đầu. Trả `{ correct, answer, explain }` |
| POST | `/documents/{id}/complete` | Ghi `completed_at` nếu chưa có (idempotent). Trả `{ completedNow, weekStage: { done, goal, passedGate, justPassedGate }, streak }` |
| POST | `/vocab/from-document` | Body: `{ documentId, blockKeys? }`, mặc định lấy mọi khối vocab. Trả `{ added, existed, total }` |
| GET | `/me/summary` | Cho trang chủ: `{ streakDays, savedWords, weekStage { done, goal }, wordsToReview, wordsLearnedThisWeek }` |

## 4. Quy tắc nghiệp vụ cần cài đặt

- Xuất bản theo lịch: job mỗi phút chuyển `scheduled` thành `published` khi tới `publish_at`. Ghi `published_at`. Job phải idempotent.
- User chỉ thấy tài liệu `published` thuộc tuần `open`. Gọi tài liệu `draft`, `scheduled`, `archived` thì trả 404.
- Sửa tài liệu đã xuất bản: tăng `version`, ghi revision. Tiến độ cũ: `last_section` vượt quá `section_count - 1` thì kẹp lại khi đọc; giữ nguyên `completed_at`.
- Chặng Vũ Môn và streak tính đúng như mục 6 file nghiệp vụ (theo giờ Việt Nam). `justPassedGate = true` chỉ ở lần `complete` làm `done` chạm `goal` lần đầu trong tuần.
- Bỏ trùng từ vựng theo `word_norm`. Không ghi đè nghĩa của từ đã có.
- Mọi API ghi dữ liệu của user đều idempotent, an toàn khi FE gửi lại (đường truyền mobile chập chờn).

## 5. Seed và kiểm thử

- Seed: 5 template (đúng cấu trúc ở mục 3.5 file nghiệp vụ); Tuần 10–13 (13 ở tương lai); Tuần 12 có `w12-doc1` (Reading: Matching Headings, đã xuất bản, đủ 8 loại khối) và `w12-doc2` (Writing Task 2, nháp).
- Unit test validator: JSON hợp lệ; thiếu `title`; `type` lạ; `answer` ngoài phạm vi; URL ảnh sai host; còn chỗ trống (warning).
- Integration test:
  - luồng admin: tạo từ template → lưu → validate → publish → user thấy
  - xung đột `version` trả 409
  - publish khi còn lỗi trả 422
  - user đọc section → complete → `weekStage` và `streak` đúng
  - lưu từ vựng bỏ trùng
  - streak qua mốc nửa đêm giờ Việt Nam
- Viết tài liệu API (OpenAPI/Swagger) cho toàn bộ endpoint trên.

## Cách làm việc

1. Đọc codebase, đề xuất danh sách file sẽ tạo hoặc sửa, chờ xác nhận.
2. Làm theo thứ tự: migration → validator + test → API admin → API user → job lịch → seed → OpenAPI.
3. Sau mỗi bước, chạy test và báo tóm tắt thay đổi.

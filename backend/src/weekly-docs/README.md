# Module Tài liệu theo tuần (`weekly-docs`)

Backend cho file nghiệp vụ 1, 2, 7 và 9 (tài liệu HTML). Bảng tự tạo nhờ `synchronize: true` như các module khác.

## Quy ước

- Prefix: `/api/admin/weekly/...` (admin, role `ADMIN`) và `/api/weekly/...` (người dùng đã đăng nhập). Không dùng `/api/documents` vì đã có module tài liệu cũ.
- Response bọc theo `TransformInterceptor`: `{ status, message, data, code, count }`.
- Lỗi: `{ status: "error", message, error: <MÃ>, code: <HTTP>, data }`. `data` có nội dung khi FE cần: 409 `DOC_VERSION_CONFLICT` → `data.current` là bản hiện tại; 422 `DOC_INVALID_CONTENT` → `data = { valid, errors, warnings }`.
- Tuần định danh bằng `number` (12), tài liệu bằng mã `w{tuần}-doc{số}`. Đổi số thứ tự (sắp xếp) thì đổi mã.
- **Loại** (`category`): `lesson` = Tài liệu (mặc định), `homework` = Bài tập (FE gắn tag HOMEWORK). Mỗi loại đánh số riêng trong tuần, bài tập có mã `w{tuần}-hw{số}`. Chọn khi tạo, không đổi sau đó; nhân bản giữ loại.
- **Tuần tự sinh**: luôn có sẵn tuần này + `WEEKLY_WEEKS_AHEAD` tuần tới (mặc định 4), nối tiếp tuần cuối theo các thứ Hai liên tiếp; DB trống thì Tuần 1 = tuần này. Chạy khi liệt kê tuần, khi tạo tài liệu và trong job mỗi giờ. Admin vẫn tạo / sửa tuần bằng API được (đổi tên, mục tiêu chặng).
- `content` là JSON tài liệu như FE dùng (`schemaVersion, id, week, order, category, title, template, meta, sections`). `id / week / order / category` luôn ghi đè theo bản ghi. Tài liệu HTML có thêm `html`, `htmlFileName` trong `content` (hoặc gửi ở cấp body).
- Thời gian lưu UTC; ngày, tuần lịch, streak tính theo giờ Việt Nam (UTC+7).

## Admin

| Method        | Path                                                                             | Ghi chú                                                                                                                                                                    |
| ------------- | -------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GET           | `/admin/weekly/weeks`                                                            | Danh sách tuần + số tài liệu theo trạng thái + `suggestion` cho form tạo tuần                                                                                              |
| POST          | `/admin/weekly/weeks`                                                            | `{ number, startDate (thứ Hai), title?, stageGoal? }`                                                                                                                      |
| PATCH         | `/admin/weekly/weeks/:number`                                                    | `title`, `stageGoal`; `startDate` chỉ khi tuần chưa mở và chưa có tài liệu xuất bản                                                                                        |
| DELETE        | `/admin/weekly/weeks/:number`                                                    | Chỉ khi tuần không còn tài liệu                                                                                                                                            |
| PUT           | `/admin/weekly/weeks/:number/documents/order`                                    | Body `[{ id, order }]`, chỉ tài liệu chưa từng xuất bản                                                                                                                    |
| GET           | `/admin/weekly/templates` · `/templates/:id`                                     | 7 lựa chọn: 5 khung + `import` + `html`                                                                                                                                    |
| GET           | `/admin/weekly/documents?week=&status=draft,scheduled&skill=&category=&q=&page=` | Không trả `content` / `html`. Lọc 1 tuần thì trả hết, không thì 20/trang                                                                                                   |
| POST          | `/admin/weekly/documents`                                                        | Từ template `{ week, order?, category?, title, skill?, template }` hoặc từ JSON `{ week?, order?, category?, content }`. HTML: `template: "html"` + `html`, `htmlFileName` |
| POST          | `/admin/weekly/documents/validate`                                               | `{ content }` (object hoặc chuỗi JSON), không lưu                                                                                                                          |
| POST          | `/admin/weekly/documents/import`                                                 | multipart `file` (.json ≤ 1 MB) + `week` (+ `order`) → `{ document, validation }`                                                                                          |
| GET           | `/admin/weekly/documents/:id?source=live`                                        | Chi tiết + `content` + `validation`. Mặc định là bản đang soạn                                                                                                             |
| PUT           | `/admin/weekly/documents/:id`                                                    | Lưu nháp `{ content, version, title?, skill?, defaultView?, allowedViews?, html?, htmlFileName? }`. Sai `version` → 409                                                    |
| DELETE        | `/admin/weekly/documents/:id`                                                    | Chỉ nháp chưa từng xuất bản (xoá mềm 30 ngày) · `POST /:id/undelete` để hoàn tác                                                                                           |
| POST          | `/admin/weekly/documents/:id/publish`                                            | `{ publishAt? }`: có giờ → hẹn giờ. Còn lỗi → 422                                                                                                                          |
| POST / DELETE | `/admin/weekly/documents/:id/schedule`                                           | Hẹn giờ (≥ hiện tại + 5 phút) / huỷ hẹn giờ                                                                                                                                |
| POST          | `/admin/weekly/documents/:id/unpublish`                                          | `{ reason? }` → ARCHIVED                                                                                                                                                   |
| POST          | `/admin/weekly/documents/:id/restore`                                            | ARCHIVED → DRAFT                                                                                                                                                           |
| POST          | `/admin/weekly/documents/:id/release`                                            | "Cập nhật bản phát hành"                                                                                                                                                   |
| DELETE        | `/admin/weekly/documents/:id/revision-draft`                                     | "Bỏ thay đổi"                                                                                                                                                              |
| POST          | `/admin/weekly/documents/:id/duplicate`                                          | `{ targetWeek }`                                                                                                                                                           |
| GET           | `/admin/weekly/documents/:id/export?source=live\|draft`                          | File `{id}.json`                                                                                                                                                           |
| GET           | `/admin/weekly/documents/:id/preview`                                            | Như người dùng thấy, không ghi tiến độ                                                                                                                                     |
| GET           | `/admin/weekly/documents/:id/revisions` · `POST /revisions/:revisionId/restore`  | Lịch sử phiên bản; khôi phục chép vào bản đang soạn                                                                                                                        |
| GET           | `/admin/weekly/documents/:id/audit`                                              | Nhật ký thao tác                                                                                                                                                           |

**Sửa tài liệu đang PUBLISHED:** `PUT` ghi vào bản nháp sửa đổi (`hasRevisionDraft: true`), người dùng vẫn thấy bản cũ cho tới khi gọi `release`. Chi tiết có `draftSectionCount` để cảnh báo khi số section giảm. FE cần lấy `version` mới từ response của `release` cho lần lưu sau.

## Người dùng

| Method | Path                                 | Ghi chú                                                                                                                       |
| ------ | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| GET    | `/weekly/weeks`                      | Tuần + `state` (`locked`/`open`) + `docTotal`, `docDone` + `currentWeek`                                                      |
| GET    | `/weekly/weeks/:number/documents`    | Tài liệu PUBLISHED (không kèm `content`) + `progress`, tài liệu trước rồi bài tập (`category`). Tuần khoá → 403 `WEEK_LOCKED` |
| GET    | `/weekly/documents/:id`              | `content` + `progress` của tôi. Có `ETag`, gửi `If-None-Match` → 304                                                          |
| PUT    | `/weekly/documents/:id/progress`     | `{ sectionIndex, viewMode? }`, idempotent. Tài liệu đã gỡ → 404 `DOC_UNPUBLISHED`                                             |
| POST   | `/weekly/documents/:id/quiz-answers` | `{ blockKey, option }` → `{ correct, answer, explain }`                                                                       |
| POST   | `/weekly/documents/:id/complete`     | → `{ completedNow, weekStage: { done, goal, passedGate, justPassedGate }, streak }`                                           |
| POST   | `/weekly/vocab/from-document`        | `{ documentId, blockKeys? }` → `{ added, existed, total }`                                                                    |
| GET    | `/weekly/me/summary`                 | `{ streakDays, savedWords, weekStage, wordsToReview, wordsLearnedThisWeek }`                                                  |

## Tài liệu HTML (file 9)

- `template = "html"`, `sections = []`, chuỗi `html` lưu ở cột riêng (không select mặc định): API danh sách không đọc, không trả `html`.
- Chuỗi `html` tối đa 5 MB UTF-8 → vượt thì 413 `HTML_TOO_LARGE`. Riêng `/api/admin/weekly/*` nhận body tới 8 MB; các API khác giữ 100 KB.
- Kiểm tra khi xuất bản chỉ còn một lỗi: "Chưa tải file HTML". BE không render HTML; chuỗi chỉ trả trong JSON của API chi tiết.

## Mã lỗi

`WEEK_NOT_FOUND`, `WEEK_NUMBER_TAKEN`, `WEEK_OVERLAP`, `WEEK_START_NOT_MONDAY`, `WEEK_DATE_LOCKED`, `WEEK_NOT_EMPTY`, `WEEK_LOCKED`,
`DOC_NOT_FOUND`, `DOC_UNPUBLISHED`, `DOC_ORDER_TAKEN`, `DOC_VERSION_CONFLICT`, `DOC_INVALID_CONTENT`, `DOC_INVALID_TRANSITION`, `DOC_EDIT_ARCHIVED`, `DOC_DELETE_NOT_ALLOWED`, `DOC_MOVE_PUBLISHED`, `DOC_SCHEDULE_PAST`, `DOC_TITLE_INVALID`,
`HTML_TOO_LARGE`, `IMPORT_TOO_LARGE`, `IMPORT_PARSE_ERROR`, `TEMPLATE_NOT_FOUND`, `REVISION_NOT_FOUND`, `SECTION_OUT_OF_RANGE`, `BLOCK_NOT_FOUND`, `QUIZ_OPTION_INVALID`, `PAYLOAD_TOO_LARGE`.

## Cấu hình, job, seed, test

- `WEEKLY_IMAGE_HOSTS=cdn.a.com,cdn.b.com`: host ảnh được phép (bỏ trống = mọi host https).
- `WEEKLY_WEEKS_AHEAD=4`: số tuần tới tự sinh sẵn (0–52).
- Job mỗi phút xuất bản tài liệu tới giờ hẹn (còn lỗi thì về nháp, ghi `schedule_failed` vào nhật ký); mỗi giờ tự sinh tuần tới và xoá hẳn nháp đã xoá mềm quá 30 ngày. Tắt bằng `WEEKLY_SCHEDULER=off`.
- `npm run seed:weekly`: trên DB chưa có tuần nào, tạo Tuần 10–13 (12 là tuần này); có Tuần 12 thì thêm `w12-doc1` đã xuất bản, `w12-doc2` nháp. Chạy lại không tạo trùng.
- Unit test: `npx jest src/weekly-docs`. Integration test cần Postgres có DB tên kết thúc bằng `_test` (test xoá sạch bảng weekly):
  `DB_NAME=weekly_test npm run test:e2e -- weekly-docs`.

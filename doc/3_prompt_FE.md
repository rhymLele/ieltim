# Prompt FE (Flutter): Tài liệu theo tuần

Bạn là Flutter developer senior. Hãy xây dựng phía app cho chức năng **Tài liệu theo tuần** của IELTS Hub theo đúng các file đính kèm:

- `1_nghiep_vu_tai_lieu_theo_tuan.md`: nghiệp vụ
- `6_ui_ux_layout_tai_lieu_theo_tuan.md`: **bố cục và UI/UX chi tiết từng màn (bắt buộc làm đúng, đây là thay cho ảnh thiết kế)**
- `5_ai_rules_FE_flutter.md`: token, quy ước code
- `weekly_doc.schema.json`

Thứ tự ưu tiên khi mâu thuẫn: nghiệp vụ (1) → bố cục (6) → rule (5) → prompt này.

## Bối cảnh kỹ thuật

- Flutter 3.x, Dart 3. Chạy trên Android, iOS, web (admin chủ yếu dùng web/desktop).
- State management: [ĐIỀN: Riverpod / Bloc / Provider…]. Router: [ĐIỀN: go_router…]. HTTP: [ĐIỀN: dio…].
- Base URL API và danh sách endpoint: theo `2_prompt_BE.md`, mục 3. Nếu BE chưa xong, tạo `FakeWeeklyDocsRepository` đọc JSON mẫu trong assets, cùng interface với repository thật.
- UI kit sẵn có trong `lib/ielts_hub_fx/`: `FxColors`, `VuMonProgress`, `YourPondCard`, `SpeakButton`, `IeltsHubLogo`. Dùng lại, không vẽ lại.
- Thương hiệu:
  - màu: primary `#800020`, background `#FFF9F2`, sidebar `#F3E5D5`, viền `#EFDCCB`, chữ `#2A1418`, chữ phụ `#6B4A4F`, vàng `#E7A23B`
  - font Manrope; đoạn đề thi (`passage`) dùng font serif
- Đọc cấu trúc project hiện có trước khi tạo file; theo đúng convention thư mục và đặt tên.

## 1. Model và parse

- Dùng `freezed` + `json_serializable`:
  - `WeeklyDoc`, `DocMeta`, `DocSection`
  - `sealed class DocBlock` với các lớp con: `HeadingBlock`, `ParagraphBlock`, `CalloutBlock`, `StepsBlock`, `PassageBlock`, `QuizBlock`, `VocabBlock` (+ `VocabItem`), `PatternBlock`, `ImageBlock`, `SlideBreakBlock`, **`UnknownBlock`** (giữ nguyên JSON gốc)
- Parse theo `type`. Gặp `type` lạ thì tạo `UnknownBlock`, **không throw**.
- Hàm `blockKey(sectionIndex, blockIndex, block)`: trả `block.id` nếu có, không thì `"$s-$b"`.
- Markdown rút gọn trong `text`: `**đậm**`, `*nghiêng*`, `[link](https://…)`. Viết parser nhỏ ra `TextSpan`, không kéo cả thư viện markdown. Link mở bằng `url_launcher`.
- Validator phía client: cài đúng các quy tắc mục 3.4 file nghiệp vụ, trả `ValidationResult { errors, warnings }` (mỗi mục có `path`, `message`). Dùng cho màn admin để báo lỗi ngay; khi xuất bản vẫn tin kết quả của BE.

## 2. Bộ hiển thị khối (dùng chung cho mọi màn)

- `BlockRegistry`: `Map<Type, Widget Function(BuildContext, DocBlock, BlockContext)>`. `BlockContext` gồm: `mode` (slide/doc), `scale`, `blockKey`, callback quiz, khối đang được chọn (admin).
- **Giao diện từng khối:**

  | Khối | Cách hiển thị |
  |---|---|
  | `heading` | chữ 24–34, đậm 800 |
  | `paragraph` | 15–18, line-height 1.6 |
  | `callout` | nền `#FDF1DE`, icon bóng đèn, "Mẹo: …" |
  | `steps` | số trong ô bo góc nền `#F3E5D5` |
  | `passage` | khung nền kem viền `#EFDCCB`, nhãn nhỏ màu primary, chữ serif |
  | `quiz` | các nút đáp án (i, ii, iii…), chọn là hiện đúng (xanh `#2F7A4B`) hoặc sai (primary) + giải thích; chọn lại được |
  | `vocab` | danh sách từ / loại từ / IPA / nghĩa; mỗi từ có `SpeakButton` |
  | `pattern` | khối nền primary chữ kem, nhãn "MẪU CÂU" |
  | `image` | `CachedNetworkImage`, có `alt` cho trợ năng, bấm vào để phóng to |
  | `UnknownBlock` | ô xám "Nội dung chưa hỗ trợ, hãy cập nhật app" |

- `DocView`: `ListView` gồm tiêu đề tài liệu, các section (nhãn số + tên section), các khối; padding 16 (mobile) hoặc 40 (desktop); cuối trang có nút "Đánh dấu đã học xong".
- `SlideView`:
  - Tách slide theo section và `slideBreak`; dùng `PageView`.
  - Mobile dọc: mỗi slide là một thẻ bo 20 có bóng; nội dung dài thì cuộn trong thẻ.
  - Ngang hoặc desktop: khung 16:9 bọc `FittedBox`, kèm nút toàn màn hình (khoá xoay ngang trên mobile).
  - Điều khiển: nút trước/sau, chấm trang (trang hiện tại kéo dài), "n / N", vuốt ngang, phím ← → và Space trên web/desktop. Ở slide cuối, nút "Tiếp" đổi thành "Hoàn thành".
- Hai view dùng chung một state (đáp án quiz, section hiện tại), nên chuyển view không mất dữ liệu.

## 3. Màn người dùng

(Bố cục chi tiết: file 6, mục U1–U3.)

1. **`WeeksScreen`** (mục "Theo tuần" trong drawer hoặc sidebar):
   - Hàng tuần cuộn ngang: đã xong ✓ · tuần hiện tại (tô primary) · khoá ("Mở thứ Hai", bấm không vào).
   - Thẻ tuần: tiến độ `docDone/docTotal`.
   - Danh sách thẻ tài liệu: icon kiểu mặc định, kicker "Tài liệu n · Skill", tiêu đề, "Slide · 4 phần · khoảng 8 phút", thanh tiến độ, trạng thái (Chưa học · Đang học n/N · Đã học màu xanh).
   - Kéo xuống để làm mới (pull-to-refresh).
2. **`DocReaderScreen(id)`**:
   - Header: nút quay lại, "Tuần x · Tài liệu n", tiêu đề, nút chuyển Slide/Doc (chỉ hiện khi `allowedViews` có cả hai), thanh tiến độ 3px.
   - Mở đúng `lastSection` theo `defaultView` (hoặc view người dùng chọn lần trước).
   - Sang section mới thì gọi `PUT /progress` (debounce 500ms). Trả lời quiz thì gọi `POST /quiz-answers`.
3. **`DocCompleteScreen`**:
   - Cá chép vàng nhảy (animation) + sparkle; "Hoàn thành Tài liệu n!".
   - Dải chặng Vũ Môn `done/goal` lấy từ response `complete`. Nếu `justPassedGate` thì phát `DragonLoader(playOnce: true, duration: 4s)` hoặc hiệu ứng lóe sáng của `VuMonProgress`.
   - Các nút: "Lưu N từ vựng vào Sổ từ" (gọi `/vocab/from-document`, xong đổi chữ thành "Đã lưu N từ"), "Học tài liệu tiếp theo" (nếu còn), "Về danh sách tuần".
   - Sau khi hoàn thành: làm mới `/me/summary` để trang chủ cập nhật `YourPondCard`, `VuMonProgress` và badge.
4. **Offline và mạng yếu:**
   - Cache JSON tài liệu theo `id` + `ETag`.
   - Hàng đợi ghi tiến độ, quiz và complete khi mất mạng; gửi lại khi có mạng (các API phía BE đều idempotent).

## 4. Màn admin: tạo / sửa tài liệu

(Bố cục chi tiết: file 6, mục A1–A2. Tối ưu cho web/desktop ≥ 1024px.)

- **`DocCreatorScreen`**, wizard 3 bước có stepper ở header, cột **Xem trước** 500px luôn hiện bên phải (nút chuyển Slide/Doc; ở kiểu Slide có nút trước/sau).
  1. **Chọn template:**
     - Ô nhập tên, tuần, số thứ tự (gợi ý max+1), chip kỹ năng.
     - Lưới thẻ template, mỗi thẻ có ảnh thu nhỏ liệt kê các section; một thẻ đặc biệt "Nhập từ file JSON".
  2. **Soạn nội dung**, có tab "Soạn theo form" / "Nhập JSON":
     - **Form:**
       - Cây section và khối (bấm để chọn; phần xem trước nhảy tới slide chứa khối và tô viền vàng khối đó).
       - Khung soạn theo loại khối:
         - quiz: câu hỏi, đáp án mỗi dòng, chọn đáp án đúng, giải thích
         - vocab: mỗi dòng `từ | loại | IPA | nghĩa`
         - passage: nhãn + đoạn văn
       - Nút ↑ ↓ xoá; chip "+ Thêm khối" (8 loại + ảnh, upload qua `/admin/uploads/images`); "+ Thêm section".
     - **JSON:** editor font mono nền tối; "Tải file .json lên"; "Kiểm tra & áp dụng" hiện danh sách lỗi kèm đường dẫn (bấm vào lỗi thì nhảy tới khối đó nếu được); "Lấy lại từ template".
     - Form và JSON là hai cách nhìn của **cùng một** `WeeklyDoc` trong state.
     - Tự lưu nháp (debounce 1,5s, gửi kèm `version`). Nhận 409 thì báo xung đột và cho chọn "Tải bản mới".
  3. **Xuất bản:**
     - Chọn `defaultView` (Slide/Doc); công tắc "Cho phép người dùng tự đổi"; thời điểm (ngay / hẹn giờ).
     - Bảng kiểm tra: đỏ chặn, vàng cảnh báo, xanh sẵn sàng.
     - Nút "Xuất bản" (nhận 422 thì hiện lỗi từ BE).
     - Thành công: "Tải {id}.json" (gọi `/export`) và "Tạo tài liệu {n+1}".
- **`AdminWeekDocsScreen`:** danh sách tài liệu theo tuần, có lọc trạng thái, các thao tác sửa / nhân bản / gỡ / xoá (chỉ nháp) / export.

## 5. Yêu cầu chung

- Tôn trọng `MediaQuery.disableAnimations`: không trượt slide, không animation chúc mừng.
- Vùng chạm ≥ 44×44 (nút chính 48–52). Nút chỉ có icon phải có `tooltip`/`Semantics`. Độ tương phản chữ ≥ 4.5:1.
- Responsive: dưới 840px dùng drawer (theo `HomePage` hiện có); từ 840px dùng sidebar.
- Không crash khi gặp dữ liệu lạ: `UnknownBlock`, section rỗng, ảnh lỗi (hiện khung giữ chỗ).
- Chuỗi giao diện tiếng Việt, gom vào một chỗ (l10n hoặc file `strings`), để sẵn cho đa ngôn ngữ sau này.

## 6. Kiểm thử

- Unit test: parse đủ 10 loại khối + `UnknownBlock`; `blockKey`; tách slide theo `slideBreak`; markdown rút gọn; validator client (cùng bộ case với BE).
- Widget test: `DocView` và `SlideView` render tài liệu mẫu; quiz chọn đúng/sai; chuyển view giữ đáp án; nút "Hoàn thành" ở slide cuối.
- Golden test (khuyến nghị): một slide và một trang doc ở 390×844 và 1280×800.
- Chạy `flutter analyze` sạch.

## Cách làm việc

1. Đọc codebase, đề xuất cấu trúc thư mục (ví dụ `features/weekly_docs/{data,domain,presentation}`) và danh sách file, chờ xác nhận.
2. Làm theo thứ tự: model + parser + validator + test → `BlockRegistry` + `DocView` + `SlideView` → màn người dùng (với repository giả) → nối API thật → màn admin → offline queue.
3. Sau mỗi bước, chạy test và báo tóm tắt thay đổi.

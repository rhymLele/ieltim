# Nghiệp vụ chi tiết: Màn admin quản lý tài liệu theo tuần

> Bổ sung cho `1_nghiep_vu_tai_lieu_theo_tuan.md` (mục 4). File này mô tả **từng use case** của admin: tạo, sửa, xoá, xuất bản, gỡ, nhân bản, sắp xếp, import/export tài liệu, và quản lý tuần. Dùng cho cả BE (quy tắc, API) và FE (luồng, thông báo). Bố cục màn hình xem `6_ui_ux_layout_tai_lieu_theo_tuan.md` (mục A1, A2).

---

## 1. Vòng đời tài liệu (state machine)

```
            ┌────────── Sửa (lưu nháp) ─────────┐
            ▼                                   │
 (tạo) ──► DRAFT ──Xuất bản ngay──────────────► PUBLISHED ──Gỡ──► ARCHIVED
            │  ▲                                 ▲   │               │
            │  └─────── Huỷ hẹn giờ ──┐          │   └─ Sửa (bản mới, vẫn published)
            │                         │          │                   │
            └──Xuất bản hẹn giờ──► SCHEDULED ──đến giờ──┘            │
                                                                     │
 DRAFT ──Xoá──► (xoá hẳn)                 ARCHIVED ──Khôi phục──► DRAFT
```

| Từ \ Hành động | Sửa | Xuất bản ngay | Hẹn giờ | Huỷ hẹn giờ | Gỡ | Khôi phục | Xoá | Nhân bản |
|---|---|---|---|---|---|---|---|---|
| **DRAFT** | ✓ | ✓ → PUBLISHED | ✓ → SCHEDULED | — | — | — | ✓ (xoá hẳn) | ✓ |
| **SCHEDULED** | ✓ (giữ lịch) | ✓ → PUBLISHED | ✓ đổi giờ | ✓ → DRAFT | — | — | — | ✓ |
| **PUBLISHED** | ✓ (tăng version) | — | — | — | ✓ → ARCHIVED | — | ✗ | ✓ |
| **ARCHIVED** | ✗ (phải khôi phục trước) | — | — | — | — | ✓ → DRAFT | ✗ | ✓ |

- Ô "✗": API trả **409** kèm thông báo (xem mục 7). FE ẩn hoặc làm mờ nút tương ứng.
- Mọi chuyển trạng thái đều được ghi **nhật ký** (mục 6).

---

## 2. Phân quyền

| Hành động | `admin` | `editor` *(tuỳ chọn, nếu cần sau này)* | `user` |
|---|---|---|---|
| Xem danh sách, xem trước mọi trạng thái | ✓ | ✓ | ✗ |
| Tạo, sửa nháp | ✓ | ✓ | ✗ |
| Xuất bản, hẹn giờ, gỡ, khôi phục | ✓ | ✗ (chỉ "Gửi duyệt") | ✗ |
| Xoá nháp | ✓ | chỉ nháp do mình tạo | ✗ |
| Quản lý tuần | ✓ | ✗ | ✗ |

> [CẦN CHỐT] Giai đoạn 1 chỉ có `admin`. Cột `editor` để dành, BE nên kiểm tra quyền theo **hành động** (permission) thay vì kiểm tra cứng theo role.

---

## 3. Quản lý tuần

### UC-W01 Tạo tuần
- **Đầu vào:** `number` (bắt buộc, số nguyên ≥ 1, duy nhất), `startDate` (bắt buộc, phải là **thứ Hai**), `endDate` (tự tính = `startDate` + 6 ngày, không cho sửa), `title` (tuỳ chọn, ≤ 80 ký tự), `stageGoal` (1–20, mặc định 5).
- **Gợi ý khi mở form:** `number` = tuần lớn nhất + 1; `startDate` = thứ Hai kế tiếp sau tuần lớn nhất.
- **Ràng buộc:** khoảng ngày không được chồng lên tuần khác. Trùng `number` thì báo "Tuần 12 đã tồn tại".

### UC-W02 Sửa tuần
- Sửa được `title` và `stageGoal`.
- Chỉ sửa được `startDate` khi tuần **chưa mở** (ngày hiện tại < `startDate`) **và** chưa có tài liệu `published`. Ngược lại khoá ô ngày, kèm gợi ý "Tuần đã mở, không đổi được ngày".
- Không đổi được `number` sau khi đã tạo (vì `id` tài liệu `w{number}-doc{order}` phụ thuộc vào nó).

### UC-W03 Xoá tuần
- Chỉ xoá được khi tuần **không còn tài liệu nào** (ở bất kỳ trạng thái nào).
- Còn tài liệu thì nút Xoá bị khoá, tooltip "Xoá hoặc chuyển hết tài liệu trước".
- Hộp xác nhận: "Xoá Tuần 13? Thao tác không hoàn tác được." `[Huỷ]` `[Xoá tuần]` (nút đỏ).

---

## 4. Use case tài liệu

### UC-D01 Xem danh sách tài liệu (màn A1)
- **Mặc định:** chọn tuần hiện tại (tuần chứa ngày hôm nay, không có thì lấy tuần gần nhất), lọc "Tất cả trạng thái", sắp theo `order` tăng dần.
- **Bộ lọc:** tuần (dropdown, có "Tất cả tuần"), trạng thái (chip, chọn được nhiều), kỹ năng, ô tìm kiếm theo tiêu đề (tìm khi đã ngừng gõ 300ms, không phân biệt dấu và hoa thường).
- **Mỗi hàng:** số thứ tự · tiêu đề · kỹ năng · kiểu mặc định · trạng thái (đã hẹn thì kèm giờ) · cập nhật lần cuối ("10:42 hôm nay · Minh") · menu `⋯`.
- **Phân trang:** 20 hàng/trang khi xem "Tất cả tuần". Lọc theo một tuần thì hiện hết, không phân trang.
- **Bộ lọc lưu trên URL** (ví dụ `?week=12&status=draft`) để tải lại trang hay chia sẻ link vẫn giữ nguyên.

### UC-D02 Tạo tài liệu
**Điểm vào:** nút `[+ Tạo tài liệu]` ở A1 (mang theo tuần đang lọc), hoặc "Tạo tài liệu {n+1}" sau khi xuất bản.

**Luồng chính:**
1. **Bước 1:** admin nhập các trường sau, rồi chọn template.

   | Trường | Bắt buộc | Quy tắc | Mặc định |
   |---|---|---|---|
   | Tên tài liệu | ✓ | 3–200 ký tự, tự trim | trống |
   | Tuần | ✓ | tuần đã tồn tại | tuần đang lọc ở A1 |
   | Tài liệu số (`order`) | ✓ | số nguyên ≥ 1, duy nhất trong tuần | lớn nhất + 1 |
   | Kỹ năng | ✓ | 1 trong 5 giá trị | theo template |
   | Template | ✓ | 1 trong 6 lựa chọn | `reading-lesson` |

2. Bấm **"Tiếp tục"** thì validate các trường trên. Hợp lệ thì **tạo bản ghi DRAFT ngay lúc này** (POST), gán `id = w{tuần}-doc{order}`, `content` = khung của template.
   - Từ đây mọi thay đổi đều là "sửa nháp" (UC-D03).
   - URL đổi thành `/admin/documents/{id}/edit?step=2` để tải lại trang không mất bài.
3. **Bước 2:** soạn nội dung (UC-D03). Bấm "Tiếp tục" thì lưu ngay bản mới nhất rồi sang bước 3.
4. **Bước 3:** xuất bản (UC-D05).

**Ngoại lệ:**
- **Trùng `order`:** báo lỗi ngay dưới ô nhập "Tuần 12 đã có Tài liệu 2", kèm gợi ý "Dùng số 3?" (bấm để điền).
- **Chọn "Nhập từ file JSON":** bước 1 chỉ cần chọn tuần. Tên, số thứ tự và kỹ năng lấy từ file ở bước 2. Nếu file có `week` / `order` khác với tuần đang chọn thì hỏi lại: "File ghi Tuần 11 · Tài liệu 3. Dùng theo file hay theo tuần đang chọn (Tuần 12 · Tài liệu 2)?"
- **Rời trang khi đã tạo nháp:** không cần hỏi vì nháp đã được lưu. Nếu còn thay đổi chưa kịp lưu (đang trong 1,5 giây chờ) thì lưu ngay trước khi rời; lưu lỗi thì hỏi "Có thay đổi chưa lưu. Rời trang?".

### UC-D03 Sửa tài liệu (nội dung)
**Điểm vào:** bấm vào hàng ở A1, hoặc menu `⋯` → "Sửa". Mở A2 ở **bước 2**. Thanh bước hiện cả 3 bước, admin bấm được để quay lại bước 1 hoặc nhảy tới bước 3.

**Quy tắc lưu:**
- **Tự lưu** sau 1,5 giây ngừng thao tác. Mỗi lần lưu gửi kèm `version` hiện tại; server trả `version` mới.
- Trên header hiện trạng thái lưu: "Đang lưu…" → "Đã lưu nháp · 10:42" → (khi lỗi) "Chưa lưu được · Thử lại".
- **Được lưu dù nội dung còn lỗi** (ví dụ quiz thiếu đáp án). Lỗi chỉ chặn ở bước xuất bản.
- Nội dung được giữ trong bộ nhớ đệm trên máy (local) theo `id`. Mất mạng vẫn soạn được; có mạng lại thì tự đẩy lên.

**Sửa tài liệu đang PUBLISHED:**
- Mở ra thì hiện dải cảnh báo vàng trên vùng làm việc: "Tài liệu đang hiển thị cho người dùng. Thay đổi chỉ được áp dụng khi bạn bấm **Cập nhật bản phát hành**."
- Thay đổi được lưu vào **bản nháp sửa đổi** (revision draft), **không** ảnh hưởng người dùng cho tới khi bấm "Cập nhật bản phát hành" ở bước 3. Khi đó `version` + 1 và người dùng thấy bản mới ở lần mở sau.
- Có nút "Bỏ thay đổi" để xoá bản nháp sửa đổi, quay về bản đang phát hành (có hộp xác nhận).
- Nếu bản mới **giảm số section** thì cảnh báo ở bước 3: "Bản mới có 3 section (trước: 4). Người dùng đang đọc ở section 4 sẽ được đưa về section 3."

**Sửa tài liệu SCHEDULED:** sửa trực tiếp, vẫn giữ lịch. Lúc đến giờ xuất bản, phải qua kiểm tra lỗi một lần nữa; còn lỗi thì **không xuất bản**, chuyển về DRAFT và thông báo cho admin (mục 6).

**Xung đột (hai người cùng sửa):**
- Server trả **409** kèm bản hiện tại và tên người sửa.
- FE hiện hộp thoại: "Minh vừa sửa tài liệu này lúc 10:41. [Tải bản mới] [Ghi đè bằng bản của tôi]".
- "Ghi đè" chỉ khả dụng với `admin`. Bản bị ghi đè vẫn còn trong lịch sử.

**Sửa thông tin chung (bước 1)** khi đã có nháp:
- Đổi được tên và kỹ năng.
- Đổi tuần / `order` = **chuyển tài liệu**: `id` đổi theo, và chỉ làm được khi tài liệu chưa từng xuất bản. Đã từng xuất bản thì khoá, gợi ý dùng "Nhân bản".
- Đổi template khi đã có nội dung: hỏi "Đổi template sẽ thay toàn bộ nội dung hiện tại bằng khung mới. Tiếp tục?". Nội dung cũ vẫn lấy lại được từ lịch sử phiên bản.

### UC-D04 Xem trước
- Ở A2: cột Xem trước luôn cập nhật theo nội dung đang soạn (chưa cần lưu).
- Ở A1: menu `⋯` → "Xem trước" mở **màn đọc của người dùng (U2)** ở chế độ chỉ xem. Trên cùng có dải "Bản xem trước · Không ghi tiến độ". Trắc nghiệm vẫn bấm được nhưng không lưu kết quả.
- Có công tắc xem dạng **mobile 390** hoặc **desktop** để kiểm tra bố cục.

### UC-D05 Xuất bản (bước 3)
1. Admin chọn `defaultView`, `allowedViews` (công tắc "Cho phép người dùng tự đổi"), và thời điểm:
   - **Ngay**
   - **Hẹn giờ:** chọn ngày và giờ theo giờ Việt Nam, phải sau thời điểm hiện tại ít nhất 5 phút. Gợi ý nhanh: "Thứ Hai tuần này 06:00", "Ngày mở tuần 06:00".
2. Hệ thống chạy kiểm tra (FE kiểm tra trước để hiện kết quả ngay, BE kiểm tra lại khi bấm):
   - **Lỗi** → nút khoá, hiện danh sách lỗi. Bấm vào lỗi thì nhảy về bước 2 đúng khối đó.
   - **Chỉ có lưu ý** → bấm Xuất bản thì hiện hộp xác nhận: "Còn 3 khối có chỗ trống [ … ]. Vẫn xuất bản?".
3. **Quy tắc theo tuần:**
   - Tuần **chưa mở**: xuất bản "ngay" thì trạng thái là PUBLISHED, nhưng người dùng chỉ thấy khi tuần mở. Hiện ghi chú: "Người dùng sẽ thấy từ thứ Hai 07/10".
   - Tuần **đã qua**: cho xuất bản (bổ sung tài liệu cho tuần cũ), kèm cảnh báo "Tuần 10 đã kết thúc. Tài liệu vẫn hiện trong danh sách tuần đó."
4. **Kết quả:** card thành công, kèm hai nút "Tải {id}.json" và "Tạo tài liệu {n+1}". Ở A1, hàng tài liệu đổi badge sang "Đã xuất bản" hoặc "Đã hẹn · 07/10 06:00".

### UC-D06 Huỷ hẹn giờ / đổi giờ
- Menu `⋯` của tài liệu SCHEDULED có: "Đổi giờ xuất bản" (mở hộp chọn ngày giờ), "Huỷ hẹn giờ" (về DRAFT, không cần xác nhận, có snackbar "Đã huỷ hẹn giờ · Hoàn tác").

### UC-D07 Gỡ tài liệu (unpublish)
- Chỉ áp dụng cho PUBLISHED.
- Hộp xác nhận: "Gỡ "Reading: Matching Headings"? Người dùng sẽ không thấy tài liệu này nữa. Tiến độ đã học vẫn được giữ."
  - Nhập lý do (tuỳ chọn, ≤ 200 ký tự).
  - Nút `[Huỷ]` `[Gỡ tài liệu]`.
- **Kết quả:** trạng thái chuyển ARCHIVED, ẩn khỏi U1/U2.
  - Người dùng **đang mở** tài liệu sẽ thấy thông báo ở lần lưu tiến độ tiếp theo: "Tài liệu này đã được gỡ" + nút về danh sách.
  - Chặng Vũ Môn và streak đã tính **không bị trừ lại**.

### UC-D08 Khôi phục
- ARCHIVED → DRAFT, giữ nguyên nội dung và `id`. Muốn hiển thị lại cho người dùng thì phải xuất bản lại.

### UC-D09 Xoá tài liệu
- **Chỉ xoá được DRAFT chưa từng xuất bản** (`publishedAt` rỗng). Tài liệu đã từng xuất bản chỉ được gỡ.
- Hộp xác nhận: "Xoá bản nháp "…"? Thao tác không hoàn tác được." `[Huỷ]` `[Xoá]` (nút đỏ).
- **Xoá mềm:** lưu thêm 30 ngày, có snackbar "Đã xoá · Hoàn tác" trong 8 giây; sau 30 ngày job dọn dẹp xoá hẳn.
- Sau khi xoá, **không tự đánh lại số** các tài liệu khác trong tuần (tránh đổi `id`). Có thể dùng UC-D10 để sắp xếp lại.

### UC-D10 Sắp xếp lại thứ tự trong tuần
- Ở A1 (đang lọc 1 tuần), bật "Sắp xếp" để kéo thả các hàng.
- **Chỉ đổi được thứ tự của tài liệu chưa từng xuất bản.** Tài liệu đã xuất bản giữ nguyên `order` để không đổi `id`, link và tiến độ; các hàng này có icon khoá và không kéo được.
- Lưu một lần cho cả danh sách bằng API cập nhật nhiều bản ghi cùng lúc (atomic).

### UC-D11 Nhân bản
- Menu `⋯` → "Nhân bản" → hộp chọn **tuần đích** (mặc định: tuần hiện tại) → tạo DRAFT mới.
  - Tiêu đề thêm hậu tố " (bản sao)", `order` = lớn nhất + 1 trong tuần đích.
  - Nội dung chép nguyên, `id` các block được tạo mới nếu có.
- Dùng khi muốn sửa lớn tài liệu đã xuất bản thành một tài liệu khác, hoặc tái sử dụng cho tuần sau.

### UC-D12 Import JSON
- **Ở bước 2, tab "Nhập JSON":**
  - Dán nội dung hoặc tải file `.json` (≤ 1 MB, mã hoá UTF-8).
  - Bấm "Kiểm tra & áp dụng": parse → validate → nếu hợp lệ thì **thay toàn bộ** nội dung nháp.
  - Có hộp xác nhận nếu nháp đã có nội dung: "Thay nội dung hiện tại bằng nội dung từ file?".
- **Import hàng loạt** (tuỳ chọn, giai đoạn 2): ở A1 nút "Import nhiều file" → chọn nhiều file JSON → bảng kết quả từng file (Tạo được / Lỗi + lý do). File nào hợp lệ thì tạo DRAFT.
- **Các key được đọc:**
  - `title`, `week`, `order`, `template`
  - `meta.skill`, `meta.defaultView`, `meta.allowedViews`
  - `sections[].title`, `sections[].blocks[]`
  - Key lạ ở cấp trên cùng bị **bỏ qua kèm cảnh báo**. `type` lạ trong block là **lỗi**.

### UC-D13 Export JSON
- Menu `⋯` → "Tải JSON", hoặc nút ở card thành công.
- Tải về file `{id}.json`, định dạng đẹp (thụt lề 2), đúng schema, gồm cả `meta`.
- Tài liệu PUBLISHED đang có bản nháp sửa đổi thì hỏi tải **bản phát hành** hay **bản nháp**.

### UC-D14 Lịch sử phiên bản
- Ở A2 có nút "Lịch sử" trên header: mở danh sách phiên bản (số phiên bản · thời gian · người sửa · ghi chú như "Xuất bản" hay "Tự lưu").
- Xem nhanh phiên bản cũ trong cột Xem trước. Bấm "Khôi phục phiên bản này" thì nội dung cũ được chép vào nháp hiện tại (không xoá lịch sử).
- Tự lưu không tạo phiên bản mới mỗi lần: gộp các lần tự lưu trong cùng một phiên soạn thành một phiên bản; mỗi lần xuất bản luôn tạo một phiên bản riêng.

---

## 5. Ràng buộc dữ liệu tổng hợp

| Trường | Quy tắc | Thông báo khi sai |
|---|---|---|
| `title` | 3–200 ký tự | "Tên tài liệu cần từ 3 đến 200 ký tự" |
| `order` | số nguyên ≥ 1, duy nhất trong tuần | "Tuần {w} đã có Tài liệu {n}" |
| `week` | tuần tồn tại | "Chưa có Tuần {w}. Tạo tuần trước" |
| `skill` | 1 trong 5 giá trị | "Chọn kỹ năng" |
| `defaultView` ∈ `allowedViews` | bắt buộc | "Kiểu mặc định phải nằm trong các kiểu cho phép" |
| `publishAt` | ≥ hiện tại + 5 phút | "Giờ xuất bản phải sau hiện tại ít nhất 5 phút" |
| `content` | theo `weekly_doc.schema.json` + quy tắc mục 3.4 file 1 | thông báo kèm đường dẫn |
| Ảnh upload | png/jpg/webp, ≤ 5 MB, ≤ 4000 px mỗi cạnh | "Ảnh cần là PNG, JPG hoặc WebP, tối đa 5 MB" |
| File JSON | ≤ 1 MB, UTF-8 | "File quá lớn (tối đa 1 MB)" / "File không phải JSON hợp lệ" |

---

## 6. Nhật ký và thông báo

- **Nhật ký thao tác** (`document_audit_logs`): `documentId`, `action` (`create | update | publish | schedule | unschedule | unpublish | restore | delete | duplicate | import | reorder`), `actorId`, `fromStatus`, `toStatus`, `version`, `note`, `createdAt`. Hiển thị ở tab "Hoạt động" trong A2.
- **Thông báo cho admin** (trong app; email nếu có):
  - Hẹn giờ xuất bản **thất bại** do còn lỗi: "Tài liệu "…" chưa được xuất bản lúc 06:00 vì còn 2 lỗi" + link sửa.
  - Hẹn giờ **thành công**: chỉ ghi nhật ký, không thông báo.

---

## 7. Danh mục thông báo (FE hiển thị, BE trả mã)

| Mã | Khi nào | Thông báo tiếng Việt |
|---|---|---|
| `DOC_ORDER_TAKEN` | trùng số thứ tự | Tuần {w} đã có Tài liệu {n}. |
| `DOC_VERSION_CONFLICT` | 409 khi lưu | {tên} vừa sửa tài liệu này lúc {giờ}. |
| `DOC_INVALID_CONTENT` | 422 khi xuất bản | Tài liệu còn {n} lỗi cần sửa trước khi xuất bản. |
| `DOC_DELETE_NOT_ALLOWED` | xoá tài liệu đã từng xuất bản | Tài liệu đã từng xuất bản nên không xoá được. Hãy dùng "Gỡ". |
| `DOC_EDIT_ARCHIVED` | sửa tài liệu đã gỡ | Tài liệu đã gỡ. Khôi phục để sửa tiếp. |
| `DOC_MOVE_PUBLISHED` | đổi tuần/số của tài liệu đã xuất bản | Tài liệu đã xuất bản không đổi tuần hoặc số thứ tự được. Hãy dùng "Nhân bản". |
| `DOC_SCHEDULE_PAST` | hẹn giờ trong quá khứ | Giờ xuất bản phải sau hiện tại ít nhất 5 phút. |
| `WEEK_NOT_EMPTY` | xoá tuần còn tài liệu | Xoá hoặc chuyển hết tài liệu trước khi xoá tuần. |
| `WEEK_NUMBER_TAKEN` | trùng số tuần | Tuần {w} đã tồn tại. |
| `WEEK_OVERLAP` | trùng khoảng ngày | Khoảng ngày bị trùng với Tuần {w}. |
| `IMPORT_TOO_LARGE` / `IMPORT_PARSE_ERROR` | import lỗi | File quá lớn (tối đa 1 MB). / File không phải JSON hợp lệ: {chi tiết}. |

---

## 8. API bổ sung (so với `2_prompt_BE.md`)

| Method | Path | Use case |
|---|---|---|
| DELETE | `/admin/weeks/{id}` | UC-W03 |
| POST | `/admin/documents/{id}/schedule` · `DELETE /admin/documents/{id}/schedule` | UC-D05, UC-D06 |
| POST | `/admin/documents/{id}/restore` | UC-D08 |
| POST | `/admin/documents/{id}/duplicate` (body `{ targetWeekId }`) | UC-D11 |
| PUT | `/admin/weeks/{id}/documents/order` (body `[{ id, order }]`) | UC-D10 |
| GET | `/admin/documents/{id}/revisions` · `POST /admin/documents/{id}/revisions/{v}/restore` | UC-D14 |
| POST | `/admin/documents/{id}/release` | UC-D03: đưa bản nháp sửa đổi thành bản phát hành |
| DELETE | `/admin/documents/{id}/revision-draft` | UC-D03: bỏ thay đổi |
| GET | `/admin/documents/{id}/audit` | mục 6 |
| GET | `/admin/documents/{id}/preview` | UC-D04: trả nội dung như user thấy, không ghi tiến độ |

---

## 9. Tiêu chí nghiệm thu (admin)

- [ ] Tạo tài liệu từ template: sau bước 1 đã có nháp; tải lại trang ở bước 2 không mất nội dung.
- [ ] Tự lưu hoạt động, hiện đúng trạng thái lưu; mất mạng vẫn soạn được và tự đồng bộ khi có mạng lại.
- [ ] Không xuất bản được khi còn lỗi; bấm vào lỗi thì nhảy đúng khối.
- [ ] Hẹn giờ: đúng giờ thì tự xuất bản; còn lỗi thì về nháp và có thông báo cho admin.
- [ ] Sửa tài liệu đã xuất bản không ảnh hưởng người dùng cho tới khi bấm "Cập nhật bản phát hành".
- [ ] Xung đột khi hai người cùng sửa được báo rõ; không mất dữ liệu.
- [ ] Không xoá được tài liệu đã từng xuất bản; gỡ thì người dùng không thấy nhưng tiến độ còn nguyên.
- [ ] Sắp xếp chỉ đổi được tài liệu chưa từng xuất bản; nhân bản sang tuần khác tạo đúng `id` mới.
- [ ] Import/export JSON khứ hồi (export rồi import lại) cho ra nội dung y hệt.
- [ ] Mọi thao tác đổi trạng thái đều có trong nhật ký.

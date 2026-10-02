# Đặc tả UI/UX và bố cục: Tài liệu theo tuần

> Tài liệu này mô tả **bằng chữ** toàn bộ bố cục để AI agent dựng đúng giao diện **mà không cần ảnh**.
> Đọc kèm `5_ai_rules_FE_flutter.md` (token màu, chữ, khoảng cách) và `1_nghiep_vu_tai_lieu_theo_tuan.md` (nghiệp vụ).
>
> **Quy ước đọc:**
> - Số đo là logical px.
> - `↔` là chiều ngang, `↕` là chiều dọc.
> - "Hàng" = `Row`, "Cột" = `Column`.
> - `[Nút]` là một nút bấm được, `( )` là ghi chú.
> - Tên màu (`primary`, `border`, `sidebar`…) và các mức chữ (title, body, eyebrow…) lấy theo `AppColors` và thang chữ trong file 5.
> - Wireframe ASCII chỉ thể hiện **vị trí tương đối**; kích thước chính xác xem bảng ngay dưới mỗi wireframe.

---

## 0. Bản đồ màn hình

| Mã | Màn | Ai dùng | Thiết bị chính |
|---|---|---|---|
| A1 | Danh sách tài liệu theo tuần (admin) | admin | desktop/web |
| A2 | Tạo / sửa tài liệu: wizard 3 bước | admin | desktop/web (≥ 1024) |
| U1 | Theo tuần: danh sách | user | mobile + desktop |
| U2 | Đọc tài liệu (Slide / Doc) | user | mobile + desktop |
| U3 | Hoàn thành tài liệu | user | mobile + desktop |

Luồng: `A1 → A2 (bước 1 → 2 → 3) → A1` · `Drawer "Theo tuần" → U1 → U2 → U3 → U1 hoặc U2 (tài liệu tiếp)`

---

## A2. Tạo / sửa tài liệu (admin, desktop 1280×800)

### A2.0 Khung chung (giống nhau ở cả 3 bước)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ HEADER 64                                                                    │
│ Admin › Theo tuần          ① Chọn template ── ② Soạn nội dung ── ③ Xuất bản   [w12-doc2.json] │
│ Tạo tài liệu mới                                                             │
├───────────────────────────────────────────────────────┬──────────────────────┤
│ VÙNG LÀM VIỆC (co giãn, cuộn dọc, padding 24)          │ XEM TRƯỚC 500        │
│                                                       │ (luôn hiện)          │
│   nội dung thay đổi theo bước                          │                      │
│                                                       │                      │
├───────────────────────────────────────────────────────┴──────────────────────┤
│ FOOTER 64   [← Quay lại]        gợi ý của bước hiện tại          [Tiếp tục →] │
└──────────────────────────────────────────────────────────────────────────────┘
```

| Vùng | Kích thước | Nội dung |
|---|---|---|
| Header | ↕ 64, nền `surface`, viền dưới 1px `border`, padding ↔ 24 | **Trái** (rộng 260): eyebrow "Admin › Theo tuần" (caption, `textMuted`) trên, "Tạo tài liệu mới" (heading 18/w800) dưới. **Giữa**: stepper. **Phải** (rộng 260, căn phải): chip tên file `w{tuần}-doc{số}.json` (caption w700, nền `background`, viền `border`, bo pill) |
| Stepper | 3 bước nằm ngang, giữa các bước có đường nối ↔ 48 × ↕ 2 | Mỗi bước: vòng tròn 28 + nhãn label. **Chưa tới**: vòng viền `borderStrong`, số màu `#B9958C`, nhãn cùng màu. **Đang ở**: vòng viền `primary` nền trắng, số `primary`, nhãn `text` w800. **Đã xong**: vòng nền `primary`, dấu ✓ màu kem; đường nối phía trước tô `primary` |
| Vùng làm việc | ↔ = 1280 − 500, ↕ = 800 − 64 − 64; padding 24; cuộn dọc | Theo bước (A2.1–A2.3) |
| Cột Xem trước | ↔ 500 cố định, nền `#FBF4EC`, viền trái 1px `border`, padding 20 trên/ngang, 16 dưới | Xem A2.4 |
| Footer | ↕ 64, nền `surface`, viền trên 1px `border`, padding ↔ 24 | **Trái**: `[← Quay lại]` (OutlinedButton 44; ẩn ở bước 1 và sau khi xuất bản). **Giữa** (co giãn): câu gợi ý của bước (caption 13, `textMuted`). **Phải**: nút chính 44, padding ↔ 22: "Tiếp tục →" ở bước 1–2, "Xuất bản" ở bước 3 (bị khoá, nền `#C9A9A3`, khi còn lỗi); ẩn sau khi xuất bản |

**Màn < 1024 (tablet / mobile):** cột Xem trước chuyển thành nút `[Xem trước]` trên header, bấm thì mở **bottom sheet** cao 90%. Stepper rút gọn còn "Bước 2/3 · Soạn nội dung".

### A2.1 Bước 1: Chọn template

```
Tên tài liệu ____________________  Tuần [12]  Tài liệu số [2]  Kỹ năng (Reading)(Listening)(Writing)…

CHỌN TEMPLATE
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│▒ ảnh thu nhỏ ▒│ │▒ ảnh thu nhỏ ▒│ │▒ ảnh thu nhỏ ▒│
│ Reading lesson  ĐANG CHỌN │ Writing Task 2 │ Vocab set      │
│ mô tả 2 dòng  │ │ mô tả         │ │ mô tả         │
└──────────────┘ └──────────────┘ └──────────────┘
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Speaking P2   │ │ Trống         │ │ { JSON } Nhập từ file JSON │
└──────────────┘ └──────────────┘ └──────────────┘
```

- **Hàng thông tin** (Grid 4 cột `2fr | 120 | 140 | 1fr`, gap 12, căn đáy). Mỗi ô là label (13/w700) phía trên + ô nhập phía dưới.
  - "Tên tài liệu": `TextField` (placeholder "Ví dụ: Reading: Matching Headings").
  - "Tuần": ô nhập số, ≥ 1.
  - "Tài liệu số": ô nhập số, mặc định = số lớn nhất trong tuần + 1.
  - "Kỹ năng": hàng chip cao 40, bo pill. Chip đang chọn nền `primary` chữ kem; chip khác nền trắng viền `borderStrong`.
  - Ô nhập: nền trắng, viền 1px `borderStrong`, bo 10, padding 10×12, chữ 14. Khi focus: viền `primary` + vòng mờ 3px `primary` 12%.
- Cách 20 → eyebrow "CHỌN TEMPLATE" → cách 10 → **lưới template 3 cột, gap 14**.
- **Thẻ template** (bấm được), cột gap 10, padding 12, nền trắng, viền 1.5px, bo 14:
  - Ảnh thu nhỏ ↕ 96, bo 10, padding 10×12: dòng kicker (10/w800, chữ hoa, ví dụ "READING-LESSON"), rồi mỗi section một dòng 11px gồm vạch 14×4 + tên section.
  - Hàng tên (14/w800) + bên phải chữ "ĐANG CHỌN" (11/w800 `primary`) nếu đang chọn.
  - Mô tả 12px `textMuted`, tối đa 2 dòng.
  - **Màu theo trạng thái:** thường thì ảnh nền `sidebar` chữ `textMuted`, viền `border`. Đang chọn thì ảnh nền `primary` chữ kem, viền `primary` + vòng mờ 3px. Thẻ "Nhập từ file JSON" có ảnh nền `#1F1214` chữ `#F3D9C4`, vạch `gold`, kicker "{ JSON }", các dòng là `schemaVersion · title · sections[ ] · blocks[ ]`.
  - Hover (web): viền `primary`, nhích lên 2px.
- **Hành vi:** chọn template thì Xem trước hiện ngay khung của template đó. Chọn "Nhập từ file JSON" thì sang bước 2 sẽ mở sẵn tab JSON.

### A2.2 Bước 2: Soạn nội dung

**Thanh trên của vùng làm việc:** segmented `[Soạn theo form | Nhập JSON]` (nền `sidebar`, padding 3, bo 12; mỗi nút cao 36, bo 9; nút đang chọn nền `primary` chữ kem) + câu gợi ý bên phải (12, `textMuted`).

#### Tab "Soạn theo form"

```
┌──── CÂY NỘI DUNG 290 ────┐ ┌──────────── KHUNG SOẠN (co giãn) ─────────────┐
│ ① DẠNG BÀI   (đang chọn) │ │ TÊN SECTION  [DẠNG BÀI____________________]   │
│    Tiêu đề               │ │ Khối: Đoạn văn            [↑] [↓] [Xoá khối]  │
│    [Tên dạng bài]        │ │ Nội dung  (Dùng **chữ đậm** để nhấn mạnh)     │
│  ▌ Đoạn văn  ◀ đang sửa  │ │ ┌───────────────────────────────────────────┐ │
│    [Mô tả dạng bài…]     │ │ │ textarea 5 dòng                           │ │
│    Mẹo                   │ │ └───────────────────────────────────────────┘ │
│ ② CHIẾN THUẬT            │ │ ───────────────────────────────────────────── │
│    …                     │ │ THÊM KHỐI VÀO SECTION NÀY                     │
│ [+ Thêm section]         │ │ (+Tiêu đề)(+Đoạn văn)(+Mẹo)(+Các bước)…       │
└──────────────────────────┘ └───────────────────────────────────────────────┘
```

- Grid 2 cột `290 | 1fr`, gap 14, chiếm hết chiều cao còn lại. Mỗi cột là card trắng viền `border`, bo 14, **cuộn độc lập**.
- **Cây nội dung** (padding 10, cột gap 10):
  - **Dòng section** (bấm được, ↕ 32, bo 8): huy hiệu số 20×20 nền `primary` + tên section (11/w800, letter-spacing 0.1em, `textMuted`). Section đang chọn có nền `sidebar`.
  - **Dòng khối** (bấm được, padding 7×10, thụt trái 36, bo 8): dòng 1 là tên loại khối (11/w800 `primary`); dòng 2 là đoạn trích nội dung (12, 1 dòng, cắt "…", tối đa 220). Khối đang chọn: nền trắng + viền trong 1.5px `primary`. Hover: nền `#FBF1E6`.
  - Cuối cây: `[+ Thêm section (slide mới)]` cao 40, viền đứt 1.5px `borderStrong`, bo 10, chữ `primary` 13/w800.
- **Khung soạn** (padding 16, cột gap 14):
  1. "TÊN SECTION" (eyebrow) + ô nhập.
  2. Hàng: "Khối: {tên loại}" (15/w800) bên trái; bên phải `[↑]` `[↓]` (36×36, viền `border`, bo 8) và `[Xoá khối]` (cao 36, viền `#F1C9CF`, chữ `primary`).
  3. **Các ô nhập theo loại khối:**

     | Loại khối | Các ô nhập |
     |---|---|
     | Tiêu đề / Đoạn văn / Mẹo | "Nội dung" + ghi chú "Dùng \*\*chữ đậm\*\* để nhấn mạnh" + textarea 5 dòng |
     | Các bước | textarea 6 dòng, ghi chú "Mỗi dòng là một bước" |
     | Đoạn đề | "Nhãn" (ô 1 dòng) + "Đoạn văn đề thi" (textarea 7 dòng) |
     | Trắc nghiệm | "Câu hỏi" (1 dòng) → "Các đáp án" (textarea 4 dòng, mỗi dòng một đáp án) → "Đáp án đúng": hàng nút 44×40 (i, ii, iii…; nút đúng nền `primary`) → "Giải thích" (textarea 3 dòng) |
     | Từ vựng | textarea 6 dòng font mono 13, ghi chú "Mỗi dòng: từ \| loại từ \| phiên âm \| nghĩa" |
     | Mẫu câu | "Cấu trúc" + "Câu ví dụ" (2 ô 1 dòng) |
     | Ảnh | vùng thả file 160 cao (viền đứt) + ô "Chú thích" + ô "Mô tả cho trợ năng (alt)" |

  4. Đường kẻ 1px `border`.
  5. "THÊM KHỐI VÀO SECTION NÀY" (eyebrow) + hàng chip tự xuống dòng (cao 34, bo pill, nền `background`, viền `borderStrong`, chữ 12/w700, dạng "+ Tiêu đề"); hover thì viền và chữ `primary`. Khối mới được chèn **ngay sau khối đang chọn** và tự được chọn.
- **Đồng bộ:** gõ đến đâu Xem trước cập nhật đến đó. Chọn khối thì Xem trước nhảy tới slide chứa khối và tô viền vàng khối đó (2px `gold` + vòng mờ 5px).
- **Tự lưu:** sau 1,5 giây không gõ thì lưu nháp; header hiện chữ nhỏ "Đã lưu nháp · 10:42" cạnh chip tên file.

#### Tab "Nhập JSON"

```
[⇪ Tải file .json lên]  [Kiểm tra & áp dụng]  [Lấy lại từ template]
┌──────────────────────────────────────────────────────────────┐
│ editor nền tối (#1F1214), chữ #F3D9C4, font mono 12.5        │
│ { "schemaVersion": 1, ... }                                  │
└──────────────────────────────────────────────────────────────┘
┌ kết quả: "JSON chưa hợp lệ" ─────────────────────────────────┐
│ • sections[2].blocks[1].answer: phải nằm trong 0…2           │
└──────────────────────────────────────────────────────────────┘
```

- **Hàng nút** (gap 10, cao 40, bo 10):
  - "Tải file .json lên": nền trắng, viền `borderStrong`, chữ `primary`, icon upload.
  - "Kiểm tra & áp dụng": nền `primary` chữ kem.
  - "Lấy lại từ template": viền, chữ `textMuted`.
- **Editor:** chiếm hết phần còn lại (tối thiểu 300 cao), padding 14, bo 12, viền 1px `#3A2226`, tắt kiểm tra chính tả, có số dòng nếu dễ làm.
- **Hộp kết quả** (chỉ hiện sau khi bấm Kiểm tra), padding 12×14, bo 12:
  - **Hợp lệ:** nền `successBg`, tiêu đề `success` "Hợp lệ, đã dựng tài liệu từ JSON".
  - **Lỗi:** nền `errorBg`, tiêu đề `primary` "JSON chưa hợp lệ".
  - Dưới tiêu đề là danh sách "• {đường dẫn}: {thông báo}" (12.5). Bấm vào một lỗi thì chuyển sang tab Form và chọn đúng khối bị lỗi (nếu xác định được).

### A2.3 Bước 3: Xuất bản

Vùng làm việc: một cột rộng tối đa 640, gap 16.

1. **Card "Hiển thị cho người dùng"** (trắng, viền, bo 14, padding 18, gap 14):
   - "Kiểu mặc định": 2 nút `[Slide] [Doc]` cao 40, bo 10. Nút đang chọn nền `primary`. Chọn thì Xem trước đổi theo.
   - Công tắc (switch 44×26) + nhãn "Cho phép người dùng tự đổi giữa Slide và Doc".
   - "Thời điểm": radio "Xuất bản ngay" / "Hẹn giờ". Chọn hẹn giờ thì hiện ô chọn ngày giờ.
2. **Hộp kiểm tra** (bo 14, padding 16×18):
   - **Đỏ** (`errorBg`, tiêu đề `primary`): "{n} lỗi cần sửa". Nút Xuất bản bị khoá.
   - **Vàng** (`tipBg`, tiêu đề `#8A5A12`): "Hợp lệ, nhưng còn lưu ý".
   - **Xanh** (`successBg`, tiêu đề `success`): "Hợp lệ, sẵn sàng xuất bản".
   - Dưới tiêu đề: danh sách lỗi hoặc lưu ý. Nếu không có gì thì ghi "{x} section, {y} khối".
3. **Sau khi xuất bản**, thay toàn bộ cột bằng **card thành công** (padding 28, căn trái, gap 12):
   - Vòng tròn 52 nền `successBg` có dấu ✓ màu `success`.
   - "Đã xuất bản Tài liệu {n} vào Tuần {w}" (22/w800).
   - Mô tả (14, `textMuted`).
   - Hai nút: `[Tải w12-doc2.json]` (chính) và `[Tạo tài liệu {n+1}]` (viền).

### A2.4 Cột Xem trước

- **Hàng đầu:** "XEM TRƯỚC" (eyebrow) bên trái; segmented nhỏ `[Slide | Doc]` bên phải (cao 30, nút đang chọn nền `primary`).
- **Khung xem trước:** ↔ 460.
  - **Slide:** ↕ 259 (16:9), nền trắng, bo 12, bóng nhẹ, padding 20. Chỉ hiện **một section**. Dưới khung là hàng `‹  Slide 2 / 4  ›` (nút tròn 36).
  - **Doc:** ↕ 520, cuộn dọc, padding 22. Hiện tiêu đề tài liệu (20/w800) rồi lần lượt từng section, cách nhau 22.
- **Cỡ chữ trong xem trước** (thu nhỏ): heading 19 (slide) / 16 (doc); body 12.5 / 12. Các khối dùng **cùng** `BlockRegistry` với màn người dùng, chỉ truyền `scale` nhỏ hơn.
- **Dòng ghi chú cuối** (12, `textMuted`):
  - Slide: "Slide: mỗi section là một slide 16:9. Nội dung dài thì tách thêm section."
  - Doc: "Doc: các section nối liền thành một trang cuộn dọc."

---

## A1. Danh sách tài liệu theo tuần (admin)

```
Tài liệu theo tuần                                   [+ Tạo tài liệu]
[Tuần 12 ▾]  (Tất cả)(Nháp)(Đã hẹn)(Đã xuất bản)(Đã gỡ)
┌────┬───────────────────────────────┬──────────┬────────┬──────────┬─────┐
│ #  │ Tiêu đề                        │ Kỹ năng  │ Kiểu   │ Trạng thái│ ⋯  │
│ 1  │ Reading: Matching Headings     │ Reading  │ Slide  │ ● Đã xuất bản │
│ 2  │ Writing Task 2: Opinion essay  │ Writing  │ Doc    │ ● Nháp    │     │
└────┴───────────────────────────────┴──────────┴────────┴──────────┴─────┘
```

- Header trang: tiêu đề (24/w800) bên trái; `[+ Tạo tài liệu]` (FilledButton 44) bên phải.
- Hàng lọc: dropdown tuần (cao 40) + chip trạng thái.
- **Bảng:** card trắng viền, mỗi hàng cao 56, hover nền `#FBF1E6`. Bấm vào hàng thì mở A2 ở bước 2. Cột "⋯" mở menu: Sửa · Nhân bản · Xem trước · Tải JSON · Gỡ (khi đã xuất bản) · Xoá (chỉ nháp, có hộp xác nhận).
- **Badge trạng thái** (chấm 8px + chữ 12/w700, nền nhạt, bo pill): Nháp = xám nâu `textMuted` / `sidebar`; Đã hẹn = vàng `#8A5A12` / `tipBg` (kèm giờ); Đã xuất bản = `success` / `successBg`; Đã gỡ = `#9A8A86` / `#F1ECE8`.
- **Rỗng:** hình lá sen nhỏ + "Tuần này chưa có tài liệu" + `[+ Tạo tài liệu]`.

---

## U1. Theo tuần: danh sách (user)

### U1-mobile (390×844)

```
┌──────────────────────────────┐
│ ☰  Theo tuần                 │ AppBar 60
├──────────────────────────────┤
│ [Tuần 10][Tuần 11][Tuần 12][Tuần 13] → cuộn ngang
│  2/2 ✓    3/3 ✓   0/2 tài liệu  Mở thứ Hai
│ ┌──────────────────────────┐ │
│ │ Tuần 12        30/09–06/10│ │ thẻ tuần (nền primary)
│ │ ▓▓▓▓░░░░░░░░             │ │
│ │ 0/2 tài liệu đã học  ·  Học xong tuần để vượt vũ môn │
│ └──────────────────────────┘ │
│ TÀI LIỆU TUẦN NÀY            │
│ ┌──────────────────────────┐ │
│ │ [▭] Tài liệu 1 · Reading  │ │
│ │     Matching Headings     │ │ thẻ tài liệu
│ │     Slide · 4 phần · ~8 phút│
│ │ ▓▓▓▓▓▓░░░░   Đang học 2/4 │ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ [▤] Tài liệu 2 · Writing  │ │
│ └──────────────────────────┘ │
│ ┆ Tài liệu mới sẽ hiện ở đây… ┆│ ô gợi ý viền đứt
└──────────────────────────────┘
```

- **AppBar 60:** nút ☰ (44×44, mở drawer chung của app) + "Theo tuần" (18/w800). Nền `background`, viền dưới `border`.
- **Thân:** `ListView`, padding 14 trên / 16 ngang / 28 dưới, gap 14.
- **Hàng chọn tuần:** cuộn ngang, tràn sát mép màn (margin âm 16, padding 16), gap 8.
  - Mỗi ô: cao 56, rộng tối thiểu 84, padding ↔ 12, bo 14, viền 1.5px. Dòng 1 "Tuần 12" (14/w800), dòng 2 trạng thái (11/w600).
  - **Tuần đang xem:** nền `primary` chữ kem. **Tuần đã xong:** nền trắng viền `border`, dòng 2 "2/2 ✓". **Tuần khoá:** nền `#F6EEE5` chữ `#B9958C`, dòng 2 "Mở thứ Hai", không bấm được.
  - Khi mở màn, tự cuộn để tuần hiện tại nằm trong tầm nhìn.
- **Thẻ tuần:** nền `primary`, chữ kem, bo 16, padding 16, gap 10.
  - Hàng: "Tuần 12" (20/w800) trái — khoảng ngày (12, `#F3D9C4`) phải.
  - Thanh tiến độ cao 8, nền kem 20%, phần đã học màu `goldLight`.
  - Hàng chữ 12: "x/y tài liệu đã học" trái — "Học xong tuần để vượt vũ môn" phải.
- Eyebrow "TÀI LIỆU TUẦN NÀY".
- **Thẻ tài liệu** (bấm được, nền trắng, viền `border`, bo 16, padding 14, gap 10):
  - **Hàng trên:**
    - Icon 44×44 bo 12 (Slide = màn chiếu, Doc = trang giấy). Nền `sidebar` icon `primary`; đã học thì nền `successBg` icon `success`.
    - Cột chữ gồm 3 dòng: kicker "Tài liệu 1 · Reading" (12/w700 `textMuted`), tiêu đề (16/w800, tối đa 2 dòng), meta "Slide · 4 phần · khoảng 8 phút" (12 `textMuted`).
  - **Hàng dưới:** thanh tiến độ 6 (nền `sidebar`, phần đã học `primary`; đã học thì `success`) + trạng thái bên phải (12/w800): "Chưa học" (`textMuted`) / "Đang học 2/4" (`primary`) / "Đã học" (`success`).
  - Khi nhấn: scale 0.98, viền `primary`.
- **Ô gợi ý cuối danh sách:** viền đứt 1.5px `borderStrong`, bo 12, padding 12×14, chữ 13 `textMuted`: "Tài liệu mới của tuần sẽ hiện ở đây khi admin xuất bản. Tuần 13 mở vào thứ Hai."
- **Trạng thái đặc biệt:**
  - Đang tải: skeleton 1 thẻ tuần + 2 thẻ tài liệu.
  - Tuần chưa có tài liệu: hình lá sen nhỏ + "Tuần này chưa có tài liệu".
  - Lỗi: "Không tải được danh sách. Thử lại" + nút.
  - Hỗ trợ kéo xuống để làm mới.

### U1-desktop (≥ 840)

- Sidebar 240 bên trái (mục "Theo tuần" đang chọn). Nội dung padding 32, rộng tối đa 1080.
- Hàng 1: tiêu đề "Theo tuần" (30/w800) + hàng chọn tuần (không cần cuộn nếu đủ chỗ).
- Hàng 2: thẻ tuần trải hết chiều ngang, cao khoảng 96 (chữ và thanh tiến độ xếp ngang).
- Hàng 3: **lưới thẻ tài liệu 2 cột** (≥ 1200 thì 3 cột), gap 16, các thẻ cao bằng nhau.

---

## U2. Đọc tài liệu (user)

### U2-mobile, kiểu Slide (390×844)

```
┌──────────────────────────────┐
│ ‹  Tuần 12 · Tài liệu 1   [▭|▤]│ header 56
│    Reading: Matching Headings │
├▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░┤ thanh tiến độ 3px
│ ┌──────────────────────────┐ │ nền màn #F6EEE5
│ │ ② CHIẾN THUẬT            │ │
│ │ 3 bước làm bài           │ │ thẻ slide: trắng, bo 20,
│ │ [1] Đọc lướt…            │ │ bóng nhẹ, padding 20,
│ │ [2] Đọc câu đầu…         │ │ cao tối thiểu 560,
│ │ [3] Loại trừ…            │ │ nội dung dài thì cuộn bên trong
│ └──────────────────────────┘ │
│  ▭ Xoay ngang để trình chiếu toàn màn hình │
├──────────────────────────────┤
│ (‹)      ● ━━ ● ●      (›)   │ footer: nút 48, chấm, "2 / 4"
│           2 / 4              │
└──────────────────────────────┘
```

- **Header** (nền `background`, viền dưới `border`):
  - Hàng cao 56: nút ‹ (44×44, quay về U1) → cột chữ (co giãn): "Tuần 12 · Tài liệu 1" (11/w700 `textMuted`) và tiêu đề (14/w800, 1 dòng, cắt "…") → segmented icon `[▭ | ▤]` (mỗi nút 38×34, có tooltip "Xem dạng slide" / "Xem dạng tài liệu"). **Ẩn segmented** nếu `allowedViews` chỉ có một kiểu.
  - Ngay dưới là **thanh tiến độ 3px** (nền `sidebar`, phần đã đọc `primary`) = (slide hiện tại + 1) / tổng số slide.
- **Thân:** nền màn `#F6EEE5`, padding 16 / 16 / 12.
  - **Thẻ slide:** nền trắng, **không viền**, bo 20, bóng `0 14 30` `primary` 10%, padding 20, cao tối thiểu 560. Nội dung trong thẻ cuộn được nếu dài.
  - Trong thẻ: nhãn section (huy hiệu số 24 nền `primary` + tên section 11/w800 chữ hoa `textMuted`) → các khối, cách nhau 14.
  - Khi đổi slide: nội dung trượt từ phải vào 16px và hiện dần (300ms; tắt nếu người dùng giảm chuyển động). Vuốt ngang trên thẻ cũng đổi slide.
  - Dưới thẻ: dòng gợi ý 12 `textMuted` có icon "Xoay ngang để trình chiếu toàn màn hình".
- **Footer** (nền `background`, viền trên, padding 10 / 16 / 18 + safe area):
  - Nút ‹ tròn 48 (viền `border`, icon `primary`; ở slide đầu mờ 40% và không bấm được).
  - Giữa: hàng chấm (chấm hiện tại 24×8, chấm khác 8×8, gap 6; hiện tại màu `primary`, khác `navActive`; bấm chấm để nhảy tới slide) + "2 / 4" (12/w700).
  - Nút › tròn 48 nền `primary`. **Ở slide cuối** đổi thành viên thuốc "Hoàn thành ›" (padding ↔ 20) và bấm thì sang U3.
- **Xoay ngang (mobile):** ẩn header và footer, slide 16:9 phủ kín màn (`FittedBox`), chạm cạnh trái/phải để lùi/tiến, chạm giữa để hiện lại thanh điều khiển trong 3 giây.

### U2-mobile, kiểu Doc

- Header giống kiểu Slide; thanh tiến độ = số section đã cuộn qua / tổng số section.
- Thân: nền `background`, padding 16 / 16 / 28. **Một card trắng** viền `border`, bo 16, padding 20, chứa lần lượt tất cả section (cách nhau 28), mỗi section có nhãn số như trên.
- Cuối trang: nút chính rộng full "Đánh dấu đã học xong" (cao 52, bo 14) → U3.
- Không có footer điều hướng.

### U2-desktop (≥ 840)

- Có sidebar. Thanh trên của nội dung: ‹ + breadcrumb "Theo tuần › Tuần 12 › Tài liệu 1" + tiêu đề (18/w800) bên trái; segmented `[Doc | Slide]` có chữ bên phải.
- **Slide:** khung 16:9 căn giữa, rộng = min(vùng nội dung − 64, 1000), bo 16, bóng; padding 44; logo mờ "ieltshub." ở góc trên phải của slide. Dưới khung là hàng điều khiển căn giữa: ‹ (44) · chấm · › (44) · "2 / 4" · nút ⛶ toàn màn hình. Phím ← → Space đổi slide; Esc thoát toàn màn hình.
- **Doc:** card rộng tối đa 760 căn giữa, padding 40; cỡ chữ heading 26 / body 16.

### Hiển thị từng khối (dùng chung cho U2, A2 xem trước và demo)

| Khối | Bố cục |
|---|---|
| heading | Chữ đậm 800, cỡ theo bảng ở file 5, letter-spacing −0.02em, line-height 1.2 |
| paragraph | Đoạn chữ, line-height 1.6; `**đậm**` thì w800 màu `primary` |
| callout | Hàng: icon bóng đèn 20 (màu `#B7791F`) + chữ "**Mẹo:** …" màu `#5A3A10`; nền `tipBg`, bo 12, padding 14×16 |
| steps | Mỗi bước một hàng: ô số 28×28 bo 8 nền `sidebar` chữ `primary` w800 + chữ bước; các bước cách nhau 10 |
| passage | Khung nền `background`, viền `border`, bo 12, padding 16×18; nhãn trên (12/w800 `primary`, chữ hoa, letter-spacing 0.12em); nội dung font **serif**, line-height 1.65 |
| quiz | Câu hỏi (w800) → các đáp án là nút rộng full, cao ≥ 48, bo 12, viền 1.5px, padding 8×12: huy hiệu tròn 26 (i, ii, iii) + chữ đáp án. Sau khi chọn: đáp án đúng nền `successBg` viền `success` huy hiệu `success` kèm chữ "Đáp án"; đáp án sai đã chọn nền `errorBg` viền `primary` kèm chữ "Bạn chọn". Bên dưới hiện hộp giải thích (nền xanh hoặc đỏ nhạt, bo 10): "**Chính xác!** …" hoặc "**Chưa đúng.** …". Được chọn lại |
| vocab | Card viền `border` bo 12; mỗi từ một dòng, phân cách bằng đường kẻ: mobile xếp 2 dòng (từ w800 `primary` + loại từ và IPA 12 `textMuted` / nghĩa 14); desktop chia 3 cột `150 / 130 / 1fr`. Cuối mỗi dòng có `SpeakButton` 32 |
| pattern | Khối nền `primary` chữ kem, bo 12, padding 14×16: eyebrow "MẪU CÂU" (`#F3D9C4`) → cấu trúc (w800) → câu ví dụ (nghiêng, `#F3D9C4`) |
| image | Ảnh rộng full, bo 12, tỉ lệ giữ nguyên; chú thích 12 `textMuted` bên dưới; bấm để phóng to |
| unknown | Ô nền `#F1ECE8`, bo 10, chữ 13 `textMuted`: "Nội dung chưa hỗ trợ, hãy cập nhật app" |

---

## U3. Hoàn thành tài liệu (user)

```
┌──────────────────────────────┐
│                              │
│         ╭──────────╮         │ vòng tròn 160 nền water,
│         │ ✦  🐟↑  ✦ │         │ cá chép vàng nhảy lên-xuống,
│         ╰──────────╯         │ 3 ngôi sao lấp lánh, gợn sóng trắng
│   Hoàn thành Tài liệu 1!     │ 26/w800
│ Cá chép tiến thêm một chặng  │ 15 textMuted
│ ( ● ● ◉ ○ ○  Tuần này 3/5 chặng ) │ viên thuốc trắng viền
│                              │
│ [ Lưu 3 từ vựng của bài vào Sổ từ ] │ viền, cao 48
│ [      Học Tài liệu 2 →         ]  │ chính, cao 52
│        Về danh sách tuần           │ TextButton
└──────────────────────────────┘
```

- Toàn màn nền `background`, padding 24, mọi thứ căn giữa, gap 16.
- **Hình minh hoạ:** vòng tròn 160 nền `water`; bên trong có đường gợn sóng trắng, cá chép vàng (khoảng 70px) nhảy lên xuống (1,6 giây, lặp lại), 3 ngôi sao 4 cánh lấp lánh lệch nhịp (2 vàng, 1 `primary`). Giảm chuyển động: cá đứng yên.
- Tiêu đề, mô tả như wireframe.
- **Viên thuốc chặng:** nền trắng viền `border`, padding 10×14: 5 chấm 10px (đã đạt `primary`, chưa đạt `border`; chặng vừa đạt có vòng ngoài) + "Tuần này 3/5 chặng" (13/w800 `primary`).
- Cách 8 → cột nút rộng full, gap 10:
  1. "Lưu {n} từ vựng của bài vào Sổ từ" (viền `borderStrong`, chữ `primary`, cao 48). Lưu xong đổi chữ thành "Đã lưu {n} từ vào Sổ từ" và khoá nút. Ẩn nút nếu bài không có khối vocab.
  2. "Học Tài liệu {n+1} →" (chính, cao 52). Ẩn nếu đây là tài liệu cuối của tuần; khi đó thay bằng "Về danh sách tuần" dạng nút chính.
  3. "Về danh sách tuần" (TextButton `textMuted`).
- **Nếu `justPassedGate`:** trước màn này phát `DragonLoader(playOnce, 4s)` toàn màn, sau đó viên thuốc đổi chữ thành "Đã vượt vũ môn tuần này!" và có viền vàng.
- **Desktop:** hiện dạng dialog căn giữa rộng 480 (không chiếm toàn màn), nền phía sau tối 45%.

---

## Quy tắc UX xuyên suốt

1. **Không mất công:** mở lại tài liệu thì vào đúng slide đang dở; đổi Slide/Doc giữ đáp án và vị trí; admin có tự lưu nháp.
2. **Phản hồi ngay:** mọi thao tác bấm đổi giao diện trong ≤ 100ms (cập nhật lạc quan); lưu thất bại thì báo bằng snackbar kèm "Thử lại".
3. **Một hành động chính mỗi màn:** chỉ một nút nền `primary` nổi bật nhất (Tiếp tục / Xuất bản / Hoàn thành / Học tài liệu tiếp).
4. **Ngôn ngữ:** nhãn ngắn, động từ đi đầu ("Lưu vào Sổ từ", "Kiểm tra & áp dụng"); thông báo lỗi nói rõ cách sửa.
5. **Cảm giác chủ đề:** trang trí (sóng, lá sen, cá) luôn mờ, nằm ở góc hoặc nền, không bao giờ nằm dưới chữ cần đọc.

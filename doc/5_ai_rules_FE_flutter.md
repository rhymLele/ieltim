# Rule cho AI khi code FE (Flutter) – IELTS Hub

> Đặt nội dung phần **RULES** vào file rule của project để AI luôn tuân thủ:
> - Claude Code: `CLAUDE.md` ở thư mục gốc
> - Cursor: `.cursor/rules/ielts-hub-fe.mdc` (hoặc `.cursorrules`)
> - Copilot: `.github/copilot-instructions.md`
>
> Rule này áp dụng cho **mọi** việc FE: màn mới, sửa UI, widget, nối API. Nghiệp vụ từng chức năng vẫn lấy từ file nghiệp vụ riêng (ví dụ `1_nghiep_vu_tai_lieu_theo_tuan.md`).

---

## RULES

### 1. Nguyên tắc làm việc

1. **Đọc trước, viết sau.** Trước khi tạo file, đọc cấu trúc thư mục, theme, các widget dùng chung và file nghiệp vụ liên quan. Có sẵn thì dùng lại, không viết lại.
2. Với việc lớn hơn khoảng 3 file: liệt kê kế hoạch (file tạo hoặc sửa, lý do) và **chờ xác nhận** trước khi code.
3. Chỉ sửa đúng phạm vi được yêu cầu. Không tự đổi tên, format lại, hay "dọn dẹp" file không liên quan.
4. Thiếu thông tin nghiệp vụ hoặc API thì **hỏi lại**, không tự bịa endpoint hay trường dữ liệu. Nếu API chưa có, dùng repository giả cùng interface.
5. Sau mỗi bước: chạy `flutter analyze` (phải sạch) và test liên quan, rồi báo tóm tắt: file đã đổi, những gì chưa làm.

### 2. Stack và cấu trúc

- Flutter 3.x, Dart 3 (dùng records, pattern matching, `sealed class`).
- State: [ĐIỀN: Riverpod / Bloc]. Router: [ĐIỀN: go_router]. HTTP: [ĐIỀN: dio]. Model: `freezed` + `json_serializable`.
- Cấu trúc theo feature:
  ```
  lib/
    core/        theme/ (tokens, ThemeData) · network/ · storage/ · l10n/ · utils/
    shared/      widgets/ dùng chung · ielts_hub_fx/ (hiệu ứng thương hiệu)
    features/<tên>/
      data/          dto, repository impl, api
      domain/        model, repository interface, validator
      presentation/  screens/, widgets/, controllers (state)
  ```
- Một file một widget public chính, tối đa khoảng 300 dòng; dài hơn thì tách widget con riêng.
- Đặt tên: file `snake_case.dart`; class `PascalCase`; màn hình kết thúc bằng `Screen`; widget con private bắt đầu `_`.

### 3. Design tokens (bắt buộc dùng, không hard-code)

Mọi màu, cỡ chữ, khoảng cách, bo góc lấy từ `core/theme/app_tokens.dart`. **Không** viết `Color(0x…)` hay số px rời rạc trong UI.

```dart
abstract final class AppColors {
  static const primary = Color(0xFF800020);      // đỏ đô – nút chính, nhấn mạnh
  static const background = Color(0xFFFFF9F2);   // nền kem
  static const surface = Color(0xFFFFFFFF);      // card
  static const sidebar = Color(0xFFF3E5D5);      // sidebar, drawer, nền chip
  static const border = Color(0xFFEFDCCB);       // viền card
  static const borderStrong = Color(0xFFE5D2BF); // viền input
  static const navActive = Color(0xFFE7C9BC);    // ô nền mục menu đang chọn
  static const text = Color(0xFF2A1418);         // chữ chính
  static const textMuted = Color(0xFF6B4A4F);    // chữ phụ (đạt 4.5:1 trên nền kem)
  static const gold = Color(0xFFE7A23B);         // điểm nhấn, cá chép, sparkle
  static const goldLight = Color(0xFFF2C06B);
  static const success = Color(0xFF2F7A4B);
  static const successBg = Color(0xFFE6F3EA);
  static const errorBg = Color(0xFFFBEAEC);      // lỗi dùng primary làm chữ
  static const tipBg = Color(0xFFFDF1DE);
  static const water = Color(0xFFE4EDF0);
}

abstract final class AppSpace { // lưới 4
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 20.0, xxl = 24.0, xxxl = 32.0;
}

abstract final class AppRadius {
  static const sm = 8.0, md = 10.0, lg = 12.0, card = 14.0, cardLg = 16.0, slide = 20.0, pill = 999.0;
}
```

- **Font:** Manrope cho toàn app; serif (Georgia hoặc font serif bundle) chỉ dùng cho đoạn đề thi `passage`; font mono chỉ cho editor JSON.
- **Thang chữ:**

  | Mức | Cỡ / độ đậm |
  |---|---|
  | display | 30 / w800 |
  | title | 24 / w800 |
  | heading | 18 / w800 |
  | body | 15 / w400, line-height 1.55 |
  | label | 13 / w700 |
  | caption | 12 / w500 |
  | eyebrow | 11–12 / w800, letter-spacing 0.12em, VIẾT HOA |

- **Đổ bóng:** card thường **không** có bóng, dùng viền `border`. Chỉ slide, modal và drawer có bóng nhẹ tông đỏ đô (`primary` alpha khoảng 12%, blur 24–30, offset y 12–14).
- **Không dùng:** gradient trang trí, emoji, font khác ngoài 3 font trên, màu ngoài bảng (cần màu mới thì hỏi và thêm vào token).

### 4. Thành phần và thương hiệu

- **Dùng lại**, không vẽ lại:
  - `IeltsHubLogo`
  - `KoiPond`, `YourPondCard`
  - `VuMonProgress`
  - `WordOfDayCard`, `SpeakButton` / `WordSpeaker`
  - `DragonLoader` (`playOnce`)
- **Nút:**
  - chính: `FilledButton` nền primary chữ kem, cao 48 (mobile 52 cho CTA), bo 10–14
  - phụ: `OutlinedButton` viền `borderStrong`
  - chữ: `TextButton` màu `textMuted`
- **Card:** nền `surface`, viền 1px `border`, bo 14–16, padding 14–20. Card có thể bấm thì dùng `InkWell` + `Material`, nhấn có scale 0.98.
- **Chip / segmented:** nền `sidebar`, mục đang chọn nền primary chữ kem, bo 10–12 (segmented) hoặc pill (chip).
- **Icon:** Material Icons bản outlined/rounded, cỡ 18–24, màu primary hoặc text. Không trộn nhiều bộ icon.
- **Chủ đề hình ảnh:** ao cá koi, thác Vũ Môn, cá chép hóa rồng. Trang trí mới phải theo chủ đề này (sóng seigaiha, lá sen, gợn nước), mờ và không che nội dung.

### 5. Layout và responsive

- **Breakpoint:** `< 600` điện thoại · `600–839` tablet · `≥ 840` desktop.
  - Dưới 840: `Scaffold` + `AppBar` + `Drawer` (rộng 300).
  - Từ 840: sidebar cố định 240.
  - Menu dùng chung một widget cho cả hai.
- Padding trang: 16 (mobile), 24 (tablet), 32 (desktop). Khoảng cách giữa các khối: 16 (mobile), 20–22 (desktop).
- Nội dung đọc dài (Doc) rộng tối đa 760 và căn giữa trên màn rộng.
- Phải chạy không tràn (overflow) ở **360×640, 390×844, 430×932, 768×1024, 1280×800, 1440×900**. Text dài dùng `maxLines` + `ellipsis` hoặc xuống dòng, không để vỡ layout.
- Tôn trọng `SafeArea` và bàn phím (`resizeToAvoidBottomInset`); form dài phải cuộn được.

### 6. Hiển thị tài liệu theo khối (Doc / Slide)

- Render **chỉ qua** `BlockRegistry` (`Type` → builder). Thêm loại khối mới bằng cách đăng ký builder, không viết `if/else` rải rác.
- `type` lạ thì render `UnknownBlock` (ô xám "Nội dung chưa hỗ trợ, hãy cập nhật app"). **Không bao giờ throw hay crash.**
- Cỡ chữ theo chế độ:

  | Thành phần | Doc mobile | Doc desktop | Slide mobile | Slide 16:9 |
  |---|---|---|---|---|
  | heading | 24 | 26 | 24 | 34 |
  | body | 15 | 16 | 15 | 18 |
  | eyebrow section | 11 | 12 | 11 | 13 |

- **Slide:**
  - Mobile dọc: mỗi slide là một thẻ bo 20, nội dung dài thì cuộn trong thẻ.
  - Ngang hoặc desktop: khung 16:9 bọc `FittedBox`.
  - Điều khiển: trước/sau, chấm trang (trang hiện tại rộng 24, trang khác 8), "n / N", vuốt ngang, phím ← → Space. Slide cuối đổi nút thành "Hoàn thành".
- Doc và Slide dùng **chung state** (section hiện tại, đáp án quiz). Chuyển view không được mất dữ liệu.
- Markdown trong `text` chỉ hỗ trợ `**đậm**` (màu primary, w800), `*nghiêng*`, `[link](https)`. Link mở bằng `url_launcher` ở trình duyệt ngoài.

### 7. Chuyển động

- Thời lượng: phản hồi chạm 120–180ms; chuyển trạng thái 250–350ms; lật thẻ 600ms. Curve: `easeOutCubic` / `easeInOutCubic`. Không dùng hiệu ứng nảy, trừ khi xuất hiện đầu rồng (`easeOutBack`).
- **Trong một khung nhìn chỉ một thứ chuyển động liên tục nổi bật** (ao cá hoặc thác, không cả hai cùng lúc).
- Animation liên tục phải dừng khi widget không hiển thị (`TickerMode`, `VisibilityDetector`) và khi app chạy nền.
- **Bắt buộc** kiểm tra `MediaQuery.disableAnimationsOf(context)`: khi bật thì tắt animation liên tục, chuyển trạng thái tức thì, nhưng UI vẫn đầy đủ thông tin.
- Hiệu ứng nặng (`DragonLoader` bản đầy đủ) chỉ dùng cho lần mở đầu tiên trong ngày hoặc khi vượt vũ môn, không dùng cho loading thường.

### 8. Trạng thái màn hình

Mỗi màn có dữ liệu phải xử lý đủ 4 trạng thái:

- **Đang tải:** skeleton theo đúng hình khối thật (nền `sidebar`, nhấp nháy nhẹ). Không dùng `CircularProgressIndicator` giữa màn, trừ nút đang gửi.
- **Rỗng:** minh hoạ nhỏ theo chủ đề (lá sen hoặc mặt ao) + 1 câu hướng dẫn + nút hành động nếu có.
- **Lỗi:** câu ngắn dễ hiểu ("Không tải được tài liệu. Kiểm tra mạng rồi thử lại.") + nút "Thử lại". Không hiện stack trace hay mã lỗi thô.
- **Có dữ liệu.**
- Mất mạng: dùng cache nếu có, kèm dải báo nhẹ "Đang xem bản offline". Thao tác ghi đưa vào hàng đợi và gửi lại khi có mạng.

### 9. Trợ năng

- Vùng chạm ≥ 44×44 (nút chính 48–52).
- Nút chỉ có icon phải có `tooltip` (cũng dùng làm nhãn `Semantics`).
- Hình trang trí bọc `ExcludeSemantics`; hình mang thông tin có `semanticLabel`.
- Độ tương phản chữ ≥ 4.5:1 (chữ ≥ 24px: 3:1). Không truyền đạt trạng thái chỉ bằng màu: đúng/sai phải kèm chữ hoặc icon.
- Hỗ trợ cỡ chữ hệ thống lớn tới 1.3× mà không vỡ layout. Thứ tự focus bàn phím hợp lý trên web và desktop.

### 10. Nội dung chữ

- Giao diện tiếng Việt có dấu, giọng thân thiện, ngắn gọn. Thuật ngữ IELTS giữ tiếng Anh.
- Tiêu đề và nút viết hoa chữ đầu câu ("Lưu vào Sổ từ", không viết "LƯU VÀO SỔ TỪ"). Eyebrow mới viết hoa toàn bộ.
- Mọi chuỗi đưa vào l10n hoặc file strings, không hard-code trong widget.
- Không dùng chữ mẫu lorem ipsum hay số liệu giả trong UI thật. Dữ liệu mẫu chỉ nằm trong repository giả.

### 11. Chất lượng code

- `flutter analyze` sạch (dùng `flutter_lints` hoặc `very_good_analysis`), không `print` (dùng logger), không để code đã comment.
- Dùng `const` tối đa; không gọi hàm nặng hay tạo object lớn trong `build`. List dài dùng `ListView.builder`. Vùng animation bọc `RepaintBoundary`.
- Dispose đủ controller, ticker, stream subscription.
- Không gọi API trực tiếp trong widget; luôn đi qua repository và state.
- Lỗi mạng map ra lỗi nghiệp vụ có thông điệp tiếng Việt ở tầng data.

### 12. Kiểm thử

- Logic thuần (parser, validator, tính tiến độ): unit test.
- Widget mới có tương tác: widget test các luồng chính.
- Màn quan trọng: golden test ở 390×844 và 1280×800.
- Sửa bug: thêm test tái hiện bug trước khi sửa.

### 13. Checklist trước khi báo hoàn thành

- [ ] Không còn màu, cỡ chữ, khoảng cách hard-code; đã dùng lại widget có sẵn
- [ ] Đủ 4 trạng thái: đang tải / rỗng / lỗi / có dữ liệu
- [ ] Không overflow ở 6 kích thước màn hình liệt kê ở mục 5
- [ ] Tắt animation (`disableAnimations`) vẫn dùng được; animation dừng khi bị che
- [ ] Vùng chạm, tooltip, độ tương phản đạt yêu cầu
- [ ] Chuỗi đã vào l10n; không có lorem ipsum hay số giả
- [ ] `flutter analyze` sạch, test xanh; đã liệt kê file đã đổi

# annotate — Bôi đen từ (sổ từ · dịch · highlight) & ghi chú trên slide

Chỉ gồm **UI + trạng thái cục bộ**. Gọi API, lưu trữ, dịch, TTS và cầu nối HTML làm theo `11_prompt_logic_boi_den_ghi_chu.md`.

Không cần package ngoài. Yêu cầu Flutter ≥ 3.22 (Dart 3).

```dart
import 'annotate/annotate_demo.dart';
void main() => runApp(const AnnotateDemoApp());
```

## Thành phần

| File | Widget / lớp | Dùng ở đâu |
|---|---|---|
| `widgets/annotatable_selection_area.dart` | `AnnotatableSelectionArea` | Bọc nội dung Doc / Slide JSON. Bôi đen thì hiện hộp thoại (mobile: thay menu Copy; web: khi thả chuột). |
| `widgets/selection_actions_card.dart` | `SelectionActionsCard` | Hộp thoại: Sổ từ · Dịch nghĩa (mở rộng tại chỗ) · Nghe · Sao chép · Highlight 4 màu · bỏ highlight |
| `widgets/vocab_sheet.dart` | `showVocabSheet()` → `VocabDraft?` | Form thêm vào sổ từ (nghĩa sửa được, câu ví dụ, chọn sổ) |
| `widgets/highlighted_text.dart` | `HighlightedText`, `resolveHighlights()` | Thay `Text` trong khối paragraph / passage để tô highlight đã lưu |
| `annotation_controller.dart` | `AnnotationController` | Công cụ, màu, nét vẽ, khoanh, chữ, ghim, hoàn tác. `onChanged` để lưu |
| `widgets/annotation_layer.dart` | `AnnotationLayer` | Đặt đè lên 1 slide (hoặc WebView/iframe HTML). Toạ độ chuẩn hoá 0..1 |
| `widgets/annotation_toolbar.dart` | `AnnotationToolbar` | Xem · Bút · Dạ quang · Khoanh · Chữ · Ghi chú · 4 màu · Hoàn tác · Xoá hết |
| `widgets/notes_panel.dart` | `NotesPanel` | Danh sách ghi chú của slide (cột phải desktop / bottom sheet mobile) |
| `models.dart` | `SlideAnnotations`, `TextHighlight`, `VocabDraft`, `TranslationResult`… | Có `toJson` / `fromJson` |

## Lắp nhanh vào weekly_docs

```dart
// doc_reader_screen.dart — chế độ Doc
AnnotatableSelectionArea(
  cardBuilder: (ctx, text, close) => SelectionActionsCard(
    text: text,
    onAddVocab: () => annotateLogic.addVocab(ctx, text, close),
    onTranslate: () => annotateLogic.translate(text),
    onHighlight: (c) => annotateLogic.highlight(text, c, close),
    ...
  ),
  child: DocContent(...),   // trong BlockView: Text → HighlightedText
)

// chế độ Slide — mỗi slide 1 controller (hoặc 1 controller + load() khi đổi slide)
Column(children: [
  AnnotationToolbar(controller: c),
  AspectRatio(aspectRatio: 16 / 9, child: AnnotationLayer(controller: c, child: SlideContent(...))),
])
```

Khi `tool != view`, lớp vẽ chặn vuốt / bấm của slide. Nhớ khoá `PageView` (`physics: NeverScrollableScrollPhysics()`) khi đang vẽ.

> Chưa biên dịch trong môi trường tạo (không có Flutter SDK). Chạy `flutter analyze` sau khi chép vào dự án.

import 'models/weekly_doc.dart';

/// Một slide: thuộc [sectionIndex] + danh sách khối.
class Slide {
  const Slide({
    required this.sectionIndex,
    required this.blocks,
    required this.blockStartIndex,
  });

  final int sectionIndex;

  /// Vị trí khối đầu của slide **trong section** (dùng để tính [blockKey]
  /// khớp với DocView, giữ đáp án khi chuyển view).
  final int blockStartIndex;
  final List<DocBlock> blocks;
}

/// Tách tài liệu thành danh sách slide để [SlideView].
///
/// - Mỗi section tạo ít nhất một slide (nhãn section hiển thị ở đầu slide).
/// - [SlideBreakBlock] tách thêm slide mới trong cùng một section.
/// - [blockStartIndex] giữ vị trí khối trong section để [blockKey] khớp
///   với DocView (giữ đáp án quiz khi chuyển view).
/// - Đoạn cuối (sau slideBreak cuối cùng) vẫn được phát hành, kể cả khi rỗng
///   để giữ thứ tự ổn định cho điều khiển "n / N".
List<Slide> splitSlides(WeeklyDoc doc) {
  final slides = <Slide>[];
  for (var s = 0; s < doc.sections.length; s++) {
    final section = doc.sections[s];
    var current = <DocBlock>[];
    var startIdx = 0;
    for (var bi = 0; bi < section.blocks.length; bi++) {
      final block = section.blocks[bi];
      if (block is SlideBreakBlock) {
        slides.add(Slide(
            sectionIndex: s,
            blocks: List.unmodifiable(current),
            blockStartIndex: startIdx));
        current = <DocBlock>[];
        startIdx = bi + 1;
      } else {
        current.add(block);
      }
    }
    slides.add(Slide(
        sectionIndex: s,
        blocks: List.unmodifiable(current),
        blockStartIndex: startIdx));
  }
  return slides;
}

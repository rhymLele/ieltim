import 'package:flutter/widgets.dart';

/// Chữ vừa bôi đen nằm ở đâu: khối nào, vị trí trong chuỗi hiển thị của khối, câu chứa nó.
class SelectionTarget {
  const SelectionTarget({required this.blockKey, required this.start, required this.end, required this.prefix, required this.suffix, required this.sentence});

  final String blockKey;
  final int start;
  final int end;

  /// ≤ 32 ký tự đứng trước / sau, để tìm lại khi admin sửa bài.
  final String prefix;
  final String suffix;

  /// Câu chứa vùng chọn (câu ví dụ cho sổ từ, ngữ cảnh khi dịch).
  final String sentence;
}

const anchorContext = 32;

/// Tìm khối chứa [text] trong các khối đang hiện ([mounted]). Nhiều khối cùng chứa thì lấy khối gần [anchor]
/// (vị trí ngón tay / con trỏ khi chọn) nhất. Không khối nào chứa trọn → null (vùng chọn kéo qua nhiều khối).
SelectionTarget? locateSelection(String text, {required Map<String, String> blockTexts, required Map<String, RenderBox> mounted, Offset? anchor}) {
  final needle = text.trim();
  if (needle.isEmpty) return null;
  final candidates = <String>[
    for (final key in mounted.keys)
      if (blockTexts[key]?.contains(needle) ?? false) key,
  ];
  if (candidates.isEmpty) return null;
  var best = candidates.first;
  if (candidates.length > 1 && anchor != null) {
    var bestDistance = double.infinity;
    for (final key in candidates) {
      final box = mounted[key]!;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final dx = anchor.dx < rect.left ? rect.left - anchor.dx : (anchor.dx > rect.right ? anchor.dx - rect.right : 0.0);
      final dy = anchor.dy < rect.top ? rect.top - anchor.dy : (anchor.dy > rect.bottom ? anchor.dy - rect.bottom : 0.0);
      final distance = dx * dx + dy * dy;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = key;
      }
    }
  }
  return targetIn(blockTexts[best]!, needle, blockKey: best);
}

/// Vị trí đầu tiên của [quote] trong [blockText] kèm prefix / suffix / câu chứa nó.
SelectionTarget? targetIn(String blockText, String quote, {required String blockKey}) {
  final start = blockText.indexOf(quote);
  if (start < 0) return null;
  final end = start + quote.length;
  return SelectionTarget(
    blockKey: blockKey,
    start: start,
    end: end,
    prefix: blockText.substring((start - anchorContext).clamp(0, start), start),
    suffix: blockText.substring(end, (end + anchorContext).clamp(end, blockText.length)),
    sentence: sentenceAround(blockText, start, end),
  );
}

/// Câu chứa đoạn [start, end): tách theo dấu `.` `!` `?` và xuống dòng.
String sentenceAround(String text, int start, int end) {
  final boundary = RegExp(r'[.!?\n]');
  var from = 0;
  for (final m in boundary.allMatches(text)) {
    if (m.end <= start) from = m.end;
  }
  var to = text.length;
  // Tìm từ ký tự cuối vùng chọn: chọn "word." thì câu kết thúc ngay ở dấu chấm đó.
  for (final m in boundary.allMatches(text, end > start ? end - 1 : end)) {
    to = text[m.start] == '\n' ? m.start : m.end;
    break;
  }
  return text.substring(from, to).trim();
}

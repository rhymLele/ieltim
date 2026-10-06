// highlighted_text.dart — Hiển thị đoạn chữ kèm các highlight của người học.
// Dùng trong renderer khối paragraph / passage của weekly_docs (thay Text bằng HighlightedText).
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../annotate_theme.dart';
import '../models.dart';

/// Vị trí đã tìm được của 1 highlight trong chuỗi.
typedef HighlightRange = ({int start, int end, HighlightColor color, String id});

/// Tìm vị trí từng highlight trong [text]: ưu tiên start/end đã lưu nếu khớp quote,
/// không thì tìm theo quote (+ prefix/suffix để phân biệt khi quote xuất hiện nhiều lần).
List<HighlightRange> resolveHighlights(String text, Iterable<TextHighlight> highlights) {
  final out = <HighlightRange>[];
  for (final h in highlights) {
    final s = h.start, e = h.end;
    if (s != null && e != null && s >= 0 && e <= text.length && s < e && text.substring(s, e) == h.quote) {
      out.add((start: s, end: e, color: h.color, id: h.id));
      continue;
    }
    var best = -1;
    var bestScore = -1;
    var from = 0;
    while (true) {
      final i = text.indexOf(h.quote, from);
      if (i < 0) break;
      var score = 0;
      if (h.prefix.isNotEmpty && text.substring(0, i).endsWith(h.prefix)) score += 2;
      if (h.suffix.isNotEmpty && text.substring(i + h.quote.length).startsWith(h.suffix)) score += 2;
      if (score > bestScore) {
        best = i;
        bestScore = score;
      }
      from = i + 1;
    }
    if (best >= 0) out.add((start: best, end: best + h.quote.length, color: h.color, id: h.id));
  }
  out.sort((a, b) => a.start.compareTo(b.start));
  // Bỏ phần chồng lấn: highlight sau cắt bớt cho khỏi đè
  final merged = <HighlightRange>[];
  for (final r in out) {
    if (merged.isNotEmpty && r.start < merged.last.end) {
      if (r.end <= merged.last.end) continue;
      merged.add((start: merged.last.end, end: r.end, color: r.color, id: r.id));
    } else {
      merged.add(r);
    }
  }
  return merged;
}

class HighlightedText extends StatefulWidget {
  const HighlightedText(this.text, {super.key, required this.highlights, this.style, this.onTapHighlight});

  final String text;
  final List<TextHighlight> highlights;
  final TextStyle? style;

  /// Chạm vào đoạn đã highlight (để đổi màu / bỏ). Truyền id highlight.
  final ValueChanged<String>? onTapHighlight;

  @override
  State<HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<HighlightedText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final text = widget.text;
    final ranges = resolveHighlights(text, widget.highlights);
    if (ranges.isEmpty) return Text(text, style: widget.style);
    final spans = <InlineSpan>[];
    var at = 0;
    for (final r in ranges) {
      if (r.start > at) spans.add(TextSpan(text: text.substring(at, r.start)));
      TapGestureRecognizer? rec;
      if (widget.onTapHighlight != null) {
        rec = TapGestureRecognizer()..onTap = () => widget.onTapHighlight!(r.id);
        _recognizers.add(rec);
      }
      spans.add(TextSpan(
        text: text.substring(r.start, r.end),
        style: TextStyle(backgroundColor: r.color.color),
        recognizer: rec,
        mouseCursor: rec == null ? null : SystemMouseCursors.click,
      ));
      at = r.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}

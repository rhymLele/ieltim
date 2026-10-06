import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/annotate/annotate.dart';
import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../block_view.dart';

/// Chữ hiển thị của khối đúng như trên màn (đã bỏ ký hiệu markdown, callout kèm nhãn "Mẹo: "…);
/// highlight neo theo chuỗi này. null = khối không có chữ để bôi (trắc nghiệm, từ vựng, ảnh…).
String? annotatableText(DocBlock block) => switch (block) {
      HeadingBlock b => b.text,
      ParagraphBlock b => spansText(RichTextLite.parse(b.text, const TextStyle(), AppColors.primary)),
      CalloutBlock b => calloutLabel(b.tone) + spansText(RichTextLite.parse(b.text, const TextStyle(), AppColors.primary)),
      StepsBlock b => b.items.map((i) => spansText(RichTextLite.parse(i, const TextStyle(), AppColors.primary))).join('\n'),
      PassageBlock b => b.text,
      _ => null,
    };

String spansText(List<InlineSpan> spans) => spans.map((s) => s is TextSpan ? s.text ?? '' : '').join();

/// Các vùng highlight nằm trong đoạn [start, start + length) của chuỗi khối, dời về toạ độ của đoạn đó.
List<HighlightRange> rangesIn(List<HighlightRange> ranges, int start, int length) => [
      for (final r in ranges)
        if (r.end > start && r.start < start + length)
          (start: (r.start - start).clamp(0, length), end: (r.end - start).clamp(0, length), color: r.color, id: r.id),
    ];

/// Text.rich từ các span markdown ([RichTextLite.parse]) có tô thêm highlight; chạm vào đoạn tô → [onTapHighlight].
class HighlightedRichText extends StatefulWidget {
  const HighlightedRichText({super.key, required this.spans, required this.ranges, required this.style, this.onTapHighlight});

  final List<InlineSpan> spans;

  /// Toạ độ trong chuỗi ghép từ [spans].
  final List<HighlightRange> ranges;
  final TextStyle style;
  final ValueChanged<String>? onTapHighlight;

  @override
  State<HighlightedRichText> createState() => _HighlightedRichTextState();
}

class _HighlightedRichTextState extends State<HighlightedRichText> {
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
    if (widget.ranges.isEmpty) return Text.rich(TextSpan(style: widget.style, children: widget.spans));
    final out = <InlineSpan>[];
    var at = 0; // vị trí của span hiện tại trong chuỗi ghép
    for (final span in widget.spans) {
      final text = span is TextSpan ? span.text ?? '' : '';
      if (span is! TextSpan || text.isEmpty) {
        out.add(span);
        continue;
      }
      var cut = 0;
      for (final r in rangesIn(widget.ranges, at, text.length)) {
        if (r.start > cut) out.add(TextSpan(text: text.substring(cut, r.start), style: span.style));
        TapGestureRecognizer? recognizer;
        final onTap = widget.onTapHighlight;
        if (onTap != null) {
          recognizer = TapGestureRecognizer()..onTap = () => onTap(r.id);
          _recognizers.add(recognizer);
        }
        out.add(TextSpan(
          text: text.substring(r.start, r.end),
          style: (span.style ?? const TextStyle()).copyWith(backgroundColor: r.color.color),
          recognizer: recognizer,
          mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
        ));
        cut = r.end;
      }
      if (cut < text.length) out.add(TextSpan(text: text.substring(cut), style: span.style));
      at += text.length;
    }
    return Text.rich(TextSpan(style: widget.style, children: out));
  }
}

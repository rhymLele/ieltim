import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Parser markdown rút gọn thành [TextSpan]:
/// - `**đậm**`
/// - `*nghiêng*`
/// - `[link](https://…)` (mở bằng [onLinkTap]; mặc định [urlLauncher])
///
/// Không kéo cả thư viện markdown. Text chưa match giữ nguyên.
TextSpan parseMiniMarkdown(
  String source, {
  required TextStyle base,
  TextStyle? boldStyle,
  TextStyle? italicStyle,
  TextStyle? linkStyle,
  void Function(String url)? onLinkTap,
}) {
  final children = <InlineSpan>[];
  final buf = StringBuffer();

  void flush() {
    final t = buf.toString();
    if (t.isNotEmpty) children.add(TextSpan(text: t));
    buf.clear();
  }

  final n = source.length;
  var i = 0;
  while (i < n) {
    final c = source[i];

    // [text](url)
    if (c == '[') {
      final link = _matchLink(source, i);
      if (link != null) {
        flush();
        final (text, url, end) = link;
        final recognizer = TapGestureRecognizer()
          ..onTap = () => (onLinkTap ?? _openUrl)(url);
        children.add(TextSpan(
          text: text,
          style: linkStyle ??
              TextStyle(
                color: base.color,
                decoration: TextDecoration.underline,
              ),
          recognizer: recognizer,
        ));
        i = end;
        continue;
      }
    }

    // **bold** — ưu tiên trước *italic*; không có cặp đóng thì giữ nguyên.
    if (c == '*' && i + 1 < n && source[i + 1] == '*') {
      final end = source.indexOf('**', i + 2);
      if (end != -1) {
        flush();
        children.add(TextSpan(
          text: source.substring(i + 2, end),
          style: boldStyle ?? base.copyWith(fontWeight: FontWeight.bold),
        ));
        i = end + 2;
        continue;
      }
      buf.write(c);
      i++;
      continue;
    }

    // *italic*
    if (c == '*') {
      final end = source.indexOf('*', i + 1);
      if (end != -1) {
        flush();
        children.add(TextSpan(
          text: source.substring(i + 1, end),
          style: italicStyle ?? base.copyWith(fontStyle: FontStyle.italic),
        ));
        i = end + 1;
        continue;
      }
    }

    buf.write(c);
    i++;
  }
  flush();
  return TextSpan(style: base, children: children);
}

Future<void> _openUrl(String url) async {
  // Trốn vòng lặp import url_launcher ở tầng domain; app sẽ inject [onLinkTap].
  // Nếu chưa inject, chỉ in log (tránh throw).
  debugPrint('parseMiniMarkdown: link $url (chưa inject onLinkTap)');
}

/// Trả `(text, url, end)` nếu [source] tại [start] khớp `[text](url)`;
/// `end` là vị trí ký tự sau `)`.
(String, String, int)? _matchLink(String source, int start) {
  final closeBracket = source.indexOf(']', start);
  if (closeBracket == -1) return null;
  if (closeBracket + 1 >= source.length || source[closeBracket + 1] != '(') {
    return null;
  }
  final closeParen = source.indexOf(')', closeBracket + 2);
  if (closeParen == -1) return null;
  final url = source.substring(closeBracket + 2, closeParen).trim();
  if (!url.startsWith('http://') && !url.startsWith('https://')) return null;
  return (
    source.substring(start + 1, closeBracket),
    url,
    closeParen + 1,
  );
}

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/weekly_docs/domain/mini_markdown.dart';

const _base = TextStyle(fontSize: 16, color: Color(0xFF2A1418));

List<TextSpan> _children(TextSpan span) =>
    span.children!.cast<TextSpan>().toList();

String _text(TextSpan s) => s.text ?? '';

void main() {
  test('text thường', () {
    final span = parseMiniMarkdown('Xin chào', base: _base);
    final c = _children(span);
    expect(c, hasLength(1));
    expect(_text(c.first), 'Xin chào');
  });

  test('đậm **…**', () {
    final span = parseMiniMarkdown('a **b** c', base: _base);
    final c = _children(span);
    expect(c.map(_text).toList(), ['a ', 'b', ' c']);
    expect(c[1].style?.fontWeight, FontWeight.bold);
  });

  test('nghiêng *…*', () {
    final span = parseMiniMarkdown('a *b* c', base: _base);
    final c = _children(span);
    expect(c.map(_text).toList(), ['a ', 'b', ' c']);
    expect(c[1].style?.fontStyle, FontStyle.italic);
  });

  test('liên kết [text](url) + onLinkTap', () {
    String? captured;
    final span = parseMiniMarkdown(
      'see [site](https://x.com) now',
      base: _base,
      onLinkTap: (u) => captured = u,
    );
    final link = _children(span)
        .firstWhere((c) => c.recognizer != null);
    expect(_text(link), 'site');
    expect(link.style?.decoration, TextDecoration.underline);
    (link.recognizer! as TapGestureRecognizer).onTap!();
    expect(captured, 'https://x.com');
  });

  test('hỗn hợp đậm + nghiêng + link', () {
    final span = parseMiniMarkdown(
      '**a***b*[c](https://d.io)',
      base: _base,
      onLinkTap: (_) {},
    );
    final c = _children(span);
    expect(c, hasLength(3));
    expect(_text(c[0]), 'a');
    expect(c[0].style?.fontWeight, FontWeight.bold);
    expect(_text(c[1]), 'b');
    expect(c[1].style?.fontStyle, FontStyle.italic);
    expect(_text(c[2]), 'c');
    expect(c[2].recognizer, isNotNull);
  });

  test('marker không đóng → giữ nguyên, không crash', () {
    final span = parseMiniMarkdown('a ** b', base: _base);
    expect(_children(span).map(_text).join(), 'a ** b');
  });

  test('link không http(s) → không phải link', () {
    final span = parseMiniMarkdown('[x](not-a-url)', base: _base);
    expect(_children(span).every((c) => c.recognizer == null), isTrue);
  });
}

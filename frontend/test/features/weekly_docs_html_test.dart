import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/weekly_docs/domain/doc_validator.dart';
import 'package:frontend/features/weekly_docs/domain/html_file.dart';
import 'package:frontend/features/weekly_docs/domain/weekly_doc.dart';
import 'package:frontend/features/weekly_docs/presentation/widgets/html_frame_io.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

String? _errorOf(String name, Uint8List bytes) {
  try {
    parseHtmlFile(name, bytes);
    return null;
  } on HtmlFileException catch (e) {
    return e.message;
  }
}

Map<String, dynamic> _htmlDoc({String? html}) => {
      'schemaVersion': 1,
      'id': 'w12-doc3',
      'week': 12,
      'order': 3,
      'title': 'Collocations chủ đề Môi trường',
      'template': 'html',
      'meta': {'skill': 'vocabulary'},
      'sections': <dynamic>[],
      'html': ?html,
      'htmlFileName': 'collocations_moi_truong.html',
    };

void main() {
  group('parseHtmlFile', () {
    test('đọc file hợp lệ, lấy <title>', () {
      final f = parseHtmlFile('Bai.HTML', _bytes('<!doctype html><html><head><title>\n  Collocations &amp; Môi trường </title></head><body>x</body></html>'));
      expect(f.name, 'Bai.HTML');
      expect(f.title, 'Collocations & Môi trường');
      expect(f.sizeBytes, greaterThan(0));
    });

    test('nhận đuôi .htm, không có <title> thì title = null', () {
      expect(parseHtmlFile('a.htm', _bytes('<div>hi</div>')).title, isNull);
    });

    test('báo lỗi đúng câu', () {
      expect(_errorOf('a.txt', _bytes('<p>x</p>')), HtmlFileErrors.extension);
      expect(_errorOf('a.html', Uint8List(0)), HtmlFileErrors.empty);
      expect(_errorOf('a.html', _bytes('   \n ')), HtmlFileErrors.empty);
      expect(_errorOf('a.html', _bytes('chỉ là chữ, không có thẻ < 3 > nào')), HtmlFileErrors.noHtml);
      expect(_errorOf('a.html', Uint8List(maxHtmlBytes + 1)), HtmlFileErrors.tooLarge);
      expect(_errorOf('a.html', _bytes('<p>${'a' * (maxHtmlBytes - 7)}</p>')), isNull);
    });

    test('htmlFileMetaError kiểm tra trước khi đọc', () {
      expect(htmlFileMetaError('x.pdf', 10), HtmlFileErrors.extension);
      expect(htmlFileMetaError('x.html', 0), HtmlFileErrors.empty);
      expect(htmlFileMetaError('x.html', maxHtmlBytes + 1), HtmlFileErrors.tooLarge);
      expect(htmlFileMetaError('x.html', null), isNull);
    });
  });

  test('utf8Length khớp utf8.encode', () {
    for (final s in ['', 'abc', 'Tiếng Việt', '😀 emoji', '中文']) {
      expect(utf8Length(s), utf8.encode(s).length, reason: s);
    }
  });

  group('validateDocJson với template html', () {
    test('thiếu html → chỉ 1 lỗi "Chưa tải file HTML"', () {
      final v = validateDocJson(_htmlDoc());
      expect(v.errors.map((e) => e.toString()), ['Chưa tải file HTML']);
    });

    test('có html → hợp lệ, bỏ qua sections rỗng', () {
      expect(validateDocJson(_htmlDoc(html: '<p>x</p>')).isValid, isTrue);
    });

    test('html quá 5 MB → lỗi', () {
      expect(validateDocJson(_htmlDoc(html: 'é' * (maxHtmlBytes ~/ 2 + 1))).isValid, isFalse);
    });
  });

  test('hasPlaceholder chỉ xét chuỗi: mảng trong khối không bị coi là chỗ trống', () {
    expect(hasPlaceholder({'type': 'steps', 'items': ['Bước một', 'Bước hai']}), isFalse);
    expect(hasPlaceholder({'type': 'paragraph', 'text': 'Xem [tài liệu](https://a.b)'}), isFalse);
    expect(hasPlaceholder({'type': 'steps', 'items': ['Mở bài: [ý]']}), isTrue);
    expect(hasPlaceholder({'type': 'heading', 'text': '[Tiêu đề]'}), isTrue);
  });

  test('WeeklyDoc giữ html và htmlFileName', () {
    final doc = WeeklyDoc.fromJson(_htmlDoc(html: '<p>x</p>'));
    expect(doc.isHtml, isTrue);
    expect(doc.sections, isEmpty);
    expect(doc.toJson()['html'], '<p>x</p>');
    expect(doc.toJson()['htmlFileName'], 'collocations_moi_truong.html');
  });

  test('WebView chỉ cho about:, data: (anchor # nằm trong about:blank)', () {
    expect(isAllowedHtmlNavigation('about:blank'), isTrue);
    expect(isAllowedHtmlNavigation('about:blank#slide-3'), isTrue);
    expect(isAllowedHtmlNavigation('data:text/html,hi'), isTrue);
    expect(isAllowedHtmlNavigation('https://example.com'), isFalse);
    expect(isAllowedHtmlNavigation('http://example.com'), isFalse);
    expect(isAllowedHtmlNavigation('intent://x#Intent;end'), isFalse);
    expect(isAllowedHtmlNavigation('javascript:alert(1)'), isFalse);
  });
}

// html_file.dart — Tài liệu dạng HTML (file 9): kiểm tra file admin tải lên, đọc <title>.
// HTML chỉ là một chuỗi: không phân tích slide, không chạy gì ở đây.

import 'dart:convert';
import 'dart:typed_data';

/// Giới hạn chuỗi `html` (UTF-8), cùng ngưỡng với BE.
const maxHtmlBytes = 5 * 1024 * 1024;

/// Câu báo lỗi hiển thị nguyên văn dưới vùng thả (file 9 mục 3).
abstract final class HtmlFileErrors {
  static const extension = 'Chỉ nhận file .html hoặc .htm';
  static const empty = 'File trống';
  static const tooLarge = 'File lớn hơn 5 MB. Hãy nén ảnh hoặc dùng link ảnh thay vì nhúng base64.';
  static const noHtml = 'File không có nội dung HTML';
  static const multiple = 'Chỉ kéo 1 file mỗi lần';
}

class HtmlFileException implements Exception {
  const HtmlFileException(this.message);
  final String message;
  @override
  String toString() => message;
}

class HtmlFile {
  const HtmlFile({required this.name, required this.html, required this.sizeBytes, this.title});
  final String name;
  final String html;
  final int sizeBytes;

  /// Nội dung thẻ `<title>` (đã bỏ khoảng trắng thừa), null nếu không có.
  final String? title;
}

final _anyTag = RegExp(r'<\s*(!doctype|[a-z][a-z0-9-]*)[\s/>]', caseSensitive: false);
final _titleTag = RegExp(r'<title[^>]*>([\s\S]*?)</title\s*>', caseSensitive: false);

/// Kiểm tra nhanh trước khi đọc nội dung (tên + dung lượng nếu đã biết). null = hợp lệ.
String? htmlFileMetaError(String name, int? sizeBytes) {
  final lower = name.toLowerCase();
  if (!lower.endsWith('.html') && !lower.endsWith('.htm')) return HtmlFileErrors.extension;
  if (sizeBytes == null) return null;
  if (sizeBytes == 0) return HtmlFileErrors.empty;
  if (sizeBytes > maxHtmlBytes) return HtmlFileErrors.tooLarge;
  return null;
}

/// Đọc file đã chọn. Sai quy tắc → [HtmlFileException] với câu báo lỗi.
HtmlFile parseHtmlFile(String name, Uint8List bytes) {
  final metaError = htmlFileMetaError(name, bytes.length);
  if (metaError != null) throw HtmlFileException(metaError);
  final html = utf8.decode(bytes, allowMalformed: true).replaceFirst('﻿', '');
  if (html.trim().isEmpty) throw const HtmlFileException(HtmlFileErrors.empty);
  if (!_anyTag.hasMatch(html)) throw const HtmlFileException(HtmlFileErrors.noHtml);
  return HtmlFile(name: name, html: html, sizeBytes: bytes.length, title: htmlTitleOf(html));
}

String? htmlTitleOf(String html) {
  final m = _titleTag.firstMatch(html);
  if (m == null) return null;
  final t = _decodeEntities(m.group(1)!).replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.isEmpty ? null : t;
}

String _decodeEntities(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&');

/// Số byte UTF-8 của chuỗi, không cấp phát bộ nhớ (chuỗi có thể tới 5 MB).
int utf8Length(String s) {
  var n = 0;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c < 0x80) {
      n += 1;
    } else if (c < 0x800) {
      n += 2;
    } else if (c >= 0xD800 && c <= 0xDBFF && i + 1 < s.length && (s.codeUnitAt(i + 1) & 0xFC00) == 0xDC00) {
      n += 4;
      i++;
    } else {
      n += 3;
    }
  }
  return n;
}

/// Chuỗi html vượt 5 MB UTF-8? Mỗi code unit chiếm 1…3 byte nên phần lớn trường hợp khỏi phải đếm.
bool htmlTooLarge(String html) {
  if (html.length > maxHtmlBytes) return true;
  if (html.length * 3 <= maxHtmlBytes) return false;
  return utf8Length(html) > maxHtmlBytes;
}

/// "248 KB", "1,4 MB".
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
}

// doc_validator.dart — Kiểm tra JSON tài liệu (cùng quy tắc với BE, mục 3.4 file nghiệp vụ).

import 'dart:convert';

import 'html_file.dart';
import '../entities/weekly_doc.dart';

class ValidationIssue {
  const ValidationIssue(this.path, this.message);
  final String path;
  final String message;

  /// Chỉ số section / block nếu xác định được từ path (để nhảy tới khối lỗi).
  (int, int?)? get location {
    final m = RegExp(r'sections\[(\d+)\](?:\.blocks\[(\d+)\])?').firstMatch(path);
    if (m == null) return null;
    return (int.parse(m.group(1)!), m.group(2) == null ? null : int.parse(m.group(2)!));
  }

  @override
  String toString() => path.isEmpty ? message : '$path: $message';
}

class ValidationResult {
  const ValidationResult({this.errors = const [], this.warnings = const []});
  final List<ValidationIssue> errors;
  final List<ValidationIssue> warnings;
  bool get isValid => errors.isEmpty;
  bool get isClean => errors.isEmpty && warnings.isEmpty;
}

const supportedBlockTypes = {'heading', 'paragraph', 'callout', 'steps', 'passage', 'quiz', 'vocab', 'pattern', 'image', 'slideBreak'};

final _placeholder = RegExp(r'\[[^\]\n]*\](?!\()');

/// Còn chỗ trống `[ … ]` trong chuỗi nào đó của khối (link markdown `[x](…)` không tính).
/// Chỉ xét chuỗi: mảng JSON như `["a","b"]` không phải chỗ trống.
bool hasPlaceholder(Object? value) => switch (value) {
      String s => _placeholder.hasMatch(s),
      List l => l.any(hasPlaceholder),
      Map m => m.values.any(hasPlaceholder),
      _ => false,
    };

/// Kiểm tra từ chuỗi JSON (tab "Nhập JSON").
ValidationResult validateDocText(String text, {Set<String> allowedImageHosts = const {}}) {
  Object? parsed;
  try {
    parsed = jsonDecode(text);
  } on FormatException catch (e) {
    return ValidationResult(errors: [ValidationIssue('', 'Lỗi cú pháp JSON: ${e.message}')]);
  }
  return validateDocJson(parsed, allowedImageHosts: allowedImageHosts);
}

/// Kiểm tra một object JSON đã parse.
ValidationResult validateDocJson(Object? json, {Set<String> allowedImageHosts = const {}}) {
  final errors = <ValidationIssue>[];
  final warnings = <ValidationIssue>[];
  void err(String p, String m) => errors.add(ValidationIssue(p, m));

  if (json is! Map) {
    return const ValidationResult(errors: [ValidationIssue('', 'File không phải một object JSON')]);
  }
  final j = asJsonMap(json);

  if (j['schemaVersion'] != 1) err('schemaVersion', 'phải là 1');
  final title = j['title'];
  if (title is! String || title.trim().isEmpty) {
    err('title', 'thiếu tên tài liệu');
  } else if (title.trim().length > 200) {
    err('title', 'tối đa 200 ký tự');
  }

  // Tài liệu HTML (file 9): bỏ qua meta.defaultView và sections, chỉ cần chuỗi html.
  if (j['template'] == 'html') {
    final html = j['html'];
    if (html is! String || html.trim().isEmpty) {
      err('', 'Chưa tải file HTML');
    } else if (htmlTooLarge(html)) {
      err('html', 'file lớn hơn 5 MB');
    }
    return ValidationResult(errors: errors, warnings: warnings);
  }

  final meta = asJsonMap(j['meta']);
  if (meta.isNotEmpty) {
    final views = meta['allowedViews'];
    final def = meta['defaultView'];
    if (views is List && def != null && !views.contains(def)) {
      err('meta.defaultView', 'phải nằm trong allowedViews');
    }
  }

  final sections = j['sections'];
  if (sections is! List || sections.isEmpty) {
    err('sections', 'phải là mảng và có ít nhất 1 section');
    return ValidationResult(errors: errors, warnings: warnings);
  }

  var placeholderBlocks = 0;
  for (var si = 0; si < sections.length; si++) {
    final sp = 'sections[$si]';
    final s = asJsonMap(sections[si]);
    if (_str(s['title']).trim().isEmpty) err('$sp.title', 'thiếu tên section');
    final blocks = s['blocks'];
    if (blocks is! List || blocks.isEmpty) {
      err('$sp.blocks', 'section chưa có khối nào');
      continue;
    }
    var chars = 0;
    for (var bi = 0; bi < blocks.length; bi++) {
      final p = '$sp.blocks[$bi]';
      final b = asJsonMap(blocks[bi]);
      final type = b['type'];
      if (!supportedBlockTypes.contains(type)) {
        err('$p.type', 'loại khối "$type" không được hỗ trợ');
        continue;
      }
      final text = _str(b['text']);
      chars += text.length + _str(b['question']).length + _str(b['structure']).length;
      switch (type) {
        case 'heading' || 'paragraph' || 'callout' || 'passage':
          if (text.trim().isEmpty) err('$p.text', 'thiếu nội dung');
        case 'steps':
          final items = b['items'];
          if (items is! List || items.where((e) => _str(e).trim().isNotEmpty).isEmpty) err('$p.items', 'cần ít nhất 1 bước');
        case 'quiz':
          final options = b['options'];
          if (_str(b['question']).trim().isEmpty) err('$p.question', 'thiếu câu hỏi');
          if (options is! List || options.length < 2 || options.length > 6) {
            err('$p.options', 'cần từ 2 đến 6 đáp án');
          } else {
            final a = b['answer'];
            if (a is! int || a < 0 || a >= options.length) err('$p.answer', 'phải nằm trong 0…${options.length - 1}');
          }
        case 'vocab':
          final items = b['items'];
          if (items is! List || items.isEmpty) {
            err('$p.items', 'cần ít nhất 1 từ');
          } else {
            for (var i = 0; i < items.length; i++) {
              final it = asJsonMap(items[i]);
              if (_str(it['word']).trim().isEmpty || _str(it['meaning']).trim().isEmpty) {
                err('$p.items[$i]', 'mỗi từ cần "word" và "meaning"');
              }
            }
          }
        case 'pattern':
          if (_str(b['structure']).trim().isEmpty) err('$p.structure', 'thiếu cấu trúc');
        case 'image':
          final url = _str(b['url']);
          final uri = Uri.tryParse(url);
          if (uri == null || uri.scheme != 'https') {
            err('$p.url', 'phải là link https');
          } else if (allowedImageHosts.isNotEmpty && !allowedImageHosts.contains(uri.host)) {
            err('$p.url', 'host ảnh không được phép');
          }
      }
      if (hasPlaceholder(b)) placeholderBlocks++;
    }
    if (blocks.length > 6 || chars > 900) {
      warnings.add(ValidationIssue(sp, 'section dài, nên tách thêm section hoặc chèn "Ngắt slide"'));
    }
  }
  if (placeholderBlocks > 0) {
    warnings.add(ValidationIssue('', '$placeholderBlocks khối còn chỗ trống [ … ] chưa điền'));
  }
  return ValidationResult(errors: errors, warnings: warnings);
}

String _str(Object? v) => v is String ? v : '';

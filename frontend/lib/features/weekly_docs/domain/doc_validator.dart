import 'models/weekly_doc.dart';

/// Mức độ của một mục lỗi.
enum IssueLevel { error, warning }

/// Một mục lỗi/cảnh báo, có `path` (định vị trong JSON) và `message`.
class ValidationIssue {
  const ValidationIssue(this.level, this.path, this.message);

  final IssueLevel level;
  final String path;
  final String message;

  @override
  String toString() => '[$level] $path: $message';
}

/// Kết quả validate phía client (dùng màn admin báo lỗi ngay).
///
/// Khi xuất bản vẫn **tin kết quả của BE**; đây chỉ là cảnh báo sớm.
class ValidationResult {
  const ValidationResult({this.errors = const [], this.warnings = const []});

  final List<ValidationIssue> errors;
  final List<ValidationIssue> warnings;

  bool get hasErrors => errors.isNotEmpty;
  bool get isReady => errors.isEmpty;
  List<ValidationIssue> get all => [...errors, ...warnings];

  @override
  String toString() => 'errors=${errors.length} warnings=${warnings.length}';
}

/// Validate một tài liệu theo bộ quy tắc phía client.
ValidationResult validateWeeklyDoc(WeeklyDoc doc) {
  final errors = <ValidationIssue>[];
  final warnings = <ValidationIssue>[];

  final meta = doc.meta;

  // ── Meta ─────────────────────────────────────────────────────────────
  if (meta.title.trim().isEmpty) {
    errors.add(const ValidationIssue(IssueLevel.error, 'meta.title',
        'Tiêu đề tài liệu bắt buộc.'));
  }
  if (meta.week < 1) {
    errors.add(ValidationIssue(
        IssueLevel.error, 'meta.week', 'Tuần phải lớn hơn 0.'));
  }
  if (meta.estimatedMinutes <= 0) {
    warnings.add(ValidationIssue(IssueLevel.warning, 'meta.estimatedMinutes',
        'Thời lượng học nên lớn hơn 0 phút.'));
  }
  if (!meta.allowedViews.contains(meta.defaultView)) {
    warnings.add(ValidationIssue(IssueLevel.warning, 'meta.defaultView',
        'View mặc định không nằm trong danh sách view cho phép.'));
  }

  // ── Sections ─────────────────────────────────────────────────────────
  if (doc.sections.isEmpty) {
    errors.add(const ValidationIssue(
        IssueLevel.error, 'sections', 'Tài liệu cần ít nhất 1 section.'));
  }

  for (var s = 0; s < doc.sections.length; s++) {
    final section = doc.sections[s];
    final spath = 'sections[$s]';

    if (section.title.trim().isEmpty) {
      errors.add(ValidationIssue(
          IssueLevel.error, '$spath.title', 'Section cần có tên.'));
    }

    if (section.blocks.isEmpty) {
      warnings.add(ValidationIssue(IssueLevel.warning, '$spath.blocks',
          'Section đang rỗng (chưa có khối nội dung).'));
    }

    for (var b = 0; b < section.blocks.length; b++) {
      final block = section.blocks[b];
      final bpath = '$spath.blocks[$b]';
      _validateBlock(block, bpath, errors, warnings);
    }
  }

  return ValidationResult(errors: errors, warnings: warnings);
}

void _validateBlock(
  DocBlock block,
  String path,
  List<ValidationIssue> errors,
  List<ValidationIssue> warnings,
) {
  block.when(
    heading: (id, text) {
      if (text.trim().isEmpty) {
        warnings.add(ValidationIssue(
            IssueLevel.warning, path, 'Heading đang trống.'));
      }
    },
    paragraph: (id, text) {
      if (text.trim().isEmpty) {
        warnings.add(ValidationIssue(
            IssueLevel.warning, path, 'Đoạn văn đang trống.'));
      }
    },
    callout: (id, text) {
      if (text.trim().isEmpty) {
        warnings.add(ValidationIssue(
            IssueLevel.warning, path, 'Khối "Mẹo" đang trống.'));
      }
    },
    steps: (id, items) {
      if (items.isEmpty) {
        errors.add(ValidationIssue(IssueLevel.error, path,
            'Khối bước cần ít nhất 1 bước.'));
      }
    },
    passage: (id, label, text) {
      if (label.trim().isEmpty) {
        warnings.add(ValidationIssue(IssueLevel.warning, '$path.label',
            'Passage nên có nhãn (Listening / Reading…).'));
      }
      if (text.trim().isEmpty) {
        warnings.add(ValidationIssue(IssueLevel.warning, path,
            'Nội dung passage đang trống.'));
      }
    },
    quiz: (id, question, options, correctIndex, explanation) {
      if (question.trim().isEmpty) {
        warnings.add(ValidationIssue(
            IssueLevel.warning, '$path.question', 'Câu hỏi đang trống.'));
      }
      if (options.length < 2) {
        errors.add(ValidationIssue(IssueLevel.error, '$path.options',
            'Quiz cần ít nhất 2 đáp án.'));
      }
      if (options.isNotEmpty &&
          (correctIndex < 0 || correctIndex >= options.length)) {
        errors.add(ValidationIssue(IssueLevel.error, '$path.correctIndex',
            'Chỉ số đáp án đúng vượt phạm vi ($correctIndex).'));
      }
      if (explanation.trim().isEmpty) {
        warnings.add(ValidationIssue(IssueLevel.warning, '$path.explanation',
            'Quiz nên có giải thích.'));
      }
    },
    vocab: (id, items) {
      if (items.isEmpty) {
        errors.add(ValidationIssue(IssueLevel.error, path,
            'Khối từ vựng cần ít nhất 1 từ.'));
      }
      for (var i = 0; i < items.length; i++) {
        final v = items[i];
        if (v.word.trim().isEmpty) {
          errors.add(ValidationIssue(IssueLevel.error, '$path.items[$i].word',
              'Từ vựng thiếu "từ".'));
        }
        if (v.meaning.trim().isEmpty) {
          warnings.add(ValidationIssue(
              IssueLevel.warning, '$path.items[$i].meaning',
              'Từ "${v.word}" thiếu nghĩa.'));
        }
      }
    },
    pattern: (id, text) {
      if (text.trim().isEmpty) {
        warnings.add(ValidationIssue(
            IssueLevel.warning, path, 'Mẫu câu đang trống.'));
      }
    },
    image: (id, url, alt) {
      if (url.trim().isEmpty) {
        errors.add(ValidationIssue(IssueLevel.error, '$path.url',
            'Ảnh thiếu URL.'));
      }
      if (alt.trim().isEmpty) {
        warnings.add(ValidationIssue(IssueLevel.warning, '$path.alt',
            'Ảnh nên có mô tả (alt) cho trợ năng.'));
      }
    },
    slideBreak: (id) {
      // Không cần kiểm tra gì thêm.
    },
    unknown: (id, type, raw) {
      warnings.add(ValidationIssue(IssueLevel.warning, path,
          'Khối có type "$type" chưa được hỗ trợ (đã bỏ qua khi hiển thị).'));
    },
  );
}

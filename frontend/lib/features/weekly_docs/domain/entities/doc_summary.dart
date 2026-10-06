import 'doc_status.dart';
import 'weekly_doc.dart';

export 'doc_category.dart';

/// Thông tin một tài liệu không kèm nội dung (danh sách admin, danh sách tuần của người học).
class DocSummary {
  const DocSummary({
    required this.id,
    required this.week,
    required this.order,
    this.category = DocCategory.lesson,
    required this.title,
    required this.skill,
    required this.template,
    this.defaultView = DocViewMode.slide,
    this.allowedViews = const [DocViewMode.slide, DocViewMode.doc],
    this.sectionCount = 0,
    this.estimatedMinutes = 1,
    this.version = 1,
    this.status = DocStatus.published,
    this.publishAt,
    this.publishedAt,
    this.updatedAt,
    this.updatedBy = '',
    this.hasRevisionDraft = false,
    this.htmlFileName,
    this.htmlSize = 0,
  });

  final String id;
  final int week;
  final int order;
  final DocCategory category;
  final String title;
  final String skill;
  final String template;
  final DocViewMode defaultView;
  final List<DocViewMode> allowedViews;
  final int sectionCount;
  final int estimatedMinutes;
  final int version;
  final DocStatus status;
  final DateTime? publishAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final String updatedBy;

  /// Tài liệu đang xuất bản có thay đổi chưa áp dụng ("Cập nhật bản phát hành").
  final bool hasRevisionDraft;
  final String? htmlFileName;
  final int htmlSize;

  bool get isHtml => template == 'html';

  bool get isHomework => category == DocCategory.homework;

  /// "Tài liệu 1" / "Bài tập 1".
  String get numberLabel => '${category.label} $order';

  /// Đã từng xuất bản: không xoá, không đổi thứ tự được.
  bool get everPublished => publishedAt != null;
}

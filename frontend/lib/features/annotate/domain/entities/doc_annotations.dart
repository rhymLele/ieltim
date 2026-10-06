import '../../../../core/widgets/annotate/models.dart';

/// Highlight và ghi chú slide của tôi trên một tài liệu (riêng từng người, không sửa tài liệu gốc).
class DocAnnotations {
  const DocAnnotations({this.highlights = const [], this.slides = const {}});

  final List<TextHighlight> highlights;

  /// slideKey → ghi chú: `"{section}-{phần}"` (tài liệu JSON), `"s3"` / `"y2"` / `"doc"` (tài liệu HTML).
  final Map<String, SlideAnnotations> slides;
}

/// Ghi chú một slide vừa được gộp với bản trên máy chủ (máy khác cũng sửa): màn đang mở nạp lại.
class SlideAnnotationsMerged {
  const SlideAnnotationsMerged({required this.docId, required this.slideKey, required this.data});

  final String docId;
  final String slideKey;
  final SlideAnnotations data;
}

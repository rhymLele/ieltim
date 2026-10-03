import 'doc_progress.dart';
import 'doc_summary.dart';
import 'weekly_doc.dart';

/// Một dòng trong danh sách tuần của người học.
class WeekDocEntry {
  const WeekDocEntry({required this.summary, required this.progress});

  final DocSummary summary;
  final DocProgress progress;
}

/// Tài liệu người học mở để đọc: nội dung + tiến độ của tôi.
class LearnerDoc {
  const LearnerDoc({required this.summary, required this.doc, required this.progress});

  final DocSummary summary;
  final WeeklyDoc doc;
  final DocProgress progress;
}

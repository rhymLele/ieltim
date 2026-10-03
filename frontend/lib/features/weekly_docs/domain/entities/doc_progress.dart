import 'weekly_doc.dart';

/// Tiến độ đọc của tôi với một tài liệu (file 1 mục 5).
class DocProgress {
  const DocProgress({
    this.seenSections = const {},
    this.lastSection = 0,
    this.completed = false,
    this.completedAt,
    this.answers = const {},
    this.lastView,
  });

  final Set<int> seenSections;
  final int lastSection;
  final bool completed;

  /// Thời điểm hoàn thành lần đầu (danh sách tuần chỉ có cờ [completed], không kèm thời điểm).
  final DateTime? completedAt;

  /// Lựa chọn trắc nghiệm gần nhất theo khoá khối.
  final Map<String, int> answers;
  final DocViewMode? lastView;

  int get seenCount => seenSections.length;

  /// Đã xem thêm section [index] (kèm kiểu xem nếu đổi).
  DocProgress withSection(int index, {DocViewMode? view}) => DocProgress(
        seenSections: {...seenSections, index},
        lastSection: index,
        completed: completed,
        completedAt: completedAt,
        answers: answers,
        lastView: view ?? lastView,
      );

  DocProgress withAnswer(String blockKey, int option) => DocProgress(
        seenSections: seenSections,
        lastSection: lastSection,
        completed: completed,
        completedAt: completedAt,
        answers: {...answers, blockKey: option},
        lastView: lastView,
      );

  DocProgress withView(DocViewMode view) => DocProgress(
        seenSections: seenSections,
        lastSection: lastSection,
        completed: completed,
        completedAt: completedAt,
        answers: answers,
        lastView: view,
      );

  DocProgress completedOn(DateTime at, int sectionCount) => DocProgress(
        seenSections: {...seenSections, for (var i = 0; i < sectionCount; i++) i},
        lastSection: lastSection,
        completed: true,
        completedAt: completedAt ?? at,
        answers: answers,
        lastView: lastView,
      );
}

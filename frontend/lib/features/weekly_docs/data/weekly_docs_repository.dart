import '../domain/models/weekly_doc.dart';

/// Dữ liệu một tuần: danh sách tài liệu đã publish theo thứ tự [DocMeta.order].
class WeekData {
  final int week;
  final List<WeeklyDoc> docs;
  const WeekData({required this.week, required this.docs});
}

/// Số liệu tiến độ tuần cho sidebar / màn hoàn thành.
class WeekProgress {
  final int week;
  final int completed;
  final int total;
  const WeekProgress({required this.week, required this.completed, required this.total});
}

abstract class WeeklyDocsRepository {
  /// Lấy danh sách các tuần có tài liệu đã publish.
  Future<List<int>> getWeeks();

  /// Lấy tất cả tài liệu đã publish của một tuần, sắp theo [DocMeta.order].
  Future<List<WeeklyDoc>> getDocsForWeek(int week);

  /// Lấy một tài liệu theo id.
  Future<WeeklyDoc?> getDocById(String id);

  /// Đánh dấu tài liệu đã học xong.
  Future<void> markCompleted(String docId);

  /// Bỏ đánh dấu đã học xong.
  Future<void> markIncomplete(String docId);

  /// Kiểm tra tài liệu có đã học xong chưa.
  Future<bool> isCompleted(String docId);

  /// Tiến độ tuần (số tài liệu đã xong / tổng).
  Future<WeekProgress> getWeekProgress(int week);
}

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

/// Bộ lọc danh sách admin.
class AdminDocFilter {
  final int? week;
  final DocStatus? status;
  final String? skill;
  final String? search;
  const AdminDocFilter({this.week, this.status, this.skill, this.search});
}

abstract class WeeklyDocsRepository {
  // ─── User ──────────────────────────────────────────────────────────────────

  Future<List<int>> getWeeks();
  Future<List<WeeklyDoc>> getDocsForWeek(int week);
  Future<WeeklyDoc?> getDocById(String id);
  Future<void> markCompleted(String docId);
  Future<void> markIncomplete(String docId);
  Future<bool> isCompleted(String docId);
  Future<WeekProgress> getWeekProgress(int week);

  // ─── Admin ─────────────────────────────────────────────────────────────────

  /// Danh sách tài liệu (mọi trạng thái) cho admin, có lọc.
  Future<List<WeeklyDoc>> getAdminDocs({AdminDocFilter? filter});

  /// Tất cả tuần (kể cả tuần chưa có tài liệu đã publish).
  Future<List<int>> getAllWeeks();

  /// Tạo tài liệu mới (DRAFT).
  Future<WeeklyDoc> createDoc(WeeklyDoc doc);

  /// Cập nhật tài liệu (giữ version tăng).
  Future<WeeklyDoc> updateDoc(WeeklyDoc doc);

  /// Xoá tài liệu (chỉ DRAFT chưa từng publish).
  Future<void> deleteDoc(String docId);

  /// Xuất bản (DRAFT → PUBLISHED).
  Future<WeeklyDoc> publishDoc(String docId);

  /// Gỡ (PUBLISHED → ARCHIVED).
  Future<WeeklyDoc> unpublishDoc(String docId);

  /// Khôi phục (ARCHIVED → DRAFT).
  Future<WeeklyDoc> restoreDoc(String docId);

  /// Nhân bản sang tuần khác. Trả về doc mới.
  Future<WeeklyDoc> duplicateDoc(String docId, {int? targetWeek});

  /// Export JSON string.
  String exportJson(WeeklyDoc doc);
}

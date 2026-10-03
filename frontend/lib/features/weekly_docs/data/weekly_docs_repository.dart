// weekly_docs_repository.dart — Model dữ liệu + hợp đồng repository cho Tài liệu theo tuần.
// Bản thật: ApiWeeklyDocsRepository (gọi BE, giữ cache để màn hình đọc đồng bộ).
// Bản giả: FakeWeeklyDocsRepository (in-memory, xem trước UI không cần BE).

import 'package:flutter/foundation.dart';

import '../domain/weekly_doc.dart';

enum DocStatus { draft, scheduled, published, archived }

extension DocStatusX on DocStatus {
  String get label => switch (this) {
        DocStatus.draft => 'Nháp',
        DocStatus.scheduled => 'Đã hẹn',
        DocStatus.published => 'Đã xuất bản',
        DocStatus.archived => 'Đã gỡ',
      };
}

class RepoException implements Exception {
  const RepoException(this.code, this.message, {this.data});
  final String code;
  final String message;

  /// Dữ liệu kèm lỗi từ BE (409 trả bản hiện tại, 422 trả danh sách lỗi).
  final Object? data;
  @override
  String toString() => message;
}

class WeekInfo {
  const WeekInfo({required this.number, required this.start, this.stageGoal = 5, this.locked, this.docTotal, this.docDone});
  final int number;
  final DateTime start;
  final int stageGoal;

  /// Trạng thái do BE tính theo giờ Việt Nam; null thì tự so với ngày bắt đầu.
  final bool? locked;

  /// Số tài liệu đã xuất bản / đã học của tuần (BE tính sẵn); null thì màn hình tự đếm.
  final int? docTotal;
  final int? docDone;

  DateTime get end => start.add(const Duration(days: 6));
  bool get isLocked => locked ?? DateTime.now().isBefore(start);

  String get rangeLabel => '${_dm(start)} – ${_dm(end)}';
  String get opensLabel => 'Mở ${_weekday(start)}';

  static String _dm(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  static String _weekday(DateTime d) => const ['thứ Hai', 'thứ Ba', 'thứ Tư', 'thứ Năm', 'thứ Sáu', 'thứ Bảy', 'Chủ nhật'][d.weekday - 1];
}

class DocRecord {
  DocRecord({
    required this.json,
    this.status = DocStatus.draft,
    this.version = 1,
    DateTime? updatedAt,
    this.publishedAt,
    this.publishAt,
    this.updatedBy = 'Admin',
    this.hasContent = true,
    this.hasRevisionDraft = false,
    int? sectionCount,
    int? estimatedMinutes,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        _sectionCount = sectionCount,
        _estimatedMinutes = estimatedMinutes;

  /// JSON tài liệu. Từ API danh sách chỉ có phần tóm tắt (không có `sections`) → [hasContent] = false.
  Map<String, dynamic> json;
  DocStatus status;
  int version;
  DateTime updatedAt;
  DateTime? publishedAt;
  DateTime? publishAt;
  String updatedBy;
  bool hasContent;

  /// Tài liệu đang xuất bản có thay đổi chưa áp dụng ("Cập nhật bản phát hành").
  bool hasRevisionDraft;
  int? _sectionCount;
  int? _estimatedMinutes;

  WeeklyDoc get doc => WeeklyDoc.fromJson(json);
  String get id => json['id'] as String? ?? '';
  int get week => json['week'] as int? ?? 0;
  int get order => json['order'] as int? ?? 0;
  String get title => json['title'] as String? ?? '';
  bool get everPublished => publishedAt != null;
  int get sectionCount => _sectionCount ?? doc.sections.length;
  int get estimatedMinutes => _estimatedMinutes ?? doc.estimatedMinutes;

  /// Cập nhật tại chỗ (màn hình đang giữ tham chiếu tới bản ghi này).
  /// Bản tóm tắt không ghi đè nội dung đầy đủ đang có, trừ khi version đã đổi.
  void updateFrom(DocRecord o) {
    if (o.hasContent || !hasContent || o.version != version) {
      json = o.json;
      hasContent = o.hasContent;
    }
    status = o.status;
    version = o.version;
    updatedAt = o.updatedAt;
    publishedAt = o.publishedAt;
    publishAt = o.publishAt;
    updatedBy = o.updatedBy;
    hasRevisionDraft = o.hasRevisionDraft;
    _sectionCount = o._sectionCount;
    _estimatedMinutes = o._estimatedMinutes;
  }
}

class DocProgress {
  DocProgress();
  final Set<int> seenSections = {};
  int lastSection = 0;
  DateTime? completedAt;
  final Map<String, int> answers = {};
  DocViewMode? lastView;

  bool get completed => completedAt != null;
}

class CompleteResult {
  const CompleteResult({
    required this.completedNow,
    required this.stageDone,
    required this.stageGoal,
    required this.justPassedGate,
    required this.streak,
  });
  final bool completedNow;
  final int stageDone;
  final int stageGoal;
  final bool justPassedGate;
  final int streak;
}

/// Hợp đồng dùng chung cho màn hình. Getter đồng bộ đọc từ cache; gọi `load…` trước để có dữ liệu.
abstract class WeeklyDocsRepository extends ChangeNotifier {
  // ───────────────────────────── Đọc (cache) ─────────────────────────────

  List<WeekInfo> get weeks;

  /// Tuần chứa hôm nay; 0 khi chưa tải tuần nào.
  int get currentWeekNumber;
  WeekInfo weekOf(int number);
  List<DocRecord> publishedDocs(int week);
  DocProgress progressOf(String id);
  List<DocRecord> adminDocs({int? week, Set<DocStatus>? statuses, String query = ''});
  DocRecord? byId(String id);
  int nextOrder(int week);
  bool orderTaken(int week, int order, {String? exceptId});

  // ───────────────────────────── Tải ─────────────────────────────

  Future<void> loadWeeks();
  Future<void> loadWeekDocs(int week);
  Future<void> loadAdminDocs();

  /// Bản ghi đủ nội dung (sửa, xem trước, tải JSON).
  Future<DocRecord> loadAdminDoc(String id);
  Future<WeeklyDoc> loadDoc(String id);

  // ───────────────────────────── Người dùng ─────────────────────────────

  /// Ghi tiến độ: cập nhật cache ngay, gửi BE ở nền.
  void saveProgress(String id, {required int sectionIndex, DocViewMode? view});
  void answerQuiz(String id, String key, int option);
  Future<CompleteResult> complete(String id, int sectionCount);

  /// Lưu từ vựng của tài liệu vào Sổ từ; trả số từ thêm mới.
  Future<int> saveVocabFrom(WeeklyDoc doc);

  // ───────────────────────────── Admin ─────────────────────────────

  Future<DocRecord> createDraft(Map<String, dynamic> json);

  /// Lưu nháp. Sai version → RepoException `DOC_VERSION_CONFLICT`, bản ghi đã được cập nhật theo bản trên máy chủ.
  Future<DocRecord> saveDraft(String id, Map<String, dynamic> json, {required int expectedVersion});
  Future<void> publish(String id, {DateTime? at});

  /// "Cập nhật bản phát hành": áp dụng thay đổi của tài liệu đang xuất bản.
  Future<DocRecord> release(String id);
  Future<void> unschedule(String id);
  Future<void> unpublish(String id);
  Future<void> restore(String id);
  Future<void> delete(String id);

  /// Hoàn tác xoá (snackbar).
  Future<void> undoDelete(DocRecord r);
  Future<DocRecord> duplicate(String id, int targetWeek);
}

/// Tìm không phân biệt dấu và hoa thường.
String foldVietnamese(String s) {
  const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString().trim();
}

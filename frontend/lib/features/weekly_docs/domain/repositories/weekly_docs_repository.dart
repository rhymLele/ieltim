import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../entities/doc_json.dart';
import '../entities/doc_progress.dart';
import '../entities/doc_summary.dart';
import '../entities/learner_doc.dart';
import '../entities/learning_results.dart';
import '../entities/week_info.dart';
import '../entities/weekly_doc.dart';
import '../entities/weekly_docs_change.dart';

/// Dữ liệu Tài liệu theo tuần (API: backend/src/weekly-docs/README.md).
///
/// Mọi hàm trả [Result], không ném exception. Lỗi nghiệp vụ là `ServerException` kèm mã của máy chủ;
/// riêng 409 khi lưu là `VersionConflictException`, 422 khi xuất bản là `InvalidContentException`.
abstract interface class WeeklyDocsRepository {
  /// Thay đổi sau mỗi lần ghi thành công, để màn đang mở (vd danh sách nằm dưới màn soạn) cập nhật theo.
  Stream<WeeklyDocsChange> get changes;

  // ───────────────────────────── Người học ─────────────────────────────

  /// Các tuần kèm trạng thái mở / khoá và số tài liệu đã học của tôi.
  Future<Result<WeekList>> getWeeks();

  /// Tài liệu đã xuất bản của tuần [week] kèm tiến độ của tôi. Tuần còn khoá → `WEEK_LOCKED`.
  Future<Result<List<WeekDocEntry>>> getWeekDocs(int week);

  /// Nội dung + tiến độ để đọc. Tài liệu đã gỡ → `DOC_UNPUBLISHED`, không có → `DOC_NOT_FOUND`.
  Future<Result<LearnerDoc>> getLearnerDoc(String id);

  /// Ghi đã xem section [sectionIndex] (idempotent) và kiểu xem đang dùng.
  Future<Result<DocProgress>> saveProgress(String id, {required int sectionIndex, DocViewMode? view});

  /// Lưu lựa chọn trắc nghiệm của khối [blockKey]; trả đúng / sai và giải thích.
  Future<Result<QuizFeedback>> answerQuiz(String id, {required String blockKey, required int option});

  /// Đánh dấu đã học xong (idempotent); trả chặng Vũ Môn và streak.
  Future<Result<CompleteResult>> completeDoc(String id);

  /// Lưu từ vựng của tài liệu vào Sổ từ, bỏ trùng.
  Future<Result<VocabSaveResult>> saveVocabFromDoc(String id);

  // ───────────────────────────── Admin ─────────────────────────────

  /// Mọi tài liệu (không kèm nội dung), sắp theo tuần giảm dần rồi số thứ tự.
  Future<Result<List<DocSummary>>> getAdminDocs();

  /// Bản đang soạn đủ nội dung để sửa / xem trước / tải JSON.
  Future<Result<AdminDoc>> getAdminDoc(String id);

  /// Tạo nháp ở tuần [week], số [order] từ [content]. Trùng số → `DOC_ORDER_TAKEN`.
  Future<Result<AdminDoc>> createDraft({required int week, required int order, required DocJson content});

  /// Lưu nháp với [version] đang giữ. Sai version → `VersionConflictException` kèm bản hiện tại.
  /// Tài liệu đang xuất bản: lưu vào bản nháp sửa đổi, người học chưa thấy tới khi [release].
  Future<Result<AdminDoc>> saveDraft(String id, {required DocJson content, required int version});

  /// Xuất bản ngay, hoặc hẹn giờ nếu có [at] (≥ hiện tại + 5 phút). Còn lỗi → `InvalidContentException`.
  Future<Result<AdminDoc>> publish(String id, {DateTime? at});

  /// "Cập nhật bản phát hành": áp dụng bản nháp sửa đổi của tài liệu đang xuất bản.
  Future<Result<AdminDoc>> release(String id);

  /// Huỷ hẹn giờ: SCHEDULED → DRAFT.
  Future<Result<AdminDoc>> unschedule(String id);

  /// Gỡ: PUBLISHED → ARCHIVED, người học không thấy nữa, tiến độ vẫn giữ.
  Future<Result<AdminDoc>> unpublish(String id);

  /// Khôi phục: ARCHIVED → DRAFT.
  Future<Result<AdminDoc>> restore(String id);

  /// Xoá nháp chưa từng xuất bản (xoá mềm, hoàn tác được bằng [undoDelete]).
  Future<Result<void>> delete(String id);

  /// Hoàn tác xoá. Số thứ tự đã bị tài liệu khác dùng → `DOC_ORDER_TAKEN`.
  Future<Result<AdminDoc>> undoDelete(String id);

  /// Nhân bản sang tuần [targetWeek] thành nháp mới.
  Future<Result<AdminDoc>> duplicate(String id, {required int targetWeek});
}

import '../../../../core/errors/result.dart';
import '../../../../core/widgets/annotate/models.dart';
import '../entities/doc_annotations.dart';

/// Highlight, ghi chú slide và dịch nghĩa của người học (`/me/docs/...`, `/translate`).
///
/// Lưu lạc quan: các hàm ghi cập nhật bản trên máy ngay rồi gửi BE sau một nhịp ngừng thao tác;
/// mất mạng thì giữ trong hàng đợi trên máy và gửi lại sau. Hàm ghi không báo lỗi, không chặn người dùng.
abstract interface class AnnotateRepository {
  /// Bản đã lưu trên máy (mở tài liệu là hiện ngay, kể cả khi offline).
  Future<Result<DocAnnotations>> loadCached(String docId);

  /// Tải từ BE rồi phủ các thay đổi chưa gửi lên trên. Tài liệu không được xem → `DOC_FORBIDDEN`.
  Future<Result<DocAnnotations>> refresh(String docId);

  /// Thêm / đổi màu highlight (cùng id là thay thế).
  Future<void> saveHighlight(String docId, int docVersion, TextHighlight highlight);

  Future<void> deleteHighlight(String docId, String id);

  /// Ghi chú vẽ của một slide (thay cả slide).
  Future<void> saveSlide(String docId, int docVersion, String slideKey, SlideAnnotations data);

  /// Gửi ngay mọi thay đổi đang chờ (rời màn đọc, app vào nền).
  Future<void> flush();

  /// Slide vừa được gộp sau xung đột: màn đang mở nạp lại bản gộp.
  Stream<SlideAnnotationsMerged> get mergedSlides;

  /// Nghĩa tiếng Việt của [text] theo ngữ cảnh [sentence]. Quá 60 lần / giờ → `TRANSLATE_RATE_LIMIT`.
  Future<Result<TranslationResult>> translate(String text, {String? sentence});
}

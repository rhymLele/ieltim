import 'doc_progress.dart';

/// Thay đổi dữ liệu để các màn đang mở cập nhật theo (vd danh sách admin nằm dưới màn soạn).
sealed class WeeklyDocsChange {
  const WeeklyDocsChange();
}

/// Admin tạo / sửa / đổi trạng thái tài liệu.
class DocumentsChanged extends WeeklyDocsChange {
  const DocumentsChanged(this.docId);
  final String docId;
}

/// Người học xem thêm section hoặc trả lời trắc nghiệm.
class ProgressChanged extends WeeklyDocsChange {
  const ProgressChanged(this.docId, this.progress);
  final String docId;
  final DocProgress progress;
}

/// Người học hoàn thành tài liệu: số tài liệu đã học của tuần đổi.
class DocCompleted extends WeeklyDocsChange {
  const DocCompleted(this.docId);
  final String docId;
}

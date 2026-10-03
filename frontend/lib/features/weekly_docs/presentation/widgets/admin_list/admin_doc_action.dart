import '../../../domain/entities/doc_status.dart';
import '../../../domain/entities/doc_summary.dart';

/// Thao tác trong menu "⋯" của mỗi dòng tài liệu (file 7 UC-D06–D11, D13).
enum AdminDocAction {
  edit('Sửa'),
  preview('Xem trước'),
  duplicate('Nhân bản'),
  export('Tải JSON'),
  unschedule('Huỷ hẹn giờ'),
  unpublish('Gỡ'),
  restore('Khôi phục'),
  delete('Xoá');

  const AdminDocAction(this.label);

  final String label;

  /// Thao tác làm tài liệu biến mất khỏi người học: tô màu cảnh báo.
  bool get isDestructive => this == delete || this == unpublish;

  /// Các thao tác hợp lệ với trạng thái hiện tại của [doc].
  static List<AdminDocAction> availableFor(DocSummary doc) => [
        if (doc.status != DocStatus.archived) edit,
        preview,
        duplicate,
        export,
        if (doc.status == DocStatus.scheduled) unschedule,
        if (doc.status == DocStatus.published) unpublish,
        if (doc.status == DocStatus.archived) restore,
        if (doc.status == DocStatus.draft && !doc.everPublished) delete,
      ];
}

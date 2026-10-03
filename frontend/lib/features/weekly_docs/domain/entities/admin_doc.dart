import 'doc_json.dart';
import 'doc_status.dart';
import 'doc_summary.dart';

/// Tài liệu đủ nội dung cho admin sửa: bản đang soạn (bản nháp sửa đổi nếu tài liệu đang xuất bản).
class AdminDoc {
  const AdminDoc({required this.summary, required this.content});

  final DocSummary summary;
  final DocJson content;

  String get id => summary.id;
  int get version => summary.version;
  DocStatus get status => summary.status;
}

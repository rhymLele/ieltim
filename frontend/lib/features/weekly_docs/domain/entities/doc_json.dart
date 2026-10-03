import 'weekly_doc.dart';

/// JSON nội dung tài liệu do admin soạn (doc/weekly_doc.schema.json), giữ nguyên dạng để sửa rồi gửi lại máy chủ.
///
/// Cố ý không ép thành model có kiểu: nháp được lưu dù còn lỗi hoặc có khối lạ, ép kiểu sẽ làm mất dữ liệu
/// admin đang soạn. Kiểm tra bằng `validateDocJson` (rules/doc_validator.dart), đọc để hiển thị bằng [toDoc].
class DocJson {
  const DocJson(this.value);

  final Map<String, Object?> value;

  WeeklyDoc toDoc() => WeeklyDoc.fromJson(value);
}

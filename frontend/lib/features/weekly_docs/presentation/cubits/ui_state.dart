/// Trạng thái tải dữ liệu chính của một màn.
enum LoadStatus { loading, ready, failure }

/// Thông báo một lần (snackbar). [id] tăng mỗi lần để màn hình biết có thông báo mới.
class UiNotice {
  const UiNotice({required this.id, required this.message, this.undoDocId});

  final int id;
  final String message;

  /// Có giá trị = snackbar kèm nút "Hoàn tác" xoá tài liệu này.
  final String? undoDocId;

  static UiNotice next(UiNotice? previous, String message, {String? undoDocId}) =>
      UiNotice(id: (previous?.id ?? 0) + 1, message: message, undoDocId: undoDocId);
}

/// Giá trị "không đổi" cho tham số nullable của `copyWith` (phân biệt với gán null).
const keep = Object();

/// Lỗi đã phân loại ở tầng data (FLUTTER_STANDARDS mục 6). UI chỉ hiển thị [message].
///
/// Feature cần dữ liệu kèm lỗi nghiệp vụ thì kế thừa [ServerException]
/// (vd xung đột phiên bản trả kèm bản hiện tại).
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Câu thông báo tiếng Việt, hiển thị được cho người dùng.
  final String message;

  @override
  String toString() => message;
}

/// Không kết nối được máy chủ (mất mạng, timeout, máy chủ tắt).
class NetworkException extends AppException {
  const NetworkException([super.message = 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.']);
}

/// Máy chủ trả lỗi. [code] là mã nghiệp vụ của BE (vd `DOC_ORDER_TAKEN`), [statusCode] là mã HTTP.
class ServerException extends AppException {
  const ServerException(super.message, {required this.code, this.statusCode});

  final String code;
  final int? statusCode;
}

/// Lỗi đọc / ghi bộ nhớ trên máy.
class CacheException extends AppException {
  const CacheException([super.message = 'Không đọc được dữ liệu đã lưu trên máy.']);
}

/// Lỗi chưa phân loại (bug, dữ liệu trả về sai định dạng…).
class UnknownException extends AppException {
  const UnknownException([super.message = 'Có lỗi xảy ra, thử lại sau.']);
}

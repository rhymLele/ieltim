import '../../../../core/errors/app_exception.dart';
import '../rules/doc_validator.dart';
import 'admin_doc.dart';

/// Lưu với `version` cũ (409): có người khác vừa sửa. [current] là bản trên máy chủ.
class VersionConflictException extends ServerException {
  const VersionConflictException(super.message, {required this.current}) : super(code: 'DOC_VERSION_CONFLICT', statusCode: 409);
  final AdminDoc current;
}

/// Xuất bản khi nội dung còn lỗi (422). [validation] là danh sách lỗi của máy chủ.
class InvalidContentException extends ServerException {
  const InvalidContentException(super.message, {required this.validation}) : super(code: 'DOC_INVALID_CONTENT', statusCode: 422);
  final ValidationResult validation;
}

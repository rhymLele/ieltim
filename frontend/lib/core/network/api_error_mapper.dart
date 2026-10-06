import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Thân lỗi chung của BE: `{ status: "error", message, error: <MÃ>, code: <HTTP>, data }`.
class ApiError {
  const ApiError({required this.statusCode, required this.code, required this.message, this.data});

  final int? statusCode;
  final String code;
  final String message;
  final Object? data;
}

/// Đổi [DioException] thành [AppException] đã phân loại.
///
/// [special]: feature tự đổi những mã lỗi có dữ liệu kèm (vd 409 trả bản hiện tại); trả null để dùng mặc định.
AppException mapDioException(DioException e, {AppException? Function(ApiError error)? special}) {
  final response = e.response;
  if (response == null) return const NetworkException();
  final status = response.statusCode;
  if (status == 401) {
    return ServerException('Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.', code: 'UNAUTHORIZED', statusCode: status);
  }
  final body = response.data;
  if (body is! Map) return ServerException('Máy chủ gặp lỗi ($status).', code: 'HTTP_$status', statusCode: status);
  final rawMessage = body['message'];
  final message = switch (rawMessage) {
    final String text => text,
    final List<Object?> lines => lines.join('\n'),
    _ => 'Có lỗi xảy ra, thử lại sau.',
  };
  final error = ApiError(statusCode: status, code: body['error'] is String ? body['error'] as String : 'HTTP_$status', message: message, data: body['data']);
  return special?.call(error) ?? ServerException(error.message, code: error.code, statusCode: status);
}

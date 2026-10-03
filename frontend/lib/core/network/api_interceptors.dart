import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class ApiAuthInterceptor extends Interceptor {
  ApiAuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers.putIfAbsent('Authorization', () => 'Bearer $token');
      }
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          message: 'Could not read the authentication token.',
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        await _tokenStorage.clear();
      } catch (_) {
        // Storage failure must not hide the HTTP error or leave it pending.
      }
    }
    handler.next(err);
  }
}

class ApiResponseInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final data = response.data;
    // Match the backend TransformInterceptor; domain objects may have a status.
    if (data is Map &&
        data['status'] == 'success' &&
        data.containsKey('data')) {
      response.data = data['data'];
    }
    handler.next(response);
  }
}

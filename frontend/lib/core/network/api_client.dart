import 'package:dio/dio.dart';

import '../constants/app_env.dart';
import '../storage/token_storage.dart';
import 'api_interceptors.dart';

class ApiClient {
  ApiClient({String? baseUrl, TokenStorage? tokenStorage})
    : _dio = _createDio(
        baseUrl: baseUrl,
        tokenStorage: tokenStorage ?? TokenStorage(),
      );

  final Dio _dio;

  static BaseOptions _buildDefaultOptions({String? baseUrl}) => BaseOptions(
    baseUrl: baseUrl ?? AppEnv.current.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/json'},
  );

  static Dio _createDio({String? baseUrl, required TokenStorage tokenStorage}) {
    return Dio(_buildDefaultOptions(baseUrl: baseUrl))
      ..interceptors.addAll([
        ApiAuthInterceptor(tokenStorage),
        ApiResponseInterceptor(),
      ]);
  }

  Dio get dio => _dio;

  /// Per-request options never replace the shared Dio configuration.
  /// Errors remain DioException so repositories can handle backend error data.
  Future<Response<T>> request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => _dio.request<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: (options ?? Options()).copyWith(method: method),
    cancelToken: cancelToken,
  );

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => request<T>(
    path,
    method: 'GET',
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => request<T>(
    path,
    method: 'POST',
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => request<T>(
    path,
    method: 'PATCH',
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => request<T>(
    path,
    method: 'PUT',
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => request<T>(
    path,
    method: 'DELETE',
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
  );

  /// Only close a client when its owner no longer needs it.
  void close({bool force = false}) => _dio.close(force: force);
}

import 'package:dio/dio.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/widgets/annotate/models.dart';
import '../models/annotation_models.dart';

/// 409 `ANNOTATION_CONFLICT`: máy khác đã lưu slide này; kèm bản hiện tại trên máy chủ.
class AnnotationConflictException extends ServerException {
  const AnnotationConflictException(super.message, {required this.current}) : super(code: 'ANNOTATION_CONFLICT', statusCode: 409);

  final SlideStateModel current;
}

/// Gọi API ghi chú của tôi + dịch (backend/src/annotations/README.md). Ném [AppException] đã phân loại.
class AnnotateRemoteDataSource {
  AnnotateRemoteDataSource([Dio? dio]) : _dio = dio ?? getSingleton<ApiClient>().dio;

  final Dio _dio;

  String _doc(String docId) => '/me/docs/${Uri.encodeComponent(docId)}';

  Future<DocAnnotationsModel> annotations(String docId) async => DocAnnotationsModel.fromJson(await _map(() => _dio.get('${_doc(docId)}/annotations')));

  Future<void> putHighlight(String docId, int docVersion, TextHighlight h) =>
      _send(() => _dio.put('${_doc(docId)}/highlights/${h.id}', data: {...h.toJson()..remove('id'), 'docVersion': docVersion}));

  Future<void> deleteHighlight(String docId, String id) => _send(() => _dio.delete('${_doc(docId)}/highlights/$id'));

  /// Trả `rev` mới. Máy khác lưu trước → [AnnotationConflictException].
  Future<int> putSlide(String docId, String slideKey, SlideSaveRequest body) async {
    final data = await _map(() => _dio.put('${_doc(docId)}/slides/${Uri.encodeComponent(slideKey)}/annotations', data: body.toJson()));
    final rev = data['rev'];
    if (rev is int) return rev;
    throw const UnknownException('Máy chủ trả dữ liệu không đúng định dạng.');
  }

  Future<TranslationModel> translate(TranslateRequest body) async => TranslationModel.fromJson(await _map(() => _dio.post('/translate', data: body.toJson())));

  Future<Map<String, dynamic>> _map(Future<Response<Object?>> Function() call) async {
    final data = await _send(call);
    if (data is Map<String, dynamic>) return data;
    throw const UnknownException('Máy chủ trả dữ liệu không đúng định dạng.');
  }

  Future<Object?> _send(Future<Response<Object?>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw mapDioException(e, special: (error) {
        final current = error.data;
        if (error.code == 'ANNOTATION_CONFLICT' && current is Map<String, dynamic>) {
          return AnnotationConflictException(error.message, current: SlideStateModel.fromJson(current));
        }
        return null;
      });
    }
  }
}

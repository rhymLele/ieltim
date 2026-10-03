import 'package:dio/dio.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/weekly_docs_exceptions.dart';
import '../models/api_error_model.dart';
import '../models/doc_models.dart';
import '../models/learning_result_models.dart';
import '../models/request_models.dart';
import '../models/validation_models.dart';
import '../models/week_models.dart';

/// Gọi API Tài liệu theo tuần (backend/src/weekly-docs/README.md).
///
/// Ném [AppException] đã phân loại; repository đổi thành `Result`. Phần bọc `{ status, data }` của BE
/// đã được interceptor của [ApiClient] bóc sẵn.
class WeeklyDocsRemoteDataSource {
  WeeklyDocsRemoteDataSource([Dio? dio]) : _dio = dio ?? getSingleton<ApiClient>().dio;

  final Dio _dio;

  static const _admin = '/admin/weekly';
  static const _user = '/weekly';

  // ───────────────────────────── Người học ─────────────────────────────

  Future<WeekListModel> getWeeks() async => WeekListModel.fromJson(await _map(() => _dio.get('$_user/weeks')));

  Future<List<DocModel>> getWeekDocs(int week) async =>
      [for (final item in await _list(() => _dio.get('$_user/weeks/$week/documents'))) DocModel.fromJson(item)];

  Future<DocModel> getLearnerDoc(String id) async => DocModel.fromJson(await _map(() => _dio.get('$_user/documents/$id')));

  Future<ProgressModel> saveProgress(String id, ProgressRequest body) async =>
      ProgressModel.fromJson(await _map(() => _dio.put('$_user/documents/$id/progress', data: body.toJson())));

  Future<QuizFeedbackModel> answerQuiz(String id, QuizAnswerRequest body) async =>
      QuizFeedbackModel.fromJson(await _map(() => _dio.post('$_user/documents/$id/quiz-answers', data: body.toJson())));

  Future<CompleteResultModel> completeDoc(String id) async =>
      CompleteResultModel.fromJson(await _map(() => _dio.post('$_user/documents/$id/complete')));

  Future<VocabSaveResultModel> saveVocabFromDoc(VocabFromDocRequest body) async =>
      VocabSaveResultModel.fromJson(await _map(() => _dio.post('$_user/vocab/from-document', data: body.toJson())));

  // ───────────────────────────── Admin ─────────────────────────────

  /// Mọi tài liệu: không lọc tuần thì BE phân trang, nên xin một trang đủ lớn.
  Future<List<DocModel>> getAdminDocs() async =>
      DocPageModel.fromJson(await _map(() => _dio.get('$_admin/documents', queryParameters: {'pageSize': 1000}))).data;

  Future<DocModel> getAdminDoc(String id) => _doc(() => _dio.get('$_admin/documents/$id'));

  Future<DocModel> createDraft(CreateDraftRequest body) => _doc(() => _dio.post('$_admin/documents', data: body.toJson()));

  Future<DocModel> saveDraft(String id, SaveDraftRequest body) => _doc(() => _dio.put('$_admin/documents/$id', data: body.toJson()));

  Future<DocModel> publish(String id, PublishRequest body) => _doc(() => _dio.post('$_admin/documents/$id/publish', data: body.toJson()));

  Future<DocModel> release(String id) => _doc(() => _dio.post('$_admin/documents/$id/release'));

  Future<DocModel> unschedule(String id) => _doc(() => _dio.delete('$_admin/documents/$id/schedule'));

  Future<DocModel> unpublish(String id) => _doc(() => _dio.post('$_admin/documents/$id/unpublish'));

  Future<DocModel> restore(String id) => _doc(() => _dio.post('$_admin/documents/$id/restore'));

  Future<void> delete(String id) => _send(() => _dio.delete('$_admin/documents/$id'));

  Future<DocModel> undoDelete(String id) => _doc(() => _dio.post('$_admin/documents/$id/undelete'));

  Future<DocModel> duplicate(String id, DuplicateRequest body) =>
      _doc(() => _dio.post('$_admin/documents/$id/duplicate', data: body.toJson()));

  // ───────────────────────────── Nội bộ ─────────────────────────────

  Future<DocModel> _doc(Future<Response<Object?>> Function() call) async => DocModel.fromJson(await _map(call));

  Future<Map<String, dynamic>> _map(Future<Response<Object?>> Function() call) async {
    final data = await _send(call);
    if (data is Map<String, dynamic>) return data;
    throw const UnknownException('Máy chủ trả dữ liệu không đúng định dạng.');
  }

  Future<List<Map<String, dynamic>>> _list(Future<Response<Object?>> Function() call) async {
    final data = await _send(call);
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    throw const UnknownException('Máy chủ trả dữ liệu không đúng định dạng.');
  }

  Future<Object?> _send(Future<Response<Object?>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw _toAppException(e);
    }
  }

  static AppException _toAppException(DioException e) {
    final response = e.response;
    if (response == null) return const NetworkException();
    final status = response.statusCode;
    if (status == 401) {
      return ServerException('Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.', code: 'UNAUTHORIZED', statusCode: status);
    }
    final body = response.data;
    if (body is! Map<String, dynamic>) return ServerException('Máy chủ gặp lỗi ($status).', code: 'HTTP_$status', statusCode: status);
    final error = ApiErrorModel.fromJson(body);
    final code = error.error ?? 'HTTP_$status';
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      if (code == 'DOC_VERSION_CONFLICT' && data['current'] is Map<String, dynamic>) {
        return VersionConflictException(error.message, current: VersionConflictModel.fromJson(data).current.toAdminDoc());
      }
      if (code == 'DOC_INVALID_CONTENT') {
        return InvalidContentException(error.message, validation: ValidationResultModel.fromJson(data).toEntity());
      }
    }
    return ServerException(error.message, code: code, statusCode: status);
  }
}

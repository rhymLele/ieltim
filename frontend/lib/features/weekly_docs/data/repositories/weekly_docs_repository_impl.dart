import 'dart:async';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/logger_service.dart';
import '../../domain/entities/admin_doc.dart';
import '../../domain/entities/doc_json.dart';
import '../../domain/entities/doc_progress.dart';
import '../../domain/entities/doc_summary.dart';
import '../../domain/entities/learner_doc.dart';
import '../../domain/entities/learning_results.dart';
import '../../domain/entities/week_info.dart';
import '../../domain/entities/weekly_doc.dart';
import '../../domain/entities/weekly_docs_change.dart';
import '../../domain/repositories/weekly_docs_repository.dart';
import '../datasources/weekly_docs_remote_datasource.dart';
import '../models/doc_models.dart';
import '../models/request_models.dart';

/// Repository gọi BE. Không ném exception: mọi lỗi thành [Failure]; ghi thành công thì phát [changes].
class WeeklyDocsRepositoryImpl implements WeeklyDocsRepository {
  WeeklyDocsRepositoryImpl({WeeklyDocsRemoteDataSource? remote, LoggerService? logger})
      : _remote = remote ?? WeeklyDocsRemoteDataSource(),
        _logger = logger ?? getSingleton<LoggerService>();

  final WeeklyDocsRemoteDataSource _remote;
  final LoggerService _logger;
  final _changes = StreamController<WeeklyDocsChange>.broadcast();

  @override
  Stream<WeeklyDocsChange> get changes => _changes.stream;

  // ───────────────────────────── Người học ─────────────────────────────

  @override
  Future<Result<WeekList>> getWeeks() => _guard('tải tuần', () async => (await _remote.getWeeks()).toEntity());

  @override
  Future<Result<List<WeekDocEntry>>> getWeekDocs(int week) =>
      _guard('tải tài liệu tuần $week', () async => [for (final d in await _remote.getWeekDocs(week)) d.toWeekEntry()]);

  @override
  Future<Result<LearnerDoc>> getLearnerDoc(String id) => _guard('mở $id', () async => (await _remote.getLearnerDoc(id)).toLearnerDoc());

  @override
  Future<Result<DocProgress>> saveProgress(String id, {required int sectionIndex, DocViewMode? view}) => _guard(
        'ghi tiến độ $id',
        () async => (await _remote.saveProgress(id, ProgressRequest(sectionIndex: sectionIndex, viewMode: view?.name))).toEntity(),
        changeOf: (progress) => ProgressChanged(id, progress),
      );

  @override
  Future<Result<QuizFeedback>> answerQuiz(String id, {required String blockKey, required int option}) => _guard(
        'trả lời trắc nghiệm $id',
        () async => (await _remote.answerQuiz(id, QuizAnswerRequest(blockKey: blockKey, option: option))).toEntity(),
      );

  @override
  Future<Result<CompleteResult>> completeDoc(String id) => _guard(
        'hoàn thành $id',
        () async => (await _remote.completeDoc(id)).toEntity(),
        changeOf: (_) => DocCompleted(id),
      );

  @override
  Future<Result<VocabSaveResult>> saveVocabFromDoc(String id) =>
      _guard('lưu từ vựng $id', () async => (await _remote.saveVocabFromDoc(VocabFromDocRequest(documentId: id))).toEntity());

  // ───────────────────────────── Admin ─────────────────────────────

  @override
  Future<Result<List<DocSummary>>> getAdminDocs() =>
      _guard('tải danh sách tài liệu', () async => [for (final d in await _remote.getAdminDocs()) d.toSummary()]);

  @override
  Future<Result<AdminDoc>> getAdminDoc(String id) => _guard('tải $id', () async => (await _remote.getAdminDoc(id)).toAdminDoc());

  @override
  Future<Result<AdminDoc>> createDraft({required int week, required int order, required DocJson content}) =>
      _adminWrite('tạo nháp', () => _remote.createDraft(CreateDraftRequest(week: week, order: order, content: content)));

  @override
  Future<Result<AdminDoc>> saveDraft(String id, {required DocJson content, required int version}) =>
      _adminWrite('lưu nháp $id', () => _remote.saveDraft(id, SaveDraftRequest(content: content, version: version)));

  @override
  Future<Result<AdminDoc>> publish(String id, {DateTime? at}) =>
      _adminWrite('xuất bản $id', () => _remote.publish(id, PublishRequest(publishAt: at?.toUtc())));

  @override
  Future<Result<AdminDoc>> release(String id) => _adminWrite('cập nhật bản phát hành $id', () => _remote.release(id));

  @override
  Future<Result<AdminDoc>> unschedule(String id) => _adminWrite('huỷ hẹn giờ $id', () => _remote.unschedule(id));

  @override
  Future<Result<AdminDoc>> unpublish(String id) => _adminWrite('gỡ $id', () => _remote.unpublish(id));

  @override
  Future<Result<AdminDoc>> restore(String id) => _adminWrite('khôi phục $id', () => _remote.restore(id));

  @override
  Future<Result<void>> delete(String id) => _guard('xoá $id', () => _remote.delete(id), changeOf: (_) => DocumentsChanged(id));

  @override
  Future<Result<AdminDoc>> undoDelete(String id) => _adminWrite('hoàn tác xoá $id', () => _remote.undoDelete(id));

  @override
  Future<Result<AdminDoc>> duplicate(String id, {required int targetWeek}) =>
      _adminWrite('nhân bản $id', () => _remote.duplicate(id, DuplicateRequest(targetWeek: targetWeek)));

  // ───────────────────────────── Nội bộ ─────────────────────────────

  /// Thao tác admin trả về một tài liệu: đổi sang entity và báo danh sách admin cập nhật.
  Future<Result<AdminDoc>> _adminWrite(String action, Future<DocModel> Function() call) => _guard(
        action,
        () async => (await call()).toAdminDoc(),
        changeOf: (doc) => DocumentsChanged(doc.id),
      );

  Future<Result<T>> _guard<T>(String action, Future<T> Function() call, {WeeklyDocsChange Function(T value)? changeOf}) async {
    try {
      final value = await call();
      if (changeOf != null) _changes.add(changeOf(value));
      return Success(value);
    } on AppException catch (e) {
      _logger.warning('weekly_docs: $action thất bại — ${e is ServerException ? e.code : e.runtimeType}: ${e.message}');
      return Failure(e);
    } on Object catch (e, stackTrace) {
      _logger.error('weekly_docs: $action gặp lỗi không xác định', e, stackTrace);
      return const Failure(UnknownException());
    }
  }
}

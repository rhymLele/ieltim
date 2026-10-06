import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/app_exception.dart';
import 'package:frontend/core/errors/result.dart';
import 'package:frontend/core/services/logger_service.dart';
import 'package:frontend/features/weekly_docs/data/datasources/weekly_docs_remote_datasource.dart';
import 'package:frontend/features/weekly_docs/data/repositories/weekly_docs_repository_impl.dart';
import 'package:frontend/features/weekly_docs/domain/entities/doc_json.dart';
import 'package:frontend/features/weekly_docs/domain/entities/doc_status.dart';
import 'package:frontend/features/weekly_docs/domain/entities/weekly_doc.dart';
import 'package:frontend/features/weekly_docs/domain/entities/weekly_docs_change.dart';
import 'package:frontend/features/weekly_docs/domain/entities/weekly_docs_exceptions.dart';
import 'package:frontend/features/weekly_docs/domain/rules/doc_templates.dart';
import 'package:logger/logger.dart';

/// Trả lời mọi request bằng [handler]; ném [DioException] để giả lập mất mạng.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, [int status = 200]) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// Một tài liệu như API trả (phần `data` sau khi interceptor bóc envelope).
Map<String, Object?> _doc({int version = 1, String status = 'draft', Map<String, Object?>? progress}) => {
      'id': 'w12-doc1',
      'week': 12,
      'order': 1,
      'title': 'Reading: Matching Headings',
      'skill': 'reading',
      'template': 'reading-lesson',
      'defaultView': 'slide',
      'allowedViews': ['slide', 'doc'],
      'sectionCount': 4,
      'estimatedMinutes': 8,
      'version': version,
      'hasRevisionDraft': false,
      'htmlSize': 0,
      'status': status,
      'publishAt': null,
      'publishedAt': null,
      'updatedAt': '2026-10-03T03:00:00.000Z',
      'updatedBy': 'Admin',
      'content': sampleReadingDoc(),
      'progress': ?progress,
    };

Map<String, Object?> _error(String code, String message, {Object? data, int status = 400}) =>
    {'status': 'error', 'error': code, 'message': message, 'code': status, 'data': ?data};

void main() {
  late _FakeAdapter adapter;
  late WeeklyDocsRepositoryImpl repo;

  void serve(ResponseBody Function(RequestOptions options) handler) {
    adapter = _FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;
    repo = WeeklyDocsRepositoryImpl(remote: WeeklyDocsRemoteDataSource(dio), logger: LoggerService(Logger(level: Level.off)));
  }

  AppException failureOf<T>(Result<T> result) => switch (result) {
        Success() => throw TestFailure('Mong Failure, nhận Success'),
        Failure(:final exception) => exception,
      };

  T dataOf<T>(Result<T> result) => switch (result) {
        Success(:final data) => data,
        Failure(:final exception) => throw TestFailure('Mong Success, nhận Failure: ${exception.message}'),
      };

  group('đọc dữ liệu (json_serializable)', () {
    test('GET /weekly/weeks: tuần khoá theo `state`, tuần hiện tại từ máy chủ', () async {
      serve((_) => _json({
            'currentWeek': 12,
            'data': [
              {'number': 12, 'startDate': '2026-09-28', 'stageGoal': 5, 'state': 'open', 'docTotal': 3, 'docDone': 1},
              {'number': 13, 'startDate': '2026-10-05', 'stageGoal': 5, 'state': 'locked'},
            ],
          }));
      final weeks = dataOf(await repo.getWeeks());
      expect(weeks.currentWeekNumber, 12);
      expect(weeks.byNumber(12)?.isLocked, isFalse);
      expect(weeks.byNumber(12)?.docDone, 1);
      expect(weeks.byNumber(13)?.isLocked, isTrue);
      expect(adapter.requests.single.path, '/weekly/weeks');
    });

    test('GET tài liệu người học: nội dung + tiến độ (lựa chọn trắc nghiệm, kiểu xem)', () async {
      serve((_) => _json(_doc(status: 'published', progress: {
            'lastSection': 2,
            'seenSections': [0, 1, 2],
            'completed': false,
            'viewMode': 'doc',
            'quizAnswers': {
              'q1': {'option': 1, 'firstCorrect': true},
            },
          })));
      final doc = dataOf(await repo.getLearnerDoc('w12-doc1'));
      expect(doc.summary.status, DocStatus.published);
      expect(doc.doc.sections, isNotEmpty);
      expect(doc.progress.lastSection, 2);
      expect(doc.progress.seenSections, {0, 1, 2});
      expect(doc.progress.lastView, DocViewMode.doc);
      expect(doc.progress.answers, {'q1': 1});
    });

    test('PUT tiến độ gửi đúng body và báo ProgressChanged', () async {
      serve((_) => _json({'lastSection': 3, 'seenSections': [3], 'completed': false, 'quizAnswers': <String, Object?>{}}));
      final changes = <WeeklyDocsChange>[];
      final sub = repo.changes.listen(changes.add);
      dataOf(await repo.saveProgress('w12-doc1', sectionIndex: 3, view: DocViewMode.slide));
      await pumpEventQueue();
      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/weekly/documents/w12-doc1/progress');
      expect(request.data, {'sectionIndex': 3, 'viewMode': 'slide'});
      expect(changes.single, isA<ProgressChanged>());
      await sub.cancel();
    });

    test('loại tài liệu: BE cũ không có `category` → Tài liệu; bài tập gửi `category` khi tạo', () async {
      serve((_) => _json(_doc()));
      expect(dataOf(await repo.getAdminDoc('w12-doc1')).summary.category, DocCategory.lesson);

      serve((_) => _json({..._doc(), 'id': 'w12-hw1', 'category': 'homework'}));
      final created = dataOf(await repo.createDraft(week: 12, order: 1, category: DocCategory.homework, content: DocJson(sampleReadingDoc())));
      expect(created.summary.isHomework, isTrue);
      expect(created.summary.numberLabel, 'Bài tập 1');
      expect(adapter.requests.single.data, containsPair('category', 'homework'));
    });

    test('ghi của admin thành công thì báo DocumentsChanged', () async {
      serve((_) => _json(_doc(version: 2)));
      final changes = <WeeklyDocsChange>[];
      final sub = repo.changes.listen(changes.add);
      final saved = dataOf(await repo.saveDraft('w12-doc1', content: DocJson(sampleReadingDoc()), version: 1));
      await pumpEventQueue();
      expect(saved.version, 2);
      expect(adapter.requests.single.data, containsPair('version', 1));
      expect(changes.single, isA<DocumentsChanged>());
      await sub.cancel();
    });
  });

  group('phân loại lỗi', () {
    test('409 DOC_VERSION_CONFLICT → VersionConflictException kèm bản hiện tại', () async {
      serve((_) => _json(_error('DOC_VERSION_CONFLICT', 'Admin vừa sửa tài liệu này lúc 10:42.', data: {'current': _doc(version: 3)}, status: 409), 409));
      final error = failureOf(await repo.saveDraft('w12-doc1', content: DocJson(sampleReadingDoc()), version: 1));
      expect(error, isA<VersionConflictException>());
      expect((error as VersionConflictException).current.version, 3);
      expect(error.message, contains('10:42'));
    });

    test('422 DOC_INVALID_CONTENT → InvalidContentException kèm danh sách lỗi', () async {
      serve((_) => _json(
            _error('DOC_INVALID_CONTENT', 'Tài liệu còn 1 lỗi.', status: 422, data: {
              'errors': [
                {'path': 'sections[0].title', 'message': 'thiếu tên section'},
              ],
              'warnings': <Object?>[],
            }),
            422,
          ));
      final error = failureOf(await repo.publish('w12-doc1'));
      expect(error, isA<InvalidContentException>());
      expect((error as InvalidContentException).validation.errors.single.location, (0, null));
    });

    test('lỗi nghiệp vụ khác giữ mã của máy chủ; message dạng mảng được nối lại', () async {
      serve((_) => _json(_error('DOC_ORDER_TAKEN', 'Tuần 12 đã có Tài liệu 1.', status: 409), 409));
      final taken = failureOf(await repo.createDraft(week: 12, order: 1, category: DocCategory.lesson, content: DocJson(sampleReadingDoc())));
      expect((taken as ServerException).code, 'DOC_ORDER_TAKEN');

      serve((_) => _json({'status': 'error', 'message': ['week phải ≥ 1', 'order phải ≥ 1'], 'error': 'Bad Request'}, 400));
      final invalid = failureOf(await repo.duplicate('w12-doc1', targetWeek: 0));
      expect(invalid.message, 'week phải ≥ 1\norder phải ≥ 1');
    });

    test('401 → UNAUTHORIZED; 500 không phải JSON → HTTP_500', () async {
      serve((_) => _json({'message': 'Unauthorized'}, 401));
      expect((failureOf(await repo.getWeeks()) as ServerException).code, 'UNAUTHORIZED');

      serve((_) => ResponseBody.fromString('<html>Bad gateway</html>', 500, headers: {
            Headers.contentTypeHeader: ['text/html'],
          }));
      expect((failureOf(await repo.getAdminDocs()) as ServerException).code, 'HTTP_500');
    });

    test('mất mạng → NetworkException', () async {
      serve((options) => throw DioException(requestOptions: options, type: DioExceptionType.connectionError));
      expect(failureOf(await repo.getWeeks()), isA<NetworkException>());
    });

    test('dữ liệu sai định dạng → UnknownException, không văng lỗi ra ngoài', () async {
      serve((_) => _json(['không phải object']));
      expect(failureOf(await repo.getLearnerDoc('w12-doc1')), isA<UnknownException>());
    });
  });
}

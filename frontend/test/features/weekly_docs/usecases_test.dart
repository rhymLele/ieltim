import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/di/service_locator.dart';
import 'package:frontend/core/errors/app_exception.dart';
import 'package:frontend/core/errors/result.dart';
import 'package:frontend/features/weekly_docs/data/repositories/fake_weekly_docs_repository.dart';
import 'package:frontend/features/weekly_docs/domain/entities/doc_json.dart';
import 'package:frontend/features/weekly_docs/domain/entities/doc_status.dart';
import 'package:frontend/features/weekly_docs/domain/entities/weekly_doc.dart';
import 'package:frontend/features/weekly_docs/domain/entities/weekly_docs_change.dart';
import 'package:frontend/features/weekly_docs/domain/entities/weekly_docs_exceptions.dart';
import 'package:frontend/features/weekly_docs/domain/repositories/weekly_docs_repository.dart';
import 'package:frontend/features/weekly_docs/domain/rules/doc_templates.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/answer_quiz_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/complete_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/create_draft_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/delete_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/duplicate_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/get_admin_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/get_admin_docs_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/get_learner_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/get_week_docs_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/get_weeks_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/publish_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/release_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/restore_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/save_draft_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/save_progress_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/save_vocab_from_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/undo_delete_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/unpublish_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/unschedule_doc_use_case.dart';
import 'package:frontend/features/weekly_docs/domain/usecases/watch_weekly_docs_changes_use_case.dart';

T _data<T>(Result<T> result) => switch (result) {
      Success(:final data) => data,
      Failure(:final exception) => throw TestFailure('Mong Success, nhận Failure: ${exception.message}'),
    };

AppException _error<T>(Result<T> result) => switch (result) {
      Success() => throw TestFailure('Mong Failure, nhận Success'),
      Failure(:final exception) => exception,
    };

String? _code(AppException e) => e is ServerException ? e.code : null;

/// Nội dung nháp hợp lệ để xuất bản được.
DocJson _validContent({required int week, required int order}) {
  final json = deepCopyJson(sampleReadingDoc()) as Map<String, dynamic>
    ..['id'] = 'w$week-doc$order'
    ..['week'] = week
    ..['order'] = order
    ..['title'] = 'Bài thử';
  return DocJson(json);
}

void main() {
  late FakeWeeklyDocsRepository repo;

  setUp(() => repo = FakeWeeklyDocsRepository(latency: Duration.zero));

  group('người học', () {
    test('GetWeeks: tuần hiện tại là 12, tuần 13 còn khoá và không lộ số tài liệu', () async {
      final weeks = _data(await GetWeeksUseCase(repo).execute());
      expect(weeks.currentWeekNumber, 12);
      expect(weeks.byNumber(13)?.isLocked, isTrue);
      expect(weeks.byNumber(13)?.docTotal, 0);
      expect(weeks.byNumber(12)?.docTotal, 2);
    });

    test('GetWeekDocs: tuần khoá trả WEEK_LOCKED', () async {
      expect(_code(_error(await GetWeekDocsUseCase(repo).execute(13))), 'WEEK_LOCKED');
      final docs = _data(await GetWeekDocsUseCase(repo).execute(12));
      expect(docs.map((e) => e.summary.id), ['w12-doc1', 'w12-doc2']);
    });

    test('GetLearnerDoc: nháp chưa xuất bản trả DOC_NOT_FOUND', () async {
      expect(_code(_error(await GetLearnerDocUseCase(repo).execute('w12-doc3'))), 'DOC_NOT_FOUND');
      final doc = _data(await GetLearnerDocUseCase(repo).execute('w12-doc1'));
      expect(doc.progress.lastSection, 1);
    });

    test('SaveProgress ghi section + kiểu xem và phát ProgressChanged', () async {
      final changes = <WeeklyDocsChange>[];
      final sub = WatchWeeklyDocsChangesUseCase(repo).execute().listen(changes.add);
      final progress = _data(await SaveProgressUseCase(repo).execute('w12-doc1', sectionIndex: 3, view: DocViewMode.doc));
      await pumpEventQueue();
      expect(progress.seenSections, containsAll([0, 1, 3]));
      expect(progress.lastView, DocViewMode.doc);
      expect(changes.single, isA<ProgressChanged>());
      await sub.cancel();
    });

    test('AnswerQuiz chấm đúng / sai; khối không tồn tại trả BLOCK_NOT_FOUND', () async {
      final doc = _data(await GetLearnerDocUseCase(repo).execute('w12-doc1')).doc;
      late QuizBlock quiz;
      late String key;
      for (var si = 0; si < doc.sections.length; si++) {
        for (var bi = 0; bi < doc.sections[si].blocks.length; bi++) {
          final block = doc.sections[si].blocks[bi];
          if (block is QuizBlock) {
            quiz = block;
            key = block.id ?? '$si-$bi';
          }
        }
      }
      final right = _data(await AnswerQuizUseCase(repo).execute('w12-doc1', blockKey: key, option: quiz.answer));
      final wrong = _data(await AnswerQuizUseCase(repo).execute('w12-doc1', blockKey: key, option: quiz.answer == 0 ? 1 : 0));
      expect(right.correct, isTrue);
      expect(wrong.correct, isFalse);
      expect(_code(_error(await AnswerQuizUseCase(repo).execute('w12-doc1', blockKey: 'khong-co', option: 0))), 'BLOCK_NOT_FOUND');
    });

    test('CompleteDoc tính chặng một lần (idempotent)', () async {
      final first = _data(await CompleteDocUseCase(repo).execute('w12-doc1'));
      final again = _data(await CompleteDocUseCase(repo).execute('w12-doc1'));
      expect(first.completedNow, isTrue);
      expect(again.completedNow, isFalse);
      expect(again.stageDone, first.stageDone);
    });

    test('SaveVocabFromDoc bỏ trùng ở lần lưu sau', () async {
      final first = _data(await SaveVocabFromDocUseCase(repo).execute('w12-doc1'));
      final again = _data(await SaveVocabFromDocUseCase(repo).execute('w12-doc1'));
      expect(first.added, greaterThan(0));
      expect(again.added, 0);
      expect(again.existed, first.added);
    });
  });

  group('admin', () {
    test('GetAdminDocs sắp tuần mới trước rồi theo số thứ tự', () async {
      final docs = _data(await GetAdminDocsUseCase(repo).execute());
      expect(docs.first.id, 'w12-doc1');
      expect(docs.map((d) => d.week).toList(), orderedEquals([...docs.map((d) => d.week)]..sort((a, b) => b.compareTo(a))));
    });

    test('CreateDraft: trùng số thứ tự trả DOC_ORDER_TAKEN', () async {
      final taken = await CreateDraftUseCase(repo).execute(week: 12, order: 1, content: _validContent(week: 12, order: 1));
      expect(_code(_error(taken)), 'DOC_ORDER_TAKEN');
      final created = _data(await CreateDraftUseCase(repo).execute(week: 12, order: 4, content: _validContent(week: 12, order: 4)));
      expect(created.summary.id, 'w12-doc4');
      expect(created.summary.status, DocStatus.draft);
    });

    test('SaveDraft: sai version trả VersionConflictException kèm bản hiện tại', () async {
      final doc = _data(await GetAdminDocUseCase(repo).execute('w12-doc3'));
      final saved = _data(await SaveDraftUseCase(repo).execute('w12-doc3', content: doc.content, version: doc.version));
      expect(saved.version, doc.version + 1);
      final stale = _error(await SaveDraftUseCase(repo).execute('w12-doc3', content: doc.content, version: doc.version));
      expect(stale, isA<VersionConflictException>());
      expect((stale as VersionConflictException).current.version, saved.version);
    });

    test('PublishDoc: nội dung lỗi thì InvalidContentException; hợp lệ thì xuất bản / hẹn giờ', () async {
      final draft = _data(await GetAdminDocUseCase(repo).execute('w12-doc3'));
      final broken = DocJson({...draft.content.value, 'sections': <Object?>[]});
      await SaveDraftUseCase(repo).execute('w12-doc3', content: broken, version: draft.version);
      final invalid = _error(await PublishDocUseCase(repo).execute('w12-doc3'));
      expect(invalid, isA<InvalidContentException>());
      expect((invalid as InvalidContentException).validation.errors, isNotEmpty);

      final created = _data(await CreateDraftUseCase(repo).execute(week: 12, order: 4, content: _validContent(week: 12, order: 4)));
      final scheduled = _data(await PublishDocUseCase(repo).execute(created.summary.id, at: DateTime.now().add(const Duration(days: 1))));
      expect(scheduled.summary.status, DocStatus.scheduled);
      expect(_data(await UnscheduleDocUseCase(repo).execute(created.summary.id)).summary.status, DocStatus.draft);
      expect(_data(await PublishDocUseCase(repo).execute(created.summary.id)).summary.status, DocStatus.published);
      expect(_data(await ReleaseDocUseCase(repo).execute(created.summary.id)).summary.status, DocStatus.published);
    });

    test('UnpublishDoc / RestoreDoc: đã gỡ thì người học nhận DOC_UNPUBLISHED', () async {
      expect(_data(await UnpublishDocUseCase(repo).execute('w12-doc2')).summary.status, DocStatus.archived);
      expect(_code(_error(await GetLearnerDocUseCase(repo).execute('w12-doc2'))), 'DOC_UNPUBLISHED');
      expect(_data(await RestoreDocUseCase(repo).execute('w12-doc2')).summary.status, DocStatus.draft);
    });

    test('DeleteDoc chỉ xoá nháp chưa từng xuất bản; UndoDeleteDoc trả lại', () async {
      expect(_code(_error(await DeleteDocUseCase(repo).execute('w12-doc1'))), 'DOC_DELETE_NOT_ALLOWED');
      expect(await DeleteDocUseCase(repo).execute('w12-doc3'), isA<Success<void>>());
      expect(_code(_error(await GetAdminDocUseCase(repo).execute('w12-doc3'))), 'DOC_NOT_FOUND');
      expect(_data(await UndoDeleteDocUseCase(repo).execute('w12-doc3')).summary.id, 'w12-doc3');
    });

    test('DuplicateDoc tạo nháp ở cuối tuần đích', () async {
      final copy = _data(await DuplicateDocUseCase(repo).execute('w12-doc1', targetWeek: 13));
      expect(copy.summary.id, 'w13-doc1');
      expect(copy.summary.status, DocStatus.draft);
      expect(copy.summary.title, endsWith('(bản sao)'));
    });

    test('WatchWeeklyDocsChanges phát DocumentsChanged sau mỗi lần ghi của admin', () async {
      final changes = <WeeklyDocsChange>[];
      final sub = WatchWeeklyDocsChangesUseCase(repo).execute().listen(changes.add);
      await UnpublishDocUseCase(repo).execute('w12-doc2');
      await pumpEventQueue();
      expect(changes.whereType<DocumentsChanged>().map((c) => c.docId), ['w12-doc2']);
      await sub.cancel();
    });
  });

  test('UseCase không truyền repository thì lấy từ service locator', () async {
    registerSingleton<WeeklyDocsRepository>(repo);
    addTearDown(resetSingletons);
    expect(_data(await GetWeeksUseCase().execute()).currentWeekNumber, 12);
  });
}

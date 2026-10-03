import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/di/service_locator.dart';
import 'package:frontend/core/errors/result.dart';
import 'package:frontend/features/weekly_docs/data/repositories/fake_weekly_docs_repository.dart';
import 'package:frontend/features/weekly_docs/domain/entities/doc_status.dart';
import 'package:frontend/features/weekly_docs/domain/entities/weekly_doc.dart';
import 'package:frontend/features/weekly_docs/domain/repositories/weekly_docs_repository.dart';
import 'package:frontend/features/weekly_docs/domain/rules/doc_templates.dart';
import 'package:frontend/features/weekly_docs/presentation/cubits/admin_docs_cubit.dart';
import 'package:frontend/features/weekly_docs/presentation/cubits/doc_complete_cubit.dart';
import 'package:frontend/features/weekly_docs/presentation/cubits/doc_creator_cubit.dart';
import 'package:frontend/features/weekly_docs/presentation/cubits/doc_reader_cubit.dart';
import 'package:frontend/features/weekly_docs/presentation/cubits/ui_state.dart';
import 'package:frontend/features/weekly_docs/presentation/cubits/weeks_cubit.dart';

void main() {
  late FakeWeeklyDocsRepository repo;

  setUp(() {
    repo = FakeWeeklyDocsRepository(latency: Duration.zero);
    registerSingleton<WeeklyDocsRepository>(repo);
  });
  tearDown(resetSingletons);

  group('WeeksCubit', () {
    test('chọn tuần hiện tại, hiện các tuần đã mở + tuần khoá kế tiếp', () async {
      final cubit = WeeksCubit();
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.selectedWeek, 12);
      expect(cubit.state.visibleWeeks.map((w) => w.number), [10, 11, 12, 13]);
      expect(cubit.state.entries.map((e) => e.summary.id), ['w12-doc1', 'w12-doc2']);
    });

    test('học xong ở màn đọc thì thẻ tài liệu cập nhật theo', () async {
      final cubit = WeeksCubit();
      addTearDown(cubit.close);
      await cubit.load();
      await repo.completeDoc('w12-doc2');
      await pumpEventQueue();
      expect(cubit.state.entries.firstWhere((e) => e.summary.id == 'w12-doc2').progress.completed, isTrue);
    });
  });

  group('DocReaderCubit', () {
    test('mở lại đúng section đang dở và ghi lại kiểu xem', () async {
      final cubit = DocReaderCubit(docId: 'w12-doc1');
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.slides[cubit.state.index].sectionIndex, 1);
      cubit.setView(DocViewMode.doc);
      await pumpEventQueue();
      final reopened = await repo.getLearnerDoc('w12-doc1');
      expect((reopened as Success).data.progress.lastView, DocViewMode.doc);
    });

    test('hoàn thành trả kết quả kèm tài liệu kế tiếp trong tuần', () async {
      final cubit = DocReaderCubit(docId: 'w12-doc1');
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.complete();
      final completion = cubit.state.completion;
      expect(completion?.result.completedNow, isTrue);
      expect(completion?.nextDoc?.id, 'w12-doc2');
    });

    test('admin xem trước: không ghi tiến độ, "Hoàn thành" chỉ yêu cầu đóng màn', () async {
      final cubit = DocReaderCubit(docId: 'w12-doc3', isAdminPreview: true);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.ready);
      await cubit.complete();
      expect(cubit.state.closeRequests, 1);
      expect(cubit.state.completion, isNull);
    });

    test('tài liệu không tồn tại: trạng thái lỗi kèm thông báo của máy chủ', () async {
      final cubit = DocReaderCubit(docId: 'khong-co');
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.errorMessage, isNotEmpty);
    });
  });

  test('DocCompleteCubit lưu từ vựng một lần', () async {
    final cubit = DocCompleteCubit();
    addTearDown(cubit.close);
    await cubit.saveVocab('w12-doc1');
    expect(cubit.state.savedCount, greaterThan(0));
    expect(cubit.state.isSaving, isFalse);
  });

  group('AdminDocsCubit', () {
    test('lần đầu lọc theo tuần hiện tại; lọc theo trạng thái và tên không dấu', () async {
      final cubit = AdminDocsCubit();
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.week, 12);
      expect(cubit.state.visibleDocs.map((d) => d.id), ['w12-doc1', 'w12-doc2', 'w12-doc3']);
      cubit.toggleStatus(DocStatus.draft, selected: true);
      expect(cubit.state.visibleDocs.map((d) => d.id), ['w12-doc3']);
      cubit
        ..toggleStatus(DocStatus.draft, selected: false)
        ..setQuery('opinion');
      expect(cubit.state.visibleDocs.map((d) => d.id), ['w12-doc2']);
      // Gõ không dấu vẫn tìm được "Tài liệu ôn tập".
      cubit
        ..setWeek(null)
        ..setQuery('on tap');
      expect(cubit.state.visibleDocs.map((d) => d.id), ['w11-doc1', 'w11-doc2', 'w11-doc3', 'w10-doc1', 'w10-doc2']);
    });

    test('xoá nháp: thông báo kèm hoàn tác, danh sách tự tải lại', () async {
      final cubit = AdminDocsCubit();
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.delete('w12-doc3');
      await pumpEventQueue();
      expect(cubit.state.notice?.undoDocId, 'w12-doc3');
      expect(cubit.state.docs.any((d) => d.id == 'w12-doc3'), isFalse);
      await cubit.undoDelete('w12-doc3');
      await pumpEventQueue();
      expect(cubit.state.docs.any((d) => d.id == 'w12-doc3'), isTrue);
    });

    test('xoá tài liệu đã xuất bản: báo lỗi của máy chủ, không có hoàn tác', () async {
      final cubit = AdminDocsCubit();
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.delete('w12-doc1');
      expect(cubit.state.notice?.undoDocId, isNull);
      expect(cubit.state.notice?.message, contains('Gỡ'));
    });
  });

  group('DocCreatorCubit', () {
    test('tạo mới: gợi ý tuần hiện tại + số thứ tự kế tiếp, kiểm tra tên trước khi tạo nháp', () async {
      final cubit = DocCreatorCubit(initialWeek: 0, autosaveDelay: Duration.zero);
      addTearDown(cubit.close);
      await cubit.start();
      expect(cubit.state.weekText, '12');
      expect(cubit.state.orderText, '4');

      await cubit.forward();
      expect(cubit.state.step, 1);
      expect(cubit.state.titleError, isNotNull);

      cubit.setTitle('Listening: Map labelling');
      await cubit.forward();
      expect(cubit.state.step, 2);
      expect(cubit.state.record?.summary.id, 'w12-doc4');
    });

    test('sửa nội dung thì tự lưu nháp và tăng version', () async {
      final cubit = DocCreatorCubit(docId: 'w12-doc3', initialWeek: 0, autosaveDelay: Duration.zero);
      addTearDown(cubit.close);
      await cubit.start();
      expect(cubit.state.step, 2);
      final version = cubit.state.version;
      cubit.addBlock('paragraph');
      await pumpEventQueue();
      await cubit.saveNow();
      expect(cubit.state.saveState, SaveState.saved);
      expect(cubit.state.version, greaterThan(version));
    });

    test('xung đột version: hỏi admin, "Tải bản mới" lấy bản trên máy chủ', () async {
      final cubit = DocCreatorCubit(docId: 'w12-doc3', initialWeek: 0, autosaveDelay: const Duration(hours: 1));
      addTearDown(cubit.close);
      await cubit.start();
      // Người khác lưu trước.
      final other = (await repo.getAdminDoc('w12-doc3') as Success).data;
      await repo.saveDraft('w12-doc3', content: other.content, version: other.version);

      cubit.addBlock('paragraph');
      await cubit.saveNow();
      expect(cubit.state.conflictMessage, isNotNull);
      await cubit.resolveConflict(reload: true);
      expect(cubit.state.conflictMessage, isNull);
      expect(cubit.state.version, other.version + 1);
    });

    test('áp dụng JSON lỗi thì giữ nội dung cũ; JSON hợp lệ thì thay nội dung', () async {
      final cubit = DocCreatorCubit(docId: 'w12-doc3', initialWeek: 0, autosaveDelay: const Duration(hours: 1));
      addTearDown(cubit.close);
      await cubit.start();
      final title = cubit.state.doc.title;
      expect(cubit.applyJsonText('{ không phải json'), isFalse);
      expect(cubit.state.jsonCheck?.isValid, isFalse);
      expect(cubit.state.doc.title, title);

      cubit.setJsonMode(on: true);
      final text = cubit.prettyJson().replaceFirst(title, 'Tên mới từ JSON');
      expect(cubit.applyJsonText(text), isTrue);
      expect(cubit.state.doc.title, 'Tên mới từ JSON');
    });

    test('xuất bản bản hợp lệ, rồi "Tạo tài liệu tiếp theo" soạn lại từ đầu', () async {
      final cubit = DocCreatorCubit(initialWeek: 12, autosaveDelay: const Duration(hours: 1));
      addTearDown(cubit.close);
      await cubit.start();
      final sample = deepCopyJson(sampleReadingDoc()) as Map<String, dynamic>
        ..['title'] = 'Reading: Bài mẫu';
      cubit.applyTemplate(templateById('import'));
      cubit.setTitle('Reading: Bài mẫu');
      await cubit.forward();
      expect(cubit.applyJsonText(jsonEncode(sample)), isTrue);
      await cubit.forward();
      expect(cubit.state.step, 3);
      expect(cubit.state.validation.isValid, isTrue);
      await cubit.forward();
      expect(cubit.state.published, isTrue);
      expect(cubit.state.record?.status, DocStatus.published);

      await cubit.startOver(12);
      expect(cubit.state.step, 1);
      expect(cubit.state.published, isFalse);
      expect(cubit.state.record, isNull);
      expect(cubit.state.orderText, '5');
    });
  });
}

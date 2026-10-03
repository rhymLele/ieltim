import 'dart:async';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/admin_doc.dart';
import '../../domain/entities/doc_json.dart';
import '../../domain/entities/doc_progress.dart';
import '../../domain/entities/doc_status.dart';
import '../../domain/entities/doc_summary.dart';
import '../../domain/entities/learner_doc.dart';
import '../../domain/entities/learning_results.dart';
import '../../domain/entities/week_info.dart';
import '../../domain/entities/weekly_doc.dart';
import '../../domain/entities/weekly_docs_change.dart';
import '../../domain/entities/weekly_docs_exceptions.dart';
import '../../domain/repositories/weekly_docs_repository.dart';
import '../../domain/rules/doc_templates.dart';
import '../../domain/rules/doc_validator.dart';
import '../../domain/rules/html_file.dart';

/// Repository giả (in-memory) để xem trước UI không cần BE:
/// `flutter run --dart-define=WEEKLY_DOCS_FAKE=true`. Lỗi trả về cùng mã với BE.
class FakeWeeklyDocsRepository implements WeeklyDocsRepository {
  FakeWeeklyDocsRepository({DateTime? now, this.latency = const Duration(milliseconds: 150)}) {
    final today = now ?? DateTime.now();
    final monday = DateTime(today.year, today.month, today.day).subtract(Duration(days: today.weekday - 1));
    for (final number in [10, 11, 12, 13]) {
      _weeks.add(WeekInfo(number: number, start: monday.add(Duration(days: (number - 12) * 7))));
    }
    _docs.add(_FakeDoc(json: deepCopyJson(sampleReadingDoc()) as Map<String, dynamic>, status: DocStatus.published, publishedAt: today));
    final writing = buildDocJson(week: 12, order: 2, title: 'Writing Task 2: Opinion essay', templateId: 'writing-task2', skill: 'writing');
    (writing['meta'] as Map<String, dynamic>)['defaultView'] = 'doc';
    _docs.add(_FakeDoc(json: writing, status: DocStatus.published, publishedAt: today));
    _docs.add(_FakeDoc(json: buildDocJson(week: 12, order: 3, title: 'Speaking Part 2: Describe a place', templateId: 'speaking-part2', skill: 'speaking')));
    for (final week in [10, 11]) {
      for (var order = 1; order <= (week == 10 ? 2 : 3); order++) {
        final json = deepCopyJson(sampleReadingDoc()) as Map<String, dynamic>
          ..['id'] = 'w$week-doc$order'
          ..['week'] = week
          ..['order'] = order
          ..['title'] = 'Tài liệu ôn tập $order';
        _docs.add(_FakeDoc(json: json, status: DocStatus.published, publishedAt: today.subtract(Duration(days: (12 - week) * 7))));
        _progress['w$week-doc$order'] = DocProgress(seenSections: const {0, 1, 2, 3}, completed: true, completedAt: today.subtract(const Duration(days: 8)));
      }
    }
    _progress['w12-doc1'] = const DocProgress(seenSections: {0, 1}, lastSection: 1);
  }

  /// Độ trễ giả lập mạng.
  final Duration latency;

  final List<WeekInfo> _weeks = [];
  final List<_FakeDoc> _docs = [];
  final List<_FakeDoc> _deleted = [];
  final Map<String, DocProgress> _progress = {};
  final Set<String> _savedWords = {};
  final _changes = StreamController<WeeklyDocsChange>.broadcast();
  int _stageDone = 2;

  @override
  Stream<WeeklyDocsChange> get changes => _changes.stream;

  // ───────────────────────────── Người học ─────────────────────────────

  @override
  Future<Result<WeekList>> getWeeks() => _run(() {
        final open = _weeks.where((w) => !w.isLocked);
        // Như BE: tuần khoá không lộ số tài liệu.
        final weeks = [
          for (final w in _weeks)
            WeekInfo(
              number: w.number,
              start: w.start,
              stageGoal: w.stageGoal,
              docTotal: w.isLocked ? 0 : _published(w.number).length,
              docDone: w.isLocked ? 0 : _published(w.number).where((d) => _progress[d.id]?.completed ?? false).length,
            ),
        ];
        return WeekList(weeks: weeks, currentWeek: open.isEmpty ? null : open.last.number);
      });

  @override
  Future<Result<List<WeekDocEntry>>> getWeekDocs(int week) => _run(() {
        final info = _weekOrThrow(week);
        if (info.isLocked) throw ServerException('Tuần $week chưa mở.', code: 'WEEK_LOCKED', statusCode: 403);
        return [
          for (final d in _published(week)) WeekDocEntry(summary: d.toSummary(), progress: _progress[d.id] ?? const DocProgress()),
        ];
      });

  @override
  Future<Result<LearnerDoc>> getLearnerDoc(String id) => _run(() {
        final d = _visible(id);
        return LearnerDoc(summary: d.toSummary(), doc: d.doc, progress: _progress[id] ?? const DocProgress());
      });

  @override
  Future<Result<DocProgress>> saveProgress(String id, {required int sectionIndex, DocViewMode? view}) => _run(() {
        _visible(id);
        final progress = (_progress[id] ?? const DocProgress()).withSection(sectionIndex, view: view);
        _progress[id] = progress;
        _changes.add(ProgressChanged(id, progress));
        return progress;
      });

  @override
  Future<Result<QuizFeedback>> answerQuiz(String id, {required String blockKey, required int option}) => _run(() {
        final doc = _visible(id).doc;
        for (var si = 0; si < doc.sections.length; si++) {
          final blocks = doc.sections[si].blocks;
          for (var bi = 0; bi < blocks.length; bi++) {
            final block = blocks[bi];
            if (block is QuizBlock && (block.id ?? '$si-$bi') == blockKey) {
              _progress[id] = (_progress[id] ?? const DocProgress()).withAnswer(blockKey, option);
              return QuizFeedback(correct: option == block.answer, answer: block.answer, explain: block.explain);
            }
          }
        }
        throw const ServerException('Không tìm thấy câu hỏi này.', code: 'BLOCK_NOT_FOUND', statusCode: 404);
      });

  @override
  Future<Result<CompleteResult>> completeDoc(String id) => _run(() {
        final d = _visible(id);
        final before = _progress[id] ?? const DocProgress();
        final completedNow = !before.completed;
        _progress[id] = before.completedOn(DateTime.now(), d.doc.sections.length);
        const goal = 5;
        var justPassed = false;
        if (completedNow) {
          justPassed = _stageDone < goal && _stageDone + 1 >= goal;
          _stageDone++;
        }
        _changes.add(DocCompleted(id));
        return CompleteResult(completedNow: completedNow, stageDone: _stageDone, stageGoal: goal, justPassedGate: justPassed, streak: 5);
      });

  @override
  Future<Result<VocabSaveResult>> saveVocabFromDoc(String id) => _run(() {
        final words = _visible(id).doc.allVocab.map((v) => v.word.trim().toLowerCase()).toSet();
        final added = words.where(_savedWords.add).length;
        return VocabSaveResult(added: added, existed: words.length - added, total: _savedWords.length);
      });

  // ───────────────────────────── Admin ─────────────────────────────

  @override
  Future<Result<List<DocSummary>>> getAdminDocs() => _run(() {
        final sorted = [..._docs]..sort((a, b) => a.week != b.week ? b.week.compareTo(a.week) : a.order.compareTo(b.order));
        return [for (final d in sorted) d.toSummary()];
      });

  @override
  Future<Result<AdminDoc>> getAdminDoc(String id) => _run(() => _byId(id).toAdminDoc());

  @override
  Future<Result<AdminDoc>> createDraft({required int week, required int order, required DocJson content}) => _run(() {
        _weekOrThrow(week);
        if (_docs.any((d) => d.week == week && d.order == order)) {
          throw ServerException('Tuần $week đã có Tài liệu $order.', code: 'DOC_ORDER_TAKEN', statusCode: 409);
        }
        final json = deepCopyJson(content.value) as Map<String, dynamic>
          ..['id'] = 'w$week-doc$order'
          ..['week'] = week
          ..['order'] = order;
        final doc = _FakeDoc(json: json);
        _docs.add(doc);
        return _changed(doc);
      });

  @override
  Future<Result<AdminDoc>> saveDraft(String id, {required DocJson content, required int version}) => _run(() {
        final doc = _byId(id);
        if (doc.status == DocStatus.archived) {
          throw const ServerException('Tài liệu đã gỡ. Khôi phục để sửa tiếp.', code: 'DOC_EDIT_ARCHIVED', statusCode: 409);
        }
        if (doc.version != version) {
          throw VersionConflictException('Admin vừa sửa tài liệu này lúc ${_hourMinute(doc.updatedAt)}.', current: doc.toAdminDoc());
        }
        doc
          ..json = (deepCopyJson(content.value) as Map<String, dynamic>
            ..['id'] = doc.id
            ..['week'] = doc.week
            ..['order'] = doc.order)
          ..version += 1
          ..updatedAt = DateTime.now();
        return _changed(doc);
      });

  @override
  Future<Result<AdminDoc>> publish(String id, {DateTime? at}) => _run(() {
        final doc = _byId(id);
        final validation = validateDocJson(doc.json);
        if (!validation.isValid) {
          throw InvalidContentException('Tài liệu còn ${validation.errors.length} lỗi cần sửa trước khi xuất bản.', validation: validation);
        }
        if (at != null && !at.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
          throw const ServerException('Giờ xuất bản phải sau hiện tại ít nhất 5 phút.', code: 'DOC_SCHEDULE_PAST', statusCode: 422);
        }
        if (at != null) {
          doc
            ..status = DocStatus.scheduled
            ..publishAt = at;
        } else {
          doc
            ..status = DocStatus.published
            ..publishedAt = DateTime.now()
            ..publishAt = null;
        }
        return _changed(doc);
      });

  /// Bản giả sửa thẳng bản phát hành khi lưu nên không còn gì để áp dụng.
  @override
  Future<Result<AdminDoc>> release(String id) => _run(() => _byId(id).toAdminDoc());

  @override
  Future<Result<AdminDoc>> unschedule(String id) => _transition(id, DocStatus.draft, clearSchedule: true);

  @override
  Future<Result<AdminDoc>> unpublish(String id) => _transition(id, DocStatus.archived);

  @override
  Future<Result<AdminDoc>> restore(String id) => _transition(id, DocStatus.draft);

  @override
  Future<Result<void>> delete(String id) => _run(() {
        final doc = _byId(id);
        if (doc.publishedAt != null || doc.status != DocStatus.draft) {
          throw const ServerException('Tài liệu đã từng xuất bản nên không xoá được. Hãy dùng "Gỡ".', code: 'DOC_DELETE_NOT_ALLOWED', statusCode: 409);
        }
        _docs.remove(doc);
        _deleted.add(doc);
        _changes.add(DocumentsChanged(id));
      });

  @override
  Future<Result<AdminDoc>> undoDelete(String id) => _run(() {
        final doc = _deleted.lastWhere((d) => d.id == id, orElse: () => throw const ServerException('Không tìm thấy tài liệu.', code: 'DOC_NOT_FOUND'));
        if (_docs.any((d) => d.week == doc.week && d.order == doc.order)) {
          throw ServerException('Tuần ${doc.week} đã có Tài liệu ${doc.order}.', code: 'DOC_ORDER_TAKEN', statusCode: 409);
        }
        _deleted.remove(doc);
        _docs.add(doc);
        return _changed(doc);
      });

  @override
  Future<Result<AdminDoc>> duplicate(String id, {required int targetWeek}) => _run(() {
        final source = _byId(id);
        _weekOrThrow(targetWeek);
        final orders = _docs.where((d) => d.week == targetWeek).map((d) => d.order);
        final order = orders.isEmpty ? 1 : orders.reduce((a, b) => a > b ? a : b) + 1;
        final json = deepCopyJson(source.json) as Map<String, dynamic>
          ..['week'] = targetWeek
          ..['order'] = order
          ..['id'] = 'w$targetWeek-doc$order'
          ..['title'] = '${source.title} (bản sao)';
        final doc = _FakeDoc(json: json);
        _docs.add(doc);
        return _changed(doc);
      });

  // ───────────────────────────── Nội bộ ─────────────────────────────

  Future<Result<T>> _run<T>(T Function() action) async {
    await Future<void>.delayed(latency);
    try {
      return Success(action());
    } on AppException catch (e) {
      return Failure(e);
    }
  }

  Future<Result<AdminDoc>> _transition(String id, DocStatus to, {bool clearSchedule = false}) => _run(() {
        final doc = _byId(id)..status = to;
        if (clearSchedule) doc.publishAt = null;
        return _changed(doc);
      });

  AdminDoc _changed(_FakeDoc doc) {
    doc.updatedAt = DateTime.now();
    _changes.add(DocumentsChanged(doc.id));
    return doc.toAdminDoc();
  }

  WeekInfo _weekOrThrow(int week) => _weeks.firstWhere(
        (w) => w.number == week,
        orElse: () => throw ServerException('Chưa có Tuần $week.', code: 'WEEK_NOT_FOUND', statusCode: 404),
      );

  _FakeDoc _byId(String id) =>
      _docs.firstWhere((d) => d.id == id, orElse: () => throw const ServerException('Không tìm thấy tài liệu.', code: 'DOC_NOT_FOUND', statusCode: 404));

  _FakeDoc _visible(String id) {
    final doc = _byId(id);
    final week = _weekOrThrow(doc.week);
    if (doc.status == DocStatus.archived) throw const ServerException('Tài liệu này đã được gỡ.', code: 'DOC_UNPUBLISHED', statusCode: 404);
    if (doc.status != DocStatus.published || week.isLocked) {
      throw const ServerException('Không tìm thấy tài liệu hoặc tài liệu đã được gỡ.', code: 'DOC_NOT_FOUND', statusCode: 404);
    }
    return doc;
  }

  List<_FakeDoc> _published(int week) =>
      _docs.where((d) => d.week == week && d.status == DocStatus.published).toList()..sort((a, b) => a.order.compareTo(b.order));

  static String _hourMinute(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _FakeDoc {
  _FakeDoc({required this.json, this.status = DocStatus.draft, this.publishedAt}) : updatedAt = DateTime.now();

  Map<String, dynamic> json;
  DocStatus status;
  int version = 1;
  DateTime updatedAt;
  DateTime? publishedAt;
  DateTime? publishAt;

  String get id => json['id'] as String? ?? '';
  int get week => json['week'] as int? ?? 0;
  int get order => json['order'] as int? ?? 0;
  String get title => json['title'] as String? ?? '';
  WeeklyDoc get doc => WeeklyDoc.fromJson(json);

  DocSummary toSummary() {
    final d = doc;
    return DocSummary(
      id: id,
      week: week,
      order: order,
      title: title,
      skill: d.meta.skill,
      template: d.template,
      defaultView: d.meta.defaultView,
      allowedViews: d.meta.allowedViews,
      sectionCount: d.sections.length,
      estimatedMinutes: d.estimatedMinutes,
      version: version,
      status: status,
      publishAt: publishAt,
      publishedAt: publishedAt,
      updatedAt: updatedAt,
      updatedBy: 'Admin',
      htmlFileName: d.htmlFileName,
      htmlSize: utf8Length(d.html ?? ''),
    );
  }

  AdminDoc toAdminDoc() => AdminDoc(summary: toSummary(), content: DocJson(deepCopyJson(json) as Map<String, dynamic>));
}

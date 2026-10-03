// fake_weekly_docs_repository.dart — Repository giả (in-memory) cho Tài liệu theo tuần.
// Dùng khi xem trước UI không có BE: flutter run --dart-define=WEEKLY_DOCS_FAKE=true

import '../domain/doc_templates.dart';
import '../domain/doc_validator.dart';
import '../domain/weekly_doc.dart';
import 'weekly_docs_repository.dart';

class FakeWeeklyDocsRepository extends WeeklyDocsRepository {
  FakeWeeklyDocsRepository() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    for (final n in [10, 11, 12, 13]) {
      _weeks.add(WeekInfo(number: n, start: monday.add(Duration(days: (n - 12) * 7))));
    }
    _docs.add(DocRecord(json: deepCopyJson(sampleReadingDoc()), status: DocStatus.published, publishedAt: now.subtract(const Duration(days: 1))));
    final writing = buildDocJson(week: 12, order: 2, title: 'Writing Task 2: Opinion essay', templateId: 'writing-task2', skill: 'writing');
    (writing['meta'] as Map)['defaultView'] = 'doc';
    _docs.add(DocRecord(json: writing, status: DocStatus.published, publishedAt: now));
    _docs.add(DocRecord(
      json: buildDocJson(week: 12, order: 3, title: 'Speaking Part 2: Describe a place', templateId: 'speaking-part2', skill: 'speaking'),
    ));
    for (final w in [10, 11]) {
      for (var o = 1; o <= (w == 10 ? 2 : 3); o++) {
        final j = deepCopyJson(sampleReadingDoc())
          ..['id'] = 'w$w-doc$o'
          ..['week'] = w
          ..['order'] = o
          ..['title'] = 'Tài liệu ôn tập $o';
        _docs.add(DocRecord(json: j, status: DocStatus.published, publishedAt: now.subtract(Duration(days: (12 - w) * 7))));
        _progress[j['id'] as String] = DocProgress()
          ..completedAt = now.subtract(const Duration(days: 8))
          ..seenSections.addAll([0, 1, 2, 3]);
      }
    }
    _progress['w12-doc1'] = DocProgress()
      ..seenSections.addAll([0, 1])
      ..lastSection = 1;
  }

  final List<WeekInfo> _weeks = [];
  final List<DocRecord> _docs = [];
  final Map<String, DocProgress> _progress = {};
  final Set<String> _savedWords = {};
  int _stageDone = 2;
  final int _streak = 5;

  // ───────────────────────────── User ─────────────────────────────

  @override
  List<WeekInfo> get weeks => List.unmodifiable(_weeks);
  @override
  int get currentWeekNumber => _weeks.lastWhere((w) => !w.isLocked, orElse: () => _weeks.first).number;

  @override
  Future<void> loadWeeks() async {}

  @override
  Future<void> loadWeekDocs(int week) async {}

  @override
  Future<void> loadAdminDocs() async {}

  @override
  Future<DocRecord> loadAdminDoc(String id) async => byId(id) ?? (throw const RepoException('DOC_NOT_FOUND', 'Không tìm thấy tài liệu.'));
  @override
  WeekInfo weekOf(int number) => _weeks.firstWhere((w) => w.number == number);
  int get stageDone => _stageDone;
  int get stageGoal => weekOf(currentWeekNumber).stageGoal;
  int get streak => _streak;
  int get savedWordCount => _savedWords.length;

  @override
  List<DocRecord> publishedDocs(int week) {
    final wk = weekOf(week);
    if (wk.isLocked) return const [];
    return _docs.where((d) => d.week == week && d.status == DocStatus.published).toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  DocProgress progressOf(String id) => _progress.putIfAbsent(id, DocProgress.new);

  @override
  Future<WeeklyDoc> loadDoc(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final r = _docs.where((d) => d.id == id && d.status == DocStatus.published);
    if (r.isEmpty) throw const RepoException('DOC_NOT_FOUND', 'Không tìm thấy tài liệu hoặc tài liệu đã được gỡ.');
    return r.first.doc;
  }

  @override
  void saveProgress(String id, {required int sectionIndex, DocViewMode? view}) {
    final p = progressOf(id)
      ..seenSections.add(sectionIndex)
      ..lastSection = sectionIndex;
    if (view != null) p.lastView = view;
    notifyListeners();
  }

  @override
  void answerQuiz(String id, String key, int option) {
    progressOf(id).answers[key] = option;
    notifyListeners();
  }

  @override
  Future<CompleteResult> complete(String id, int sectionCount) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final p = progressOf(id);
    final now = p.completedAt == null;
    var justPassed = false;
    if (now) {
      p.completedAt = DateTime.now();
      p.seenSections.addAll(List.generate(sectionCount, (i) => i));
      final before = _stageDone;
      _stageDone++;
      justPassed = before < stageGoal && _stageDone >= stageGoal;
    }
    notifyListeners();
    return CompleteResult(completedNow: now, stageDone: _stageDone, stageGoal: stageGoal, justPassedGate: justPassed, streak: _streak);
  }

  /// Lưu từ vựng của tài liệu vào Sổ từ; trả số từ thêm mới.
  @override
  Future<int> saveVocabFrom(WeeklyDoc doc) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var added = 0;
    for (final v in doc.allVocab) {
      if (_savedWords.add(v.word.trim().toLowerCase())) added++;
    }
    notifyListeners();
    return added;
  }

  // ───────────────────────────── Admin ─────────────────────────────

  @override
  List<DocRecord> adminDocs({int? week, Set<DocStatus>? statuses, String query = ''}) {
    final q = foldVietnamese(query);
    return _docs
        .where((d) => week == null || d.week == week)
        .where((d) => statuses == null || statuses.isEmpty || statuses.contains(d.status))
        .where((d) => q.isEmpty || foldVietnamese(d.title).contains(q))
        .toList()
      ..sort((a, b) => a.week != b.week ? b.week.compareTo(a.week) : a.order.compareTo(b.order));
  }

  @override
  DocRecord? byId(String id) {
    final r = _docs.where((d) => d.id == id);
    return r.isEmpty ? null : r.first;
  }

  @override
  int nextOrder(int week) {
    final orders = _docs.where((d) => d.week == week).map((d) => d.order);
    return orders.isEmpty ? 1 : orders.reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  bool orderTaken(int week, int order, {String? exceptId}) => _docs.any((d) => d.week == week && d.order == order && d.id != exceptId);

  @override
  Future<DocRecord> createDraft(Map<String, dynamic> json) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final week = json['week'] as int;
    final order = json['order'] as int;
    if (!_weeks.any((w) => w.number == week)) throw RepoException('WEEK_NOT_FOUND', 'Chưa có Tuần $week. Tạo tuần trước.');
    if (orderTaken(week, order)) throw RepoException('DOC_ORDER_TAKEN', 'Tuần $week đã có Tài liệu $order.');
    json['id'] = 'w$week-doc$order';
    final r = DocRecord(json: deepCopyJson(json));
    _docs.add(r);
    notifyListeners();
    return r;
  }

  /// Lưu nháp. Sai version → DOC_VERSION_CONFLICT (409).
  @override
  Future<DocRecord> saveDraft(String id, Map<String, dynamic> json, {required int expectedVersion}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final r = byId(id) ?? (throw const RepoException('DOC_NOT_FOUND', 'Không tìm thấy tài liệu.'));
    if (r.status == DocStatus.archived) throw const RepoException('DOC_EDIT_ARCHIVED', 'Tài liệu đã gỡ. Khôi phục để sửa tiếp.');
    if (r.version != expectedVersion) {
      throw RepoException('DOC_VERSION_CONFLICT', '${r.updatedBy} vừa sửa tài liệu này lúc ${_hm(r.updatedAt)}.');
    }
    r
      ..json = deepCopyJson(json)
      ..version += 1
      ..updatedAt = DateTime.now();
    notifyListeners();
    return r;
  }

  @override
  Future<void> publish(String id, {DateTime? at}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final r = byId(id)!;
    final v = validateDocJson(r.json);
    if (!v.isValid) throw RepoException('DOC_INVALID_CONTENT', 'Tài liệu còn ${v.errors.length} lỗi cần sửa trước khi xuất bản.');
    if (at != null && at.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      r
        ..status = DocStatus.scheduled
        ..publishAt = at;
    } else if (at != null) {
      throw const RepoException('DOC_SCHEDULE_PAST', 'Giờ xuất bản phải sau hiện tại ít nhất 5 phút.');
    } else {
      r
        ..status = DocStatus.published
        ..publishedAt = DateTime.now()
        ..publishAt = null;
    }
    r.updatedAt = DateTime.now();
    notifyListeners();
  }

  /// Bản giả sửa thẳng bản phát hành khi lưu nháp nên không còn gì để áp dụng.
  @override
  Future<DocRecord> release(String id) async => byId(id)!;

  @override
  Future<void> unschedule(String id) async => _set(id, DocStatus.draft, clearSchedule: true);
  @override
  Future<void> unpublish(String id) async => _set(id, DocStatus.archived);
  @override
  Future<void> restore(String id) async => _set(id, DocStatus.draft);

  @override
  Future<void> delete(String id) async {
    final r = byId(id)!;
    if (r.everPublished || r.status != DocStatus.draft) {
      throw const RepoException('DOC_DELETE_NOT_ALLOWED', 'Tài liệu đã từng xuất bản nên không xoá được. Hãy dùng "Gỡ".');
    }
    _docs.remove(r);
    notifyListeners();
  }

  @override
  Future<void> undoDelete(DocRecord r) async {
    _docs.add(r);
    notifyListeners();
  }

  @override
  Future<DocRecord> duplicate(String id, int targetWeek) async {
    final src = byId(id)!;
    final order = nextOrder(targetWeek);
    final j = deepCopyJson(src.json)
      ..['week'] = targetWeek
      ..['order'] = order
      ..['id'] = 'w$targetWeek-doc$order'
      ..['title'] = '${src.title} (bản sao)';
    final r = DocRecord(json: j);
    _docs.add(r);
    notifyListeners();
    return r;
  }

  void _set(String id, DocStatus s, {bool clearSchedule = false}) {
    final r = byId(id)!;
    r
      ..status = s
      ..updatedAt = DateTime.now();
    if (clearSchedule) r.publishAt = null;
    notifyListeners();
  }

  static String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// api_weekly_docs_repository.dart — Repository gọi BE (backend/src/weekly-docs, xem README ở đó).
// Giữ cache để màn hình đọc đồng bộ; thao tác ghi gọi API rồi cập nhật cache + notifyListeners.
// Bản ghi admin giữ một instance cho mỗi id và cập nhật tại chỗ (màn soạn đang giữ tham chiếu).

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../domain/doc_templates.dart';
import '../domain/weekly_doc.dart';
import 'weekly_docs_repository.dart';

class ApiWeeklyDocsRepository extends WeeklyDocsRepository {
  ApiWeeklyDocsRepository([ApiClient? api]) : _api = api ?? ApiClient();

  final ApiClient _api;

  static const _admin = '/admin/weekly';
  static const _user = '/weekly';

  List<WeekInfo> _weeks = const [];
  int? _currentWeek;
  final Map<int, List<DocRecord>> _weekDocs = {};
  final Map<String, DocProgress> _progress = {};
  final Map<String, DocRecord> _adminRecords = {};

  /// Tuần của các tài liệu đã mở (tải lại danh sách tuần đó sau khi hoàn thành).
  final Map<String, int> _docWeek = {};

  // ───────────────────────────── Đọc (cache) ─────────────────────────────

  @override
  List<WeekInfo> get weeks => List.unmodifiable(_weeks);

  @override
  int get currentWeekNumber {
    if (_currentWeek != null) return _currentWeek!;
    final open = _weeks.where((w) => !w.isLocked);
    if (open.isNotEmpty) return open.last.number;
    return _weeks.isEmpty ? 0 : _weeks.first.number;
  }

  @override
  WeekInfo weekOf(int number) => _weeks.firstWhere((w) => w.number == number, orElse: () => WeekInfo(number: number, start: DateTime.now()));

  @override
  List<DocRecord> publishedDocs(int week) => List.unmodifiable(_weekDocs[week] ?? const <DocRecord>[]);

  @override
  DocProgress progressOf(String id) => _progress.putIfAbsent(id, DocProgress.new);

  @override
  List<DocRecord> adminDocs({int? week, Set<DocStatus>? statuses, String query = ''}) {
    final q = foldVietnamese(query);
    return _adminRecords.values
        .where((d) => week == null || d.week == week)
        .where((d) => statuses == null || statuses.isEmpty || statuses.contains(d.status))
        .where((d) => q.isEmpty || foldVietnamese(d.title).contains(q))
        .toList()
      ..sort((a, b) => a.week != b.week ? b.week.compareTo(a.week) : a.order.compareTo(b.order));
  }

  @override
  DocRecord? byId(String id) => _adminRecords[id];

  @override
  int nextOrder(int week) {
    final orders = _adminRecords.values.where((d) => d.week == week).map((d) => d.order);
    return orders.isEmpty ? 1 : orders.reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  bool orderTaken(int week, int order, {String? exceptId}) => _adminRecords.values.any((d) => d.week == week && d.order == order && d.id != exceptId);

  // ───────────────────────────── Tải ─────────────────────────────

  @override
  Future<void> loadWeeks() async {
    final data = asJsonMap(await _send(() => _api.get<dynamic>('$_user/weeks')));
    _currentWeek = data['currentWeek'] as int?;
    _weeks = [for (final w in data['data'] as List? ?? const []) _parseWeek(asJsonMap(w))];
    notifyListeners();
  }

  @override
  Future<void> loadWeekDocs(int week) async {
    final list = await _send(() => _api.get<dynamic>('$_user/weeks/$week/documents')) as List? ?? const [];
    _weekDocs[week] = [
      for (final raw in list)
        () {
          final j = asJsonMap(raw);
          _applyProgress(j['id'] as String, asJsonMap(j['progress']));
          return _parseRecord(j, status: DocStatus.published);
        }(),
    ];
    notifyListeners();
  }

  @override
  Future<void> loadAdminDocs() async {
    final data = asJsonMap(await _send(() => _api.get<dynamic>('$_admin/documents', queryParameters: {'pageSize': 1000})));
    final ids = <String>{};
    for (final raw in data['data'] as List? ?? const []) {
      ids.add(_upsertAdmin(_parseRecord(asJsonMap(raw))).id);
    }
    _adminRecords.removeWhere((id, _) => !ids.contains(id));
    notifyListeners();
  }

  @override
  Future<DocRecord> loadAdminDoc(String id) => _adminCall(() => _api.get<dynamic>('$_admin/documents/$id'));

  @override
  Future<WeeklyDoc> loadDoc(String id) async {
    final data = asJsonMap(await _send(() => _api.get<dynamic>('$_user/documents/$id')));
    _applyProgress(id, asJsonMap(data['progress']));
    if (data['week'] is int) _docWeek[id] = data['week'] as int;
    return WeeklyDoc.fromJson(data['content']);
  }

  // ───────────────────────────── Người dùng ─────────────────────────────

  @override
  void saveProgress(String id, {required int sectionIndex, DocViewMode? view}) {
    final p = progressOf(id)
      ..seenSections.add(sectionIndex)
      ..lastSection = sectionIndex;
    if (view != null) p.lastView = view;
    notifyListeners();
    _background(() => _api.put<dynamic>('$_user/documents/$id/progress', data: {'sectionIndex': sectionIndex, if (view != null) 'viewMode': view.name}));
  }

  @override
  void answerQuiz(String id, String key, int option) {
    progressOf(id).answers[key] = option;
    notifyListeners();
    _background(() => _api.post<dynamic>('$_user/documents/$id/quiz-answers', data: {'blockKey': key, 'option': option}));
  }

  @override
  Future<CompleteResult> complete(String id, int sectionCount) async {
    final data = asJsonMap(await _send(() => _api.post<dynamic>('$_user/documents/$id/complete')));
    final stage = asJsonMap(data['weekStage']);
    final p = progressOf(id)..seenSections.addAll(List.generate(sectionCount, (i) => i));
    p.completedAt ??= DateTime.now();
    notifyListeners();
    // Cập nhật số tài liệu đã học của tuần và tài liệu tiếp theo cho màn hoàn thành.
    final week = _docWeek[id];
    try {
      await Future.wait<void>([loadWeeks(), if (week != null) loadWeekDocs(week)]);
    } on RepoException catch (e) {
      debugPrint('weekly_docs: không tải lại được danh sách tuần: ${e.message}');
    }
    return CompleteResult(
      completedNow: data['completedNow'] == true,
      stageDone: stage['done'] as int? ?? 0,
      stageGoal: stage['goal'] as int? ?? 5,
      justPassedGate: stage['justPassedGate'] == true,
      streak: data['streak'] as int? ?? 0,
    );
  }

  @override
  Future<int> saveVocabFrom(WeeklyDoc doc) async {
    final data = asJsonMap(await _send(() => _api.post<dynamic>('$_user/vocab/from-document', data: {'documentId': doc.id})));
    return data['added'] as int? ?? 0;
  }

  // ───────────────────────────── Admin ─────────────────────────────

  @override
  Future<DocRecord> createDraft(Map<String, dynamic> json) => _adminCall(
        () => _api.post<dynamic>('$_admin/documents', data: {'week': json['week'], 'order': json['order'], 'content': json}),
      );

  @override
  Future<DocRecord> saveDraft(String id, Map<String, dynamic> json, {required int expectedVersion}) async {
    try {
      return await _adminCall(() => _api.put<dynamic>('$_admin/documents/$id', data: {'content': json, 'version': expectedVersion}));
    } on RepoException catch (e) {
      // 409: BE trả bản hiện tại → cập nhật bản ghi để màn soạn "Tải bản mới" / "Ghi đè" theo đúng version.
      final current = e.data is Map ? (e.data as Map)['current'] : null;
      if (e.code == 'DOC_VERSION_CONFLICT' && current is Map) {
        _upsertAdmin(_parseRecord(asJsonMap(current)));
        notifyListeners();
      }
      rethrow;
    }
  }

  @override
  Future<void> publish(String id, {DateTime? at}) => _adminCall(
        () => _api.post<dynamic>('$_admin/documents/$id/publish', data: {if (at != null) 'publishAt': at.toUtc().toIso8601String()}),
      );

  @override
  Future<DocRecord> release(String id) => _adminCall(() => _api.post<dynamic>('$_admin/documents/$id/release'));

  @override
  Future<void> unschedule(String id) => _adminCall(() => _api.delete<dynamic>('$_admin/documents/$id/schedule'));

  @override
  Future<void> unpublish(String id) => _adminCall(() => _api.post<dynamic>('$_admin/documents/$id/unpublish'));

  @override
  Future<void> restore(String id) => _adminCall(() => _api.post<dynamic>('$_admin/documents/$id/restore'));

  @override
  Future<void> delete(String id) async {
    await _send(() => _api.delete<dynamic>('$_admin/documents/$id'));
    _adminRecords.remove(id);
    notifyListeners();
  }

  @override
  Future<void> undoDelete(DocRecord r) => _adminCall(() => _api.post<dynamic>('$_admin/documents/${r.id}/undelete'));

  @override
  Future<DocRecord> duplicate(String id, int targetWeek) =>
      _adminCall(() => _api.post<dynamic>('$_admin/documents/$id/duplicate', data: {'targetWeek': targetWeek}));

  // ───────────────────────────── Nội bộ ─────────────────────────────

  /// Gọi API admin trả về một tài liệu → cập nhật cache.
  Future<DocRecord> _adminCall(Future<Response<dynamic>> Function() call) async {
    final r = _upsertAdmin(_parseRecord(asJsonMap(await _send(call))));
    notifyListeners();
    return r;
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw _toRepoException(e);
    }
  }

  /// Ghi tiến độ ở nền: lỗi mạng không chặn việc đọc.
  void _background(Future<Response<dynamic>> Function() call) {
    _send(call).catchError((Object e) {
      debugPrint('weekly_docs: ghi tiến độ thất bại: $e');
    });
  }

  RepoException _toRepoException(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (status == 401) return const RepoException('UNAUTHORIZED', 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.');
    if (body is Map) {
      final msg = body['message'];
      return RepoException(
        '${body['error'] ?? 'HTTP_$status'}',
        msg is List ? msg.join('\n') : '${msg ?? 'Có lỗi xảy ra, thử lại sau.'}',
        data: body['data'],
      );
    }
    return const RepoException('NETWORK_ERROR', 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.');
  }

  DocRecord _upsertAdmin(DocRecord r) {
    final cur = _adminRecords[r.id];
    if (cur == null) return _adminRecords[r.id] = r;
    cur.updateFrom(r);
    return cur;
  }

  WeekInfo _parseWeek(Map<String, dynamic> j) => WeekInfo(
        number: j['number'] as int,
        start: DateTime.parse(j['startDate'] as String),
        stageGoal: j['stageGoal'] as int? ?? 5,
        locked: j['state'] == 'locked',
        docTotal: j['docTotal'] as int?,
        docDone: j['docDone'] as int?,
      );

  /// Bản ghi từ API (danh sách: chỉ tóm tắt; chi tiết: kèm `content`).
  DocRecord _parseRecord(Map<String, dynamic> j, {DocStatus? status}) {
    final content = j['content'];
    final json = content is Map
        ? deepCopyJson(content) as Map<String, dynamic>
        : <String, dynamic>{
            'schemaVersion': 1,
            'id': j['id'],
            'week': j['week'],
            'order': j['order'],
            'title': j['title'],
            'template': j['template'],
            'meta': {'skill': j['skill'], 'defaultView': j['defaultView'], 'allowedViews': j['allowedViews']},
            'sections': <dynamic>[],
            if (j['htmlFileName'] != null) 'htmlFileName': j['htmlFileName'],
          };
    return DocRecord(
      json: json,
      hasContent: content is Map,
      status: status ?? DocStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => DocStatus.draft),
      version: j['version'] as int? ?? 1,
      updatedAt: _date(j['updatedAt']),
      publishedAt: _date(j['publishedAt']),
      publishAt: _date(j['publishAt']),
      updatedBy: j['updatedBy'] as String? ?? 'Admin',
      hasRevisionDraft: j['hasRevisionDraft'] == true,
      sectionCount: j['sectionCount'] as int?,
      estimatedMinutes: j['estimatedMinutes'] as int?,
    );
  }

  void _applyProgress(String id, Map<String, dynamic> j) {
    if (j.isEmpty) return;
    final p = progressOf(id);
    final seen = j['seenSections'];
    p.seenSections
      ..clear()
      ..addAll(seen is List ? seen.whereType<int>() : List.generate(j['seenCount'] as int? ?? 0, (i) => i));
    p.lastSection = j['lastSection'] as int? ?? 0;
    p.completedAt = j['completed'] == true ? (_date(j['completedAt']) ?? p.completedAt ?? DateTime.now()) : null;
    if (j['viewMode'] is String) p.lastView = DocViewMode.parse(j['viewMode']);
    final answers = j['quizAnswers'];
    if (answers is Map) {
      p.answers
        ..clear()
        ..addAll({for (final e in answers.entries) '${e.key}': (asJsonMap(e.value)['option'] as int? ?? 0)});
    }
  }

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
}

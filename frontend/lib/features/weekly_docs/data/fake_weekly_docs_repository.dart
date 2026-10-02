import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/block_parser.dart';
import '../domain/models/weekly_doc.dart';
import 'weekly_docs_repository.dart';

/// Repository giả: đọc JSON từ assets, lưu trạng thái trong bộ nhớ.
class FakeWeeklyDocsRepository implements WeeklyDocsRepository {
  List<WeeklyDoc> _allDocs = [];
  final Set<String> _completed = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/weekly_docs_sample.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _allDocs = list.map((e) => parseWeeklyDoc(e)).toList();
    } catch (_) {
      _allDocs = [];
    }
    _loaded = true;
  }

  // ─── User ──────────────────────────────────────────────────────────────────

  @override
  Future<List<int>> getWeeks() async {
    await _ensureLoaded();
    final weeks = _allDocs
        .where((d) => d.meta.status == DocStatus.published)
        .map((d) => d.meta.week)
        .toSet();
    return weeks.toList()..sort();
  }

  @override
  Future<List<WeeklyDoc>> getDocsForWeek(int week) async {
    await _ensureLoaded();
    final docs = _allDocs
        .where((d) => d.meta.week == week && d.meta.status == DocStatus.published)
        .toList()
      ..sort((a, b) => a.meta.order.compareTo(b.meta.order));
    return docs;
  }

  @override
  Future<WeeklyDoc?> getDocById(String id) async {
    await _ensureLoaded();
    for (final doc in _allDocs) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  @override
  Future<void> markCompleted(String docId) async {
    _completed.add(docId);
  }

  @override
  Future<void> markIncomplete(String docId) async {
    _completed.remove(docId);
  }

  @override
  Future<bool> isCompleted(String docId) async {
    return _completed.contains(docId);
  }

  @override
  Future<WeekProgress> getWeekProgress(int week) async {
    await _ensureLoaded();
    final docs = _allDocs
        .where((d) => d.meta.week == week && d.meta.status == DocStatus.published)
        .toList();
    final completed = docs.where((d) => _completed.contains(d.id)).length;
    return WeekProgress(week: week, completed: completed, total: docs.length);
  }

  // ─── Admin ─────────────────────────────────────────────────────────────────

  @override
  Future<List<WeeklyDoc>> getAdminDocs({AdminDocFilter? filter}) async {
    await _ensureLoaded();
    var docs = List<WeeklyDoc>.from(_allDocs);

    if (filter != null) {
      if (filter.week != null) {
        docs = docs.where((d) => d.meta.week == filter.week).toList();
      }
      if (filter.status != null) {
        docs = docs.where((d) => d.meta.status == filter.status).toList();
      }
      if (filter.skill != null && filter.skill!.isNotEmpty) {
        docs = docs.where((d) => d.meta.skills.contains(filter.skill)).toList();
      }
      if (filter.search != null && filter.search!.trim().isNotEmpty) {
        final q = filter.search!.toLowerCase();
        docs = docs.where((d) => d.meta.title.toLowerCase().contains(q)).toList();
      }
    }

    docs.sort((a, b) {
      final w = a.meta.week.compareTo(b.meta.week);
      if (w != 0) return w;
      return a.meta.order.compareTo(b.meta.order);
    });
    return docs;
  }

  @override
  Future<List<int>> getAllWeeks() async {
    await _ensureLoaded();
    final weeks = _allDocs.map((d) => d.meta.week).toSet();
    return weeks.toList()..sort();
  }

  @override
  Future<WeeklyDoc> createDoc(WeeklyDoc doc) async {
    await _ensureLoaded();
    _allDocs.add(doc);
    return doc;
  }

  @override
  Future<WeeklyDoc> updateDoc(WeeklyDoc doc) async {
    await _ensureLoaded();
    final idx = _allDocs.indexWhere((d) => d.id == doc.id);
    if (idx == -1) throw Exception('Doc not found: ${doc.id}');
    final updated = doc.copyWith(
      meta: doc.meta.copyWith(version: _allDocs[idx].meta.version + 1),
    );
    _allDocs[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteDoc(String docId) async {
    await _ensureLoaded();
    final idx = _allDocs.indexWhere((d) => d.id == docId);
    if (idx == -1) return;
    final doc = _allDocs[idx];
    if (doc.meta.status != DocStatus.draft) {
      throw Exception('Cannot delete: doc is ${doc.meta.status.name}');
    }
    _allDocs.removeAt(idx);
  }

  @override
  Future<WeeklyDoc> publishDoc(String docId) async {
    await _ensureLoaded();
    final idx = _allDocs.indexWhere((d) => d.id == docId);
    if (idx == -1) throw Exception('Doc not found: $docId');
    final doc = _allDocs[idx];
    final updated = doc.copyWith(
      meta: doc.meta.copyWith(
        status: DocStatus.published,
        version: doc.meta.version + 1,
      ),
    );
    _allDocs[idx] = updated;
    return updated;
  }

  @override
  Future<WeeklyDoc> unpublishDoc(String docId) async {
    await _ensureLoaded();
    final idx = _allDocs.indexWhere((d) => d.id == docId);
    if (idx == -1) throw Exception('Doc not found: $docId');
    final doc = _allDocs[idx];
    if (doc.meta.status != DocStatus.published) {
      throw Exception('Can only unpublish PUBLISHED docs');
    }
    final updated = doc.copyWith(
      meta: doc.meta.copyWith(
        status: DocStatus.archived,
        version: doc.meta.version + 1,
      ),
    );
    _allDocs[idx] = updated;
    return updated;
  }

  @override
  Future<WeeklyDoc> restoreDoc(String docId) async {
    await _ensureLoaded();
    final idx = _allDocs.indexWhere((d) => d.id == docId);
    if (idx == -1) throw Exception('Doc not found: $docId');
    final doc = _allDocs[idx];
    if (doc.meta.status != DocStatus.archived) {
      throw Exception('Can only restore ARCHIVED docs');
    }
    final updated = doc.copyWith(
      meta: doc.meta.copyWith(
        status: DocStatus.draft,
        version: doc.meta.version + 1,
      ),
    );
    _allDocs[idx] = updated;
    return updated;
  }

  @override
  Future<WeeklyDoc> duplicateDoc(String docId, {int? targetWeek}) async {
    await _ensureLoaded();
    final src = _allDocs.firstWhere((d) => d.id == docId);
    final week = targetWeek ?? src.meta.week;
    final maxOrder = _allDocs
        .where((d) => d.meta.week == week)
        .map((d) => d.meta.order)
        .fold(0, (m, o) => o > m ? o : m);
    final newId = 'w${week}-doc${maxOrder + 1}';
    final newDoc = src.copyWith(
      id: newId,
      meta: src.meta.copyWith(
        title: '${src.meta.title} (bản sao)',
        week: week,
        order: maxOrder + 1,
        status: DocStatus.draft,
        version: 1,
        id: null,
      ),
    );
    _allDocs.add(newDoc);
    return newDoc;
  }

  @override
  String exportJson(WeeklyDoc doc) {
    return const JsonEncoder.withIndent('  ').convert(weeklyDocToMap(doc));
  }
}

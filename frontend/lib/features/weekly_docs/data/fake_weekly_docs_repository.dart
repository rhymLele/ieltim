import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/block_parser.dart';
import '../domain/models/weekly_doc.dart';
import 'weekly_docs_repository.dart';

/// Repository giả: đọc JSON từ assets, lưu trạng thái đã học trong bộ nhớ.
class FakeWeeklyDocsRepository implements WeeklyDocsRepository {
  List<WeeklyDoc> _allDocs = [];
  final Set<String> _completed = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/weekly_docs_sample.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _allDocs = list.map((e) => parseWeeklyDoc(e)).toList();
    _loaded = true;
  }

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
}

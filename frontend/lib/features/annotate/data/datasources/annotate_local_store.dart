import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/annotate/models.dart';
import '../../domain/entities/doc_annotations.dart';

/// Ghi chú một slide trên máy: [data] là bản đang dùng, [rev] / [base] là bản trên máy chủ lần đồng bộ trước
/// (để gửi kèm `rev` và gộp khi xung đột).
class StoredSlide {
  const StoredSlide({required this.data, this.rev = 0, this.base = const SlideAnnotations()});

  factory StoredSlide.fromJson(Map<String, dynamic> j) => StoredSlide(
        data: SlideAnnotations.fromJson(_map(j['data'])),
        rev: j['rev'] as int? ?? 0,
        base: SlideAnnotations.fromJson(_map(j['base'])),
      );

  final SlideAnnotations data;
  final int rev;
  final SlideAnnotations base;

  Map<String, dynamic> toJson() => {'data': data.toJson(), 'rev': rev, 'base': base.toJson()};
}

/// Highlight + ghi chú slide của một tài liệu lưu trên máy (`ann.{userId}.{docId}`).
class StoredDocAnnotations {
  const StoredDocAnnotations({this.highlights = const [], this.slides = const {}});

  factory StoredDocAnnotations.fromJson(Map<String, dynamic> j) => StoredDocAnnotations(
        highlights: [for (final h in (j['highlights'] as List? ?? const [])) TextHighlight.fromJson(_map(h))],
        slides: {for (final e in _map(j['slides']).entries) e.key: StoredSlide.fromJson(_map(e.value))},
      );

  final List<TextHighlight> highlights;
  final Map<String, StoredSlide> slides;

  DocAnnotations toEntity() => DocAnnotations(highlights: highlights, slides: {for (final e in slides.entries) e.key: e.value.data});

  Map<String, dynamic> toJson() => {
        'highlights': [for (final h in highlights) h.toJson()],
        'slides': {for (final e in slides.entries) e.key: e.value.toJson()},
      };
}

/// Thao tác chưa gửi được lên BE (hàng đợi `ann.queue.{userId}`).
sealed class PendingOp {
  const PendingOp(this.docId);

  factory PendingOp.fromJson(Map<String, dynamic> j) => switch (j['op']) {
        'putHighlight' => PutHighlightOp(j['docId'] as String, j['docVersion'] as int? ?? 0, TextHighlight.fromJson(_map(j['highlight']))),
        'deleteHighlight' => DeleteHighlightOp(j['docId'] as String, j['id'] as String),
        _ => PutSlideOp(j['docId'] as String, j['docVersion'] as int? ?? 0, j['slideKey'] as String),
      };

  final String docId;

  /// Thao tác sau cùng ghi đè thao tác trước cùng khoá (cùng highlight / cùng slide).
  String get key;

  Map<String, dynamic> toJson();
}

class PutHighlightOp extends PendingOp {
  const PutHighlightOp(super.docId, this.docVersion, this.highlight);

  final int docVersion;
  final TextHighlight highlight;

  @override
  String get key => 'h:$docId:${highlight.id}';

  @override
  Map<String, dynamic> toJson() => {'op': 'putHighlight', 'docId': docId, 'docVersion': docVersion, 'highlight': highlight.toJson()};
}

class DeleteHighlightOp extends PendingOp {
  const DeleteHighlightOp(super.docId, this.id);

  final String id;

  @override
  String get key => 'h:$docId:$id';

  @override
  Map<String, dynamic> toJson() => {'op': 'deleteHighlight', 'docId': docId, 'id': id};
}

/// Nội dung slide lấy từ bản trên máy lúc gửi (luôn là bản mới nhất).
class PutSlideOp extends PendingOp {
  const PutSlideOp(super.docId, this.docVersion, this.slideKey);

  final int docVersion;
  final String slideKey;

  @override
  String get key => 's:$docId:$slideKey';

  @override
  Map<String, dynamic> toJson() => {'op': 'putSlide', 'docId': docId, 'docVersion': docVersion, 'slideKey': slideKey};
}

/// Lưu ghi chú và hàng đợi trên máy bằng shared_preferences.
class AnnotateLocalStore {
  AnnotateLocalStore([Future<SharedPreferences> Function()? prefs]) : _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  Future<StoredDocAnnotations> read(String userId, String docId) async {
    final raw = (await _prefs()).getString(_docKey(userId, docId));
    if (raw == null) return const StoredDocAnnotations();
    return StoredDocAnnotations.fromJson(_map(jsonDecode(raw)));
  }

  Future<void> write(String userId, String docId, StoredDocAnnotations doc) async =>
      (await _prefs()).setString(_docKey(userId, docId), jsonEncode(doc.toJson()));

  Future<List<PendingOp>> readQueue(String userId) async {
    final raw = (await _prefs()).getString('ann.queue.$userId');
    if (raw == null) return [];
    return [for (final op in jsonDecode(raw) as List) PendingOp.fromJson(_map(op))];
  }

  Future<void> writeQueue(String userId, List<PendingOp> ops) async =>
      (await _prefs()).setString('ann.queue.$userId', jsonEncode([for (final op in ops) op.toJson()]));

  static String _docKey(String userId, String docId) => 'ann.$userId.$docId';
}

Map<String, dynamic> _map(Object? v) => v is Map ? v.map((k, val) => MapEntry(k.toString(), val)) : <String, dynamic>{};

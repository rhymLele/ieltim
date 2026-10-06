// models.dart — Model dữ liệu (thuần Dart, có toJson/fromJson để lưu lên BE).
// Toạ độ trên slide đều CHUẨN HOÁ 0..1 theo chiều rộng / cao của slide → đổi máy, xoay màn hình vẫn đúng chỗ.
import 'dart:ui';

import 'annotate_theme.dart';

enum AnnotationTool { view, pen, marker, circle, text, comment }

Color _c(Object? v) => Color(int.parse((v as String? ?? '#800020').substring(1), radix: 16) | 0xFF000000);
String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Nét bút / bút dạ quang.
class StrokeMark {
  const StrokeMark({required this.id, required this.points, required this.color, this.marker = false});

  factory StrokeMark.fromJson(Map<String, dynamic> j) => StrokeMark(
        id: j['id'] as String,
        points: [for (final p in j['points'] as List) Offset((p[0] as num).toDouble(), (p[1] as num).toDouble())],
        color: _c(j['color']),
        marker: j['tool'] == 'marker',
      );

  final String id;
  final List<Offset> points; // 0..1
  final Color color;
  final bool marker;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'stroke',
        'tool': marker ? 'marker' : 'pen',
        'color': _hex(color),
        'points': [for (final p in points) [_r(p.dx), _r(p.dy)]],
      };
}

/// Khoanh tròn (ellipse theo khung chữ nhật chuẩn hoá).
class EllipseMark {
  const EllipseMark({required this.id, required this.rect, required this.color});

  factory EllipseMark.fromJson(Map<String, dynamic> j) => EllipseMark(
        id: j['id'] as String,
        rect: Rect.fromLTWH((j['x'] as num).toDouble(), (j['y'] as num).toDouble(), (j['w'] as num).toDouble(), (j['h'] as num).toDouble()),
        color: _c(j['color']),
      );

  final String id;
  final Rect rect; // 0..1
  final Color color;

  Map<String, dynamic> toJson() =>
      {'id': id, 'type': 'ellipse', 'color': _hex(color), 'x': _r(rect.left), 'y': _r(rect.top), 'w': _r(rect.width), 'h': _r(rect.height)};
}

/// Chữ người học thêm lên slide.
class TextMark {
  const TextMark({required this.id, required this.at, required this.text, required this.color});

  factory TextMark.fromJson(Map<String, dynamic> j) =>
      TextMark(id: j['id'] as String, at: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()), text: j['text'] as String, color: _c(j['color']));

  final String id;
  final Offset at; // 0..1
  final String text;
  final Color color;

  Map<String, dynamic> toJson() => {'id': id, 'type': 'text', 'color': _hex(color), 'x': _r(at.dx), 'y': _r(at.dy), 'text': text};
}

/// Ghim ghi chú.
class PinNote {
  const PinNote({required this.id, required this.at, this.text = '', required this.createdAt});

  factory PinNote.fromJson(Map<String, dynamic> j) => PinNote(
        id: j['id'] as String,
        at: Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()),
        text: j['text'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  final String id;
  final Offset at; // 0..1
  final String text;
  final DateTime createdAt;

  PinNote copyWith({String? text}) => PinNote(id: id, at: at, text: text ?? this.text, createdAt: createdAt);

  Map<String, dynamic> toJson() =>
      {'id': id, 'type': 'pin', 'x': _r(at.dx), 'y': _r(at.dy), 'text': text, 'createdAt': createdAt.toIso8601String()};
}

/// Toàn bộ ghi chú của 1 người trên 1 slide.
class SlideAnnotations {
  const SlideAnnotations({this.strokes = const [], this.ellipses = const [], this.texts = const [], this.pins = const []});

  factory SlideAnnotations.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? const []).cast<Map<String, dynamic>>();
    return SlideAnnotations(
      strokes: [for (final i in items) if (i['type'] == 'stroke') StrokeMark.fromJson(i)],
      ellipses: [for (final i in items) if (i['type'] == 'ellipse') EllipseMark.fromJson(i)],
      texts: [for (final i in items) if (i['type'] == 'text') TextMark.fromJson(i)],
      pins: [for (final i in items) if (i['type'] == 'pin') PinNote.fromJson(i)],
    );
  }

  final List<StrokeMark> strokes;
  final List<EllipseMark> ellipses;
  final List<TextMark> texts;
  final List<PinNote> pins;

  bool get isEmpty => strokes.isEmpty && ellipses.isEmpty && texts.isEmpty && pins.isEmpty;

  SlideAnnotations copyWith({List<StrokeMark>? strokes, List<EllipseMark>? ellipses, List<TextMark>? texts, List<PinNote>? pins}) =>
      SlideAnnotations(
        strokes: strokes ?? this.strokes,
        ellipses: ellipses ?? this.ellipses,
        texts: texts ?? this.texts,
        pins: pins ?? this.pins,
      );

  Map<String, dynamic> toJson() => {
        'items': [
          ...strokes.map((e) => e.toJson()),
          ...ellipses.map((e) => e.toJson()),
          ...texts.map((e) => e.toJson()),
          ...pins.map((e) => e.toJson()),
        ],
      };
}

/// Highlight trên chữ, neo theo "trích đoạn" để vẫn tìm lại được khi admin sửa bài.
class TextHighlight {
  const TextHighlight({required this.id, required this.blockKey, required this.quote, this.prefix = '', this.suffix = '', required this.color, this.start, this.end});

  factory TextHighlight.fromJson(Map<String, dynamic> j) => TextHighlight(
        id: j['id'] as String,
        blockKey: j['blockKey'] as String,
        quote: j['quote'] as String,
        prefix: j['prefix'] as String? ?? '',
        suffix: j['suffix'] as String? ?? '',
        color: HighlightColor.fromName(j['color'] as String?),
        start: j['start'] as int?,
        end: j['end'] as int?,
      );

  final String id;
  final String blockKey; // khối JSON (blockKey) hoặc "html" cho tài liệu HTML
  final String quote; // đoạn chữ được bôi
  final String prefix; // ~30 ký tự đứng trước
  final String suffix; // ~30 ký tự đứng sau
  final HighlightColor color;
  final int? start; // vị trí ký tự trong khối (gợi ý, có thể lệch nếu bài bị sửa)
  final int? end;

  TextHighlight copyWith({HighlightColor? color, int? start, int? end}) => TextHighlight(
      id: id, blockKey: blockKey, quote: quote, prefix: prefix, suffix: suffix, color: color ?? this.color, start: start ?? this.start, end: end ?? this.end);

  Map<String, dynamic> toJson() =>
      {'id': id, 'blockKey': blockKey, 'quote': quote, 'prefix': prefix, 'suffix': suffix, 'color': color.name, 'start': start, 'end': end};
}

/// Kết quả dịch (logic thật gọi API / từ điển).
class TranslationResult {
  const TranslationResult({required this.text, required this.meaning, this.ipa, this.partOfSpeech, this.sentenceTranslation});
  final String text;
  final String meaning;
  final String? ipa;
  final String? partOfSpeech;
  final String? sentenceTranslation;
}

/// Bản nháp để lưu vào sổ từ.
class VocabDraft {
  const VocabDraft({required this.text, required this.meaning, this.ipa, this.example, required this.deck, this.sourceDocId});
  final String text;
  final String meaning;
  final String? ipa;
  final String? example;
  final String deck;
  final String? sourceDocId;
}

double _r(double v) => (v * 10000).roundToDouble() / 10000;

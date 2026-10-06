import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/annotate/annotate.dart';

TextHighlight _h(String id, String quote, {String prefix = '', String suffix = '', int? start, int? end, HighlightColor color = HighlightColor.yellow}) =>
    TextHighlight(id: id, blockKey: '0-0-0', quote: quote, prefix: prefix, suffix: suffix, color: color, start: start, end: end);

void main() {
  group('resolveHighlights', () {
    const text = 'Cities offer grants. Critics question the grants.';

    test('start/end đã lưu khớp quote → dùng luôn', () {
      final start = text.lastIndexOf('grants');
      final ranges = resolveHighlights(text, [_h('a', 'grants', start: start, end: start + 6)]);
      expect(ranges.single, (start: start, end: start + 6, color: HighlightColor.yellow, id: 'a'));
    });

    test('bài bị sửa (vị trí lệch) → tìm lại theo quote', () {
      const edited = 'Many cities now offer grants.';
      final ranges = resolveHighlights(edited, [_h('a', 'offer', start: 7, end: 12)]);
      expect(ranges.single.start, edited.indexOf('offer'));
      expect(ranges.single.end, edited.indexOf('offer') + 5);
    });

    test('quote xuất hiện nhiều lần → prefix / suffix chọn đúng chỗ', () {
      final second = text.lastIndexOf('grants');
      final bySuffix = resolveHighlights(text, [_h('a', 'grants', suffix: '.', start: 0, end: 3)]);
      expect(bySuffix.single.start, text.indexOf('grants'), reason: 'cả hai đều có "." phía sau → giữ chỗ đầu');
      final byPrefix = resolveHighlights(text, [_h('a', 'grants', prefix: 'question the ')]);
      expect(byPrefix.single.start, second);
    });

    test('không còn quote trong bài → bỏ', () {
      expect(resolveHighlights(text, [_h('a', 'vegetable')]), isEmpty);
    });

    test('chồng lấn: highlight sau bị cắt, nằm trọn trong cái trước thì bỏ', () {
      final ranges = resolveHighlights(text, [
        _h('a', 'Cities offer', start: 0, end: 12),
        _h('b', 'offer grants', start: 7, end: 19, color: HighlightColor.values.last),
        _h('c', 'offer', start: 7, end: 12),
      ]);
      expect(ranges.map((r) => (r.id, r.start, r.end)), [('a', 0, 12), ('b', 12, 19)]);
    });
  });

  group('SlideAnnotations', () {
    test('toJson → JSON → fromJson giữ nguyên mọi loại ghi chú (toạ độ 0..1)', () {
      final data = SlideAnnotations(
        strokes: [
          StrokeMark(id: 's1', points: const [Offset(0.1, 0.2), Offset(0.35, 0.5)], color: kPenColors[0]),
          StrokeMark(id: 's2', points: const [Offset(0.5, 0.5), Offset(0.75, 0.5)], color: kPenColors[1], marker: true),
        ],
        ellipses: [EllipseMark(id: 'e1', rect: const Rect.fromLTWH(0.2, 0.3, 0.25, 0.125), color: kPenColors[2])],
        texts: [TextMark(id: 't1', at: const Offset(0.6, 0.1), text: 'main idea', color: kPenColors[0])],
        pins: [PinNote(id: 'p1', at: const Offset(0.9, 0.9), text: 'xem lại', createdAt: DateTime.utc(2026, 10, 6, 8))],
      );
      final restored = SlideAnnotations.fromJson(jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>);
      expect(restored.toJson(), data.toJson());
      expect(restored.strokes.last.marker, isTrue);
      expect(restored.ellipses.single.rect, const Rect.fromLTWH(0.2, 0.3, 0.25, 0.125));
      expect(restored.pins.single.text, 'xem lại');
      for (final item in (data.toJson()['items'] as List).cast<Map<String, dynamic>>()) {
        for (final key in ['x', 'y', 'w', 'h']) {
          if (item[key] case final num v) expect(v, inInclusiveRange(0, 1), reason: '${item['id']}.$key');
        }
      }
    });
  });

  group('AnnotationController', () {
    late List<SlideAnnotations> changes;
    late AnnotationController c;

    setUp(() {
      changes = [];
      c = AnnotationController(onChanged: changes.add);
    });
    tearDown(() => c.dispose());

    void stroke(List<Offset> points) {
      c.strokeStart(points.first);
      for (final p in points.skip(1)) {
        c.strokeUpdate(p);
      }
      c.strokeEnd();
    }

    test('bút / dạ quang: một nét mỗi lần thả tay; chấm một điểm thì bỏ', () {
      c.tool = AnnotationTool.pen;
      stroke(const [Offset(0.1, 0.1), Offset(0.2, 0.2), Offset(0.3, 0.25)]);
      c.tool = AnnotationTool.marker;
      stroke(const [Offset(0.5, 0.5), Offset(0.8, 0.5)]);
      stroke(const [Offset(0.4, 0.4)]);
      expect(c.data.strokes.map((s) => s.marker), [false, true]);
      expect(c.data.strokes.first.points, hasLength(3));
      expect(changes, hasLength(2));
    });

    test('khoanh: nét quá nhỏ thì bỏ', () {
      c.tool = AnnotationTool.circle;
      c.ellipseStart(const Offset(0.2, 0.2));
      c.ellipseUpdate(const Offset(0.5, 0.4));
      c.ellipseEnd();
      c.ellipseStart(const Offset(0.6, 0.6));
      c.ellipseUpdate(const Offset(0.601, 0.601));
      c.ellipseEnd();
      expect(c.data.ellipses, hasLength(1));
      expect(c.data.ellipses.single.rect.width, closeTo(0.3, 1e-9));
    });

    test('chữ: bỏ khoảng trắng thừa, chữ rỗng thì không thêm', () {
      c.addText(const Offset(0.3, 0.3), '  topic sentence ');
      c.addText(const Offset(0.4, 0.4), '   ');
      expect(c.data.texts.single.text, 'topic sentence');
    });

    test('ghim: thêm thì mở ngay; sửa chữ không thành một bước hoàn tác', () {
      c.addPin(const Offset(0.7, 0.2));
      expect(c.activePin, 0);
      c.updatePinText(0, 'h');
      c.updatePinText(0, 'hỏi cô');
      expect(c.data.pins.single.text, 'hỏi cô');
      c.undo();
      expect(c.data.pins, isEmpty);
      expect(c.canUndo, isFalse);
    });

    test('hoàn tác 3 bước về trạng thái ban đầu', () {
      c.tool = AnnotationTool.pen;
      stroke(const [Offset(0.1, 0.1), Offset(0.2, 0.2)]);
      c.tool = AnnotationTool.circle;
      c.ellipseStart(const Offset(0.2, 0.2));
      c.ellipseUpdate(const Offset(0.5, 0.4));
      c.ellipseEnd();
      c.addText(const Offset(0.3, 0.3), 'note');
      c.undo();
      expect((c.data.strokes.length, c.data.ellipses.length, c.data.texts.length), (1, 1, 0));
      c.undo();
      expect((c.data.strokes.length, c.data.ellipses.length), (1, 0));
      c.undo();
      expect(c.data.isEmpty, isTrue);
      expect(c.canUndo, isFalse);
      expect(changes.last.isEmpty, isTrue, reason: 'hoàn tác cũng báo onChanged để lưu');
    });

    test('xoá hết rồi hoàn tác → hiện lại như cũ', () {
      c.tool = AnnotationTool.pen;
      stroke(const [Offset(0.1, 0.1), Offset(0.2, 0.2)]);
      c.addPin(const Offset(0.5, 0.5));
      final before = c.data.toJson();
      c.clear();
      expect(c.data.isEmpty, isTrue);
      c.undo();
      expect(c.data.toJson(), before);
    });

    test('load thay dữ liệu và xoá lịch sử hoàn tác', () {
      c.addText(const Offset(0.1, 0.1), 'a');
      c.load(SlideAnnotations(texts: [TextMark(id: 'x', at: const Offset(0.5, 0.5), text: 'server', color: kPenColors[0])]));
      expect(c.canUndo, isFalse);
      expect(c.data.texts.single.text, 'server');
    });
  });
}

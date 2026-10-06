import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/weekly_docs/presentation/widgets/annotate/selection_target.dart';

void main() {
  group('sentenceAround', () {
    const text = 'Officials argue that roofs reduce heat. Critics question the cost! Is it worth it?\nNew line here';

    test('câu chứa vùng chọn, cắt theo . ! ? và xuống dòng', () {
      final i = text.indexOf('reduce');
      expect(sentenceAround(text, i, i + 6), 'Officials argue that roofs reduce heat.');
      final j = text.indexOf('question');
      expect(sentenceAround(text, j, j + 8), 'Critics question the cost!');
      final k = text.indexOf('New');
      expect(sentenceAround(text, k, k + 3), 'New line here');
    });

    test('chọn cả dấu chấm cuối câu → không kéo sang câu sau', () {
      final i = text.indexOf('heat.');
      expect(sentenceAround(text, i, i + 5), 'Officials argue that roofs reduce heat.');
    });

    test('vùng chọn qua hai câu → lấy trọn cả hai', () {
      final i = text.indexOf('heat');
      final j = text.indexOf('Critics') + 7;
      expect(sentenceAround(text, i, j), 'Officials argue that roofs reduce heat. Critics question the cost!');
    });
  });

  test('targetIn: vị trí, prefix / suffix ≤ 32 ký tự, câu ví dụ', () {
    const block = 'In recent years, a growing number of city councils have offered grants to residents who convert flat roofs.';
    final t = targetIn(block, 'offered grants', blockKey: '2-0-1')!;
    expect(block.substring(t.start, t.end), 'offered grants');
    expect(t.prefix.length, anchorContext);
    expect(block.substring(0, t.start).endsWith(t.prefix), isTrue);
    expect(block.substring(t.end).startsWith(t.suffix), isTrue);
    expect(t.sentence, block);
    expect(targetIn(block, 'vegetable', blockKey: '2-0-1'), isNull);
  });

  testWidgets('locateSelection: chữ có ở nhiều khối → lấy khối gần con trỏ; kéo qua nhiều khối → null', (tester) async {
    final keys = {'0-0-0': GlobalKey(), '1-0-0': GlobalKey()};
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [for (final k in keys.values) SizedBox(key: k, width: 300, height: 200)]),
    ));
    final mounted = {for (final e in keys.entries) e.key: e.value.currentContext!.findRenderObject()! as RenderBox};
    const texts = {'0-0-0': 'Grants help residents.', '1-0-0': 'Critics say grants cost too much.'};

    final near2 = locateSelection('grants', blockTexts: texts, mounted: mounted, anchor: const Offset(50, 350))!;
    expect(near2.blockKey, '1-0-0');
    expect(near2.sentence, 'Critics say grants cost too much.');

    // Khối có chữ "Grants" (hoa) không chứa "grants" → chỉ còn khối thứ hai dù con trỏ ở khối đầu.
    expect(locateSelection(' grants ', blockTexts: texts, mounted: mounted, anchor: const Offset(50, 50))!.blockKey, '1-0-0');
    expect(locateSelection('residents.\nCritics', blockTexts: texts, mounted: mounted), isNull);
    expect(locateSelection('   ', blockTexts: texts, mounted: mounted), isNull);
    // Khối không hiện trên màn hình thì bỏ qua.
    expect(locateSelection('Grants', blockTexts: texts, mounted: {'1-0-0': mounted['1-0-0']!}), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/weekly_docs/domain/block_key.dart';
import 'package:frontend/features/weekly_docs/domain/models/weekly_doc.dart';

void main() {
  group('blockKey', () {
    test('trả id nếu có', () {
      final b = DocBlock.heading(id: 'h-9', text: 'X');
      expect(blockKey(0, 3, b), 'h-9');
    });

    test('id rỗng → fallback theo vị trí', () {
      final b = DocBlock.paragraph(id: '', text: 'X');
      expect(blockKey(1, 2, b), '1-2');
    });

    test('không có id → fallback theo vị trí', () {
      final b = DocBlock.callout(text: 'X');
      expect(blockKey(4, 0, b), '4-0');
    });

    test('khác section/khối → key khác', () {
      final a = DocBlock.paragraph(text: 'X');
      final b = DocBlock.paragraph(text: 'X');
      expect(blockKey(0, 0, a), '0-0');
      expect(blockKey(0, 1, b), '0-1');
    });

    test('UnknownBlock có id vẫn dùng id', () {
      final b = DocBlock.unknown(type: 'x', raw: const {}, id: 'u1');
      expect(blockKey(2, 5, b), 'u1');
    });
  });
}

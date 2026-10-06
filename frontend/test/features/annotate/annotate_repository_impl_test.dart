import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/app_exception.dart';
import 'package:frontend/core/errors/result.dart';
import 'package:frontend/core/services/logger_service.dart';
import 'package:frontend/core/widgets/annotate/annotate.dart';
import 'package:frontend/features/annotate/data/datasources/fake_annotate_remote_datasource.dart';
import 'package:frontend/features/annotate/data/repositories/annotate_repository_impl.dart';
import 'package:frontend/features/annotate/domain/entities/doc_annotations.dart';
import 'package:frontend/features/annotate/domain/rules/slide_merge.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _doc = 'w12-doc1';

StrokeMark _stroke(String id) => StrokeMark(id: id, points: const [Offset(0.1, 0.1), Offset(0.2, 0.2)], color: kPenColors[0]);

PinNote _pin(String id, String text) => PinNote(id: id, at: const Offset(0.5, 0.5), text: text, createdAt: DateTime.utc(2026, 10, 6));

TextHighlight _highlight(String id) =>
    TextHighlight(id: id, blockKey: '0-0-0', quote: 'grants', prefix: 'offer ', suffix: '.', color: HighlightColor.yellow, start: 12, end: 18);

Set<String> _ids(SlideAnnotations a) => {for (final item in (a.toJson()['items'] as List).cast<Map<String, dynamic>>()) item['id'] as String};

/// Một "máy": repository riêng (bản trên máy theo user riêng), dùng chung BE giả.
AnnotateRepositoryImpl _device(FakeAnnotateRemoteDataSource remote, {String user = 'u1'}) => AnnotateRepositoryImpl(
      remote: remote,
      currentUserId: () async => user,
      logger: LoggerService(Logger(level: Level.off)),
      saveDelay: const Duration(hours: 1), // chỉ gửi khi gọi flush()
      retryDelay: const Duration(hours: 1),
    );

/// BE giả trả lỗi cố định khi ghi highlight.
class _FailingRemote extends FakeAnnotateRemoteDataSource {
  _FailingRemote(this.error) : super(latency: Duration.zero);

  AppException error;
  int calls = 0;

  @override
  Future<void> putHighlight(String docId, int docVersion, TextHighlight h) async {
    calls++;
    throw error;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('mergeSlideAnnotations (409)', () {
    test('giữ nét mới của cả hai máy', () {
      final base = SlideAnnotations(strokes: [_stroke('a1')]);
      final merged = mergeSlideAnnotations(
        base: base,
        local: SlideAnnotations(strokes: [_stroke('a1'), _stroke('b1')]),
        remote: SlideAnnotations(strokes: [_stroke('a1'), _stroke('a2')]),
      );
      expect(merged.strokes.map((s) => s.id), ['a1', 'a2', 'b1']);
    });

    test('nét đã xoá ở một máy thì không quay lại', () {
      final base = SlideAnnotations(strokes: [_stroke('x'), _stroke('y')]);
      final merged = mergeSlideAnnotations(
        base: base,
        local: SlideAnnotations(strokes: [_stroke('y')]), // máy này xoá x
        remote: SlideAnnotations(strokes: [_stroke('x')]), // máy kia xoá y
      );
      expect(merged.isEmpty, isTrue);
    });

    test('cùng một ghim sửa ở cả hai máy → giữ bản máy này', () {
      final merged = mergeSlideAnnotations(
        base: SlideAnnotations(pins: [_pin('p', '')]),
        local: SlideAnnotations(pins: [_pin('p', 'của tôi')]),
        remote: SlideAnnotations(pins: [_pin('p', 'máy kia')]),
      );
      expect(merged.pins.single.text, 'của tôi');
    });
  });

  group('AnnotateRepositoryImpl', () {
    test('lưu lạc quan: bản trên máy có ngay, BE chỉ nhận khi gửi', () async {
      final remote = FakeAnnotateRemoteDataSource(latency: Duration.zero);
      final repo = _device(remote);
      await repo.saveHighlight(_doc, 3, _highlight('h1'));
      expect(switch (await repo.loadCached(_doc)) { Success(:final data) => data.highlights.map((h) => h.id), _ => null }, ['h1']);
      expect(remote.highlights[_doc], isNull);
      await repo.flush();
      expect(remote.highlights[_doc]!.keys, ['h1']);
    });

    test('mất mạng: giữ hàng đợi (cả khi mở lại app), có mạng thì gửi lại', () async {
      final remote = FakeAnnotateRemoteDataSource(latency: Duration.zero)..offline = true;
      final repo = _device(remote);
      await repo.saveHighlight(_doc, 3, _highlight('h1'));
      await repo.saveSlide(_doc, 3, '0-0', SlideAnnotations(strokes: [_stroke('s1')]));
      await repo.deleteHighlight(_doc, 'old');
      await repo.flush();
      expect(remote.highlights[_doc], isNull);
      expect(remote.slides[_doc], isNull);

      // Mở lại app (repository mới, cùng SharedPreferences): hàng đợi vẫn còn.
      remote.offline = false;
      remote.highlights[_doc] = {'old': _highlight('old')};
      final reopened = _device(remote);
      await reopened.flush();
      expect(remote.highlights[_doc]!.keys, ['h1']);
      expect(_ids(SlideAnnotations.fromJson(remote.slides[_doc]!['0-0']!.data)), {'s1'});
      expect(remote.slides[_doc]!['0-0']!.rev, 1);
    });

    test('409: gộp với bản máy khác, giữ nét của cả hai máy rồi gửi lại', () async {
      final remote = FakeAnnotateRemoteDataSource(latency: Duration.zero);
      final phone = _device(remote, user: 'phone');
      final laptop = _device(remote, user: 'laptop');

      await phone.saveSlide(_doc, 3, '1-0', SlideAnnotations(strokes: [_stroke('a1')]));
      await phone.flush();
      await laptop.refresh(_doc);

      final merged = <SlideAnnotationsMerged>[];
      final sub = laptop.mergedSlides.listen(merged.add);
      addTearDown(sub.cancel);

      await laptop.saveSlide(_doc, 3, '1-0', SlideAnnotations(strokes: [_stroke('a1'), _stroke('b1')]));
      await phone.saveSlide(_doc, 3, '1-0', SlideAnnotations(strokes: [_stroke('a1'), _stroke('a2')]));
      await phone.flush(); // rev 2
      await laptop.flush(); // gửi rev 1 → 409 → gộp → gửi lại

      final server = remote.slides[_doc]!['1-0']!;
      expect(_ids(SlideAnnotations.fromJson(server.data)), {'a1', 'a2', 'b1'});
      expect(server.rev, 3);
      await Future<void>.delayed(Duration.zero);
      expect(_ids(merged.single.data), {'a1', 'a2', 'b1'}, reason: 'màn đọc nhận bản đã gộp để vẽ lại');
      expect(switch (await laptop.loadCached(_doc)) { Success(:final data) => _ids(data.slides['1-0']!), _ => null }, {'a1', 'a2', 'b1'});
    });

    test('lỗi 4xx (dữ liệu sai): bỏ thao tác, không gửi lại mãi', () async {
      final remote = _FailingRemote(const ServerException('Sai dữ liệu', code: 'VALIDATION_FAILED', statusCode: 400));
      final repo = _device(remote);
      await repo.saveHighlight(_doc, 3, _highlight('h1'));
      await repo.flush();
      await repo.flush();
      expect(remote.calls, 1);
    });

    test('lỗi 5xx / 429: giữ thao tác để thử lại', () async {
      final remote = _FailingRemote(const ServerException('Máy chủ bận', code: 'INTERNAL', statusCode: 503));
      final repo = _device(remote);
      await repo.saveHighlight(_doc, 3, _highlight('h1'));
      await repo.flush();
      remote.error = const ServerException('Chậm lại', code: 'RATE_LIMITED', statusCode: 429);
      await repo.flush();
      expect(remote.calls, 2);
    });

    test('tải từ máy chủ không đè thay đổi chưa gửi', () async {
      final remote = FakeAnnotateRemoteDataSource(latency: Duration.zero);
      remote.highlights[_doc] = {'h1': _highlight('h1').copyWith(color: HighlightColor.yellow)};
      final repo = _device(remote);
      await repo.saveHighlight(_doc, 3, _highlight('h1').copyWith(color: HighlightColor.values.last));
      await repo.saveSlide(_doc, 3, '0-0', SlideAnnotations(strokes: [_stroke('local')]));
      final fresh = switch (await repo.refresh(_doc)) { Success(:final data) => data, Failure() => null };
      expect(fresh!.highlights.single.color, HighlightColor.values.last);
      expect(_ids(fresh.slides['0-0']!), {'local'});
    });

    test('đổi tài khoản: không thấy ghi chú của người trước', () async {
      final remote = FakeAnnotateRemoteDataSource(latency: Duration.zero)..offline = true;
      var user = 'u1';
      final repo = AnnotateRepositoryImpl(
        remote: remote,
        currentUserId: () async => user,
        logger: LoggerService(Logger(level: Level.off)),
        saveDelay: const Duration(hours: 1),
        retryDelay: const Duration(hours: 1),
      );
      await repo.saveHighlight(_doc, 3, _highlight('h1'));
      user = 'u2';
      expect(switch (await repo.loadCached(_doc)) { Success(:final data) => data.highlights, _ => null }, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/di/service_locator.dart';
import 'package:frontend/core/errors/app_exception.dart';
import 'package:frontend/core/errors/result.dart';
import 'package:frontend/core/services/logger_service.dart';
import 'package:frontend/core/widgets/annotate/annotate.dart';
import 'package:frontend/features/annotate/data/datasources/fake_annotate_remote_datasource.dart';
import 'package:frontend/features/annotate/data/models/annotation_models.dart';
import 'package:frontend/features/annotate/data/repositories/annotate_repository_impl.dart';
import 'package:frontend/features/annotate/domain/repositories/annotate_repository.dart';
import 'package:frontend/features/annotate/presentation/cubits/doc_annotations_cubit.dart';
import 'package:frontend/features/vocab/data/repositories/fake_vocab_repository.dart';
import 'package:frontend/features/vocab/domain/entities/vocab_entry.dart';
import 'package:frontend/features/vocab/domain/repositories/vocab_repository.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _doc = 'w12-doc1';

TextHighlight _highlight(String id, int start, int end, {HighlightColor color = HighlightColor.yellow}) =>
    TextHighlight(id: id, blockKey: '0-0-0', quote: 'x' * (end - start), color: color, start: start, end: end);

/// BE giả: tài liệu không được xem (403) / dịch lỗi theo cờ.
class _Remote extends FakeAnnotateRemoteDataSource {
  _Remote() : super(latency: Duration.zero);

  bool forbidden = false;
  bool translateDown = false;

  @override
  Future<DocAnnotationsModel> annotations(String docId) async {
    if (forbidden) throw const ServerException('Bạn không có quyền xem tài liệu này.', code: 'DOC_FORBIDDEN', statusCode: 403);
    return super.annotations(docId);
  }

  @override
  Future<TranslationModel> translate(TranslateRequest body) async {
    if (translateDown) throw const ServerException('Chưa dịch được', code: 'TRANSLATE_UNAVAILABLE', statusCode: 503);
    return super.translate(body);
  }
}

void main() {
  late _Remote remote;
  late FakeVocabRepository vocab;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    remote = _Remote();
    vocab = FakeVocabRepository();
    registerSingleton<LoggerService>(LoggerService(Logger(level: Level.off)));
    registerSingleton<VocabRepository>(vocab);
    registerSingleton<AnnotateRepository>(
      AnnotateRepositoryImpl(remote: remote, currentUserId: () async => 'u1', saveDelay: Duration.zero, retryDelay: const Duration(hours: 1)),
    );
  });
  tearDown(resetSingletons);

  Future<DocAnnotationsCubit> open() async {
    final cubit = DocAnnotationsCubit(docId: _doc, docVersion: 3);
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  test('load: nạp highlight + ghi chú slide từ máy chủ', () async {
    remote.highlights[_doc] = {'h1': _highlight('h1', 0, 5)};
    remote.slides[_doc] = {'1-0': const SlideStateModel(data: {'items': []}, rev: 2)};
    final cubit = await open();
    expect(cubit.state.highlights.map((h) => h.id), ['h1']);
    expect(cubit.state.slides.keys, ['1-0']);
    expect(cubit.state.forbidden, isFalse);
  });

  test('403 DOC_FORBIDDEN → forbidden (ẩn công cụ ghi chú)', () async {
    remote.forbidden = true;
    final cubit = await open();
    expect(cubit.state.forbidden, isTrue);
  });

  test('highlight: thêm thay vùng chồng lấn, đổi màu, bỏ — state đổi ngay, BE nhận sau', () async {
    final cubit = await open();
    cubit.addHighlight(_highlight('a', 0, 10));
    cubit.addHighlight(_highlight('b', 5, 15), replaces: ['a']);
    expect(cubit.state.highlights.map((h) => h.id), ['b']);

    cubit.recolorHighlight('b', HighlightColor.values.last);
    expect(cubit.state.byId('b')!.color, HighlightColor.values.last);
    await cubit.flush();
    expect(remote.highlights[_doc]!.keys, ['b']);
    expect(remote.highlights[_doc]!['b']!.color, HighlightColor.values.last);

    cubit.removeHighlight('b');
    expect(cubit.state.highlights, isEmpty);
    await cubit.flush();
    expect(remote.highlights[_doc], isEmpty);
  });

  test('ghi chú slide: chấm trang có ghi chú, lưu lên BE', () async {
    final cubit = await open();
    final data = SlideAnnotations(texts: [TextMark(id: 't', at: const Offset(0.5, 0.5), text: 'main idea', color: kPenColors[0])]);
    cubit.slideChanged('2-0', data);
    expect(cubit.state.hasNotes('2-0'), isTrue);
    expect(cubit.state.hasNotes('3-0'), isFalse);
    await cubit.flush();
    expect(remote.slides[_doc]!['2-0']!.rev, 1);
  });

  test('dịch: cache trong phiên; lỗi thì ném và lần sau gọi lại', () async {
    final cubit = await open();
    final first = await cubit.translate('mitigate', sentence: 'We must mitigate risks.');
    await cubit.translate('Mitigate ', sentence: 'We must mitigate risks.');
    expect(first.meaning, 'giảm nhẹ, làm dịu bớt');
    expect(remote.translateCalls, 1);
    expect((await cubit.cachedTranslation('mitigate', sentence: 'We must mitigate risks.'))?.ipa, '/ˈmɪtɪɡeɪt/');

    remote.translateDown = true;
    await expectLater(cubit.translate('vulnerable'), throwsA(isA<ServerException>()));
    remote.translateDown = false;
    expect((await cubit.translate('vulnerable')).meaning, 'dễ bị tổn thương');
  });

  test('sổ từ: sổ "Tuần N" đứng đầu; thêm từ → Từ đã lưu; thêm trùng → đã có', () async {
    final cubit = await open();
    expect(await cubit.decks(week: 12), ['Tuần 12', defaultVocabDeck]);

    const word = NewVocab(text: 'mitigate', meaning: 'giảm nhẹ', deck: 'Tuần 12', sourceDocId: _doc, sourceBlockKey: '2-0-1');
    expect(await cubit.addVocab(word), isA<Success<VocabEntry>>());
    expect(cubit.state.savedWords.single.sourceBlockKey, '2-0-1');
    expect(await cubit.vocabExists('mitigate'), isTrue);

    final again = await cubit.addVocab(word);
    expect(again, isA<Failure<VocabEntry>>().having((f) => f.exception, 'exception', isA<VocabExistsException>()));
    expect(cubit.state.savedWords, hasLength(1));

    await vocab.add(const NewVocab(text: 'other doc', sourceDocId: 'w11-doc1'));
    await cubit.loadSavedWords();
    expect(cubit.state.savedWords.map((w) => w.text), ['mitigate'], reason: 'chỉ từ lưu từ tài liệu này');
  });
}

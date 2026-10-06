import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/annotate/models.dart';
import '../models/annotation_models.dart';
import 'annotate_remote_datasource.dart';

/// BE giả trong bộ nhớ (`--dart-define=WEEKLY_DOCS_FAKE=true`, test): highlight, ghi chú slide có `rev`, dịch bằng từ điển nhỏ.
class FakeAnnotateRemoteDataSource extends AnnotateRemoteDataSource {
  FakeAnnotateRemoteDataSource({this.latency = const Duration(milliseconds: 120)}) : super(Dio()); // không gọi mạng

  final Duration latency;

  /// Bật để giả lập mất mạng.
  bool offline = false;

  final highlights = <String, Map<String, TextHighlight>>{};
  final slides = <String, Map<String, SlideStateModel>>{};
  int translateCalls = 0;

  static const _dictionary = {
    'mitigate': ('/ˈmɪtɪɡeɪt/', 'động từ', 'giảm nhẹ, làm dịu bớt'),
    'headings': ('/ˈhedɪŋz/', 'danh từ', 'tiêu đề'),
    'paragraph': ('/ˈpærəɡrɑːf/', 'danh từ', 'đoạn văn'),
    'vulnerable': ('/ˈvʌlnərəbl/', 'tính từ', 'dễ bị tổn thương'),
  };

  Future<void> _wait() async {
    await Future<void>.delayed(latency);
    if (offline) throw const NetworkException();
  }

  @override
  Future<DocAnnotationsModel> annotations(String docId) async {
    await _wait();
    return DocAnnotationsModel(
      highlights: [for (final h in (highlights[docId] ?? const {}).values) h.toJson()],
      slides: Map.of(slides[docId] ?? const {}),
    );
  }

  @override
  Future<void> putHighlight(String docId, int docVersion, TextHighlight h) async {
    await _wait();
    (highlights[docId] ??= {})[h.id] = h;
  }

  @override
  Future<void> deleteHighlight(String docId, String id) async {
    await _wait();
    highlights[docId]?.remove(id);
  }

  @override
  Future<int> putSlide(String docId, String slideKey, SlideSaveRequest body) async {
    await _wait();
    final doc = slides[docId] ??= {};
    final current = doc[slideKey];
    final rev = current?.rev ?? 0;
    if (body.rev != rev) throw AnnotationConflictException('Ghi chú vừa được sửa trên máy khác.', current: current ?? const SlideStateModel(data: {}, rev: 0));
    doc[slideKey] = SlideStateModel(data: body.data, rev: rev + 1);
    return rev + 1;
  }

  @override
  Future<TranslationModel> translate(TranslateRequest body) async {
    await _wait();
    translateCalls++;
    final entry = _dictionary[body.text.trim().toLowerCase()];
    return TranslationModel(
      text: body.text,
      meaning: entry?.$3 ?? '(bản giả) nghĩa của "${body.text}"',
      ipa: entry?.$1,
      partOfSpeech: entry?.$2,
      sentenceTranslation: body.sentence == null ? null : '(bản giả) dịch câu: ${body.sentence}',
    );
  }
}

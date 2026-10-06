import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/widgets/annotate/annotate_theme.dart';
import '../../../../core/widgets/annotate/models.dart';
import '../../../vocab/domain/entities/vocab_entry.dart';
import '../../../vocab/domain/usecases/add_vocab_use_case.dart';
import '../../../vocab/domain/usecases/get_vocab_decks_use_case.dart';
import '../../../vocab/domain/usecases/list_vocab_use_case.dart';
import '../../../vocab/domain/usecases/vocab_exists_use_case.dart';
import '../../domain/entities/doc_annotations.dart';
import '../../domain/usecases/delete_highlight_use_case.dart';
import '../../domain/usecases/flush_annotations_use_case.dart';
import '../../domain/usecases/load_cached_annotations_use_case.dart';
import '../../domain/usecases/refresh_annotations_use_case.dart';
import '../../domain/usecases/save_highlight_use_case.dart';
import '../../domain/usecases/save_slide_annotations_use_case.dart';
import '../../domain/usecases/translate_text_use_case.dart';
import '../../domain/usecases/watch_merged_slides_use_case.dart';

class DocAnnotationsState {
  const DocAnnotationsState({
    this.highlights = const [],
    this.slides = const {},
    this.slideEpochs = const {},
    this.savedWords = const [],
    this.forbidden = false,
  });

  final List<TextHighlight> highlights;
  final Map<String, SlideAnnotations> slides;

  /// Tăng khi ghi chú một slide bị thay từ ngoài (tải từ máy chủ, gộp sau xung đột): lớp vẽ nạp lại.
  final Map<String, int> slideEpochs;

  /// Từ đã lưu vào Sổ từ từ tài liệu này (tab "Từ đã lưu").
  final List<VocabEntry> savedWords;

  /// Máy chủ báo không được ghi chú tài liệu này (403): ẩn công cụ.
  final bool forbidden;

  List<TextHighlight> highlightsOf(String blockKey) => [for (final h in highlights) if (h.blockKey == blockKey) h];

  TextHighlight? byId(String id) {
    for (final h in highlights) {
      if (h.id == id) return h;
    }
    return null;
  }

  /// Slide nào có ghi chú (chấm trang viền vàng).
  bool hasNotes(String slideKey) => !(slides[slideKey]?.isEmpty ?? true);

  DocAnnotationsState copyWith({
    List<TextHighlight>? highlights,
    Map<String, SlideAnnotations>? slides,
    Map<String, int>? slideEpochs,
    List<VocabEntry>? savedWords,
    bool? forbidden,
  }) =>
      DocAnnotationsState(
        highlights: highlights ?? this.highlights,
        slides: slides ?? this.slides,
        slideEpochs: slideEpochs ?? this.slideEpochs,
        savedWords: savedWords ?? this.savedWords,
        forbidden: forbidden ?? this.forbidden,
      );
}

/// Bôi đen / highlight / ghi chú slide / sổ từ / dịch của người học trên một tài liệu.
/// Ghi là lạc quan: state đổi ngay, repository tự lưu trên máy và gửi BE sau.
class DocAnnotationsCubit extends Cubit<DocAnnotationsState> {
  DocAnnotationsCubit({
    required this.docId,
    required this.docVersion,
    LoadCachedAnnotationsUseCase? loadCached,
    RefreshAnnotationsUseCase? refresh,
    SaveHighlightUseCase? saveHighlight,
    DeleteHighlightUseCase? deleteHighlight,
    SaveSlideAnnotationsUseCase? saveSlide,
    FlushAnnotationsUseCase? flush,
    WatchMergedSlidesUseCase? watchMerged,
    TranslateTextUseCase? translate,
    AddVocabUseCase? addVocab,
    VocabExistsUseCase? vocabExists,
    GetVocabDecksUseCase? decks,
    ListVocabUseCase? listVocab,
  })  : _loadCached = loadCached ?? LoadCachedAnnotationsUseCase(),
        _refresh = refresh ?? RefreshAnnotationsUseCase(),
        _saveHighlight = saveHighlight ?? SaveHighlightUseCase(),
        _deleteHighlight = deleteHighlight ?? DeleteHighlightUseCase(),
        _saveSlide = saveSlide ?? SaveSlideAnnotationsUseCase(),
        _flush = flush ?? FlushAnnotationsUseCase(),
        _translate = translate ?? TranslateTextUseCase(),
        _addVocab = addVocab ?? AddVocabUseCase(),
        _vocabExists = vocabExists ?? VocabExistsUseCase(),
        _decks = decks ?? GetVocabDecksUseCase(),
        _listVocab = listVocab ?? ListVocabUseCase(),
        super(const DocAnnotationsState()) {
    _merged = (watchMerged ?? WatchMergedSlidesUseCase()).execute().where((m) => m.docId == docId).listen((m) {
      if (!isClosed) emit(_withSlide(m.slideKey, m.data, replaced: true));
    });
  }

  final String docId;
  final int docVersion;
  final LoadCachedAnnotationsUseCase _loadCached;
  final RefreshAnnotationsUseCase _refresh;
  final SaveHighlightUseCase _saveHighlight;
  final DeleteHighlightUseCase _deleteHighlight;
  final SaveSlideAnnotationsUseCase _saveSlide;
  final FlushAnnotationsUseCase _flush;
  final TranslateTextUseCase _translate;
  final AddVocabUseCase _addVocab;
  final VocabExistsUseCase _vocabExists;
  final GetVocabDecksUseCase _decks;
  final ListVocabUseCase _listVocab;
  late final StreamSubscription<SlideAnnotationsMerged> _merged;

  // Cache trong phiên đọc.
  final _translations = <String, Future<TranslationResult>>{};
  final _exists = <String, bool>{};
  List<String>? _deckList;

  /// Hiện ngay bản trên máy, rồi cập nhật theo máy chủ.
  Future<void> load() async {
    if (await _loadCached.execute(docId) case Success(:final data)) {
      if (!isClosed) emit(_withAll(data));
    }
    final fresh = await _refresh.execute(docId);
    if (isClosed) return;
    switch (fresh) {
      case Success(:final data):
        emit(_withAll(data));
      case Failure(:final exception):
        if (exception is ServerException && (exception.code == 'DOC_FORBIDDEN' || exception.code == 'USER_INACTIVE')) {
          emit(state.copyWith(forbidden: true));
        }
    }
  }

  // ───────────────────────────── Highlight ─────────────────────────────

  /// Thêm highlight; các highlight cũ chồng lên vùng này ([replaces]) bị thay.
  void addHighlight(TextHighlight highlight, {Iterable<String> replaces = const []}) {
    final drop = replaces.toSet();
    emit(state.copyWith(highlights: [...state.highlights.where((h) => !drop.contains(h.id) && h.id != highlight.id), highlight]));
    for (final id in drop) {
      if (id != highlight.id) unawaited(_deleteHighlight.execute(docId, id));
    }
    unawaited(_saveHighlight.execute(docId, docVersion, highlight));
  }

  void recolorHighlight(String id, HighlightColor color) {
    final h = state.byId(id);
    if (h == null) return;
    addHighlight(h.copyWith(color: color));
  }

  void removeHighlight(String id) {
    emit(state.copyWith(highlights: state.highlights.where((h) => h.id != id).toList()));
    unawaited(_deleteHighlight.execute(docId, id));
  }

  // ───────────────────────────── Ghi chú slide ─────────────────────────────

  /// Lớp vẽ vừa đổi (bút, khoanh, chữ, ghim, hoàn tác…).
  void slideChanged(String slideKey, SlideAnnotations data) {
    emit(_withSlide(slideKey, data));
    unawaited(_saveSlide.execute(docId, docVersion, slideKey, data));
  }

  /// Gửi ngay thay đổi đang chờ (rời màn đọc, app vào nền).
  Future<void> flush() => _flush.execute();

  // ───────────────────────────── Dịch, sổ từ ─────────────────────────────

  /// Ném [AppException] khi lỗi (hộp thoại tự hiện "Chưa dịch được…"). Cache trong phiên theo từ + câu.
  Future<TranslationResult> translate(String text, {String? sentence}) {
    final key = _translationKey(text, sentence);
    final cached = _translations[key];
    if (cached != null) return cached;
    final future = _translate.execute(text, sentence: sentence).then((r) => switch (r) {
          Success(:final data) => data,
          Failure(:final exception) => throw exception,
        });
    _translations[key] = future;
    // Lỗi thì lần sau thử lại (onError không trả lại future lỗi, kẻo thành lỗi không ai bắt).
    unawaited(future.then((_) {}, onError: (Object _) {
      _translations.remove(key);
    }));
    return future;
  }

  /// Bản dịch đã có trong phiên (để điền sẵn IPA, nghĩa vào form sổ từ).
  Future<TranslationResult?> cachedTranslation(String text, {String? sentence}) async {
    final pending = _translations[_translationKey(text, sentence)];
    if (pending == null) return null;
    try {
      return await pending;
    } on Object {
      return null;
    }
  }

  static String _translationKey(String text, String? sentence) => '${text.trim().toLowerCase()}|${sentence?.trim().toLowerCase() ?? ''}';

  Future<bool> vocabExists(String text) async {
    final key = text.trim().toLowerCase();
    final known = _exists[key];
    if (known != null) return known;
    final exists = switch (await _vocabExists.execute(text.trim())) {
      Success(data: true) => true,
      _ => false,
    };
    _exists[key] = exists;
    return exists;
  }

  /// Sổ để chọn khi lưu: "Tuần N" của tài liệu trước, rồi các sổ đã có.
  Future<List<String>> decks({required int week}) async {
    final server = _deckList ??= switch (await _decks.execute()) {
      Success(:final data) => data,
      Failure() => const [defaultVocabDeck],
    };
    return {'Tuần $week', ...server, defaultVocabDeck}.toList();
  }

  Future<Result<VocabEntry>> addVocab(NewVocab vocab) async {
    final result = await _addVocab.execute(vocab);
    if (isClosed) return result;
    if (result case Success(:final data)) {
      _exists[vocab.text.trim().toLowerCase()] = true;
      _deckList = {vocab.deck, ...?_deckList}.toList();
      emit(state.copyWith(savedWords: [data, ...state.savedWords.where((w) => w.id != data.id)]));
    } else if (result case Failure(exception: VocabExistsException())) {
      _exists[vocab.text.trim().toLowerCase()] = true;
    }
    return result;
  }

  /// Tab "Từ đã lưu từ bài này".
  Future<void> loadSavedWords() async {
    final result = await _listVocab.execute();
    if (isClosed) return;
    if (result case Success(:final data)) emit(state.copyWith(savedWords: [for (final w in data) if (w.sourceDocId == docId) w]));
  }

  // ───────────────────────────── Nội bộ ─────────────────────────────

  DocAnnotationsState _withAll(DocAnnotations data) => state.copyWith(
        highlights: data.highlights,
        slides: data.slides,
        slideEpochs: {for (final key in {...state.slideEpochs.keys, ...data.slides.keys}) key: (state.slideEpochs[key] ?? 0) + 1},
      );

  DocAnnotationsState _withSlide(String key, SlideAnnotations data, {bool replaced = false}) => state.copyWith(
        slides: {...state.slides, key: data},
        slideEpochs: replaced ? {...state.slideEpochs, key: (state.slideEpochs[key] ?? 0) + 1} : null,
      );

  @override
  Future<void> close() async {
    await _merged.cancel();
    unawaited(_flush.execute());
    return super.close();
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/doc_progress.dart';
import '../../domain/entities/doc_summary.dart';
import '../../domain/entities/weekly_doc.dart';
import '../../domain/usecases/answer_quiz_use_case.dart';
import '../../domain/usecases/complete_doc_use_case.dart';
import '../../domain/usecases/get_admin_doc_use_case.dart';
import '../../domain/usecases/get_learner_doc_use_case.dart';
import '../../domain/usecases/get_week_docs_use_case.dart';
import '../../domain/usecases/save_progress_use_case.dart';
import 'doc_complete_cubit.dart';
import 'ui_state.dart';

class DocReaderState {
  const DocReaderState({
    this.status = LoadStatus.loading,
    this.errorMessage,
    this.doc,
    this.docVersion = 0,
    this.slides = const [],
    this.index = 0,
    this.view = DocViewMode.slide,
    this.answers = const {},
    this.docSeen = 0,
    this.isCompleting = false,
    this.completion,
    this.closeRequests = 0,
    this.notice,
  });

  final LoadStatus status;
  final String? errorMessage;
  final WeeklyDoc? doc;

  /// Phiên bản tài liệu đang đọc (gắn vào highlight / ghi chú để biết lúc tạo admin chưa sửa bài).
  final int docVersion;
  final List<SlidePage> slides;

  /// Slide đang xem (kiểu Slide).
  final int index;
  final DocViewMode view;
  final Map<String, int> answers;

  /// Số section đã cuộn qua (kiểu Doc).
  final int docSeen;
  final bool isCompleting;

  /// Có giá trị = đã hoàn thành, màn hình chuyển sang màn chúc mừng.
  final DocCompleteArgs? completion;

  /// Tăng khi cần đóng màn (admin xem trước bấm "Đóng xem trước").
  final int closeRequests;
  final UiNotice? notice;

  bool get isLastSlide => index >= slides.length - 1;

  /// Thanh tiến độ trên đầu màn đọc.
  double get readFraction {
    if (slides.isEmpty) return 0;
    if (view == DocViewMode.slide) return (index + 1) / slides.length;
    final total = doc?.sections.length ?? 0;
    return total == 0 ? 0 : docSeen / total;
  }

  DocReaderState copyWith({
    LoadStatus? status,
    Object? errorMessage = keep,
    WeeklyDoc? doc,
    int? docVersion,
    List<SlidePage>? slides,
    int? index,
    DocViewMode? view,
    Map<String, int>? answers,
    int? docSeen,
    bool? isCompleting,
    DocCompleteArgs? completion,
    int? closeRequests,
    UiNotice? notice,
  }) =>
      DocReaderState(
        status: status ?? this.status,
        errorMessage: identical(errorMessage, keep) ? this.errorMessage : errorMessage as String?,
        doc: doc ?? this.doc,
        docVersion: docVersion ?? this.docVersion,
        slides: slides ?? this.slides,
        index: index ?? this.index,
        view: view ?? this.view,
        answers: answers ?? this.answers,
        docSeen: docSeen ?? this.docSeen,
        isCompleting: isCompleting ?? this.isCompleting,
        completion: completion ?? this.completion,
        closeRequests: closeRequests ?? this.closeRequests,
        notice: notice ?? this.notice,
      );
}

/// Màn đọc (U2): Slide / Doc, tiến độ, trắc nghiệm, hoàn thành. Admin xem trước thì không ghi gì.
class DocReaderCubit extends Cubit<DocReaderState> {
  DocReaderCubit({
    required this.docId,
    this.isAdminPreview = false,
    GetLearnerDocUseCase? getLearnerDoc,
    GetAdminDocUseCase? getAdminDoc,
    SaveProgressUseCase? saveProgress,
    AnswerQuizUseCase? answerQuiz,
    CompleteDocUseCase? completeDoc,
    GetWeekDocsUseCase? getWeekDocs,
  })  : _getLearnerDoc = getLearnerDoc ?? GetLearnerDocUseCase(),
        _getAdminDoc = getAdminDoc ?? GetAdminDocUseCase(),
        _saveProgress = saveProgress ?? SaveProgressUseCase(),
        _answerQuiz = answerQuiz ?? AnswerQuizUseCase(),
        _completeDoc = completeDoc ?? CompleteDocUseCase(),
        _getWeekDocs = getWeekDocs ?? GetWeekDocsUseCase(),
        super(const DocReaderState());

  final String docId;

  /// Admin xem trước: đọc bản đang soạn (mọi trạng thái), không ghi tiến độ.
  final bool isAdminPreview;
  final GetLearnerDocUseCase _getLearnerDoc;
  final GetAdminDocUseCase _getAdminDoc;
  final SaveProgressUseCase _saveProgress;
  final AnswerQuizUseCase _answerQuiz;
  final CompleteDocUseCase _completeDoc;
  final GetWeekDocsUseCase _getWeekDocs;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, errorMessage: null));
    final Result<(WeeklyDoc, DocProgress, int)> loaded = isAdminPreview
        ? switch (await _getAdminDoc.execute(docId)) {
            Success(:final data) => Success((data.content.toDoc(), const DocProgress(), data.summary.version)),
            Failure(:final exception) => Failure(exception),
          }
        : switch (await _getLearnerDoc.execute(docId)) {
            Success(:final data) => Success((data.doc, data.progress, data.summary.version)),
            Failure(:final exception) => Failure(exception),
          };
    if (isClosed) return;
    switch (loaded) {
      case Failure(:final exception):
        emit(state.copyWith(status: LoadStatus.failure, errorMessage: exception.message));
      case Success(data: (final doc, final progress, final version)):
        final slides = buildSlides(doc);
        var start = 0;
        // Mở lại đúng section đang dở; đã học xong thì mở từ đầu.
        if (!isAdminPreview && !progress.completed) {
          start = slides.indexWhere((s) => s.sectionIndex == progress.lastSection);
          if (start < 0) start = slides.length - 1;
        }
        final meta = doc.meta;
        final view = isAdminPreview ? meta.defaultView : (meta.canSwitch ? (progress.lastView ?? meta.defaultView) : meta.allowedViews.first);
        emit(state.copyWith(
          status: LoadStatus.ready,
          doc: doc,
          docVersion: version,
          slides: slides,
          index: start.clamp(0, slides.isEmpty ? 0 : slides.length - 1),
          view: view,
          answers: isAdminPreview ? const {} : progress.answers,
        ));
        _record(state.index);
    }
  }

  /// PageView đã chuyển tới slide [index].
  void showSlide(int index) {
    if (index < 0 || index >= state.slides.length) return;
    emit(state.copyWith(index: index));
    _record(index);
  }

  void setView(DocViewMode view) {
    emit(state.copyWith(view: view));
    if (!isAdminPreview && state.slides.isNotEmpty) {
      unawaited(_saveProgress.execute(docId, sectionIndex: state.slides[state.index].sectionIndex, view: view));
    }
  }

  void answer(String blockKey, int option) {
    emit(state.copyWith(answers: {...state.answers, blockKey: option}));
    if (!isAdminPreview) unawaited(_answerQuiz.execute(docId, blockKey: blockKey, option: option));
  }

  /// Kiểu Doc: đã cuộn qua [seen] section (đỉnh section lên quá nửa màn hình).
  void markDocSeen(int seen) {
    if (seen == state.docSeen) return;
    emit(state.copyWith(docSeen: seen));
    if (!isAdminPreview && seen > 0) unawaited(_saveProgress.execute(docId, sectionIndex: seen - 1, view: DocViewMode.doc));
  }

  /// "Hoàn thành" / "Đánh dấu đã học xong". Admin xem trước: chỉ đóng màn.
  Future<void> complete() async {
    final doc = state.doc;
    if (doc == null || state.isCompleting) return;
    if (isAdminPreview) {
      emit(state.copyWith(closeRequests: state.closeRequests + 1));
      return;
    }
    emit(state.copyWith(isCompleting: true));
    final result = await _completeDoc.execute(docId);
    switch (result) {
      case Failure(:final exception):
        if (!isClosed) emit(state.copyWith(isCompleting: false, notice: UiNotice.next(state.notice, 'Chưa lưu được. ${exception.message}')));
      case Success(:final data):
        final nextDoc = await _nextDoc(doc);
        if (!isClosed) emit(state.copyWith(isCompleting: false, completion: DocCompleteArgs(doc: doc, result: data, nextDoc: nextDoc)));
    }
  }

  /// Tài liệu / bài tập kế tiếp cùng loại trong tuần; không tải được thì bỏ qua nút "Học … tiếp theo".
  Future<DocSummary?> _nextDoc(WeeklyDoc doc) async {
    switch (await _getWeekDocs.execute(doc.week)) {
      case Success(:final data):
        final sameKind = data.map((e) => e.summary).where((s) => s.category == doc.category && s.order > doc.order).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        return sameKind.isEmpty ? null : sameKind.first;
      case Failure():
        return null;
    }
  }

  void _record(int slideIndex) {
    if (isAdminPreview || state.slides.isEmpty) return;
    unawaited(_saveProgress.execute(docId, sectionIndex: state.slides[slideIndex].sectionIndex, view: state.view));
  }
}

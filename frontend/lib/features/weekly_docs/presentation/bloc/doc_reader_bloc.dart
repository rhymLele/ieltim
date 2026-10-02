import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/models/weekly_doc.dart';
import '../../data/weekly_docs_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class DocReaderEvent extends Equatable {
  const DocReaderEvent();
  @override
  List<Object?> get props => [];
}

class LoadDoc extends DocReaderEvent {
  final String docId;
  const LoadDoc({required this.docId});
  @override
  List<Object?> get props => [docId];
}

class SwitchViewMode extends DocReaderEvent {
  final DocViewMode mode;
  const SwitchViewMode({required this.mode});
  @override
  List<Object?> get props => [mode];
}

class SetSlide extends DocReaderEvent {
  final int index;
  const SetSlide({required this.index});
  @override
  List<Object?> get props => [index];
}

class AnswerQuiz extends DocReaderEvent {
  final String blockKey;
  final int selectedIndex;
  const AnswerQuiz({required this.blockKey, required this.selectedIndex});
  @override
  List<Object?> get props => [blockKey, selectedIndex];
}

class CompleteDoc extends DocReaderEvent {
  const CompleteDoc();
}

// ─── State ───────────────────────────────────────────────────────────────────

enum DocReaderStatus { initial, loading, ready, error }

class DocReaderState extends Equatable {
  const DocReaderState({
    this.status = DocReaderStatus.initial,
    this.error,
    this.doc,
    this.viewMode = DocViewMode.doc,
    this.currentSlide = 0,
    this.quizAnswers = const {},
    this.isCompleted = false,
  });

  final DocReaderStatus status;
  final String? error;
  final WeeklyDoc? doc;
  final DocViewMode viewMode;
  final int currentSlide;
  final Map<String, int> quizAnswers;
  final bool isCompleted;

  bool get isReady => status == DocReaderStatus.ready && doc != null;

  int get totalSlides => doc != null ? _countSlides(doc!.sections) : 0;

  static int _countSlides(List<DocSection> sections) {
    var count = 0;
    for (final s in sections) {
      var slideCount = 1;
      for (final b in s.blocks) {
        if (b is SlideBreakBlock) slideCount++;
      }
      count += slideCount;
    }
    return count == 0 ? 1 : count;
  }

  double get progress =>
      totalSlides == 0 ? 0 : (currentSlide + 1) / totalSlides;

  DocReaderState copyWith({
    DocReaderStatus? status,
    String? error,
    WeeklyDoc? doc,
    DocViewMode? viewMode,
    int? currentSlide,
    Map<String, int>? quizAnswers,
    bool? isCompleted,
    bool clearError = false,
  }) =>
      DocReaderState(
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
        doc: doc ?? this.doc,
        viewMode: viewMode ?? this.viewMode,
        currentSlide: currentSlide ?? this.currentSlide,
        quizAnswers: quizAnswers ?? this.quizAnswers,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  @override
  List<Object?> get props =>
      [status, error, doc, viewMode, currentSlide, quizAnswers, isCompleted];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class DocReaderBloc
    extends Bloc<DocReaderEvent, DocReaderState> {
  final WeeklyDocsRepository _repo;

  DocReaderBloc({required WeeklyDocsRepository repo})
      : _repo = repo,
        super(const DocReaderState()) {
    on<LoadDoc>(_onLoad);
    on<SwitchViewMode>(_onSwitchView);
    on<SetSlide>(_onSetSlide);
    on<AnswerQuiz>(_onAnswerQuiz);
    on<CompleteDoc>(_onComplete);
  }

  Future<void> _onLoad(
    LoadDoc event,
    Emitter<DocReaderState> emit,
  ) async {
    emit(state.copyWith(status: DocReaderStatus.loading, clearError: true));
    try {
      final doc = await _repo.getDocById(event.docId);
      if (doc == null) {
        emit(state.copyWith(
          status: DocReaderStatus.error,
          error: 'Không tìm thấy tài liệu',
        ));
        return;
      }
      final completed = await _repo.isCompleted(event.docId);
      final mode = doc.meta.defaultView;
      emit(state.copyWith(
        status: DocReaderStatus.ready,
        doc: doc,
        viewMode: mode,
        isCompleted: completed,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DocReaderStatus.error,
        error: 'Lỗi tải tài liệu: $e',
      ));
    }
  }

  void _onSwitchView(
    SwitchViewMode event,
    Emitter<DocReaderState> emit,
  ) {
    if (state.doc == null) return;
    if (!state.doc!.meta.allowedViews.contains(event.mode)) return;
    emit(state.copyWith(viewMode: event.mode));
  }

  void _onSetSlide(
    SetSlide event,
    Emitter<DocReaderState> emit,
  ) {
    final max = state.totalSlides - 1;
    final clamped = event.index.clamp(0, max < 0 ? 0 : max);
    emit(state.copyWith(currentSlide: clamped));
  }

  void _onAnswerQuiz(
    AnswerQuiz event,
    Emitter<DocReaderState> emit,
  ) {
    final updated = {...state.quizAnswers, event.blockKey: event.selectedIndex};
    emit(state.copyWith(quizAnswers: updated));
  }

  Future<void> _onComplete(
    CompleteDoc event,
    Emitter<DocReaderState> emit,
  ) async {
    final docId = state.doc?.id;
    if (docId == null || state.isCompleted) return;
    await _repo.markCompleted(docId);
    emit(state.copyWith(isCompleted: true));
  }
}

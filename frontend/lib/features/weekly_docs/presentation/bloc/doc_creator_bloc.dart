import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/models/weekly_doc.dart';
import '../../domain/doc_validator.dart';
import '../../data/weekly_docs_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class DocCreatorEvent extends Equatable {
  const DocCreatorEvent();
  @override
  List<Object?> get props => [];
}

class InitCreate extends DocCreatorEvent {
  final int? initialWeek;
  const InitCreate({this.initialWeek});
  @override
  List<Object?> get props => [initialWeek];
}

class InitEdit extends DocCreatorEvent {
  final String docId;
  const InitEdit({required this.docId});
  @override
  List<Object?> get props => [docId];
}

class GoToStep extends DocCreatorEvent {
  final int step;
  const GoToStep({required this.step});
  @override
  List<Object?> get props => [step];
}

class UpdateMetadata extends DocCreatorEvent {
  final String? title;
  final int? week;
  final int? order;
  final String? skill;
  final String? templateId;
  const UpdateMetadata({this.title, this.week, this.order, this.skill, this.templateId});
  @override
  List<Object?> get props => [title, week, order, skill, templateId];
}

class UpdateContent extends DocCreatorEvent {
  final List<DocSection> sections;
  const UpdateContent({required this.sections});
  @override
  List<Object?> get props => [sections];
}

class UpdatePublish extends DocCreatorEvent {
  final DocViewMode? defaultView;
  final List<DocViewMode>? allowedViews;
  final bool? allowUserSwitchView;
  const UpdatePublish({this.defaultView, this.allowedViews, this.allowUserSwitchView});
  @override
  List<Object?> get props => [defaultView, allowedViews, allowUserSwitchView];
}

class SaveAndProceed extends DocCreatorEvent {
  const SaveAndProceed();
}

class PublishDoc extends DocCreatorEvent {
  const PublishDoc();
}

// ─── State ───────────────────────────────────────────────────────────────────

class DocCreatorState extends Equatable {
  const DocCreatorState({
    this.step = 1,
    this.loading = false,
    this.error,
    this.doc,
    this.isNew = true,
    this.weeks = const [],
    this.validations = const [],
    this.publishResult,
  });

  final int step;
  final bool loading;
  final String? error;
  final WeeklyDoc? doc;
  final bool isNew;
  final List<int> weeks;
  final List<ValidationIssue> validations;
  final String? publishResult;

  bool get canGoNext {
    if (step == 1) {
      return doc != null &&
          doc!.meta.title.trim().length >= 3 &&
          doc!.meta.week > 0 &&
          doc!.meta.order > 0;
    }
    if (step == 2) return doc != null;
    return false;
  }

  DocCreatorState copyWith({
    int? step,
    bool? loading,
    String? error,
    WeeklyDoc? doc,
    bool? isNew,
    List<int>? weeks,
    List<ValidationIssue>? validations,
    String? publishResult,
    bool clearError = false,
  }) =>
      DocCreatorState(
        step: step ?? this.step,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        doc: doc ?? this.doc,
        isNew: isNew ?? this.isNew,
        weeks: weeks ?? this.weeks,
        validations: validations ?? this.validations,
        publishResult: publishResult ?? this.publishResult,
      );

  @override
  List<Object?> get props =>
      [step, loading, error, doc, isNew, weeks, validations, publishResult];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class DocCreatorBloc extends Bloc<DocCreatorEvent, DocCreatorState> {
  final WeeklyDocsRepository _repo;

  DocCreatorBloc({required WeeklyDocsRepository repo})
      : _repo = repo,
        super(const DocCreatorState()) {
    on<InitCreate>(_onInitCreate);
    on<InitEdit>(_onInitEdit);
    on<GoToStep>(_onGoToStep);
    on<UpdateMetadata>(_onUpdateMetadata);
    on<UpdateContent>(_onUpdateContent);
    on<UpdatePublish>(_onUpdatePublish);
    on<SaveAndProceed>(_onSaveAndProceed);
    on<PublishDoc>(_onPublish);
  }

  Future<void> _onInitCreate(
    InitCreate event,
    Emitter<DocCreatorState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    final weeks = await _repo.getAllWeeks();
    final defaultWeek = event.initialWeek ?? (weeks.isNotEmpty ? weeks.last : 1);
    emit(state.copyWith(
      loading: false,
      weeks: weeks,
      doc: WeeklyDoc(
        id: 'w${defaultWeek}-doc-new',
        meta: DocMeta(
          title: '',
          week: defaultWeek,
          order: 1,
          skills: const ['Reading'],
          status: DocStatus.draft,
        ),
        sections: const [],
      ),
      isNew: true,
    ));
  }

  Future<void> _onInitEdit(
    InitEdit event,
    Emitter<DocCreatorState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final doc = await _repo.getDocById(event.docId);
      final weeks = await _repo.getAllWeeks();
      if (doc == null) {
        emit(state.copyWith(loading: false, error: 'Không tìm thấy tài liệu'));
        return;
      }
      emit(state.copyWith(loading: false, doc: doc, weeks: weeks, isNew: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Lỗi: $e'));
    }
  }

  void _onGoToStep(GoToStep event, Emitter<DocCreatorState> emit) {
    final step = event.step.clamp(1, 3);
    if (step == 3) {
      final issues = validateWeeklyDoc(state.doc!);
      emit(state.copyWith(step: step, validations: issues.all));
    } else {
      emit(state.copyWith(step: step));
    }
  }

  void _onUpdateMetadata(
    UpdateMetadata event,
    Emitter<DocCreatorState> emit,
  ) {
    final doc = state.doc;
    if (doc == null) return;
    final meta = doc.meta.copyWith(
      title: event.title ?? doc.meta.title,
      week: event.week ?? doc.meta.week,
      order: event.order ?? doc.meta.order,
      skills: event.skill != null ? [event.skill!] : doc.meta.skills,
      defaultView: event.skill != null && event.skill! != doc.meta.skill
          ? DocViewMode.doc
          : doc.meta.defaultView,
    );
    emit(state.copyWith(doc: doc.copyWith(meta: meta)));
  }

  void _onUpdateContent(
    UpdateContent event,
    Emitter<DocCreatorState> emit,
  ) {
    final doc = state.doc;
    if (doc == null) return;
    emit(state.copyWith(doc: doc.copyWith(sections: event.sections)));
  }

  void _onUpdatePublish(
    UpdatePublish event,
    Emitter<DocCreatorState> emit,
  ) {
    final doc = state.doc;
    if (doc == null) return;
    final meta = doc.meta.copyWith(
      defaultView: event.defaultView ?? doc.meta.defaultView,
      allowedViews: event.allowedViews ?? doc.meta.allowedViews,
      allowUserSwitchView: event.allowUserSwitchView ?? doc.meta.allowUserSwitchView,
    );
    emit(state.copyWith(doc: doc.copyWith(meta: meta)));
  }

  Future<void> _onSaveAndProceed(
    SaveAndProceed event,
    Emitter<DocCreatorState> emit,
  ) async {
    final doc = state.doc;
    if (doc == null) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      WeeklyDoc saved;
      if (state.isNew) {
        final week = doc.meta.week;
        final id = 'w${week}-doc${doc.meta.order}';
        saved = doc.copyWith(id: id);
        await _repo.createDoc(saved);
        emit(state.copyWith(loading: false, doc: saved, isNew: false));
      } else {
        saved = await _repo.updateDoc(doc);
        emit(state.copyWith(loading: false, doc: saved));
      }
      emit(state.copyWith(step: state.step + 1));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Lỗi lưu: $e'));
    }
  }

  Future<void> _onPublish(
    PublishDoc event,
    Emitter<DocCreatorState> emit,
  ) async {
    final doc = state.doc;
    if (doc == null) return;
    final issues = validateWeeklyDoc(doc);
    if (issues.errors.isNotEmpty) {
      emit(state.copyWith(
        validations: issues.all,
        error: 'Còn ${issues.errors.length} lỗi cần sửa',
      ));
      return;
    }
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final saved = await _repo.publishDoc(doc.id);
      emit(state.copyWith(
        loading: false,
        doc: saved,
        publishResult: 'Đã xuất bản thành công',
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Xuất bản thất bại: $e'));
    }
  }
}

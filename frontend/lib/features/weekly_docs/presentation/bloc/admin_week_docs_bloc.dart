import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/models/weekly_doc.dart';
import '../../data/weekly_docs_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class AdminWeekDocsEvent extends Equatable {
  const AdminWeekDocsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminDocs extends AdminWeekDocsEvent {
  const LoadAdminDocs();
}

class SetWeekFilter extends AdminWeekDocsEvent {
  final int? week;
  const SetWeekFilter({required this.week});
  @override
  List<Object?> get props => [week];
}

class SetStatusFilter extends AdminWeekDocsEvent {
  final DocStatus? status;
  const SetStatusFilter({required this.status});
  @override
  List<Object?> get props => [status];
}

class SetSkillFilter extends AdminWeekDocsEvent {
  final String? skill;
  const SetSkillFilter({required this.skill});
  @override
  List<Object?> get props => [skill];
}

class SetSearch extends AdminWeekDocsEvent {
  final String query;
  const SetSearch({required this.query});
  @override
  List<Object?> get props => [query];
}

class DeleteDocEvent extends AdminWeekDocsEvent {
  final String docId;
  const DeleteDocEvent({required this.docId});
  @override
  List<Object?> get props => [docId];
}

class PublishDocEvent extends AdminWeekDocsEvent {
  final String docId;
  const PublishDocEvent({required this.docId});
  @override
  List<Object?> get props => [docId];
}

class UnpublishDocEvent extends AdminWeekDocsEvent {
  final String docId;
  const UnpublishDocEvent({required this.docId});
  @override
  List<Object?> get props => [docId];
}

class RestoreDocEvent extends AdminWeekDocsEvent {
  final String docId;
  const RestoreDocEvent({required this.docId});
  @override
  List<Object?> get props => [docId];
}

class DuplicateDocEvent extends AdminWeekDocsEvent {
  final String docId;
  final int? targetWeek;
  const DuplicateDocEvent({required this.docId, this.targetWeek});
  @override
  List<Object?> get props => [docId, targetWeek];
}

// ─── State ───────────────────────────────────────────────────────────────────

class AdminWeekDocsState extends Equatable {
  const AdminWeekDocsState({
    this.loading = false,
    this.error,
    this.docs = const [],
    this.weeks = const [],
    this.filterWeek,
    this.filterStatus,
    this.filterSkill,
    this.searchQuery = '',
    this.lastAction,
  });

  final bool loading;
  final String? error;
  final List<WeeklyDoc> docs;
  final List<int> weeks;
  final int? filterWeek;
  final DocStatus? filterStatus;
  final String? filterSkill;
  final String searchQuery;

  /// Snackbar message after an action.
  final String? lastAction;

  AdminDocFilter get filter => AdminDocFilter(
        week: filterWeek,
        status: filterStatus,
        skill: filterSkill,
        search: searchQuery,
      );

  AdminWeekDocsState copyWith({
    bool? loading,
    String? error,
    List<WeeklyDoc>? docs,
    List<int>? weeks,
    int? filterWeek,
    DocStatus? filterStatus,
    String? filterSkill,
    String? searchQuery,
    String? lastAction,
    bool clearError = false,
    bool clearAction = false,
    bool clearWeek = false,
    bool clearStatus = false,
    bool clearSkill = false,
  }) =>
      AdminWeekDocsState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        docs: docs ?? this.docs,
        weeks: weeks ?? this.weeks,
        filterWeek: clearWeek ? null : (filterWeek ?? this.filterWeek),
        filterStatus: clearStatus ? null : (filterStatus ?? this.filterStatus),
        filterSkill: clearSkill ? null : (filterSkill ?? this.filterSkill),
        searchQuery: searchQuery ?? this.searchQuery,
        lastAction: clearAction ? null : (lastAction ?? this.lastAction),
      );

  @override
  List<Object?> get props => [
        loading, error, docs, weeks,
        filterWeek, filterStatus, filterSkill, searchQuery, lastAction,
      ];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class AdminWeekDocsBloc
    extends Bloc<AdminWeekDocsEvent, AdminWeekDocsState> {
  final WeeklyDocsRepository _repo;

  AdminWeekDocsBloc({required WeeklyDocsRepository repo})
      : _repo = repo,
        super(const AdminWeekDocsState()) {
    on<LoadAdminDocs>(_onLoad);
    on<SetWeekFilter>(_onFilterChange);
    on<SetStatusFilter>(_onFilterChange);
    on<SetSkillFilter>(_onFilterChange);
    on<SetSearch>(_onFilterChange);
    on<DeleteDocEvent>(_onDelete);
    on<PublishDocEvent>(_onPublish);
    on<UnpublishDocEvent>(_onUnpublish);
    on<RestoreDocEvent>(_onRestore);
    on<DuplicateDocEvent>(_onDuplicate);
  }

  Future<void> _onLoad(
    LoadAdminDocs event,
    Emitter<AdminWeekDocsState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final (docs, weeks) = await Future.wait([
        _repo.getAdminDocs(filter: state.filter),
        _repo.getAllWeeks(),
      ]);
      emit(state.copyWith(loading: false, docs: docs, weeks: weeks));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Lỗi tải: $e'));
    }
  }

  Future<void> _onFilterChange(
    AdminWeekDocsEvent event,
    Emitter<AdminWeekDocsState> emit,
  ) async {
    if (event is SetWeekFilter) {
      emit(state.copyWith(filterWeek: event.week, clearWeek: event.week == null));
    } else if (event is SetStatusFilter) {
      emit(state.copyWith(filterStatus: event.status, clearStatus: event.status == null));
    } else if (event is SetSkillFilter) {
      emit(state.copyWith(filterSkill: event.skill, clearSkill: event.skill == null || event.skill!.isEmpty));
    } else if (event is SetSearch) {
      emit(state.copyWith(searchQuery: event.query));
    }
    // Reload
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final docs = await _repo.getAdminDocs(filter: state.filter);
      emit(state.copyWith(loading: false, docs: docs));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Lỗi: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteDocEvent event,
    Emitter<AdminWeekDocsState> emit,
  ) async {
    try {
      await _repo.deleteDoc(event.docId);
      emit(state.copyWith(lastAction: 'Đã xoá tài liệu'));
      final docs = await _repo.getAdminDocs(filter: state.filter);
      emit(state.copyWith(docs: docs));
    } catch (e) {
      emit(state.copyWith(error: 'Xoá thất bại: $e'));
    }
  }

  Future<void> _onPublish(
    PublishDocEvent event,
    Emitter<AdminWeekDocsState> emit,
  ) async {
    try {
      await _repo.publishDoc(event.docId);
      emit(state.copyWith(lastAction: 'Đã xuất bản'));
      final docs = await _repo.getAdminDocs(filter: state.filter);
      emit(state.copyWith(docs: docs));
    } catch (e) {
      emit(state.copyWith(error: 'Xuất bản thất bại: $e'));
    }
  }

  Future<void> _onUnpublish(
    UnpublishDocEvent event,
    Emitter<AdminWeekDocsState> emit,
  ) async {
    try {
      await _repo.unpublishDoc(event.docId);
      emit(state.copyWith(lastAction: 'Đã gỡ tài liệu'));
      final docs = await _repo.getAdminDocs(filter: state.filter);
      emit(state.copyWith(docs: docs));
    } catch (e) {
      emit(state.copyWith(error: 'Gỡ thất bại: $e'));
    }
  }

  Future<void> _onRestore(
    RestoreDocEvent event,
    Emitter<AdminWeekDocsState> emit,
  ) async {
    try {
      await _repo.restoreDoc(event.docId);
      emit(state.copyWith(lastAction: 'Đã khôi phục'));
      final docs = await _repo.getAdminDocs(filter: state.filter);
      emit(state.copyWith(docs: docs));
    } catch (e) {
      emit(state.copyWith(error: 'Khôi phục thất bại: $e'));
    }
  }

  Future<void> _onDuplicate(
    DuplicateDocEvent event,
    Emitter<AdminWeekDocsState> emit,
  ) async {
    try {
      await _repo.duplicateDoc(event.docId, targetWeek: event.targetWeek);
      emit(state.copyWith(lastAction: 'Đã nhân bản'));
      final docs = await _repo.getAdminDocs(filter: state.filter);
      emit(state.copyWith(docs: docs));
    } catch (e) {
      emit(state.copyWith(error: 'Nhân bản thất bại: $e'));
    }
  }
}

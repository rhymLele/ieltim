import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/vietnamese_text.dart';
import '../../domain/entities/admin_doc.dart';
import '../../domain/entities/doc_status.dart';
import '../../domain/entities/doc_summary.dart';
import '../../domain/entities/week_info.dart';
import '../../domain/entities/weekly_docs_change.dart';
import '../../domain/usecases/delete_doc_use_case.dart';
import '../../domain/usecases/duplicate_doc_use_case.dart';
import '../../domain/usecases/get_admin_doc_use_case.dart';
import '../../domain/usecases/get_admin_docs_use_case.dart';
import '../../domain/usecases/get_weeks_use_case.dart';
import '../../domain/usecases/restore_doc_use_case.dart';
import '../../domain/usecases/undo_delete_doc_use_case.dart';
import '../../domain/usecases/unpublish_doc_use_case.dart';
import '../../domain/usecases/unschedule_doc_use_case.dart';
import '../../domain/usecases/watch_weekly_docs_changes_use_case.dart';
import 'ui_state.dart';

class AdminDocsState {
  const AdminDocsState({
    this.status = LoadStatus.loading,
    this.errorMessage,
    this.weeks = const [],
    this.docs = const [],
    this.week,
    this.statuses = const {},
    this.categories = const {},
    this.query = '',
    this.notice,
  });

  final LoadStatus status;
  final String? errorMessage;
  final List<WeekInfo> weeks;
  final List<DocSummary> docs;

  /// Tuần đang lọc; null = tất cả tuần.
  final int? week;
  final Set<DocStatus> statuses;

  /// Lọc Tài liệu / Bài tập; rỗng = cả hai.
  final Set<DocCategory> categories;
  final String query;
  final UiNotice? notice;

  /// Danh sách sau khi lọc tuần, trạng thái, loại, tiêu đề (không dấu); tuần mới trước, trong tuần tài liệu
  /// trước rồi bài tập, mỗi loại theo số thứ tự.
  List<DocSummary> get visibleDocs {
    final needle = foldVietnamese(query);
    return docs
        .where((d) => week == null || d.week == week)
        .where((d) => statuses.isEmpty || statuses.contains(d.status))
        .where((d) => categories.isEmpty || categories.contains(d.category))
        .where((d) => needle.isEmpty || foldVietnamese(d.title).contains(needle))
        .toList()
      ..sort((a, b) {
        if (a.week != b.week) return b.week.compareTo(a.week);
        if (a.category != b.category) return a.category.index.compareTo(b.category.index);
        return a.order.compareTo(b.order);
      });
  }

  AdminDocsState copyWith({
    LoadStatus? status,
    Object? errorMessage = keep,
    List<WeekInfo>? weeks,
    List<DocSummary>? docs,
    Object? week = keep,
    Set<DocStatus>? statuses,
    Set<DocCategory>? categories,
    String? query,
    UiNotice? notice,
  }) =>
      AdminDocsState(
        status: status ?? this.status,
        errorMessage: identical(errorMessage, keep) ? this.errorMessage : errorMessage as String?,
        weeks: weeks ?? this.weeks,
        docs: docs ?? this.docs,
        week: identical(week, keep) ? this.week : week as int?,
        statuses: statuses ?? this.statuses,
        categories: categories ?? this.categories,
        query: query ?? this.query,
        notice: notice ?? this.notice,
      );
}

/// Màn quản lý tài liệu theo tuần (A1): lọc, nhân bản, hẹn giờ, gỡ, khôi phục, xoá / hoàn tác, tải JSON.
class AdminDocsCubit extends Cubit<AdminDocsState> {
  AdminDocsCubit({
    GetWeeksUseCase? getWeeks,
    GetAdminDocsUseCase? getAdminDocs,
    GetAdminDocUseCase? getAdminDoc,
    DuplicateDocUseCase? duplicateDoc,
    UnscheduleDocUseCase? unscheduleDoc,
    UnpublishDocUseCase? unpublishDoc,
    RestoreDocUseCase? restoreDoc,
    DeleteDocUseCase? deleteDoc,
    UndoDeleteDocUseCase? undoDeleteDoc,
    WatchWeeklyDocsChangesUseCase? watchChanges,
  })  : _getWeeks = getWeeks ?? GetWeeksUseCase(),
        _getAdminDocs = getAdminDocs ?? GetAdminDocsUseCase(),
        _getAdminDoc = getAdminDoc ?? GetAdminDocUseCase(),
        _duplicateDoc = duplicateDoc ?? DuplicateDocUseCase(),
        _unscheduleDoc = unscheduleDoc ?? UnscheduleDocUseCase(),
        _unpublishDoc = unpublishDoc ?? UnpublishDocUseCase(),
        _restoreDoc = restoreDoc ?? RestoreDocUseCase(),
        _deleteDoc = deleteDoc ?? DeleteDocUseCase(),
        _undoDeleteDoc = undoDeleteDoc ?? UndoDeleteDocUseCase(),
        super(const AdminDocsState()) {
    // Màn soạn nằm trên danh sách: mỗi lần lưu / xuất bản ở đó thì tải lại danh sách.
    _changes = (watchChanges ?? WatchWeeklyDocsChangesUseCase()).execute().where((c) => c is DocumentsChanged).listen((_) => _reloadDocs());
  }

  final GetWeeksUseCase _getWeeks;
  final GetAdminDocsUseCase _getAdminDocs;
  final GetAdminDocUseCase _getAdminDoc;
  final DuplicateDocUseCase _duplicateDoc;
  final UnscheduleDocUseCase _unscheduleDoc;
  final UnpublishDocUseCase _unpublishDoc;
  final RestoreDocUseCase _restoreDoc;
  final DeleteDocUseCase _deleteDoc;
  final UndoDeleteDocUseCase _undoDeleteDoc;
  late final StreamSubscription<WeeklyDocsChange> _changes;

  /// Tải tuần + tài liệu; lần đầu lọc theo tuần chứa hôm nay (không có thì "Tất cả tuần").
  Future<void> load() async {
    final weeks = await _getWeeks.execute();
    final docs = await _getAdminDocs.execute();
    if (isClosed) return;
    switch ((weeks, docs)) {
      case (Success(data: final weekList), Success(data: final docList)):
        final current = weekList.currentWeekNumber;
        final keepWeek = state.status == LoadStatus.ready;
        emit(state.copyWith(
          status: LoadStatus.ready,
          errorMessage: null,
          weeks: weekList.weeks,
          docs: docList,
          week: keepWeek ? state.week : (current == 0 ? null : current),
        ));
      case (Failure(:final exception), _) || (_, Failure(:final exception)):
        emit(state.copyWith(status: LoadStatus.failure, errorMessage: exception.message));
    }
  }

  Future<void> retry() {
    emit(state.copyWith(status: LoadStatus.loading, errorMessage: null));
    return load();
  }

  void setWeek(int? week) => emit(state.copyWith(week: week));

  void toggleStatus(DocStatus status, {required bool selected}) =>
      emit(state.copyWith(statuses: selected ? {...state.statuses, status} : ({...state.statuses}..remove(status))));

  void toggleCategory(DocCategory category, {required bool selected}) =>
      emit(state.copyWith(categories: selected ? {...state.categories, category} : ({...state.categories}..remove(category))));

  void setQuery(String query) => emit(state.copyWith(query: query));

  Future<void> duplicate(String id, int targetWeek) => _write(
        _duplicateDoc.execute(id, targetWeek: targetWeek),
        (copy) => 'Đã nhân bản thành Tuần ${copy.summary.week} · Tài liệu ${copy.summary.order}',
      );

  Future<void> unschedule(String id) => _write(_unscheduleDoc.execute(id), (_) => 'Đã huỷ hẹn giờ');

  Future<void> unpublish(String id) => _write(_unpublishDoc.execute(id), (_) => 'Đã gỡ tài liệu');

  Future<void> restore(String id) => _write(_restoreDoc.execute(id), (_) => 'Đã khôi phục về nháp');

  Future<void> delete(String id) async {
    final result = await _deleteDoc.execute(id);
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(state.copyWith(notice: UiNotice.next(state.notice, 'Đã xoá', undoDocId: id)));
      case Failure(:final exception):
        _notify(exception.message);
    }
  }

  Future<void> undoDelete(String id) => _write(_undoDeleteDoc.execute(id), (_) => 'Đã hoàn tác xoá');

  /// JSON đầy đủ (thụt lề 2) để tải về; null nếu không tải được (đã báo lỗi).
  Future<String?> exportJson(String id) async {
    switch (await _getAdminDoc.execute(id)) {
      case Success(:final data):
        return const JsonEncoder.withIndent('  ').convert(data.content.value);
      case Failure(:final exception):
        _notify(exception.message);
        return null;
    }
  }

  Future<void> _write(Future<Result<AdminDoc>> action, String Function(AdminDoc doc) successMessage) async {
    switch (await action) {
      case Success(:final data):
        _notify(successMessage(data));
      case Failure(:final exception):
        _notify(exception.message);
    }
  }

  Future<void> _reloadDocs() async {
    final result = await _getAdminDocs.execute();
    if (isClosed) return;
    if (result case Success(:final data)) emit(state.copyWith(docs: data));
  }

  void _notify(String message) {
    if (!isClosed) emit(state.copyWith(notice: UiNotice.next(state.notice, message)));
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/learner_doc.dart';
import '../../domain/entities/week_info.dart';
import '../../domain/entities/weekly_docs_change.dart';
import '../../domain/usecases/get_week_docs_use_case.dart';
import '../../domain/usecases/get_weeks_use_case.dart';
import '../../domain/usecases/watch_weekly_docs_changes_use_case.dart';
import 'ui_state.dart';

class WeeksState {
  const WeeksState({
    this.status = LoadStatus.loading,
    this.weekList = const WeekList(weeks: []),
    this.selectedWeek = 0,
    this.entries = const [],
    this.isLoadingDocs = false,
    this.errorMessage,
    this.notice,
  });

  final LoadStatus status;
  final WeekList weekList;
  final int selectedWeek;
  final List<WeekDocEntry> entries;
  final bool isLoadingDocs;
  final String? errorMessage;
  final UiNotice? notice;

  WeekInfo? get selected => weekList.byNumber(selectedWeek);

  /// Tuần đã mở + tuần sắp mở gần nhất (BE sinh sẵn vài tuần tới cho admin soạn trước).
  List<WeekInfo> get visibleWeeks {
    final weeks = weekList.weeks;
    final firstLocked = weeks.indexWhere((w) => w.isLocked);
    return [
      for (var i = 0; i < weeks.length; i++)
        if (!weeks[i].isLocked || i == firstLocked) weeks[i],
    ];
  }

  WeeksState copyWith({
    LoadStatus? status,
    WeekList? weekList,
    int? selectedWeek,
    List<WeekDocEntry>? entries,
    bool? isLoadingDocs,
    Object? errorMessage = keep,
    UiNotice? notice,
  }) =>
      WeeksState(
        status: status ?? this.status,
        weekList: weekList ?? this.weekList,
        selectedWeek: selectedWeek ?? this.selectedWeek,
        entries: entries ?? this.entries,
        isLoadingDocs: isLoadingDocs ?? this.isLoadingDocs,
        errorMessage: identical(errorMessage, keep) ? this.errorMessage : errorMessage as String?,
        notice: notice ?? this.notice,
      );
}

/// Màn "Theo tuần" (U1): danh sách tuần + tài liệu của tuần đang chọn.
class WeeksCubit extends Cubit<WeeksState> {
  WeeksCubit({GetWeeksUseCase? getWeeks, GetWeekDocsUseCase? getWeekDocs, WatchWeeklyDocsChangesUseCase? watchChanges})
      : _getWeeks = getWeeks ?? GetWeeksUseCase(),
        _getWeekDocs = getWeekDocs ?? GetWeekDocsUseCase(),
        super(const WeeksState()) {
    _changes = (watchChanges ?? WatchWeeklyDocsChangesUseCase()).execute().listen(_onChange);
  }

  final GetWeeksUseCase _getWeeks;
  final GetWeekDocsUseCase _getWeekDocs;
  late final StreamSubscription<WeeklyDocsChange> _changes;

  /// Tải tuần, chọn tuần hiện tại (giữ tuần đang chọn nếu vẫn mở), rồi tải tài liệu của tuần đó.
  Future<void> load() async {
    final result = await _getWeeks.execute();
    if (isClosed) return;
    switch (result) {
      case Failure(:final exception):
        emit(state.copyWith(status: LoadStatus.failure, errorMessage: exception.message));
      case Success(:final data):
        final selected = _isOpen(data, state.selectedWeek) ? state.selectedWeek : data.currentWeekNumber;
        emit(state.copyWith(status: LoadStatus.ready, weekList: data, selectedWeek: selected, errorMessage: null));
        if (_isOpen(data, selected)) await _loadDocs(selected);
    }
  }

  Future<void> refresh() {
    emit(state.copyWith(status: LoadStatus.loading, errorMessage: null));
    return load();
  }

  Future<void> selectWeek(int number) async {
    emit(state.copyWith(selectedWeek: number, entries: const []));
    await _loadDocs(number);
  }

  Future<void> _loadDocs(int week) async {
    emit(state.copyWith(isLoadingDocs: true));
    final result = await _getWeekDocs.execute(week);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        if (state.selectedWeek == week) emit(state.copyWith(entries: data, isLoadingDocs: false));
      case Failure(:final exception):
        emit(state.copyWith(isLoadingDocs: false, notice: UiNotice.next(state.notice, exception.message)));
    }
  }

  void _onChange(WeeklyDocsChange change) {
    switch (change) {
      case ProgressChanged(:final docId, :final progress):
        // Đọc thêm section ở màn đọc (đang nằm trên): cập nhật thẻ tài liệu, không cần gọi lại API.
        emit(state.copyWith(entries: [
          for (final e in state.entries) e.summary.id == docId ? WeekDocEntry(summary: e.summary, progress: progress) : e,
        ]));
      case DocCompleted() || DocumentsChanged():
        load();
    }
  }

  static bool _isOpen(WeekList list, int number) => list.byNumber(number)?.isLocked == false;

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}

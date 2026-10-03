import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/doc_summary.dart';
import '../../domain/entities/learning_results.dart';
import '../../domain/entities/weekly_doc.dart';
import '../../domain/usecases/save_vocab_from_doc_use_case.dart';
import 'ui_state.dart';

/// Dữ liệu màn hoàn thành, truyền qua `extra` của route: kết quả "Hoàn thành" chỉ có ngay sau khi bấm,
/// không dựng lại được từ URL.
class DocCompleteArgs {
  const DocCompleteArgs({required this.doc, required this.result, this.nextDoc});

  final WeeklyDoc doc;
  final CompleteResult result;

  /// Tài liệu kế tiếp trong tuần (để "Học tài liệu tiếp theo"), null nếu đã là cuối tuần.
  final DocSummary? nextDoc;
}

class DocCompleteState {
  const DocCompleteState({this.isSaving = false, this.savedCount, this.notice});

  final bool isSaving;

  /// Số từ vừa thêm vào Sổ từ; null khi chưa lưu.
  final int? savedCount;
  final UiNotice? notice;
}

/// Màn hoàn thành (U3): lưu từ vựng của tài liệu vào Sổ từ.
class DocCompleteCubit extends Cubit<DocCompleteState> {
  DocCompleteCubit({SaveVocabFromDocUseCase? saveVocab})
      : _saveVocab = saveVocab ?? SaveVocabFromDocUseCase(),
        super(const DocCompleteState());

  final SaveVocabFromDocUseCase _saveVocab;

  Future<void> saveVocab(String docId) async {
    if (state.isSaving) return;
    emit(DocCompleteState(isSaving: true, savedCount: state.savedCount, notice: state.notice));
    final result = await _saveVocab.execute(docId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(DocCompleteState(savedCount: data.added, notice: state.notice));
      case Failure(:final exception):
        emit(DocCompleteState(savedCount: state.savedCount, notice: UiNotice.next(state.notice, exception.message)));
    }
  }
}

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../repositories/weekly_docs_repository.dart';

class DeleteDocUseCase {
  DeleteDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Xoá nháp chưa từng xuất bản (hoàn tác được bằng [UndoDeleteDocUseCase]).
  Future<Result<void>> execute(String id) => _repository.delete(id);
}

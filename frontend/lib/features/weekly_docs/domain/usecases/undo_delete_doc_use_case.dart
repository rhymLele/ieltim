import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class UndoDeleteDocUseCase {
  UndoDeleteDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Hoàn tác xoá nháp.
  Future<Result<AdminDoc>> execute(String id) => _repository.undoDelete(id);
}

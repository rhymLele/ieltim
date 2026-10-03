import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/learning_results.dart';
import '../repositories/weekly_docs_repository.dart';

class CompleteDocUseCase {
  CompleteDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Đánh dấu đã học xong tài liệu [id] (idempotent); trả chặng Vũ Môn và streak.
  Future<Result<CompleteResult>> execute(String id) => _repository.completeDoc(id);
}

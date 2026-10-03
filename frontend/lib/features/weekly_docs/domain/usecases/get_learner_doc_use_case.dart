import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/learner_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class GetLearnerDocUseCase {
  GetLearnerDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Mở tài liệu để đọc: nội dung + tiến độ của tôi.
  Future<Result<LearnerDoc>> execute(String id) => _repository.getLearnerDoc(id);
}

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/learner_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class GetWeekDocsUseCase {
  GetWeekDocsUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Lấy tài liệu đã xuất bản của tuần [week] kèm tiến độ của tôi.
  Future<Result<List<WeekDocEntry>>> execute(int week) => _repository.getWeekDocs(week);
}

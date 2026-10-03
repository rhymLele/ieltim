import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/week_info.dart';
import '../repositories/weekly_docs_repository.dart';

class GetWeeksUseCase {
  GetWeeksUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Lấy các tuần kèm trạng thái mở / khoá và số tài liệu đã học.
  Future<Result<WeekList>> execute() => _repository.getWeeks();
}

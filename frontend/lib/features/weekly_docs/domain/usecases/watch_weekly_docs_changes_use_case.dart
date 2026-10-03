import '../../../../core/di/service_locator.dart';
import '../entities/weekly_docs_change.dart';
import '../repositories/weekly_docs_repository.dart';

class WatchWeeklyDocsChangesUseCase {
  WatchWeeklyDocsChangesUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Luồng thay đổi sau mỗi lần ghi thành công; không phát lại các thay đổi đã qua.
  Stream<WeeklyDocsChange> execute() => _repository.changes;
}

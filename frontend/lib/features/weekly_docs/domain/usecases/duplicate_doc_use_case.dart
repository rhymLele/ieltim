import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class DuplicateDocUseCase {
  DuplicateDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Nhân bản tài liệu [id] sang tuần [targetWeek] thành nháp mới.
  Future<Result<AdminDoc>> execute(String id, {required int targetWeek}) => _repository.duplicate(id, targetWeek: targetWeek);
}

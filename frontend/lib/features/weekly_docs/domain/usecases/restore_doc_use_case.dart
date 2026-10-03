import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class RestoreDocUseCase {
  RestoreDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Khôi phục tài liệu đã gỡ về nháp.
  Future<Result<AdminDoc>> execute(String id) => _repository.restore(id);
}

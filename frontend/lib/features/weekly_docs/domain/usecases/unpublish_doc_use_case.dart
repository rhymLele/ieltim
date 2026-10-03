import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class UnpublishDocUseCase {
  UnpublishDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Gỡ tài liệu đang xuất bản; tiến độ của người học vẫn giữ.
  Future<Result<AdminDoc>> execute(String id) => _repository.unpublish(id);
}

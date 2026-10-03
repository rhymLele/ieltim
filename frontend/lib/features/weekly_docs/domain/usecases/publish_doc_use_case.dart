import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class PublishDocUseCase {
  PublishDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Xuất bản ngay, hoặc hẹn giờ nếu có [at]. Còn lỗi → `InvalidContentException`.
  Future<Result<AdminDoc>> execute(String id, {DateTime? at}) => _repository.publish(id, at: at);
}

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class GetAdminDocUseCase {
  GetAdminDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Lấy bản đang soạn đủ nội dung của tài liệu [id].
  Future<Result<AdminDoc>> execute(String id) => _repository.getAdminDoc(id);
}

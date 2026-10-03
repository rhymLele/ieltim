import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/doc_summary.dart';
import '../repositories/weekly_docs_repository.dart';

class GetAdminDocsUseCase {
  GetAdminDocsUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// Lấy mọi tài liệu cho màn quản lý (không kèm nội dung).
  Future<Result<List<DocSummary>>> execute() => _repository.getAdminDocs();
}

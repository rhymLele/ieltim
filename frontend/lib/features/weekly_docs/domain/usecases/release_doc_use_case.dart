import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/admin_doc.dart';
import '../repositories/weekly_docs_repository.dart';

class ReleaseDocUseCase {
  ReleaseDocUseCase([WeeklyDocsRepository? repository]) : _repository = repository ?? getSingleton<WeeklyDocsRepository>();

  final WeeklyDocsRepository _repository;

  /// "Cập nhật bản phát hành": áp dụng bản nháp sửa đổi của tài liệu đang xuất bản.
  Future<Result<AdminDoc>> execute(String id) => _repository.release(id);
}

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/doc_annotations.dart';
import '../repositories/annotate_repository.dart';

class RefreshAnnotationsUseCase {
  RefreshAnnotationsUseCase([AnnotateRepository? repository]) : _repository = repository ?? getSingleton<AnnotateRepository>();

  final AnnotateRepository _repository;

  /// Tải bản mới nhất từ máy chủ, giữ các thay đổi chưa gửi.
  Future<Result<DocAnnotations>> execute(String docId) => _repository.refresh(docId);
}

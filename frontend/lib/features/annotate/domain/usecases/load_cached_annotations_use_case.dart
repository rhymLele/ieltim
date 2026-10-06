import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/doc_annotations.dart';
import '../repositories/annotate_repository.dart';

class LoadCachedAnnotationsUseCase {
  LoadCachedAnnotationsUseCase([AnnotateRepository? repository]) : _repository = repository ?? getSingleton<AnnotateRepository>();

  final AnnotateRepository _repository;

  /// Highlight và ghi chú đã lưu trên máy (hiện ngay khi mở tài liệu).
  Future<Result<DocAnnotations>> execute(String docId) => _repository.loadCached(docId);
}

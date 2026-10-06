import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/annotate/models.dart';
import '../repositories/annotate_repository.dart';

class SaveHighlightUseCase {
  SaveHighlightUseCase([AnnotateRepository? repository]) : _repository = repository ?? getSingleton<AnnotateRepository>();

  final AnnotateRepository _repository;

  /// Thêm / đổi màu highlight; lưu trên máy ngay, gửi BE sau.
  Future<void> execute(String docId, int docVersion, TextHighlight highlight) => _repository.saveHighlight(docId, docVersion, highlight);
}

import '../../../../core/di/service_locator.dart';
import '../repositories/annotate_repository.dart';

class DeleteHighlightUseCase {
  DeleteHighlightUseCase([AnnotateRepository? repository]) : _repository = repository ?? getSingleton<AnnotateRepository>();

  final AnnotateRepository _repository;

  /// Bỏ highlight.
  Future<void> execute(String docId, String id) => _repository.deleteHighlight(docId, id);
}

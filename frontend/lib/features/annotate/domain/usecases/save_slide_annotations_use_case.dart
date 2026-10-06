import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/annotate/models.dart';
import '../repositories/annotate_repository.dart';

class SaveSlideAnnotationsUseCase {
  SaveSlideAnnotationsUseCase([AnnotateRepository? repository]) : _repository = repository ?? getSingleton<AnnotateRepository>();

  final AnnotateRepository _repository;

  /// Lưu ghi chú vẽ của một slide; gửi BE sau một nhịp ngừng thao tác.
  Future<void> execute(String docId, int docVersion, String slideKey, SlideAnnotations data) =>
      _repository.saveSlide(docId, docVersion, slideKey, data);
}

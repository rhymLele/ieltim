import '../../../../core/di/service_locator.dart';
import '../entities/doc_annotations.dart';
import '../repositories/annotate_repository.dart';

class WatchMergedSlidesUseCase {
  WatchMergedSlidesUseCase([AnnotateRepository? repository]) : _repository = repository ?? getSingleton<AnnotateRepository>();

  final AnnotateRepository _repository;

  /// Slide vừa được gộp sau xung đột với máy khác.
  Stream<SlideAnnotationsMerged> execute() => _repository.mergedSlides;
}

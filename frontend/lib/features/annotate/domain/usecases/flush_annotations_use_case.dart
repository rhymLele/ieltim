import '../../../../core/di/service_locator.dart';
import '../repositories/annotate_repository.dart';

class FlushAnnotationsUseCase {
  FlushAnnotationsUseCase([AnnotateRepository? repository]) : _repository = repository ?? getSingleton<AnnotateRepository>();

  final AnnotateRepository _repository;

  /// Gửi ngay mọi thay đổi đang chờ.
  Future<void> execute() => _repository.flush();
}

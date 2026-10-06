import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../repositories/vocab_repository.dart';

class VocabExistsUseCase {
  VocabExistsUseCase([VocabRepository? repository]) : _repository = repository ?? getSingleton<VocabRepository>();

  final VocabRepository _repository;

  /// Từ đã có trong sổ nào chưa.
  Future<Result<bool>> execute(String text) => _repository.exists(text);
}

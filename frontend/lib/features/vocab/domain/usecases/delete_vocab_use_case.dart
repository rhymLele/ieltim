import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../repositories/vocab_repository.dart';

class DeleteVocabUseCase {
  DeleteVocabUseCase([VocabRepository? repository]) : _repository = repository ?? getSingleton<VocabRepository>();

  final VocabRepository _repository;

  /// Xoá một từ khỏi sổ.
  Future<Result<void>> execute(String id) => _repository.delete(id);
}

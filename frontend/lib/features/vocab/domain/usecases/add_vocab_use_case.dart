import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/result.dart';
import '../entities/vocab_entry.dart';
import '../repositories/vocab_repository.dart';

class AddVocabUseCase {
  AddVocabUseCase([VocabRepository? repository]) : _repository = repository ?? getSingleton<VocabRepository>();

  final VocabRepository _repository;

  /// Thêm từ vào sổ. Trùng trong cùng sổ → `VocabExistsException`.
  Future<Result<VocabEntry>> execute(NewVocab vocab) => _repository.add(vocab);
}
